package views;

import controllers.TodosController.TodoIndexLocals;
import rails.action_view.HtmlNode;
import rails.action_view.Template;
import routes.Routes;
import views.TodoSummaryView.TodoSummaryLocals;

@:railsTemplate("controllers/todos/_dashboard")
@:railsTemplateAst("render")
class TodoDashboardView {
	public static function render(locals:TodoIndexLocals):HtmlNode {
		return <section class="typed-dashboard">
			<h2>Composed typed partial</h2>
			<link_to url=${Routes.todosPath()} class="typed-route-link">
				<span>${locals.todos.length > 0 ? "Back to todos" : "Back to empty todo route"}</span>
				<span class="typed-route-count">${locals.todos.length}</span>
			</link_to>
			<partial template=${(Template.named("controllers/todos/summary") : Template<TodoSummaryLocals>)} locals=${{todos: locals.todos}} />
		</section>;
	}
}
