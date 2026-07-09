// Class/static member smoke.
//
// Demonstrates: a Haxe-owned class with static state, a static expression
// initializer, normal methods, and rebindable static/instance dynamic methods.
// Type safety: `Counter.value` and `Counter.label` are checked as ordinary
// typed Haxe fields, while dynamic method replacements keep their signatures.
// IntelliSense: editors complete state, methods, and replacement callbacks
// because `Counter` remains an ordinary typed Haxe class.
// Ruby output: a normal Ruby class whose dynamic method writers install
// receiver-local dispatch wrappers.
class Main {
	static function main():Void {
		Counter.value = 1;
		Sys.println(Counter.next());
		Sys.println(Counter.label);

		Sys.println(Counter.decorate("static"));
		var originalDecorate = Counter.decorate;
		Counter.decorate = value -> "custom:" + value;
		Sys.println(Counter.decorate("static"));
		Counter.decorate = null;
		Sys.println(Counter.decorate == null);
		Counter.decorate = originalDecorate;
		Sys.println(Counter.decorate("restored"));

		var counter = new Counter();
		Sys.println(counter.bump(2));
		counter.bump = value -> value + 10;
		Sys.println(counter.bump(2));
		Sys.println(new Counter().bump(2));
	}
}

class Counter {
	public function new() {}

	static var prefix:String = "counter";

	public static var label:String = prefix;
	public static var value:Int = 0;

	public static function next():Int {
		value = value + 1;
		return value;
	}

	public static dynamic function decorate(value:String):String {
		return "base:" + value;
	}

	public dynamic function bump(value:Int):Int {
		return value + 1;
	}
}
