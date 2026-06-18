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

typedef ScopeOptions = {
	moduleName:String,
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

	public static macro function externalTo(target:Expr):Expr {
		#if macro
		var parsed = externalTargetLiteral(target, "externalTo");
		return macro @:pos(target.pos) rails.routing.RouteTarget.to($v{parsed.controller}, $v{parsed.action});
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

	public static macro function options(path:Expr, target:Expr, ?options:Expr):Expr {
		return verb("options", path, target, options);
	}

	public static macro function head(path:Expr, target:Expr, ?options:Expr):Expr {
		return verb("head", path, target, options);
	}

	public static macro function match(path:Expr, target:Expr, verbs:Expr, ?options:Expr):Expr {
		#if macro
		var checkedPath = routePathLiteral(path, "match");
		var checkedVerbs = httpVerbList(verbs, "match via");
		var optionsInfo = routeOptions(options);
		return macro @:pos(path.pos) rails.routing.RouteDecl.match($v{checkedPath}, $target, $e{stringArray(checkedVerbs, verbs.pos)}, $v{optionsInfo.name});
		#else
		return macro null;
		#end
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

	public static macro function rubyConst(name:Expr):Expr {
		#if macro
		return macro $v{rubyConstantLiteral(name, "rubyConst")};
		#else
		return macro null;
		#end
	}

	public static macro function at(path:Expr):Expr {
		#if macro
		return macro $v{routePathLiteral(path, "at")};
		#else
		return macro null;
		#end
	}

	public static macro function resources(model:Expr, controller:Expr, ?options:Expr, ?children:Expr):Expr {
		#if macro
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
			$e{stringArray([for (action in optionsInfo.except) railsActionName(controllerType, action)], model.pos)}, $v{optionsInfo.param},
			$e{routeDeclArray(children, model.pos)});
		#else
		return macro null;
		#end
	}

	public static macro function resource(model:Expr, controller:Expr, ?options:Expr, ?children:Expr):Expr {
		#if macro
		var modelType = modelClass(model, "resource");
		var controllerType = controllerClass(controller, "resource");
		var optionsInfo = resourceOptions(options);
		for (action in optionsInfo.only) {
			validateAction(controllerType, action, options == null ? controller.pos : options.pos, "resource only");
		}
		for (action in optionsInfo.except) {
			validateAction(controllerType, action, options == null ? controller.pos : options.pos, "resource except");
		}
		return macro @:pos(model.pos) rails.routing.RouteDecl.resource($v{modelSingularRouteName(modelType)}, $v{controllerPath(controllerType)},
			$e{stringArray([for (action in optionsInfo.only) railsActionName(controllerType, action)], model.pos)},
			$e{stringArray([for (action in optionsInfo.except) railsActionName(controllerType, action)], model.pos)}, $v{optionsInfo.param},
			$e{routeDeclArray(children, model.pos)});
		#else
		return macro null;
		#end
	}

	public static macro function collection(children:Expr):Expr {
		#if macro
		return macro @:pos(children.pos) rails.routing.RouteDecl.collection($e{routeDeclArray(children, children.pos)});
		#else
		return macro null;
		#end
	}

	public static macro function member(children:Expr):Expr {
		#if macro
		return macro @:pos(children.pos) rails.routing.RouteDecl.member($e{routeDeclArray(children, children.pos)});
		#else
		return macro null;
		#end
	}

	public static macro function namespace(name:Expr, children:Expr):Expr {
		#if macro
		var checkedName = routeNameLiteral(name, "namespace");
		return macro @:pos(name.pos) rails.routing.RouteDecl.namespace($v{checkedName}, $e{routeDeclArray(children, children.pos)});
		#else
		return macro null;
		#end
	}

	public static macro function scope(path:Expr, optionsOrChildren:Expr, ?children:Expr):Expr {
		#if macro
		var checkedPath = routePathLiteral(path, "scope");
		var optionsInfo = children == null ? {moduleName: "", name: ""} : scopeOptions(optionsOrChildren);
		var childExpr = children == null ? optionsOrChildren : children;
		return macro @:pos(path.pos) rails.routing.RouteDecl.scope($v{checkedPath}, $v{optionsInfo.moduleName}, $v{optionsInfo.name},
			$e{routeDeclArray(childExpr, childExpr.pos)});
		#else
		return macro null;
		#end
	}

	public static macro function controller(controller:Expr, children:Expr):Expr {
		#if macro
		var classType = controllerClass(controller, "controller");
		return macro @:pos(controller.pos) rails.routing.RouteDecl.controller($v{controllerPath(classType)}, $e{routeDeclArray(children, children.pos)});
		#else
		return macro null;
		#end
	}

	public static macro function mountExternal(app:Expr, path:Expr, ?options:Expr):Expr {
		#if macro
		var checkedApp = rubyConstantLiteral(app, "mountExternal app");
		var checkedPath = routePathLiteral(path, "mountExternal at");
		var optionsInfo = routeOptions(options);
		return macro @:pos(app.pos) rails.routing.RouteDecl.mount($v{checkedApp}, $v{checkedPath}, $v{optionsInfo.name});
		#else
		return macro null;
		#end
	}

	public static macro function uncheckedRubyRoute(line:Expr):Expr {
		#if macro
		if (!Context.defined("railshx_allow_unchecked_routes")) {
			Context.error("uncheckedRubyRoute(...) requires -D railshx_allow_unchecked_routes. Prefer typed route declarations or checked escapes such as externalTo(...).",
				line.pos);
		}
		var checkedLine = rawRubyRouteLine(line, "uncheckedRubyRoute");
		return macro @:pos(line.pos) rails.routing.RouteDecl.rawRuby($v{checkedLine});
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

	static function routeDeclArray(children:Null<Expr>, pos:Position):Expr {
		if (children == null || isNullLiteral(children)) {
			return {expr: EArrayDecl([]), pos: pos};
		}
		var entries = switch (unwrap(children).expr) {
			case EBlock(values): values;
			case EArrayDecl(values): values;
			case _: [children];
		}
		return {expr: EArrayDecl(entries), pos: children.pos};
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

	static function scopeOptions(options:Null<Expr>):ScopeOptions {
		if (options == null || isNullLiteral(options)) {
			return {moduleName: "", name: ""};
		}
		return switch (unwrap(options).expr) {
			case EObjectDecl(fields):
				var moduleName = "";
				var name = "";
				for (field in fields) {
					switch (field.field) {
						case "moduleName":
							moduleName = routeNameLiteral(field.expr, "scope moduleName");
						case "asName":
							name = routeNameLiteral(field.expr, "scope asName");
						case other:
							Context.error('scope unsupported option "$other". Supported options are moduleName and asName.', field.expr.pos);
					}
				}
				{moduleName: moduleName, name: name};
			case _:
				Context.error("scope options must be an object literal.", options.pos);
				{moduleName: "", name: ""};
		}
	}

	static function routePathLiteral(expr:Expr, context:String):String {
		var value = wrappedStringLiteral(expr, ["at"], context + " path");
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
		validateRoutePathSyntax(value, context, expr.pos);
		return value;
	}

	static function validateRoutePathSyntax(value:String, context:String, pos:Position):Void {
		var optionalDepth = 0;
		var i = 0;
		while (i < value.length) {
			var ch = value.charAt(i);
			switch (ch) {
				case "(":
					optionalDepth++;
					if (optionalDepth > 1) {
						Context.error(context + " path optional segments cannot be nested.", pos);
					}
				case ")":
					optionalDepth--;
					if (optionalDepth < 0) {
						Context.error(context + " path has an unmatched optional segment close.", pos);
					}
				case ":":
					i = validateRoutePathIdentifier(value, i + 1, context + " path param", pos);
				case "*":
					i = validateRoutePathIdentifier(value, i + 1, context + " path glob", pos);
				case _:
			}
			i++;
		}
		if (optionalDepth != 0) {
			Context.error(context + " path has an unclosed optional segment.", pos);
		}
	}

	static function validateRoutePathIdentifier(value:String, start:Int, context:String, pos:Position):Int {
		if (start >= value.length || !isIdentifierStart(value.charCodeAt(start))) {
			Context.error(context + " must have a name like :id or *path.", pos);
			return start;
		}
		var i = start + 1;
		while (i < value.length && isIdentifierPart(value.charCodeAt(i))) {
			i++;
		}
		return i - 1;
	}

	static function isIdentifierStart(code:Int):Bool {
		return (code >= "A".code && code <= "Z".code) || (code >= "a".code && code <= "z".code) || code == "_".code;
	}

	static function isIdentifierPart(code:Int):Bool {
		return isIdentifierStart(code) || (code >= "0".code && code <= "9".code);
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

	static function externalTargetLiteral(expr:Expr, context:String):{controller:String, action:String} {
		var value = stringLiteral(expr, context);
		var parts = value.split("#");
		if (parts.length != 2 || parts[0] == "" || parts[1] == "") {
			Context.error(context + ' expects a literal Rails target such as "legacy/posts#show".', expr.pos);
		}
		var controller = parts[0];
		var action = parts.length > 1 ? parts[1] : "";
		if (!~/^[a-z][a-z0-9_]*(\/[a-z][a-z0-9_]*)*$/.match(controller)) {
			Context.error(context + " controller path must be a safe slash-separated Rails controller path.", expr.pos);
		}
		if (!~/^[a-z][a-z0-9_]*$/.match(action)) {
			Context.error(context + " action must be a safe snake_case Rails action name.", expr.pos);
		}
		return {controller: controller, action: action};
	}

	static function rubyConstantLiteral(expr:Expr, context:String):String {
		var value = wrappedStringLiteral(expr, ["rubyConst"], context);
		if (!~/^[A-Z][A-Za-z0-9_]*(::[A-Z][A-Za-z0-9_]*)*$/.match(value)) {
			Context.error(context + ' expects a safe Ruby constant path such as "Sidekiq::Web".', expr.pos);
		}
		return value;
	}

	static function rawRubyRouteLine(expr:Expr, context:String):String {
		var value = stringLiteral(expr, context);
		if (value == "") {
			Context.error(context + " line must not be empty.", expr.pos);
		}
		for (i in 0...value.length) {
			if (value.charCodeAt(i) < 32) {
				Context.error(context + " line must be a single-line literal without control characters.", expr.pos);
			}
		}
		return value;
	}

	static function wrappedStringLiteral(expr:Expr, wrappers:Array<String>, context:String):String {
		return switch (unwrap(expr).expr) {
			case ECall(callee, [arg]):
				switch (unwrap(callee).expr) {
					case EConst(CIdent(name)) if (wrappers.indexOf(name) != -1):
						stringLiteral(arg, context);
					case _:
						stringLiteral(expr, context);
				}
			case _:
				stringLiteral(expr, context);
		}
	}

	static function stringLiteral(expr:Expr, context:String):String {
		return switch (unwrap(expr).expr) {
			case EConst(CString(value, _)): value;
			case _:
				Context.error(context + " must be a literal string.", expr.pos);
				"";
		}
	}

	static function httpVerbList(expr:Expr, context:String):Array<String> {
		return switch (unwrap(expr).expr) {
			case EArrayDecl(values):
				if (values.length == 0) {
					Context.error(context + " must include at least one HTTP verb identifier.", expr.pos);
				}
				[for (value in values) httpVerb(value, context)];
			case _:
				[httpVerb(expr, context)];
		}
	}

	static function httpVerb(expr:Expr, context:String):String {
		var name = identifier(expr, context + " expects HTTP verb identifiers such as [GET, POST].");
		return switch (name) {
			case "GET": "get";
			case "POST": "post";
			case "PATCH": "patch";
			case "PUT": "put";
			case "DELETE": "delete";
			case "OPTIONS": "options";
			case "HEAD": "head";
			case _:
				Context.error(context + ' unsupported HTTP verb "$name". Supported verbs are GET, POST, PATCH, PUT, DELETE, OPTIONS, and HEAD.', expr.pos);
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

	static function modelSingularRouteName(classType:ClassType):String {
		var plural = modelRouteName(classType);
		if (StringTools.endsWith(plural, "s") && plural.length > 1) {
			return plural.substr(0, plural.length - 1);
		}
		return plural;
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
