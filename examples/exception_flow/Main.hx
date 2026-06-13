// Exception flow smoke.
//
// Demonstrates: Haxe `throw`/`try`/`catch` lowering to Ruby exception control
// flow while preserving Haxe's typed catch value.
// Type safety: the catch binding is declared as `String`, so downstream code
// sees a typed `message` instead of an untyped Ruby exception object.
// IntelliSense: editors should expose String members on `message`.
// Ruby output: Ruby `raise`/`rescue` using the hxruby exception wrapper.
class Main {
	static function main():Void {
		try {
			fail();
			Sys.println("unreachable");
		} catch (message:String) {
			Sys.println(message);
		}
	}

	static function fail():Void {
		throw "boom";
	}
}
