package unit;

/**
	Minimal typed assertion adapter for the selected upstream top-level and issue
	classes. The official sources remain byte-identical; this adapter replaces
	the upstream utest runner without changing their expected values.
**/
class Test {
	static var assertions = 0;

	public function new() {}

	public static function reset():Void {
		assertions = 0;
	}

	public static function assertionCount():Int {
		return assertions;
	}

	public function eq<T>(actual:T, expected:T):Void {
		assertions++;
		if (expected != actual) {
			throw 'official assertion failed: expected ${Std.string(expected)}, got ${Std.string(actual)}';
		}
	}

	public function t(condition:Bool):Void {
		assertions++;
		if (!condition) {
			throw "official assertion failed: expected true";
		}
	}

	public function f(condition:Bool):Void {
		assertions++;
		if (condition) {
			throw "official assertion failed: expected false";
		}
	}
}
