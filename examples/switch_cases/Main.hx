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
