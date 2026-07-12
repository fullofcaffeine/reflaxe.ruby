package reflaxe.ruby.compiler;

#if (macro || reflaxe_runtime)
import haxe.macro.Type.TVar;
import haxe.macro.Type.TypedExpr;
import haxe.macro.TypedExprTools;

/**
	Owns the use analysis for a Haxe keyword-carrier parameter.

	A Ruby keyword method does not naturally receive the anonymous object that
	appears in its Haxe signature. Known field reads can bind directly to Ruby
	keyword locals (or the optional-key bucket), which produces the code a Ruby
	author would normally write. Returning, storing, mutating, reflecting over,
	or otherwise using the carrier as a value requires reconstructing its Haxe
	string-key hash. This conservative analysis decides when that reconstruction
	is semantically necessary; unfamiliar uses materialize instead of leaking a
	partially modeled carrier.
**/
class RubyKeywordSemantics {
	public static function requiresMaterialization(body:TypedExpr, parameter:TVar):Bool {
		var required = false;

		function scan(expr:TypedExpr):Void {
			if (required || expr == null) {
				return;
			}
			switch (expr.expr) {
				case TBinop(OpAssign, lhs, rhs) | TBinop(OpAssignOp(_), lhs, rhs) if (isParameterField(lhs, parameter.id)):
					// Ruby keyword locals are inputs, not a mutable object. Preserve Haxe
					// anonymous-object mutation by rebuilding the carrier before the body.
					required = true;
					scan(rhs);
				case TUnop(OpIncrement, _, inner) | TUnop(OpDecrement, _, inner) if (isParameterField(inner, parameter.id)):
					required = true;
				case TCall(callee, [target, key]) if (isReflectHasField(callee)
					&& isParameterLocal(target, parameter.id)
					&& isLiteralString(key)):
					// Presence is representable directly: required keywords are always
					// present and optional keywords use Hash#key? on the captured bucket.
				case TField(target, _) if (isParameterLocal(target, parameter.id)):
					// A known typed field read can bind straight to its keyword value.
				case TLocal(variable) if (variable.id == parameter.id):
					required = true;
				case _:
					TypedExprTools.iter(expr, scan);
			}
		}

		scan(body);
		return required;
	}

	public static function isParameterLocal(expr:TypedExpr, parameterId:Int):Bool {
		return switch (expr.expr) {
			case TLocal(variable): variable.id == parameterId;
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _): isParameterLocal(inner, parameterId);
			case _: false;
		}
	}

	public static function isReflectHasField(callee:TypedExpr):Bool {
		return switch (callee.expr) {
			case TField(_, FStatic(classRef, fieldRef)): var classType = classRef.get(); classType.pack.length == 0 && classType.name == "Reflect" && fieldRef.get()
					.name == "hasField";
			case _: false;
		}
	}

	static function isParameterField(expr:TypedExpr, parameterId:Int):Bool {
		return switch (expr.expr) {
			case TField(target, _): isParameterLocal(target, parameterId);
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _): isParameterField(inner, parameterId);
			case _: false;
		}
	}

	static function isLiteralString(expr:TypedExpr):Bool {
		return switch (expr.expr) {
			case TConst(TString(_)): true;
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _): isLiteralString(inner);
			case _: false;
		}
	}
}
#end
