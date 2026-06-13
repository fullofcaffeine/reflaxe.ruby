package rails.action_controller;

class Base {
	public function new() {}

	public function params():Params {
		return cast null;
	}

	public function request():Request {
		return cast null;
	}

	public function response():Response {
		return cast null;
	}

	public function flash():KeyValueStore<String> {
		return cast null;
	}

	public function session():KeyValueStore<Dynamic> {
		return cast null;
	}

	public function cookies():KeyValueStore<String> {
		return cast null;
	}

	@:rubyKwargs
	public function render(options:Dynamic):Void {}

	@:native("redirect_to")
	@:rubyKwargs
	public function redirectTo(options:Dynamic):Void {}

	@:native("head")
	public function head(status:Status):Void {}
}
