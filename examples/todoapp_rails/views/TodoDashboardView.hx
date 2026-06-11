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
		return <section class="card typed-dashboard">
			<div class="typed-dashboard-header">
				<span class="eyebrow">Composed typed partial</span>
				<h2>One typed partial, reused by Rails.</h2>
			</div>
			<link_to url="#open-work" class="typed-route-link" data-railshx-scroll>
				<span>${locals.todos.length > 0 ? "Jump to open work" : "Jump to the empty state"}</span>
				<span class="typed-route-count">${locals.todos.length}</span>
			</link_to>
			<partial template=${(Template.named("controllers/todos/summary") : Template<TodoSummaryLocals>)} locals=${{todos: locals.todos}} />
		</section>;
	}
}
