// Switch lowering smoke.
//
// Demonstrates: switching over primitive values and Haxe enums.
// Type safety: enum cases are checked against `Color`; misspelled or impossible
// enum branches fail in Haxe rather than becoming Ruby condition bugs.
// IntelliSense: editors should complete `Red`, `Green`, and `Blue` in the enum
// switch and know `number` is an `Int`.
// Ruby output: normal Ruby `case` expressions/statements with stable enum tags.
enum Color {
	Red;
	Green;
	Blue;
}

class Main {
	static function main():Void {
		var number = 2;
		switch (number) {
			case 1:
				Sys.println("one");
			case 2:
				Sys.println("two");
			default:
				Sys.println("other");
		}

		var color = Green;
		switch (color) {
			case Red:
				Sys.println("red");
			case Green:
				Sys.println("green");
			case Blue:
				Sys.println("blue");
		}
	}
}
