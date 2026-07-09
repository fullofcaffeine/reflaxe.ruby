// Class/static member smoke.
//
// Demonstrates: a Haxe-owned class with static state, a static expression
// initializer, and a static method.
// Type safety: `Counter.value` and `Counter.label` are checked as ordinary
// typed Haxe fields; wrong assignments fail at Haxe compile time.
// IntelliSense: editors should complete `Counter.value`, `Counter.label`, and
// `Counter.next()` because the class is ordinary typed Haxe.
// Ruby output: a normal Ruby class with singleton accessors/methods.
class Main {
	static function main():Void {
		Counter.value = 1;
		Sys.println(Counter.next());
		Sys.println(Counter.label);
	}
}

class Counter {
	static var prefix:String = "counter";

	public static var label:String = prefix;
	public static var value:Int = 0;

	public static function next():Int {
		value = value + 1;
		return value;
	}
}
