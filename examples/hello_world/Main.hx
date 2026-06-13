// Minimal compiler smoke.
//
// Demonstrates: the smallest Haxe entrypoint that can be lowered to Ruby.
// Type safety: `Sys.println` is the standard typed Haxe API; passing unsupported
// values or misspelling `println` fails before Ruby is emitted.
// IntelliSense: editors should complete `Sys.println` from the Haxe std surface.
// Ruby output: a normal `Main.main` method that prints through Ruby `puts`.
class Main {
	static function main():Void {
		Sys.println("Hello from reflaxe.ruby");
	}
}
