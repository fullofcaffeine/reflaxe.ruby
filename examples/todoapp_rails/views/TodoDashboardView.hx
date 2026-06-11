package views;

import controllers.TodosController.TodoIndexLocals;
import rails.action_view.H;
import rails.action_view.HtmlNode;
import rails.action_view.Template;
import routes.Routes;
import views.TodoSummaryView.TodoSummaryLocals;

@:railsTemplate("controllers/todos/_dashboard")
@:railsTemplateAst("render")
class TodoDashboardView {
	public static function render(locals:TodoIndexLocals):HtmlNode {
		return H.el("section", [H.className("typed-dashboard")], [
			H.el("h2", [], [H.text("Composed typed partial")]),
			H.linkTo("Back to todo route", Routes.todosPath(), [H.className("typed-route-link")]),
			H.partial((Template.named("controllers/todos/summary") : Template<TodoSummaryLocals>), {todos: locals.todos})
		]);
	}
}
