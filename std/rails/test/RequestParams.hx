package rails.test;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.ruby.naming.RubyNaming;
#end

/**
	Phantom type for compiler-erased Rails request params payloads.

	The Ruby compiler lowers `RequestParams.model(...)` calls directly to a
	Rails params hash. This carrier gives Haxe request options a precise type
	without exposing a raw dynamic hash in app-facing test code.
**/
class RequestParamsPayload<TAttrs> {
	private function new() {}
}

/**
	Typed request-param helpers for Haxe-authored Rails tests.

	`model(Todo.railsParamKey, {...})` is a macro so it can validate object
	keys against the model's `@:railsColumn` fields before the Ruby compiler
	lowers the marker to a normal Rails params hash such as
	`{"todo" => {title: "Ship", is_completed: false}}`.
**/
class RequestParams {
	public static macro function model(root:Expr, attrs:Expr):Expr {
		var modelName = sourceRailsModelKey(root);
		if (modelName == null) {
			Context.error("RequestParams.model expects a generated model key such as Todo.railsParamKey.", root.pos);
		}
		var model = resolveModel(modelName, root.pos);
		validateRequestParamAttrs(model, attrs);
		return macro rails.test.RequestParams.modelRoot($v{RubyNaming.toLocalName(model.name)}, $attrs);
	}

	public static function modelRoot<TAttrs>(root:String, attrs:TAttrs):RequestParamsPayload<TAttrs> {
		throw "rails.test.RequestParams.modelRoot must be lowered by reflaxe.ruby.";
	}

	#if macro
	static function sourceRailsModelKey(expr:Expr):Null<String> {
		return switch (expr.expr) {
			case EField(owner, "railsParamKey"):
				sourceExprName(owner);
			case EParenthesis(inner) | ECheckType(inner, _):
				sourceRailsModelKey(inner);
			case _:
				null;
		}
	}

	static function sourceExprName(expr:Expr):Null<String> {
		return switch (expr.expr) {
			case EConst(CIdent(name)):
				name;
			case EField(owner, field):
				var prefix = sourceExprName(owner);
				prefix == null ? field : prefix + "." + field;
			case _:
				null;
		}
	}

	static function resolveModel(name:String, pos:Position):ClassType {
		return switch (Context.getType(name)) {
			case TInst(ref, _):
				ref.get();
			case _:
				Context.error('RequestParams.model expected $name to resolve to a RailsHx model class.', pos);
				throw "unreachable";
		}
	}

	static function validateRequestParamAttrs(model:ClassType, attrs:Expr):Void {
		var known = railsColumnNames(model);
		switch (attrs.expr) {
			case EObjectDecl(fields):
				for (field in fields) {
					if (!known.exists(field.field)) {
						Context.error('RequestParams.model field "${field.field}" is not a @:railsColumn field on ${model.name}.', field.expr.pos);
					}
				}
			case _:
				Context.error("RequestParams.model attrs must be an object literal so RailsHx can validate model fields.", attrs.pos);
		}
	}

	static function railsColumnNames(model:ClassType):Map<String, Bool> {
		var out = new Map<String, Bool>();
		for (field in model.fields.get()) {
			if (field.meta.has(":railsColumn")) {
				out.set(field.name, true);
			}
		}
		return out;
	}
	#end
}
