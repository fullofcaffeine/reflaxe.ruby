package views;

import controllers.TodosController.TodoIndexLocals;

@:railsTemplate("controllers/todos/index", "../app/views/controllers/todos/index.html.erb")
class TodoIndexView {
	public static var locals:TodoIndexLocals;
}
