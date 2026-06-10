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
