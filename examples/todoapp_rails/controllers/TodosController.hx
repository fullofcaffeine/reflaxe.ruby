package controllers;

import app.auth.UserAuth;
import models.ChatMessage;
import models.Todo;
import models.User;
import rails.action_view.Template;
import rails.action_controller.Status;
import rails.macros.ControllerDsl.beforeAction;
import rails.macros.ParamsMacro;
import rails.macros.ViewMacro;
import rails.turbo.StreamTarget;
import rails.turbo.TurboStreams;
import routes.Routes;
import shared.TodoHooks;
import views.ApplicationLayoutView;
import views.TodoIndexView;
import views.TodoListView;
import views.TodoListView.TodoListLocals;

typedef TodoIndexLocals = {
	var todos:Array<Todo>;
	var users:Array<User>;
	var chatMessages:Array<ChatMessage>;
	var todoCount:Int;
	var typedColumnCount:Int;
	var sampleUser:Null<User>;
	var currentUser:Null<User>;
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
	static final lifecycle = {
		// The board is public so guests can reach the typed DeviseHx sign-in
		// panel; mutations stay protected and can safely use Devise sessions.
		beforeAction(UserAuth.authenticate, {except: [index]});
	};

	public function index() {
		var todos = Todo.incomplete().includes(Todo.a.user).order(Todo.f.title.asc()).limit(10).toArray();
		var users = User.order(User.f.name.asc()).toArray();
		var chatMessages = ChatMessage.latest().toArray();
		var currentUser = UserAuth.current(this);
		ViewMacro.renderTemplateWithLayout(this, (Template.of(TodoIndexView) : Template<TodoIndexLocals>), {
			todos: todos,
			users: users,
			chatMessages: chatMessages,
			todoCount: todos.length,
			typedColumnCount: Todo.typedColumnCount(),
			sampleUser: currentUser,
			currentUser: currentUser
		}, Template.layout(ApplicationLayoutView));
	}

	public function create() {
		var attrs = ParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.title, Todo.f.notes, Todo.f.userId]);
		var todo = Todo.create(attrs);
		respondTo(function(format) {
			format.turboStream(function() {
				render({
					turboStream: TurboStreams.replace(StreamTarget.named(TodoHooks.todoListId), (Template.of(TodoListView) : Template<TodoListLocals>), {
						todos: Todo.incomplete().includes(Todo.a.user).order(Todo.f.title.asc()).limit(10).toArray()
					})
				});
			});
			format.html(function() {
				redirectToLocation(Routes.todosPath(), {status: Status.seeOther});
			});
		});
	}

	public function completed() {}

	public function complete() {}

	public function optionalReport() {}

	public function file() {}
}
