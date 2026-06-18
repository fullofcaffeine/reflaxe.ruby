package reflaxe.js;

#if macro
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
	This facade keeps that target-specific machinery behind typed Haxe helpers so
	RailsHx client code can stay editor-friendly while still producing ordinary
	browser JavaScript.
**/
class Async {
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
