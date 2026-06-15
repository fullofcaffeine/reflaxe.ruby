package rails.action_controller;

/**
	Typed facade over Rails' request.format MIME object.

	Rails owns this runtime object; RailsHx only types the common MIME predicate
	and display methods so app code does not need to treat request formats as
	Dynamic.
**/
extern class RequestFormat {
	public function symbol():String;

	@:native("to_s")
	public function toString():String;

	@:native("html?")
	public function html():Bool;

	@:native("json?")
	public function json():Bool;

	@:native("turbo_stream?")
	public function turboStream():Bool;

	@:native("xml?")
	public function xml():Bool;

	@:native("any?")
	public function any():Bool;
}
