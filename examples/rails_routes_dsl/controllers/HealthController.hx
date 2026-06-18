package controllers;

@:railsController
class HealthController extends rails.action_controller.Base {
	static final lifecycle = [];

	// Route DSL snapshots use typed controller/action refs. IntelliSense should
	// expose this method, and a rename/missing action should fail at Haxe compile
	// time before Rails ever sees config/routes.rb.
	public function show():Void {}
}
