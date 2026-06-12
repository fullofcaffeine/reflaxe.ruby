package interop;

@:native("LegacyPriceFormatter")
extern class LegacyPriceFormatter {
	public static function call(cents:Int):String;

	@:native("badge_label")
	public static function badgeLabel(kind:String, cents:Int):String;
}
