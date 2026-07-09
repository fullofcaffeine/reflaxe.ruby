// Algebraic data type smoke.
//
// Demonstrates: Haxe enum constructors with required, optional, and no payloads.
// Type safety: `Some` requires an `Int` payload and `None` accepts no payload;
// `Optional()` defaults its typed payload to null, while invalid constructors or
// payload types fail at Haxe compile time.
// IntelliSense: editors should complete each constructor and its payload names
// directly from the enum declaration.
// Ruby output: generated Ruby data constructors backed by the hxruby data helper.
enum MaybeInt {
	None;
	Some(value:Int);
	Optional(?value:Int);
}

class Main {
	static function main():Void {
		var value = Some(41);
		var empty = None;
		var optional = Optional();
		Sys.println("constructed");
		switch (optional) {
			case Optional(value):
				Sys.println(value == null);
			case _:
				Sys.println(false);
		}
	}
}
