import {Register} from "railshx/genes/Register"

/**
Typed async/await helpers for Haxe-authored JavaScript compiled through Genes.

Genes already knows how to emit native ES `async` methods from `@:async`
field metadata and native `await` from `js.Syntax.code("await {0}", promise)`.
This facade keeps that target-specific machinery behind typed Haxe helpers.
`enable()` also borrows Genes' `@:await expr` sugar so RailsHx client code can
read closer to JavaScript/TypeScript while staying parser-valid Haxe.
*/
export const Async = Register.global("$hxClasses")["reflaxe.js.Async"] = 
class Async {
	
	/**
	Create a typed promise that resolves after `milliseconds`.
	
	This mirrors the browser timer API while giving Haxe callers a real
	`Promise<Bool>` completion token they can pass to `Async.await(...)`.
	*/
	static delay(milliseconds) {
		return new Promise(function (resolve, _reject) {
			window.setTimeout(function () {
				resolve(true);
			}, milliseconds);
		});
	}
	static get __name__() {
		return "reflaxe.js.Async"
	}
	get __class__() {
		return Async
	}
}

