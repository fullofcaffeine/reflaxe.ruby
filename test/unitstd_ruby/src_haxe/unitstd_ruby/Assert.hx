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

	static function fail(message:String):Void {
		throw "unitstd-ruby assertion failed: " + message;
	}
}
