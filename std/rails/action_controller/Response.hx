package rails.action_controller;

/**
	Typed facade over Rails' ActionDispatch response object.

	Values are supplied by Rails at runtime; this extern only gives Haxe code
	completion and type checking while preserving normal Rails response calls.
**/
extern class Response {
	public function status():Int;

	@:native("media_type")
	public function mediaType():Null<String>;
}
