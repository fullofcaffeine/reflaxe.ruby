package rails.action_controller;

class Responder {
	@:rubyBlockArg
	public function html(block:Void->Void):Void {}

	@:rubyBlockArg
	public function json(block:Void->Void):Void {}

	@:native("turbo_stream")
	@:rubyBlockArg
	public function turboStream(block:Void->Void):Void {}

	@:rubyBlockArg
	public function xml(block:Void->Void):Void {}

	@:rubyBlockArg
	public function any(block:Void->Void):Void {}
}
