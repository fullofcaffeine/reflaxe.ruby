package routes;

import app.auth.UserAuth;
import controllers.ChatMessagesController;
import controllers.SessionsController;
import controllers.TodosController;
import controllers.UsersController;
import devisehx.routes.DeviseRouteGroup.*;
import devisehx.routes.DeviseRoutes;
import models.ChatMessage;
import models.Todo;
import rails.macros.RoutesDsl.*;

// Haxe-owned Rails routes for the todoapp.
//
// Demonstrates: greenfield RailsHx route source of truth through `@:railsRoutes`
// and the canonical `static final routes = { ... }` declaration host.
// Type safety: `to(TodosController, index)` and the `only` actions validate the
// controller/action references at Haxe compile time; `resources(Todo, ...)`
// derives the Rails resource name from typed model metadata.
// IntelliSense: editors should complete controller classes, action identifiers,
// model classes, and the RoutesDsl calls from this file.
// Ruby/Rails output: ordinary `config/routes.rb`; route helper externs remain
// generated from Rails output in `Routes.hx`.
@:railsRoutes
class AppRoutes {
	static final routes = {
		DeviseRoutes.deviseFor(UserAuth.scope, {only: [Sessions]});
		root(to(TodosController, index));
		resources(Todo, TodosController, {only: [index, create]}, {
			collection({
				get("completed", to(TodosController, completed));
			});
			member({
				patch("complete", to(TodosController, complete));
			});
		});
		resources(ChatMessage, ChatMessagesController, {only: [index, create]});
		get("users", to(UsersController, index), {asName: routeName("users")});
		post("guest", to(SessionsController, createGuest), {asName: routeName("guest_sign_in")});
		namespace("admin", {
			get("users", to(UsersController, index));
		});
		get("reports(/:year)", to(TodosController, optionalReport), {asName: routeName("optional_report")});
		get("files/*path", to(TodosController, file), {asName: routeName("file")});
	};
}
