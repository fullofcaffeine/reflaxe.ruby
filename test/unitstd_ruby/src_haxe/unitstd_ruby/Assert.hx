package unitstd_ruby;

/**
	Tiny assertion surface for upstream `unitstd` expression fixtures.

	The Ruby parity lane runs as plain generated Ruby, so failed assertions throw
	Haxe exceptions instead of depending on a separate test framework adapter.
**/
class Assert {
	public static function isTrue(condition:Bool, message:String):Void {
		if (!condition) {
			fail(message);
		}
	}

	public static function isFalse(condition:Bool, message:String):Void {
		if (condition) {
			fail(message);
		}
	}

	public static function inDelta(expected:Float, actual:Float, delta:Float, message:String):Void {
		if (Math.isNaN(expected) || Math.isNaN(actual)) {
			isTrue(Math.isNaN(expected) && Math.isNaN(actual), message);
			return;
		}
		if (expected == Math.POSITIVE_INFINITY || expected == Math.NEGATIVE_INFINITY || actual == Math.POSITIVE_INFINITY || actual == Math.NEGATIVE_INFINITY) {
			isTrue(actual == expected, message);
			return;
		}
		if (Math.abs(expected - actual) > delta) {
			fail(message + " expected " + expected + " but got " + actual);
		}
	}

	public static function sameArray<T>(expected:Array<T>, actual:Array<T>, message:String):Void {
		if (!arraysSame(expected, actual)) {
			fail(message + " expected " + Std.string(expected) + " but got " + Std.string(actual));
		}
	}

	public static function raises(action:() -> Void, message:String):Void {
		// `exc(...)` must observe native Ruby errors as well as Haxe throws. Keep
		// this target escape local to the Ruby-only harness and return only Bool.
		var raised:Bool = untyped __ruby__("(begin {0}.call; false; rescue StandardError; true; end)", action);
		if (!raised) {
			fail(message + " expected an exception");
		}
	}

	public static function arraysSame<T>(expected:Array<T>, actual:Array<T>):Bool {
		return untyped __ruby__("HXRuby.array_contents_match?({0}, {1})", expected, actual);
	}

	static function fail(message:String):Void {
		throw "unitstd-ruby assertion failed: " + message;
	}
}
