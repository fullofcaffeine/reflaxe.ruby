package rails.active_support;

// Typed facade for ActiveSupport's Object#blank?, Object#present?, and
// Object#presence receiver extensions.
//
// Use with:
//
//   using rails.active_support.ObjectPresence;
//
// The Haxe methods are normal static extension methods for completion and type
// checking. The Ruby compiler lowers them to direct receiver calls such as
// `value.blank?()` after requiring ActiveSupport's core extension file.
@:rubyRequire("active_support/core_ext/object/blank")
@:rubyPatch(Dynamic)
extern class ObjectPresence {
	@:native("blank?")
	public static function blank<T>(receiver:T):Bool;

	@:native("present?")
	public static function present<T>(receiver:T):Bool;

	public static function presence<T>(receiver:T):Null<T>;
}
