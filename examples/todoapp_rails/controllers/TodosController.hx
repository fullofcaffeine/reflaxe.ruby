package controllers;

import models.Todo;
import models.User;
import rails.action_view.Template;
import rails.macros.ParamsMacro;
import rails.macros.ViewMacro;
import routes.Routes;
import views.ApplicationLayoutView;
import views.TodoIndexView;

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
		ViewMacro.renderTemplateWithLayout(this, (Template.of(TodoIndexView) : Template<TodoIndexLocals>), {
			todos: todos,
			todoCount: todos.length,
			typedColumnCount: Todo.typedColumnCount(),
			sampleUser: User.first()
		}, Template.layout(ApplicationLayoutView));
	}

	public function create() {
		var attrs = ParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.title, Todo.f.notes, Todo.f.userId]);
		var todo = Todo.create(attrs);
		redirectTo(Routes.todosPath());
	}
}
