package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.MetaAccess;
import reflaxe.ruby.naming.RubyNaming;

typedef ResourceOptions = {
	only:Array<String>,
	except:Array<String>,
	param:String
}

typedef RouteOptions = {
	name:String
}
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

	public static macro function get(path:Expr, target:Expr, ?options:Expr):Expr {
		return verb("get", path, target, options);
	}

	public static macro function post(path:Expr, target:Expr, ?options:Expr):Expr {
		return verb("post", path, target, options);
	}

	public static macro function patch(path:Expr, target:Expr, ?options:Expr):Expr {
		return verb("patch", path, target, options);
	}

	public static macro function put(path:Expr, target:Expr, ?options:Expr):Expr {
		return verb("put", path, target, options);
	}

	public static macro function delete(path:Expr, target:Expr, ?options:Expr):Expr {
		return verb("delete", path, target, options);
	}

	public static macro function routeName(name:Expr):Expr {
		#if macro
		return macro $v{routeNameLiteral(name, "routeName")};
		#else
		return macro null;
		#end
	}

	public static macro function paramName(name:Expr):Expr {
		#if macro
		return macro $v{routeNameLiteral(name, "paramName")};
		#else
		return macro null;
		#end
	}

	public static macro function resources(model:Expr, controller:Expr, ?options:Expr, ?children:Expr):Expr {
		#if macro
		if (children != null && !isNullLiteral(children)) {
			Context.error("resources children blocks are not implemented in this first RailsHx routing slice. File/follow the routing bead before using member/collection here.",
				children.pos);
		}
		var modelType = modelClass(model, "resources");
		var controllerType = controllerClass(controller, "resources");
		var optionsInfo = resourceOptions(options);
		for (action in optionsInfo.only) {
			validateAction(controllerType, action, options == null ? controller.pos : options.pos, "resources only");
		}
		for (action in optionsInfo.except) {
			validateAction(controllerType, action, options == null ? controller.pos : options.pos, "resources except");
		}
		return macro @:pos(model.pos) rails.routing.RouteDecl.resources($v{modelRouteName(modelType)}, $v{controllerPath(controllerType)},
			$e{stringArray([for (action in optionsInfo.only) railsActionName(controllerType, action)], model.pos)},
			$e{stringArray([for (action in optionsInfo.except) railsActionName(controllerType, action)], model.pos)}, $v{optionsInfo.param});
		#else
		return macro null;
		#end
	}

	#if macro
	static function verb(method:String, path:Expr, target:Expr, ?options:Expr):Expr {
		var checkedPath = routePathLiteral(path, method);
		var optionsInfo = routeOptions(options);
		return macro @:pos(path.pos) rails.routing.RouteDecl.verb($v{method}, $v{checkedPath}, $target, $v{optionsInfo.name});
	}

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

	static function resourceOptions(options:Null<Expr>):ResourceOptions {
		if (options == null) {
			return {only: [], except: [], param: ""};
		}
		return switch (unwrap(options).expr) {
			case EObjectDecl(fields):
				var only:Null<Array<String>> = null;
				var except:Null<Array<String>> = null;
				var param = "";
				for (field in fields) {
					switch (field.field) {
						case "only":
							only = actionList(field.expr, "resources only");
						case "except":
							except = actionList(field.expr, "resources except");
						case "param":
							param = routeNameLiteral(field.expr, "resources param");
						case other:
							Context.error('resources unsupported option "$other". Supported options are only, except, and param.', field.expr.pos);
					}
				}
				if (only != null && except != null) {
					Context.error("resources cannot combine only and except; choose one Rails route filter.", options.pos);
				}
				{only: only == null ? [] : only, except: except == null ? [] : except, param: param};
			case _:
				Context.error("resources options must be an object literal.", options.pos);
				{only: [], except: [], param: ""};
		}
	}

	static function routeOptions(options:Null<Expr>):RouteOptions {
		if (options == null || isNullLiteral(options)) {
			return {name: ""};
		}
		return switch (unwrap(options).expr) {
			case EObjectDecl(fields):
				var name = "";
				for (field in fields) {
					switch (field.field) {
						case "asName":
							name = routeNameLiteral(field.expr, "route asName");
						case other:
							Context.error('route unsupported option "$other". Supported option is asName.', field.expr.pos);
					}
				}
				{name: name};
			case _:
				Context.error("route options must be an object literal.", options.pos);
				{name: ""};
		}
	}

	static function routePathLiteral(expr:Expr, context:String):String {
		var value = stringLiteral(expr, context + " path");
		if (value == "") {
			Context.error(context + " path must not be empty.", expr.pos);
		}
		if (value.indexOf("\\") >= 0 || value.indexOf("..") >= 0) {
			Context.error(context + " path must be a safe Rails route literal without backslashes or traversal.", expr.pos);
		}
		for (i in 0...value.length) {
			var code = value.charCodeAt(i);
			if (code < 32 || value.charAt(i) == "\"" || value.charAt(i) == "'") {
				Context.error(context + " path contains an unsafe character.", expr.pos);
			}
		}
		return value;
	}

	static function routeNameLiteral(expr:Expr, context:String):String {
		var value = switch (unwrap(expr).expr) {
			case ECall(callee, [arg]):
				switch (unwrap(callee).expr) {
					case EConst(CIdent("routeName")) | EConst(CIdent("paramName")):
						stringLiteral(arg, context);
					case _:
						stringLiteral(expr, context);
				}
			case _:
				stringLiteral(expr, context);
		}
		if (!~/^[a-z][a-z0-9_]*$/.match(value)) {
			Context.error(context + ' must be a snake_case literal such as "admin_posts".', expr.pos);
		}
		return value;
	}

	static function stringLiteral(expr:Expr, context:String):String {
		return switch (unwrap(expr).expr) {
			case EConst(CString(value, _)): value;
			case _:
				Context.error(context + " must be a literal string.", expr.pos);
				"";
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
