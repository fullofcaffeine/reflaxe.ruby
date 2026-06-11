import controllers.TodosController;
import models.Todo;
import views.TodoIndexView;
import views.TodoSummaryView;

class Main {
	static function main() {
		var todo:Todo = null;
		var controller:TodosController = null;
		var view:Class<TodoIndexView> = TodoIndexView;
		var summaryView:Class<TodoSummaryView> = TodoSummaryView;
		Sys.println(todo == null);
		Sys.println(controller == null);
		Sys.println(view != null);
		Sys.println(summaryView != null);
	}
}
