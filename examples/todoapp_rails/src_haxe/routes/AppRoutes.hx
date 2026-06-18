package routes;

import controllers.TodosController;
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
		root(to(TodosController, index));
		resources(Todo, TodosController, {only: [index, create]});
	};
}
