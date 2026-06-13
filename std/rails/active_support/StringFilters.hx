package rails.active_support;

// Typed facade for ActiveSupport string filter receiver extensions.
//
// Use with:
//
//   using rails.active_support.StringFilters;
//
// The facade intentionally exposes the Ruby method names as Haxe extension
// methods when they already read naturally in Haxe. Generated Ruby remains a
// direct ActiveSupport call such as `" a  b ".squish()`.
@:rubyRequire("active_support/core_ext/string/filters")
@:rubyPatch(String)
extern class StringFilters {
	public static function squish(receiver:String):String;
}
