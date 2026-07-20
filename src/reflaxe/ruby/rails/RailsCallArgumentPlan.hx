package reflaxe.ruby.rails;

#if (macro || reflaxe_runtime)
import haxe.macro.Type.ClassType;
import haxe.macro.Type.TypedExpr;
import haxe.macro.TypeTools;
import reflaxe.ruby.naming.RubyNaming;

/** One source field retained for a Rails `locals:` object literal. **/
typedef RailsLocalsLiteralField = {
	var rubyName:String;
	var value:TypedExpr;
}

/** One declared field projected from a stable typed `locals:` carrier. **/
typedef RailsLocalsProjectionField = {
	var haxeName:String;
	var rubyName:String;
}

/** Closed source-level choice for a Rails response status argument. **/
enum RailsStatusArgumentPlan {
	RailsStatusSymbol(name:String);
	RailsStatusExpression(value:TypedExpr);
}

/** Closed source-level choice for a Rails `locals:` keyword value. **/
enum RailsLocalsArgumentPlan {
	RailsLocalsLiteral(fields:Array<RailsLocalsLiteralField>);
	RailsLocalsProjection(receiver:TypedExpr, fields:Array<RailsLocalsProjectionField>);
}

/**
	Classifies the Rails-specific values shared by two output boundaries.

	Structured `@:rubyKwargs` calls need RubyAST values, while a few validated
	Rails test/Turbo emitters still own target text. Status symbolization and
	`locals:` projection are source-typing decisions, so this service makes them
	once and lets each consumer choose only its representation. It deliberately
	does not mirror general `TypedExpr` structure or encode ordinary Ruby call syntax.

	The nominal host is intentional: Haxe 4.3.7 needs a main type matching this
	module so other modules can import both these helpers and the auxiliary plan
	types. The class is macro-only compiler structure, not emitted Ruby API.
**/
class RailsCallArgumentPlan {
	public static function classifyStatus(expr:TypedExpr):Null<RailsStatusArgumentPlan> {
		var source = unwrap(expr);
		return switch (source.expr) {
			case TConst(TString(value)):
				RailsStatusSymbol(RubyNaming.toLocalName(value));
			case TField(_, FStatic(classRef, fieldRef)) if (isStatusType(classRef.get())):
				RailsStatusSymbol(RubyNaming.toLocalName(fieldRef.get().name));
			case TCall(callee, [value]) if (isNamedStatusCall(callee)):
				switch (unwrap(value).expr) {
					case TConst(TString(literal)): RailsStatusSymbol(RubyNaming.toLocalName(literal));
					case _: RailsStatusExpression(value);
				}
			case _:
				null;
		}
	}

	public static function classifyLocals(expr:TypedExpr):Null<RailsLocalsArgumentPlan> {
		var source = unwrap(expr);
		return switch (source.expr) {
			case TObjectDecl(fields):
				RailsLocalsLiteral([
					for (field in fields)
						{
							rubyName: RubyNaming.toLocalName(field.name),
							value: field.expr
						}
				]);
			case TLocal(_):
				var fields = switch (TypeTools.follow(source.t)) {
					case TAnonymous(anonRef): anonRef.get().fields;
					case _: null;
				}
				if (fields == null || fields.length == 0) {
					null;
				} else {
					RailsLocalsProjection(source, [
						for (field in fields)
							{
								haxeName: field.name,
								rubyName: RubyNaming.toLocalName(field.name)
							}
					]);
				}
			case _:
				null;
		}
	}

	static function isNamedStatusCall(callee:TypedExpr):Bool {
		return switch (unwrap(callee).expr) {
			case TField(_, FStatic(classRef, fieldRef)): fieldRef.get().name == "named" && isStatusType(classRef.get());
			case _:
				false;
		}
	}

	static function isStatusType(classType:ClassType):Bool {
		var name = fullTypeName(classType);
		// Haxe places an abstract's implementation class in an underscore-prefixed
		// module package. Keep the allowlist Rails-specific: a different library's
		// abstract named Status must not gain Action Controller symbol semantics.
		return name == "rails.action_controller.Status"
			|| name == "rails.action_controller.Status_Impl_"
			|| name == "rails.action_controller._Status.Status_Impl_";
	}

	static function fullTypeName(classType:ClassType):String {
		return (classType.pack.length == 0 ? "" : classType.pack.join(".") + ".") + classType.name;
	}

	static function unwrap(expr:TypedExpr):TypedExpr {
		return switch (expr.expr) {
			case TCast(inner, _) | TParenthesis(inner) | TMeta(_, inner): unwrap(inner);
			case _: expr;
		}
	}
}
#end
