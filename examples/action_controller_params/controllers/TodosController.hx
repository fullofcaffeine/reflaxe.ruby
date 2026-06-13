package controllers;

import rails.action_controller.Status;
import rails.macros.ParamsMacro;

// Typed ActionController params fixture.
//
// Demonstrates: a RailsHx controller method using strong-param lowering and
// Rails response helpers.
// Type safety: `ParamsMacro.requirePermit(...)` validates the call shape in
// Haxe and lowers to Rails strong params. This small fixture uses string fields
// to exercise the lower-level API; RailsHx app code should prefer model field
// refs such as `Todo.f.title` when a model schema is available. `flash`,
// `session`, and `cookies` expose typed store helpers instead of raw Dynamic
// bracket access.
// IntelliSense: editors should complete `params`, `render`, `redirectTo`, and
// the `ParamsMacro` entrypoint, plus store methods `get`, `set`, and `delete`.
// Ruby output: an `ActionController::Base` subclass with normal Rails
// `params.require(...).permit(...)`, `flash[:key]`, `session[:key]`,
// `cookies[:key]`, `render`, `redirect_to`, and `head(:status)` calls.
@:railsController
class TodosController extends rails.action_controller.Base {
	public function create() {
		var attrs = ParamsMacro.requirePermit(this.params(), "todo", ["title", "isCompleted"]);
		flash().set("notice", "Todo queued");
		session().set("lastTodoTitle", attrs);
		var remembered = session().get("lastTodoTitle");
		cookies().set("todoFilter", "open");
		cookies().delete("staleFilter");
		render({json: attrs});
		redirectTo({action: "index"});
		head(Status.noContent);
	}
}
