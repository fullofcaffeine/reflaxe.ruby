// Core expression/control-flow smoke.
//
// Demonstrates: arithmetic precedence, typed locals, `if`/`else`, `while`,
// array literals, object literals, and `Sys.println` lowering.
// Type safety: Haxe checks local variable types, branch conditions, arithmetic
// operands, and literal shapes before Ruby is generated.
// IntelliSense: editors should infer `total`/`i` as `Int` and expose Haxe
// members for arrays/anonymous structures where applicable.
// Ruby output: ordinary Ruby assignments, conditionals, loops, arrays, hashes,
// and `puts` calls without a parallel runtime DSL.
class Main {
	static function main():Void {
		var total = 1 + 2 * 3;
		if (total > 5) {
			Sys.println("big");
		} else {
			Sys.println("small");
		}

		var i = 0;
		while (i < 2) {
			Sys.println("loop");
			i = i + 1;
		}

		Sys.println([1, 2, 3]);
		Sys.println({name: "ruby", count: 3});
		Sys.println("done");
	}
}
