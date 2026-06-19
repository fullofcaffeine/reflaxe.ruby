package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.ruby.naming.RubyNaming;
#else
import haxe.macro.Expr;
#end

/**
	Typed Rails controller lifecycle declarations.

	Haxe macros can only reinterpret syntax that is already valid Haxe. RailsHx
	therefore uses a contextual static block:

	```haxe
	static final lifecycle = {
		beforeAction(authenticateUser, {only: [create]});
		rescueFrom(RecordNotFound, notFound);
	}
	```

	The individual calls validate method/type references and expand to typed
	compiler marker calls. The Ruby compiler only gives those markers meaning
	when they appear in `@:railsController`'s `lifecycle` field, then erases the
	field into normal Rails class macros.
**/
class ControllerDsl {
	public static macro function beforeAction(handler:Expr, ?options:Expr):Expr {
		return filter("before_action", handler, options);
	}

	public static macro function afterAction(handler:Expr, ?options:Expr):Expr {
		return filter("after_action", handler, options);
	}

	public static macro function aroundAction(handler:Expr, ?options:Expr):Expr {
		return filter("around_action", handler, options);
	}

	public static macro function rescueFrom(exception:Expr, handler:Expr):Expr {
		#if macro
		return rescue([rubyExceptionConstant(exception)], handler);
		#else
		return macro null;
		#end
	}

	public static macro function rescueFromNamed(exception:String, handler:Expr):Expr {
		#if macro
		if (!isSafeRubyConstantPath(exception)) {
			Context.error('rescueFromNamed exception "$exception" is not a safe Ruby constant path.', Context.currentPos());
		}
		return rescue([exception], handler);
		#else
		return macro null;
		#end
	}

	#if macro
	static function filter(kind:String, handler:Expr, options:Null<Expr>):Expr {
		var method = authFilterReference(handler);
		if (method == null) {
			method = methodReference(handler, kind, 0, false);
		}
		var only:Array<String> = [];
		var except:Array<String> = [];
		if (options != null) {
			switch (unwrap(options).expr) {
				case EConst(CIdent("null")) | EBlock([]):
					// Macro optional arguments may arrive as `null`, and Haxe parses
					// `{}` as an empty block rather than an object literal. Treat both
					// as "no Rails lifecycle options" so `beforeAction(auth, {})`
					// remains ergonomic while still validating non-empty options.
				case EObjectDecl(fields):
					for (field in fields) {
						switch (field.field) {
							case "only":
								only = actionList(field.expr, kind + " only");
							case "except":
								except = actionList(field.expr, kind + " except");
							case other:
								Context.error(kind + ' unsupported option "$other". Use only or except.', field.expr.pos);
						}
					}
				case _:
					Context.error(kind + " options must be an object literal.", options.pos);
			}
		}
		return filterCarrier(kind, method, only, except, handler.pos);
	}

	static function rescue(exceptions:Array<String>, handler:Expr):Expr {
		var method = methodReference(handler, "rescue_from", 1, true);
		return rescueCarrier(method, exceptions, handler.pos);
	}

	static function methodReference(expr:Expr, context:String, maxArgs:Int, allowOneArg:Bool):String {
		var name = identifier(expr, context + " expects a method reference such as authenticateUser.");
		var field = findInstanceMethod(name);
		if (field == null) {
			Context.error(context + ' references missing controller method "$name".', expr.pos);
			return name;
		}
		switch (field.kind) {
			case FMethod(_):
				var max = allowOneArg ? maxArgs : 0;
				var argCount = methodArgCount(field);
				if (argCount != null && argCount > max) {
					Context.error(context + ' method "$name" has too many arguments for Rails lifecycle dispatch.', expr.pos);
				}
			case _:
				Context.error(context + ' reference "$name" is not a method.', expr.pos);
		}
		return name;
	}

	static function authFilterReference(expr:Expr):Null<String> {
		switch (unwrap(expr).expr) {
			case EConst(CIdent(_)):
				return null;
			case _:
		}
		var typed = Context.typeExpr(expr);
		var field = switch (typed.expr) {
			case TField(_, FStatic(_, fieldRef)):
				fieldRef.get();
			case _:
				null;
		}
		if (field == null) {
			return null;
		}
		var entries = field.meta.extract(":deviseHxAuthFilter");
		if (entries.length == 0) {
			return null;
		}
		if (entries[0].params == null || entries[0].params.length != 1) {
			Context.error("@:deviseHxAuthFilter expects one object-literal metadata argument.", expr.pos);
		}
		var scope = metadataString(entries[0].params[0], "mappingScope", expr.pos);
		if (!~/^[a-z][a-z0-9_]*$/.match(scope)) {
			Context.error("DeviseHx auth filter mappingScope must be a safe snake_case Devise scope.", expr.pos);
		}
		return "authenticate_" + scope + "!";
	}

	static function metadataString(expr:Expr, key:String, pos:Position):String {
		return switch (unwrap(expr).expr) {
			case EObjectDecl(fields):
				for (field in fields) {
					if (field.field == key) {
						return switch (field.expr.expr) {
							case EConst(CString(value, _)): value;
							case _:
								Context.error('DeviseHx metadata "$key" must be a string literal.', field.expr.pos);
								"";
						}
					}
				}
				Context.error('DeviseHx metadata is missing "$key".', pos);
				"";
			case _:
				Context.error("DeviseHx auth filter metadata must be an object literal.", pos);
				"";
		}
	}

	static function methodArgCount(field:ClassField):Null<Int> {
		switch (field.type) {
			case TFun(args, _):
				return args.length;
			case _:
		}
		var expr = field.expr();
		if (expr != null) {
			switch (expr.expr) {
				case TFunction(fn):
					return fn.args.length;
				case _:
			}
		}
		return null;
	}

	static function actionList(expr:Expr, context:String):Array<String> {
		return switch (unwrap(expr).expr) {
			case EArrayDecl(values):
				[for (value in values) actionReference(value, context)];
			case _:
				[actionReference(expr, context)];
		}
	}

	static function actionReference(expr:Expr, context:String):String {
		var name = identifier(expr, context + " expects action method references, e.g. {only: [create]}.");
		if (findInstanceMethod(name) == null) {
			Context.error(context + ' references missing controller action "$name".', expr.pos);
		}
		return name;
	}

	static function identifier(expr:Expr, message:String):String {
		return switch (unwrap(expr).expr) {
			case EConst(CIdent(name)):
				name;
			case _:
				Context.error(message, expr.pos);
				"";
		}
	}

	static function findInstanceMethod(name:String):Null<ClassField> {
		var local = Context.getLocalClass();
		if (local == null) {
			return null;
		}
		return findInstanceMethodIn(local.get(), name);
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

	static function rubyExceptionConstant(expr:Expr):String {
		return switch (Context.typeExpr(expr).expr) {
			case TTypeExpr(TClassDecl(classRef)):
				rubyClassConstant(classRef.get());
			case _:
				Context.error("rescueFrom expects an exception type reference. Use rescueFromNamed(\"Ruby::Constant\", handler) for explicit interop.",
					expr.pos);
				"StandardError";
		}
	}

	static function rubyClassConstant(classType:ClassType):String {
		var native = metaString(classType.meta, ":native");
		if (native != null) {
			if (!isSafeRubyConstantPath(native)) {
				Context.error('@:native("$native") is not a safe Ruby constant path for rescueFrom.', classType.pos);
			}
			return native;
		}
		var segments = classType.pack.concat([classType.name]);
		return segments.map(RubyNaming.toConstantName).join("::");
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
			case EConst(CString(value, _)): value;
			case _: null;
		}
	}

	static function isSafeRubyConstantPath(value:String):Bool {
		return ~/^[A-Z][A-Za-z0-9_]*(::[A-Z][A-Za-z0-9_]*)*$/.match(value);
	}

	static function filterCarrier(kind:String, method:String, only:Array<String>, except:Array<String>, pos:Position):Expr {
		return macro @:pos(pos) rails.action_controller.LifecycleDecl.filter($v{kind}, $v{method}, $e{stringArray(only, pos)}, $e{stringArray(except, pos)});
	}

	static function rescueCarrier(method:String, exceptions:Array<String>, pos:Position):Expr {
		return macro @:pos(pos) rails.action_controller.LifecycleDecl.rescue($v{method}, $e{stringArray(exceptions, pos)});
	}

	static function stringArray(values:Array<String>, pos:Position):Expr {
		return {
			expr: EArrayDecl([for (value in values) macro $v{value}]),
			pos: pos
		};
	}

	static function unwrap(expr:Expr):Expr {
		return switch (expr.expr) {
			case EParenthesis(inner) | ECheckType(inner, _) | EMeta(_, inner): unwrap(inner);
			case _: expr;
		}
	}
	#end
}
