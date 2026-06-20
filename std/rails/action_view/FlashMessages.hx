package rails.action_view;

/**
	Typed facade for reading Rails `flash` from ActionView templates.

	Controllers use `rails.action_controller.FlashStore` to write messages.
	Templates need the mirror operation: read `flash[:alert]` / `flash[:notice]`
	without dropping app HHX back to raw ERB. This extern is a compiler-recognized
	authoring marker: RailsHx type-checks the call in Haxe, then erases it to
	ordinary Rails flash reads in generated ERB rather than shipping a runtime
	`FlashMessages` class.
**/
extern class FlashMessages {
	public static function alert():Null<String>;
	public static function notice():Null<String>;
	public static function message():Null<String>;
	public static function hasMessage():Bool;
	public static function kind():String;
}
