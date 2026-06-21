package rails.action_controller;

/**
	Typed facade over Rails' request.variant inquirer.

	Rails owns the runtime object and answers predicate methods such as
	`phone?`/`tablet?`. The extern keeps those predicates discoverable and typed
	in Haxe while generated Ruby remains direct Rails calls like
	`request.variant.phone?`.
**/
extern class RequestVariant {
	@:native("to_s")
	public function toString():String;

	@:native("phone?")
	public function phone():Bool;

	@:native("tablet?")
	public function tablet():Bool;

	@:native("desktop?")
	public function desktop():Bool;

	@:native("native_app?")
	public function nativeApp():Bool;
}
