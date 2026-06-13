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

// RailsHx todo controller.
//
// Demonstrates: typed ActiveRecord queries, typed route helpers, typed strong
// params, and typed template rendering in one Rails controller.
// Type safety: `Todo.a.user` and `Todo.f.title` are generated association/field
// refs; `Template.of(TodoIndexView) : Template<TodoIndexLocals>` checks render
// locals; `ParamsMacro.requirePermit` derives permitted fields from model refs.
// IntelliSense: editors should complete model refs, relation chains,
// `Routes.todosPath`, locals fields, and controller helper methods.
// Ruby/Rails output: a normal Rails controller using ActiveRecord, strong
// params, route helpers, and `render`/`redirect_to`.
@:railsController
class TodosController extends rails.action_controller.Base {
	public function index() {
		var todos = Todo.incomplete().includes(Todo.a.user).order(Todo.f.title.asc()).limit(10).toArray();
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
