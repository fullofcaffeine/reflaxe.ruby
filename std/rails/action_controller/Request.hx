package rails.action_controller;

/**
	Typed facade over Rails' ActionDispatch request object.

	Values are supplied by Rails at runtime; this extern only gives Haxe code
	completion and type checking while preserving normal Rails request calls.
**/
extern class Request {
	@:native("request_method")
	public function requestMethod():String;

	public function path():String;

	@:native("fullpath")
	public function fullPath():String;

	public function format():RequestFormat;

	public function formats():Array<RequestFormat>;

	@:native("content_mime_type")
	public function contentMimeType():Null<RequestFormat>;

	@:native("media_type")
	public function mediaType():Null<String>;

	public function variant():RequestVariant;

	@:native("xhr?")
	public function xhr():Bool;
}
