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
	public function render(options:RenderOptions):Void {}

	@:native("redirect_to")
	@:rubyKwargs
	public function redirectTo(location:String):Void {}

	@:native("redirect_to")
	@:rubyKwargs
	public function redirectToOptions(options:RedirectOptions):Void {}

	@:native("head")
	public function head(status:Status):Void {}

	@:native("respond_to")
	@:rubyBlockArg
	public function respondTo(block:Responder->Void):Void {}
}
