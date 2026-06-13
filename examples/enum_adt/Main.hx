// Algebraic data type smoke.
//
// Demonstrates: Haxe enum constructors with and without payloads.
// Type safety: `Some` requires an `Int` payload and `None` accepts no payload;
// invalid constructors or payload types fail at Haxe compile time.
// IntelliSense: editors should complete `None`, `Some(value:Int)`, and payload
// names from the enum declaration.
// Ruby output: generated Ruby data constructors backed by the hxruby data helper.
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
