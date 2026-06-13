package controllers;

import rails.macros.ParamsMacro;

// Typed ActionController params fixture.
//
// Demonstrates: a RailsHx controller method using strong-param lowering and
// Rails response helpers.
// Type safety: `ParamsMacro.requirePermit(...)` validates the call shape in
// Haxe and lowers to Rails strong params. This small fixture uses string fields
// to exercise the lower-level API; RailsHx app code should prefer model field
// refs such as `Todo.f.title` when a model schema is available.
// IntelliSense: editors should complete `params`, `render`, `redirectTo`, and
// the `ParamsMacro` entrypoint.
// Ruby output: an `ActionController::Base` subclass with normal Rails
// `params.require(...).permit(...)`, `render`, and `redirect_to` calls.
@:railsController
class TodosController extends rails.action_controller.Base {
	public function create() {
		var attrs = ParamsMacro.requirePermit(this.params(), "todo", ["title", "isCompleted"]);
		render({json: attrs});
		redirectTo({action: "index"});
	}
}
