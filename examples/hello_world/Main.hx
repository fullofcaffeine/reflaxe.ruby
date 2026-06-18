// Minimal compiler smoke.
//
// Demonstrates: the smallest Haxe entrypoint that can be lowered to Ruby.
// Type safety: `ruby.Prelude.puts` is an explicit static-import alias for
// `Sys.println`, so misspelling the helper or passing unsupported values fails
// before Ruby is emitted.
// IntelliSense: editors should complete `puts` after the static import, while
// `ruby.Kernel.puts` remains available separately for exact Ruby interop.
// Ruby output: a normal `Main.main` method that prints through Ruby `puts` with
// HXRuby stringification.
import ruby.Prelude.puts;

class Main {
	static function main():Void {
		puts("Hello from reflaxe.ruby");
	}
}
