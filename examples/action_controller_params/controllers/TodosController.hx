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
// refs such as `Todo.f.title` when a model schema is available. Nested permit
// specs use Rails-shaped Haxe object literals, e.g. `{metadata: ["source"]}`.
// `flash`, `session`, and `cookies` expose typed store helpers instead of raw
// Dynamic bracket access. `request()` and `response()` expose typed facades
// over the Rails runtime objects without wrapping them. `@:beforeAction`,
// `@:afterAction`, and `@:railsFilter(...)` annotate real Haxe methods, so the
// callback method exists at compile time and Rails receives normal symbols.
// IntelliSense: editors should complete `params`, `render`, `redirectTo`, and
// the `ParamsMacro` entrypoint, plus store methods `get`, `set`, and `delete`
// and request/response helpers such as `requestMethod`, `path`, and `status`.
// Ruby output: an `ActionController::Base` subclass with normal Rails
// `params.require(...).permit(...)`, `flash[:key]`, `session[:key]`,
// `cookies[:key]`, `render(..., status: :status)`, `redirect_to`,
// `head(:status)`, and Rails filter declarations.
@:railsController
class TodosController extends rails.action_controller.Base {
	@:beforeAction({only: ["create"]})
	function authenticateUser() {
		var method = request().requestMethod();
	}

	@:afterAction({only: ["create"]})
	function auditResponse() {
		var status = response().status();
	}

	@:railsFilter("before_action", {except: ["index"]})
	function loadTenant() {
		var path = request().path();
	}

	public function create() {
		var attrs = ParamsMacro.requirePermit(this.params(), "todo", ["title", "isCompleted"], {metadata: ["source", "priority"], tags: []});
		var requestMethod = request().requestMethod();
		var requestPath = request().path();
		var currentStatus = response().status();
		flash().set("notice", "Todo queued");
		session().set("lastTodoTitle", attrs);
		var remembered = session().get("lastTodoTitle");
		cookies().set("todoFilter", "open");
		cookies().delete("staleFilter");
		render({json: attrs, status: Status.created});
		redirectToOptions({action: "index"});
		head(Status.noContent);
	}
}
