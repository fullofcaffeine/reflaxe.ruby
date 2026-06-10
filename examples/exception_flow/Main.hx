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
