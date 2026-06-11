import controllers.TodosController;
import models.Todo;
import views.TodoIndexView;

class Main {
	static function main() {
		var todo:Todo = null;
		var controller:TodosController = null;
		var view:Class<TodoIndexView> = TodoIndexView;
		Sys.println(todo == null);
		Sys.println(controller == null);
		Sys.println(view != null);
	}
}
