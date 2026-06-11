package controllers;

import models.Todo;
import rails.macros.ParamsMacro;
import routes.Routes;

@:railsController
class TodosController extends rails.action_controller.Base {
	public function index() {
		var todos = Todo.incomplete();
		render({template: "controllers/todos/index", locals: {todos: todos}});
	}

	public function create() {
		var attrs = ParamsMacro.requirePermit(this.params(), "todo", ["title", "isCompleted", "userId"]);
		var todo = Todo.create(attrs);
		redirectTo(Routes.todosPath());
	}
}
