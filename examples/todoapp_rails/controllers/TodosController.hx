package controllers;

import models.Todo;
import models.User;
import rails.action_view.Template;
import rails.macros.ParamsMacro;
import rails.macros.ViewMacro;
import routes.Routes;

typedef TodoIndexLocals = {
	var todos:Array<Todo>;
	var todoCount:Int;
	var typedColumnCount:Int;
	var sampleUser:Null<User>;
}

@:railsController
class TodosController extends rails.action_controller.Base {
	public function index() {
		var todos = Todo.incomplete();
		ViewMacro.renderTemplateWithLayout(this, (Template.named("controllers/todos/index") : Template<TodoIndexLocals>), {
			todos: todos,
			todoCount: todos.length,
			typedColumnCount: Todo.typedColumnCount(),
			sampleUser: User.first()
		}, "application");
	}

	public function create() {
		var attrs = ParamsMacro.requirePermit(this.params(), "todo", ["title", "notes", "userId"]);
		var todo = Todo.create(attrs);
		redirectTo(Routes.todosPath());
	}
}
