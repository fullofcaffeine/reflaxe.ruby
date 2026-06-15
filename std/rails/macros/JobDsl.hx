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
	Typed Rails ActiveJob lifecycle declarations.

	ActiveJob's Ruby class macros live in the class body, but Haxe class bodies
	cannot contain naked function calls. RailsHx uses a legal contextual field:

	```haxe
	static final lifecycle = {
		queueAs("mailers");
		retryOn(StandardError, {waitSeconds: 5, attempts: 3});
		discardOn(DeserializationError);
	}
	```

	These macros validate queue literals, option objects, and exception type
	refs, then emit compiler-only marker calls that the Ruby backend lowers to
	`queue_as`, `retry_on`, and `discard_on`.
**/
class JobDsl {
	public static macro function queueAs(queue:String):Expr {
		#if macro
		if (queue.length == 0) {
			Context.error("queueAs expects a non-empty queue name.", Context.currentPos());
		}
		return macro @:pos(Context.currentPos()) rails.active_job.LifecycleDecl.queue($v{queue});
		#else
		return macro null;
		#end
	}

	public static macro function retryOn(exception:Expr, ?options:Expr):Expr {
		#if macro
		var opts = retryOptions(options, "retryOn");
		return retryCarrier(rubyExceptionConstant(exception, "retryOn"), opts, exception.pos);
		#else
		return macro null;
		#end
	}

	public static macro function retryOnNamed(exception:String, ?options:Expr):Expr {
		#if macro
		if (!isSafeRubyConstantPath(exception)) {
			Context.error('retryOnNamed exception "$exception" is not a safe Ruby constant path.', Context.currentPos());
		}
		var opts = retryOptions(options, "retryOnNamed");
		return retryCarrier(exception, opts, Context.currentPos());
		#else
		return macro null;
		#end
	}

	public static macro function discardOn(exception:Expr):Expr {
		#if macro
		return macro @:pos(exception.pos) rails.active_job.LifecycleDecl.discard($v{rubyExceptionConstant(exception, "discardOn")});
		#else
		return macro null;
		#end
	}

	public static macro function discardOnNamed(exception:String):Expr {
		#if macro
		if (!isSafeRubyConstantPath(exception)) {
			Context.error('discardOnNamed exception "$exception" is not a safe Ruby constant path.', Context.currentPos());
		}
		return macro @:pos(Context.currentPos()) rails.active_job.LifecycleDecl.discard($v{exception});
		#else
		return macro null;
		#end
	}

	#if macro
	static function retryOptions(options:Null<Expr>, context:String):{waitSeconds:Int, attempts:Int, queue:String} {
		var out = {waitSeconds: -1, attempts: -1, queue: ""};
		if (options == null) {
			return out;
		}
		switch (unwrap(options).expr) {
			case EObjectDecl(fields):
				for (field in fields) {
					switch (field.field) {
						case "waitSeconds":
							out.waitSeconds = intLiteral(field.expr, context + " waitSeconds");
						case "attempts":
							out.attempts = intLiteral(field.expr, context + " attempts");
						case "queue":
							out.queue = stringLiteral(field.expr, context + " queue");
							if (out.queue.length == 0) {
								Context.error(context + " queue must be a non-empty string literal.", field.expr.pos);
							}
						case other:
							Context.error(context + ' unsupported option "$other". Use waitSeconds, attempts, or queue.', field.expr.pos);
					}
				}
			case _:
				Context.error(context + " options must be an object literal.", options.pos);
		}
		return out;
	}

	static function intLiteral(expr:Expr, context:String):Int {
		return switch (unwrap(expr).expr) {
			case EConst(CInt(value, _)):
				var parsed = Std.parseInt(value);
				if (parsed == null || parsed < 0) {
					Context.error(context + " must be a non-negative integer literal.", expr.pos);
					-1;
				} else {
					parsed;
				}
			case _:
				Context.error(context + " must be an integer literal.", expr.pos);
				-1;
		}
	}

	static function stringLiteral(expr:Expr, context:String):String {
		return switch (unwrap(expr).expr) {
			case EConst(CString(value, _)): value;
			case _:
				Context.error(context + " must be a string literal.", expr.pos);
				"";
		}
	}

	static function rubyExceptionConstant(expr:Expr, context:String):String {
		return switch (Context.typeExpr(expr).expr) {
			case TTypeExpr(TClassDecl(classRef)):
				rubyClassConstant(classRef.get(), context);
			case _:
				Context.error(context + " expects an exception type reference. Use " + context + "Named(\"Ruby::Constant\") for explicit interop.", expr.pos);
				"StandardError";
		}
	}

	static function rubyClassConstant(classType:ClassType, context:String):String {
		var native = metaString(classType.meta, ":native");
		if (native != null) {
			if (!isSafeRubyConstantPath(native)) {
				Context.error('@:native("$native") is not a safe Ruby constant path for ' + context + ".", classType.pos);
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

	static function retryCarrier(exception:String, options:{waitSeconds:Int, attempts:Int, queue:String}, pos:Position):Expr {
		return macro @:pos(pos) rails.active_job.LifecycleDecl.retry($v{exception}, $v{options.waitSeconds}, $v{options.attempts}, $v{options.queue});
	}

	static function unwrap(expr:Expr):Expr {
		return switch (expr.expr) {
			case EParenthesis(inner) | ECheckType(inner, _) | EMeta(_, inner): unwrap(inner);
			case _: expr;
		}
	}
	#end
}
