package services;

// Haxe-owned service consumed by Rails.
//
// Demonstrates: new app logic authored in Haxe and emitted as ordinary Ruby.
// Type safety: `summary` requires `Array<String>` and returns `String`; legacy
// ERB/Ruby can still call the generated Ruby constant normally.
// IntelliSense: editors should complete `TypedStats.summary` and
// `TypedStats.confidenceLabel` for Haxe callers.
// Ruby output: a normal `Services::TypedStats` class with static methods.
class TypedStats {
	public static function summary(items:Array<String>):String {
		return "Typed Haxe summarized " + items.length + " Rails surfaces.";
	}

	public static function confidenceLabel():String {
		return "Ruby called a generated Haxe service with no adapter.";
	}
}
