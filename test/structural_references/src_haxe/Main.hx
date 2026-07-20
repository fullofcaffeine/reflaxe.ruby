private enum WorkState {
	Idle;
	Count(value:Int);
}

private class Counter {
	public var value:Int;

	public function new(value:Int) {
		this.value = value;
	}
}

private class Helpers {
	public static var label = "ready";

	public static function addOne(value:Int):Int {
		return value + 1;
	}
}

/**
	Exercises constant paths and member places that must stay structural until
	Ruby printing. Runtime output proves reads, writes, enum constructors, method
	values, type constants, Math constants, and iterator function values retain
	their Haxe behavior while the smoke gate separately checks the Ruby shape.
**/
class Main {
	static function main():Void {
		var counted = WorkState.Count(3);
		var idle = WorkState.Idle;
		var counter = new Counter(4);
		var observed = counter.value;
		counter.value = observed + 1;
		var addOne = Helpers.addOne;
		var values = ["a", "b"];
		var iteratorFactory:() -> KeyValueIterator<Int, String> = values.keyValueIterator;
		var iterator = iteratorFactory();
		var entries = [for (key => value in iterator) key + ":" + value];

		Sys.println(switch (counted) {
			case Count(value): "Count:" + value;
			case Idle: "Idle";
		});
		Sys.println(switch (idle) {
			case Idle: "Idle";
			case Count(value): "Count:" + value;
		});
		Sys.println(counter.value);
		Sys.println(Helpers.label);
		Sys.println(addOne(5));
		Sys.println(entries.join(","));
		Sys.println(Math.PI > 3 && Math.POSITIVE_INFINITY > 0 && Math.NEGATIVE_INFINITY < 0 && Math.isNaN(Math.NaN));
		Sys.println(Std.isOfType(counter, Counter));
	}
}
