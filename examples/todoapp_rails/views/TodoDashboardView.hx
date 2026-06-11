package views;

import controllers.TodosController.TodoIndexLocals;
import rails.action_view.HtmlNode;
import rails.action_view.Slot;
import rails.action_view.Template;
import routes.Routes;
import views.TodoCardView.TodoCardLocals;
import views.TodoSummaryView.TodoSummaryLocals;

@:railsTemplate("controllers/todos/_dashboard")
@:railsTemplateAst("render")
class TodoDashboardView {
	public static function render(locals:TodoIndexLocals):HtmlNode {
		return <component template=${(Template.named("controllers/todos/card") : Template<TodoCardLocals>)} slot="body" locals=${{
			eyebrow: "Composed typed component",
			title: "One typed component, reused by Rails.",
			body: Slot.content()
		}}>
			<link_to url="#open-work" class="typed-route-link" data-railshx-scroll>
				<span>${locals.todos.length > 0 ? "Jump to open work" : "Jump to the empty state"}</span>
				<span class="typed-route-count">${locals.todos.length}</span>
			</link_to>
			<partial template=${(Template.named("controllers/todos/summary") : Template<TodoSummaryLocals>)} locals=${{todos: locals.todos}} />
		</component>;
	}
}
