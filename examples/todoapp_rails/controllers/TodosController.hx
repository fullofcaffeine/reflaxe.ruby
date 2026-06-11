package controllers;

import models.Todo;
import rails.action_view.Template;
import rails.macros.ParamsMacro;
import rails.macros.ViewMacro;
import routes.Routes;

typedef TodoIndexLocals = {
	var todos:Array<Todo>;
}

@:railsController
class TodosController extends rails.action_controller.Base {
	public function index() {
		var todos = Todo.incomplete();
		ViewMacro.renderTemplate(this, (Template.named("controllers/todos/index") : Template<TodoIndexLocals>), {todos: todos});
	}

	public function create() {
		var attrs = ParamsMacro.requirePermit(this.params(), "todo", ["title", "isCompleted", "userId"]);
		var todo = Todo.create(attrs);
		redirectTo(Routes.todosPath());
	}
}
