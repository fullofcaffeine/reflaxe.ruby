package reflaxe.ruby.compiler;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Type.TVar;
import haxe.macro.Type.TypedExpr;
import haxe.macro.TypeTools;
import reflaxe.ruby.ast.RubyAST.RubyExpr;
import reflaxe.ruby.ast.RubyAST.RubyStatement;
import reflaxe.ruby.ast.RubyRuntimePlan;
import reflaxe.ruby.ast.RubyRuntimePlan.RubyRuntimeHelper;

/** Structural exception output plus the exact HXRuby core-use count it owns. **/
typedef RubyExceptionLoweringResult = {
	var expr:RubyExpr;
	var coreRuntimeUseCount:Int;
}

private typedef RubyCatchDispatch = {
	var body:Array<RubyStatement>;
	var coreRuntimeUseCount:Int;
}

/**
	Owns the vertical Haxe-to-Ruby exception boundary.

	Reflaxe supplies pre-filter typed catches, so Ruby rescue syntax alone cannot
	represent Haxe source-order type dispatch. This module retains those source
	facts only while it builds ordinary RubyAST. Its callbacks keep expression
	compilation, local allocation, and target type naming under the orchestration
	context that already owns them; the returned count lets that context register
	per-file HXRuby core requirements without hidden module state.
**/
class RubyExceptionLowering {
	public static function compileTry(tryExpr:TypedExpr, catches:Array<{v:TVar, expr:TypedExpr}>, compileBody:TypedExpr->Array<RubyStatement>,
			localName:TVar->String, allocateLocal:String->String, rubyTypeName:Type->Null<String>):RubyExceptionLoweringResult {
		if (catches == null || catches.length == 0) {
			Context.error("RubyHx received a typed try expression without a catch arm.", tryExpr.pos);
			return {expr: RubyNil, coreRuntimeUseCount: 0};
		}

		var exceptionName = allocateLocal("haxe_exception");
		var thrownName = allocateLocal("haxe_thrown");
		var exceptionValue = RubyLocal(exceptionName);
		var thrownValue = RubyLocal(thrownName);
		var body = compileBody(tryExpr);
		var dispatch = compileCatchDispatch(catches, 0, exceptionValue, thrownValue, compileBody, localName, rubyTypeName);
		var rescueBody:Array<RubyStatement> = [
			RubyAssign(thrownValue,
				RubyConditional(RubyCall(exceptionValue, "is_a?", [RubyLocal("HxException")]), RubyMember(exceptionValue, "value"), exceptionValue))
		];
		rescueBody = rescueBody.concat(dispatch.body);
		return {
			expr: RubyBeginRescue(body, [
				{
					exceptionClasses: ["StandardError"],
					binding: exceptionName,
					body: rescueBody
				}
			]),
			coreRuntimeUseCount: dispatch.coreRuntimeUseCount
		};
	}

	/** Builds a structural raise whose closed runtime intent preserves identity. **/
	public static function compileThrow(thrown:TypedExpr, compileExpr:TypedExpr->RubyExpr):RubyExceptionLoweringResult {
		return {
			expr: RubyRaise(runtimeCall(RubyRuntimeHelper.ExceptionWrap, [compileExpr(thrown)])),
			coreRuntimeUseCount: 0
		};
	}

	static function compileCatchDispatch(catches:Array<{v:TVar, expr:TypedExpr}>, index:Int, exceptionValue:RubyExpr, thrownValue:RubyExpr,
			compileBody:TypedExpr->Array<RubyStatement>, localName:TVar->String, rubyTypeName:Type->Null<String>):RubyCatchDispatch {
		if (index >= catches.length) {
			return {
				body: [RubyExprStatement(RubyRaise())],
				coreRuntimeUseCount: 0
			};
		}
		var current = catches[index];
		var catchesHaxeException = isExactHaxeExceptionType(current.v.t);
		var catchesAnything = isDynamicType(current.v.t) || catchesHaxeException;
		// Unlike the unwrapped value wildcard, haxe.Exception is a typed facade.
		// Native Ruby errors need a carrier exposing get_message while retaining
		// the original exception for an identity-preserving explicit rethrow.
		var bindingValue = catchesHaxeException ? runtimeCall(RubyRuntimeHelper.ExceptionCaught, [exceptionValue]) : thrownValue;
		var body:Array<RubyStatement> = [RubyAssign(RubyLocal(localName(current.v)), bindingValue)];
		body = body.concat(compileBody(current.expr));
		if (catchesAnything) {
			return {body: body, coreRuntimeUseCount: 0};
		}

		var catchTypeName = rubyTypeName(current.v.t);
		if (catchTypeName == null) {
			Context.error("RubyHx cannot resolve catch type `" + TypeTools.toString(current.v.t) + "` to a Ruby runtime type.", current.expr.pos);
			return {
				body: [RubyExprStatement(RubyRaise())],
				coreRuntimeUseCount: 0
			};
		}
		var remaining = compileCatchDispatch(catches, index + 1, exceptionValue, thrownValue, compileBody, localName, rubyTypeName);
		return {
			body: [
				RubyIfStmt(runtimeCall(RubyRuntimeHelper.IsOfType, [thrownValue, RubyLocal(catchTypeName)]), body, remaining.body)
			],
			coreRuntimeUseCount: 1 + remaining.coreRuntimeUseCount
		};
	}

	static function runtimeCall(helper:RubyRuntimeHelper, args:Array<RubyExpr>):RubyExpr {
		return RubyRuntimeCall(RubyRuntimePlan.select(helper), args);
	}

	static function isDynamicType(type:Type):Bool {
		return switch (TypeTools.follow(type)) {
			case TDynamic(_): true;
			case _: false;
		}
	}

	static function isExactHaxeExceptionType(type:Type):Bool {
		return switch (TypeTools.follow(type)) {
			case TInst(classRef, _):
				var classType = classRef.get();
				classType.pack.concat([classType.name]).join(".") == "haxe.Exception";
			case _:
				false;
		}
	}
}
#end
