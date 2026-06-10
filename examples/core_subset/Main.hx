class Main {
	static function main():Void {
		var total = 1 + 2 * 3;
		if (total > 5) {
			Sys.println("big");
		} else {
			Sys.println("small");
		}

		var i = 0;
		while (i < 2) {
			Sys.println("loop");
			i = i + 1;
		}

		Sys.println([1, 2, 3]);
		Sys.println({name: "ruby", count: 3});
		Sys.println("done");
	}
}
