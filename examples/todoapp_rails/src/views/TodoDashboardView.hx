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
// helper links, typed locals, mixed route ownership, and nested typed partials.
// Type safety: `Template.of(TodoCardView) : Template<TodoCardLocals>` validates
// component locals, `Slot.content()` supplies the captured child slot,
// `TodoSummaryLocals` checks the nested summary render, and both Haxe-owned and
// Rails-owned route helpers are regular typed `Routes.*` methods.
// IntelliSense: editors should complete `Routes`, `Template.of`, `Slot`, and
// `locals.todos` as `Array<Todo>`.
// Ruby/Rails output: Rails-native `link_to` and `render partial:` calls, not a
// custom component runtime.
@:railsTemplate("todos/_dashboard")
@:railsTemplateAst("render")
class TodoDashboardView {
	public static function render(locals:TodoIndexLocals):HtmlNode {
		// The second link below consumes a Rails-owned route from typed Haxe.
		// `legacy_health_path` is not authored in AppRoutes.hx; it comes from
		// the Rails-owned route snippet under rails/config and is surfaced to
		// Haxe by the generated `Routes.legacyHealthPath()` extern.
		return <component component=${(RailsComponent.of(TodoCardView, TodoHooks.componentBodySlot) : RailsComponent<TodoCardLocals>)} locals=${{
			eyebrow: "Composed typed component",
			title: "One typed component, reused by Rails.",
			body: Slot.content()
		}}>
			<link_to url=${TodoHooks.openWorkHref} class="typed-route-link" data-railshx-scroll>
				<span>${locals.todos.length > 0 ? "Jump to open work" : "Jump to the empty state"}</span>
				<span class="typed-route-count">${locals.todos.length}</span>
			</link_to>
			<link_to url=${Routes.legacyHealthPath()} class="typed-route-link rails-owned-route-link">
				<span>Rails-owned route, typed in Haxe</span>
			</link_to>
			<partial template=${(Template.of(TodoSummaryView) : Template<TodoSummaryLocals>)} locals=${{todos: locals.todos}} />
		</component>;
	}
}
