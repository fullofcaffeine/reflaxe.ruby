package controllers;

import app.auth.UserAuth;
import models.ChatMessage;
import models.Todo;
import models.User;
import rails.action_controller.SendDisposition;
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
	var currentUser:User;
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
class TodosController extends ApplicationController {
	static final lifecycle = {
		// The board is a real authenticated Rails surface. Devise owns the
		// redirect/filter; RailsHx only gives the filter a typed Haxe ref.
		beforeAction(UserAuth.authenticate, {});
	};

	public function index() {
		var currentUser = UserAuth.currentRequired(this);
		var todos = Todo.where({isCompleted: false, userId: currentUser.id})
			.includes(Todo.a.user)
			.order(Todo.f.title.asc())
			.limit(10)
			.toArray();
		var users = User.order(User.f.name.asc()).toArray();
		var chatMessages = ChatMessage.latest().toArray();
		ViewMacro.renderTemplateWithLayout(this, (Template.of(TodoIndexView) : Template<TodoIndexLocals>), {
			todos: todos,
			users: users,
			chatMessages: chatMessages,
			todoCount: todos.length,
			typedColumnCount: Todo.typedColumnCount(),
			currentUser: currentUser
		}, Template.layout(ApplicationLayoutView));
	}

	public function create() {
		var currentUser = UserAuth.currentRequired(this);
		var attrs = ParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.title, Todo.f.notes]);
		attrs = ParamsMacro.mergeField(attrs, Todo.f.userId, currentUser.id);
		var todo = Todo.create(attrs);
		respondTo(function(format) {
			format.turboStream(function() {
				render({
					turboStream: TurboStreams.replace(StreamTarget.named(TodoHooks.todoListId), (Template.of(TodoListView) : Template<TodoListLocals>), {
						todos: Todo.where({isCompleted: false, userId: currentUser.id})
							.includes(Todo.a.user)
							.order(Todo.f.title.asc())
							.limit(10)
							.toArray()})
				});
			});
			format.html(function() {
				redirectToLocation(Routes.todosPath(), {status: Status.seeOther});
			});
		});
	}

	public function completed() {
		var currentUser = UserAuth.currentRequired(this);
		var titles = Todo.where({isCompleted: true, userId: currentUser.id}).order(Todo.f.title.asc()).pluck(Todo.f.title);
		render({plain: "Completed todos: " + titles.join(", "), status: Status.ok});
	}

	public function complete() {
		var currentUser = UserAuth.currentRequired(this);
		var todo = Todo.where({id: paramId(), userId: currentUser.id}).first();
		if (todo == null) {
			render({plain: "Todo not found", status: Status.notFound});
			return;
		}
		todo.update({isCompleted: true});
		this.flash.notice("Todo completed");
		redirectToLocation(Routes.todosPath(), {status: Status.seeOther});
	}

	public function optionalReport() {
		var currentUser = UserAuth.currentRequired(this);
		var year = this.params().get("year");
		var label = year == null ? "all years" : year;
		var count = Todo.where({userId: currentUser.id}).count();
		render({plain: "Todo report for " + label + ": " + Std.string(count) + " todos", status: Status.ok});
	}

	public function file() {
		var path = this.params().get("path");
		var label = path == null ? "root" : path;
		sendData("RailsHx file route: " + label + "\n", {
			filename: "todoapp-route.txt",
			type: "text/plain",
			disposition: SendDisposition.inlineContent,
			status: Status.ok
		});
	}

	function paramId():Int {
		var raw = this.params().get("id");
		var parsed = raw == null ? null : Std.parseInt(raw);
		return parsed == null ? 0 : parsed;
	}
}
