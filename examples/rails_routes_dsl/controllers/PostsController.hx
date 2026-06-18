package controllers;

@:railsController
class PostsController extends rails.action_controller.Base {
	static final lifecycle = [];

	public function index():Void {}

	public function show():Void {}

	// Haxe cannot author a plain `new` method comfortably, so RailsHx uses a
	// Haxe-safe name and @:native("new") tells the compiler to emit the Rails
	// :new action. The route macro rejects newAction without this metadata.

	@:native("new")
	public function newAction():Void {}

	public function edit():Void {}

	public function create():Void {}

	public function update():Void {}

	public function destroy():Void {}

	public function archive():Void {}

	public function publish():Void {}

	public function search():Void {}

	public function file():Void {}

	public function showOptional():Void {}
}
