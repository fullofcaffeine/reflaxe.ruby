package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.MetaAccess;
import reflaxe.ruby.naming.RubyNaming;
#end

/**
	Typed Haxe authoring layer for Rails routes.

	Haxe macros can only transform syntax that the Haxe parser accepts, so
	RailsHx routes use a contextual field:

	```haxe
	@:railsRoutes
	class AppRoutes {
		static final routes = {
			root(to(TodosController, index));
			resources(Todo, TodosController, {only: [index, create]});
		};
	}
	```

	The calls below expand to compiler marker calls under `rails.routing`. The
	Ruby compiler consumes those markers, emits ordinary Rails `config/routes.rb`,
	and does not generate a Ruby `AppRoutes` class.
**/
class RoutesDsl {
	public static macro function to(controller:Expr, action:Expr):Expr {
		#if macro
		var classType = controllerClass(controller, "to");
		var actionName = identifier(action, "to expects an action method reference such as index.");
		validateAction(classType, actionName, action.pos, "to");
		return macro @:pos(action.pos) rails.routing.RouteTarget.to($v{controllerPath(classType)}, $v{railsActionName(classType, actionName)});
		#else
		return macro null;
		#end
	}

	public static macro function root(target:Expr):Expr {
		return macro @:pos(target.pos) rails.routing.RouteDecl.root($target);
	}

	public static macro function resources(model:Expr, controller:Expr, ?options:Expr, ?children:Expr):Expr {
		#if macro
		if (children != null && !isNullLiteral(children)) {
			Context.error("resources children blocks are not implemented in this first RailsHx routing slice. File/follow the routing bead before using member/collection here.",
				children.pos);
		}
		var modelType = modelClass(model, "resources");
		var controllerType = controllerClass(controller, "resources");
		var only = routeOnly(options);
		for (action in only) {
			validateAction(controllerType, action, options == null ? controller.pos : options.pos, "resources only");
		}
		return macro @:pos(model.pos) rails.routing.RouteDecl.resources($v{modelRouteName(modelType)}, $v{controllerPath(controllerType)},
			$e{stringArray(only, model.pos)});
		#else
		return macro null;
		#end
	}

	#if macro
	static function controllerClass(expr:Expr, context:String):ClassType {
		return switch (Context.typeExpr(expr).expr) {
			case TTypeExpr(TClassDecl(classRef)):
				var classType = classRef.get();
				if (!hasMeta(classType.meta, ":railsController") && !hasMeta(classType.meta, ":railsExternalController")) {
					Context.error(context + " expects a @:railsController or @:railsExternalController class reference.", expr.pos);
				}
				classType;
			case _:
				Context.error(context + " expects a controller class reference.", expr.pos);
				null;
		}
	}

	static function modelClass(expr:Expr, context:String):ClassType {
		return switch (Context.typeExpr(expr).expr) {
			case TTypeExpr(TClassDecl(classRef)):
				var classType = classRef.get();
				if (!hasMeta(classType.meta, ":railsModel")) {
					Context.error(context + " expects a @:railsModel class reference.", expr.pos);
				}
				classType;
			case _:
				Context.error(context + " expects a model class reference.", expr.pos);
				null;
		}
	}

	static function routeOnly(options:Null<Expr>):Array<String> {
		if (options == null) {
			return ["index", "show", "create", "update", "destroy"];
		}
		return switch (unwrap(options).expr) {
			case EObjectDecl(fields):
				var only:Null<Array<String>> = null;
				for (field in fields) {
					switch (field.field) {
						case "only":
							only = actionList(field.expr, "resources only");
						case other:
							Context.error('resources unsupported option "$other" in this first routing slice. Use only for now.', field.expr.pos);
					}
				}
				only == null ? ["index", "show", "create", "update", "destroy"] : only;
			case _:
				Context.error("resources options must be an object literal.", options.pos);
				[];
		}
	}

	static function actionList(expr:Expr, context:String):Array<String> {
		return switch (unwrap(expr).expr) {
			case EArrayDecl(values):
				[
					for (value in values)
						identifier(value, context + " expects action identifiers such as [index, create].")
				];
			case _:
				[
					identifier(expr, context + " expects action identifiers such as [index, create].")
				];
		}
	}

	static function validateAction(classType:ClassType, name:String, pos:Position, context:String):Void {
		if (classType == null || name == "") {
			return;
		}
		var field = findInstanceMethodIn(classType, name);
		if (field == null) {
			Context.error(context + ' references missing controller action "$name".', pos);
			return;
		}
		switch (field.kind) {
			case FMethod(_):
			case _:
				Context.error(context + ' reference "$name" is not a controller method.', pos);
		}
	}

	static function findInstanceMethodIn(classType:ClassType, name:String):Null<ClassField> {
		for (field in classType.fields.get()) {
			if (field.name == name) {
				return field;
			}
		}
		if (classType.superClass != null) {
			return findInstanceMethodIn(classType.superClass.t.get(), name);
		}
		return null;
	}

	static function railsActionName(classType:ClassType, name:String):String {
		var field = findInstanceMethodIn(classType, name);
		if (field == null) {
			return RubyNaming.toMethodName(name);
		}
		var native = metaString(field.meta, ":native");
		return native == null ? RubyNaming.toMethodName(name) : native;
	}

	static function controllerPath(classType:ClassType):String {
		var external = metaString(classType.meta, ":railsExternalController");
		if (external != null) {
			return external;
		}
		var segments = classType.pack.copy();
		var name = classType.name;
		var suffix = "Controller";
		if (StringTools.endsWith(name, suffix)) {
			name = name.substr(0, name.length - suffix.length);
		}
		segments.push(RubyNaming.fileName(name));
		return segments.join("/");
	}

	static function modelRouteName(classType:ClassType):String {
		var explicit = metaString(classType.meta, ":railsModel");
		if (explicit != null) {
			return explicit;
		}
		return RubyNaming.fileName(classType.name) + "s";
	}

	static function identifier(expr:Expr, message:String):String {
		return switch (unwrap(expr).expr) {
			case EConst(CIdent(name)): name;
			case _:
				Context.error(message, expr.pos);
				"";
		}
	}

	static function stringArray(values:Array<String>, pos:Position):Expr {
		return {
			expr: EArrayDecl([for (value in values) macro $v{value}]),
			pos: pos
		};
	}

	static function metaString(meta:MetaAccess, name:String):Null<String> {
		if (meta == null) {
			return null;
		}
		var entries = meta.extract(name);
		if (entries.length == 0 || entries[0].params == null || entries[0].params.length == 0) {
			return null;
		}
		return switch (entries[0].params[0].expr) {
			case EConst(CString(value, _)) if (value.length > 0): value;
			case _: null;
		}
	}

	static function hasMeta(meta:MetaAccess, name:String):Bool {
		return meta != null && meta.has(name);
	}

	static function isNullLiteral(expr:Expr):Bool {
		return switch (unwrap(expr).expr) {
			case EConst(CIdent("null")): true;
			case _: false;
		}
	}

	static function unwrap(expr:Expr):Expr {
		return switch (expr.expr) {
			case EParenthesis(inner) | ECheckType(inner, _) | EMeta(_, inner): unwrap(inner);
			case _: expr;
		}
	}
	#end
}
