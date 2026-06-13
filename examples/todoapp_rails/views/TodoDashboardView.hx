package views;

import controllers.TodosController.TodoIndexLocals;
import rails.action_view.Component as RailsComponent;
import rails.action_view.HtmlNode;
import rails.action_view.Slot;
import rails.action_view.Template;
import routes.Routes;
import shared.TodoHooks;
import views.TodoCardView.TodoCardLocals;
import views.TodoSummaryView.TodoSummaryLocals;

// Typed component/slot dashboard.
//
// Demonstrates: RailsHx component composition with captured child content, route
// helper links, typed locals, and nested typed partials.
// Type safety: `Template.of(TodoCardView) : Template<TodoCardLocals>` validates
// component locals, `Slot.content()` supplies the captured child slot, and
// `TodoSummaryLocals` checks the nested summary render.
// IntelliSense: editors should complete `Routes`, `Template.of`, `Slot`, and
// `locals.todos` as `Array<Todo>`.
// Ruby/Rails output: Rails-native `link_to` and `render partial:` calls, not a
// custom component runtime.
@:railsTemplate("controllers/todos/_dashboard")
@:railsTemplateAst("render")
class TodoDashboardView {
	public static function render(locals:TodoIndexLocals):HtmlNode {
		return <component component=${(RailsComponent.of(TodoCardView, TodoHooks.componentBodySlot) : RailsComponent<TodoCardLocals>)} locals=${{
			eyebrow: "Composed typed component",
			title: "One typed component, reused by Rails.",
			body: Slot.content()
		}}>
			<link_to url=${TodoHooks.openWorkHref} class="typed-route-link" data-railshx-scroll>
				<span>${locals.todos.length > 0 ? "Jump to open work" : "Jump to the empty state"}</span>
				<span class="typed-route-count">${locals.todos.length}</span>
			</link_to>
			<partial template=${(Template.of(TodoSummaryView) : Template<TodoSummaryLocals>)} locals=${{todos: locals.todos}} />
		</component>;
	}
}
