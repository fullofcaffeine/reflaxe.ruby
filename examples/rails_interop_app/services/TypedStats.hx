package services;

class TypedStats {
	public static function summary(items:Array<String>):String {
		return "Typed Haxe summarized " + items.length + " Rails surfaces.";
	}

	public static function confidenceLabel():String {
		return "Ruby called a generated Haxe service with no adapter.";
	}
}
