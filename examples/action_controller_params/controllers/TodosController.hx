package controllers;

import rails.macros.ParamsMacro;

@:railsController
class TodosController extends rails.action_controller.Base {
	public function create() {
		var attrs = ParamsMacro.requirePermit(this.params(), "todo", ["title", "isCompleted"]);
		render({json: attrs});
		redirectTo({action: "index"});
	}
}
