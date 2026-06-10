package rails.action_controller;

class Base {
	public function new() {}

	public function params():Params {
		return cast null;
	}

	@:rubyKwargs
	public function render(options:Dynamic):Void {}

	@:native("redirect_to")
	@:rubyKwargs
	public function redirectTo(options:Dynamic):Void {}
}
