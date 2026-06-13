// Class/static member smoke.
//
// Demonstrates: a Haxe-owned class with static state and a static method.
// Type safety: `Counter.value` is checked as `Int`, and `Counter.next()` is
// checked as returning `Int`; wrong assignments fail at Haxe compile time.
// IntelliSense: editors should complete `Counter.value` and `Counter.next()`
// because the class is ordinary typed Haxe.
// Ruby output: a normal Ruby class with singleton accessors/methods.
class Main {
	static function main():Void {
		Counter.value = 1;
		Sys.println(Counter.next());
	}
}

class Counter {
	public static var value:Int = 0;

	public static function next():Int {
		value = value + 1;
		return value;
	}
}
