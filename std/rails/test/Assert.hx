package rails.test;

import rails.action_controller.Status;

/**
	Typed RailsHx assertion facade.

	These helpers exist for Haxe authoring ergonomics and IntelliSense. The Ruby
	compiler recognizes calls to this class inside `@:railsTest` sources and
	lowers them directly to ordinary helpers for the selected adapter, such as
	Minitest `assert_equal` or RSpec `expect(...).to eq(...)`. The fallback
	bodies fail loudly if a helper escapes compiler lowering.
**/
class Assert {
	public static function equal<T>(expected:T, actual:T):Void {
		unlowered("equal");
	}

	public static function assertEqual<T>(expected:T, actual:T):Void {
		unlowered("assertEqual");
	}

	public static function notEqual<T>(expected:T, actual:T):Void {
		unlowered("notEqual");
	}

	public static function assertNotEqual<T>(expected:T, actual:T):Void {
		unlowered("assertNotEqual");
	}

	public static function truthy(condition:Bool):Void {
		unlowered("truthy");
	}

	public static function assertTrue(condition:Bool):Void {
		unlowered("assertTrue");
	}

	public static function falsy(condition:Bool):Void {
		unlowered("falsy");
	}

	public static function assertFalse(condition:Bool):Void {
		unlowered("assertFalse");
	}

	public static function includes<C, T>(collection:C, value:T):Void {
		unlowered("includes");
	}

	public static function assertIncludes<C, T>(collection:C, value:T):Void {
		unlowered("assertIncludes");
	}

	public static function notIncludes<C, T>(collection:C, value:T):Void {
		unlowered("notIncludes");
	}

	public static function assertNotIncludes<C, T>(collection:C, value:T):Void {
		unlowered("assertNotIncludes");
	}

	public static function nilValue<T>(value:Null<T>):Void {
		unlowered("nilValue");
	}

	public static function assertNil<T>(value:Null<T>):Void {
		unlowered("assertNil");
	}

	public static function notNil<T>(value:Null<T>):Void {
		unlowered("notNil");
	}

	public static function assertNotNil<T>(value:Null<T>):Void {
		unlowered("assertNotNil");
	}

	public static function assertResponse(status:Status):Void {
		unlowered("assertResponse");
	}

	public static function assertRedirectedTo(path:String):Void {
		unlowered("assertRedirectedTo");
	}

	public static function assertDifference<T>(measure:Void->T, difference:Int, body:Void->Void):Void {
		unlowered("assertDifference");
	}

	public static function assertNoDifference<T>(measure:Void->T, body:Void->Void):Void {
		unlowered("assertNoDifference");
	}

	static function unlowered(name:String):Void {
		throw 'rails.test.Assert.$name must be lowered by reflaxe.ruby.';
	}
}
