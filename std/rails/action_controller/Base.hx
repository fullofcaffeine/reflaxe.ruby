package rails.action_controller;

class Base {
	public function new() {}

	public function params():Params {
		return cast null;
	}

	@:native("request")
	public var request(get, never):Request;

	@:native("request")
	function get_request():Request {
		return cast null;
	}

	@:native("response")
	public var response(get, never):Response;

	@:native("response")
	function get_response():Response {
		return cast null;
	}

	@:native("flash")
	public var flash(get, never):FlashStore;

	function get_flash():FlashStore {
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
	// This overload is positional-only. Keyword-bearing redirect forms use the
	// distinct typed methods below, so @:rubyKwargs never has to guess whether a
	// String argument is a keyword carrier.
	public function redirectTo(location:String):Void {}

	// Rails/Turbo form submissions should usually redirect with an explicit
	// status, especially `Status.seeOther`. This overload-shaped facade keeps
	// the Haxe call typed while lowering to `redirect_to path, status: ...`.

	@:native("redirect_to")
	@:rubyKwargs
	public function redirectToLocation(location:String, options:RedirectOptions):Void {}

	@:native("redirect_to")
	@:rubyKwargs
	public function redirectToOptions(options:RedirectOptions):Void {}

	@:native("head")
	public function head(status:Status):Void {}

	@:native("send_file")
	@:rubyKwargs
	public function sendFile(path:String, options:SendOptions):Void {}

	@:native("send_data")
	@:rubyKwargs
	public function sendData(data:String, options:SendOptions):Void {}

	@:native("fresh_when")
	@:rubyKwargs
	public function freshWhen(options:FreshnessOptions):Void {}

	@:native("stale?")
	@:rubyKwargs
	public function stale(options:FreshnessOptions):Bool {
		return false;
	}

	@:native("respond_to")
	@:rubyBlockArg
	public function respondTo(block:Responder->Void):Void {}
}
