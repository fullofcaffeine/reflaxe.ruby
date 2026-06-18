package reflaxe.js;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;
#else
import js.Browser;
import js.lib.Promise;
#end

/**
	Typed async/await helpers for Haxe-authored JavaScript compiled through Genes.

	Genes already knows how to emit native ES `async` methods from `@:async`
	field metadata and native `await` from `js.Syntax.code("await {0}", promise)`.
	This facade keeps that target-specific machinery behind typed Haxe helpers.
	`enable()` also borrows Genes' `@:await expr` sugar so RailsHx client code can
	read closer to JavaScript/TypeScript while staying parser-valid Haxe.
**/
class Async {
	public static function enable():Void {
		#if macro
		Compiler.addGlobalMetadata("", "@:build(reflaxe.js.Async.build())", true, true, false);
		#end
	}

	public static macro function build():Array<Field> {
		return [
			for (field in Context.getBuildFields())
				processField(field)
		];
	}

	/**
		Await a JavaScript promise inside an async Genes-emitted function.

		This is a compile-time/native boundary: Haxe type-checks the promise as
		`Promise<T>`, then Genes recognizes the exact `js.Syntax.code("await {0}")`
		shape and emits real `await promise` instead of a runtime wrapper call.
	**/
	#if !macro
	public static inline function await<T>(promise:Promise<T>):T {
		return js.Syntax.code("await {0}", promise);
	}

	/**
		Create a typed promise that resolves after `milliseconds`.

		This mirrors the browser timer API while giving Haxe callers a real
		`Promise<Bool>` completion token they can pass to `Async.await(...)`.
	**/
	public static function delay(milliseconds:Int):Promise<Bool> {
		return new Promise(function(resolve, _reject):Void {
			Browser.window.setTimeout(function():Void {
				resolve(true);
			}, milliseconds);
		});
	}
	#end

	/**
		Mark an inline function expression as native async for Genes.

		Haxe metadata can mark class fields directly with `@:async`, but callbacks
		are expressions, not fields. This macro inserts Genes' erased marker local
		as the first statement of the lambda body, so Genes emits `async function`
		and removes the marker from the final JavaScript.
	**/
	public static macro function async(expr:Expr):Expr {
		return switch (expr.expr) {
			case EFunction(kind, func):
				{
					expr: EFunction(kind, {
						args: func.args,
						ret: func.ret,
						expr: markFunctionBody(func.expr),
						params: func.params
					}),
					pos: expr.pos
				};
			default:
				Context.error("Async.async(...) expects a function expression such as Async.async(() -> { ... }).", expr.pos);
		}
	}

	#if macro
	static function processField(field:Field):Field {
		return switch field.kind {
			case FFun(fn) if (fn != null && fn.expr != null):
				fn.expr = processExpression(fn.expr);
				field;
			case FVar(t, e) if (e != null):
				{
					name: field.name,
					doc: field.doc,
					access: field.access,
					kind: FVar(t, processExpression(e)),
					pos: field.pos,
					meta: field.meta
				};
			case FProp(get, set, t, e) if (e != null):
				{
					name: field.name,
					doc: field.doc,
					access: field.access,
					kind: FProp(get, set, t, processExpression(e)),
					pos: field.pos,
					meta: field.meta
				};
			default:
				field;
		}
	}

	static function processExpression(expr:Expr):Expr {
		return switch expr.expr {
			case EMeta(meta, inner) if (meta.name == ":await" || meta.name == "await"):
				lowerAwaitMeta(expr, meta, inner);
			default:
				expr.map(processExpression);
		}
	}

	/**
		Desugar `@:await promiseExpr` to the existing typed `await(promiseExpr)`.

		This mirrors Genes' async sugar but intentionally stays syntax-only here:
		build macros run before method locals are typed, so the actual promise
		type-checking remains in the normal Haxe typing pass for `Async.await`.
	**/
	static function lowerAwaitMeta(whole:Expr, meta:MetadataEntry, inner:Expr):Expr {
		if (meta.params.length > 0) {
			Context.error("@:await does not take metadata arguments. Use `@:await expr`, `@:await (expr)` with a space, or `await(expr)`.", meta.pos);
		}
		var operand = processExpression(inner);
		var out = macro reflaxe.js.Async.await($operand);
		out.pos = whole.pos;
		return out;
	}

	static function markFunctionBody(body:Expr):Expr {
		var marker = macro var __async_marker__ = true;
		return switch (body.expr) {
			case EBlock(exprs):
				{
					expr: EBlock([marker].concat(exprs)),
					pos: body.pos
				};
			default:
				macro {
					var __async_marker__ = true;
					return $body;
				};
		}
	}
	#end
}
