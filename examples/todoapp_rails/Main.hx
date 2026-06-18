import controllers.TodosController;
import migrations.CreateTodos;
import migrations.UpdateTodos;
import models.Todo;
import routes.AppRoutes;
import test_haxe.models.TodoHaxeTest;
import views.ApplicationLayoutView;
import views.TodoCardView;
import views.TodoComposerView;
import views.TodoDashboardView;
import views.TodoFormView;
import views.TodoIndexView;
import views.TodoListView;
import views.TodoSummaryView;

// RailsHx todoapp compile sentinel.
//
// Demonstrates: the end-to-end app graph compiles: models, migrations,
// controller, layout, and all HHX views.
// Type safety: each imported class must resolve through Haxe, so renaming a view
// or migration breaks the compile before Rails receives stale generated files.
// The Haxe-authored Rails test import proves generated test artifacts are also
// in the compile graph without being emitted into app autoload paths.
// IntelliSense: editors should complete the full app surface from Haxe packages.
// Ruby/Rails output: generated Rails app artifacts under the configured output
// root plus ActionView templates and migrations.
class Main {
	static function main() {
		var todo:Todo = null;
		var routes:Class<AppRoutes> = null;
		var haxeAuthoredTest:Class<TodoHaxeTest> = TodoHaxeTest;
		var migration:Class<CreateTodos> = CreateTodos;
		var updateMigration:Class<UpdateTodos> = UpdateTodos;
		var controller:TodosController = null;
		var layoutView:Class<ApplicationLayoutView> = ApplicationLayoutView;
		var cardView:Class<TodoCardView> = TodoCardView;
		var composerView:Class<TodoComposerView> = TodoComposerView;
		var dashboardView:Class<TodoDashboardView> = TodoDashboardView;
		var formView:Class<TodoFormView> = TodoFormView;
		var listView:Class<TodoListView> = TodoListView;
		var view:Class<TodoIndexView> = TodoIndexView;
		var summaryView:Class<TodoSummaryView> = TodoSummaryView;
		Sys.println(todo == null);
		Sys.println(routes == null);
		Sys.println(haxeAuthoredTest != null);
		Sys.println(migration != null);
		Sys.println(updateMigration != null);
		Sys.println(controller == null);
		Sys.println(layoutView != null);
		Sys.println(cardView != null);
		Sys.println(composerView != null);
		Sys.println(dashboardView != null);
		Sys.println(formView != null);
		Sys.println(listView != null);
		Sys.println(view != null);
		Sys.println(summaryView != null);
	}
}
