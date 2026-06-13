package interop;

// Existing Ruby service boundary.
//
// Demonstrates: wrapping a legacy Ruby constant with a typed Haxe extern.
// Type safety: callers must pass `Int` cents and receive `String` results; Ruby
// naming differences are isolated with `@:native`.
// IntelliSense: editors should complete `call(cents:Int)` and
// `badgeLabel(kind:String, cents:Int)`.
// Ruby output: direct `LegacyPriceFormatter.call` and
// `LegacyPriceFormatter.badge_label` calls, with no generated wrapper class.
@:native("LegacyPriceFormatter")
extern class LegacyPriceFormatter {
	public static function call(cents:Int):String;

	@:native("badge_label")
	public static function badgeLabel(kind:String, cents:Int):String;
}
