enum MaybeInt {
	None;
	Some(value:Int);
}

class Main {
	static function main():Void {
		var value = Some(41);
		var empty = None;
		Sys.println("constructed");
	}
}
