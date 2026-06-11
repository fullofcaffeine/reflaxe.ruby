import controllers.TodosController;
import models.Todo;
import views.ApplicationLayoutView;
import views.TodoCardView;
import views.TodoComposerView;
import views.TodoDashboardView;
import views.TodoFormView;
import views.TodoIndexView;
import views.TodoListView;
import views.TodoSummaryView;

class Main {
	static function main() {
		var todo:Todo = null;
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
