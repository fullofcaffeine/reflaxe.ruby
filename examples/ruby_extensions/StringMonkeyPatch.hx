// Scenario: consume Ruby receiver methods added by a monkey patch.
//
// The implementation lives in Ruby (`support/extensions.rb`) and reopens
// `String`. This extern class is only a typed Haxe contract: it is not emitted
// as Ruby, and it does not wrap the receiver at runtime.
//
// Type safety: Haxe validates the receiver and argument/return types through
// normal static extension-method typing. The compiler also validates that every
// `@:rubyPatch` member is a static function with an explicit receiver argument.
//
// IntelliSense: after `using StringMonkeyPatch`, editors should complete
// `headline()` and `surround(...)` on `String` values while preserving the
// Haxe-friendly method names.
//
// Ruby output: calls lower to direct receiver dispatch, for example
// `"ship".headline()` and `"ship".surround("[", "]")`.
@:rubyRequireRelative("./support/extensions")
@:rubyPatch(String)
extern class StringMonkeyPatch {
	public static function headline(receiver:String):String;
	public static function surround(receiver:String, left:String, right:String):String;
}
