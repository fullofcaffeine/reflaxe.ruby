package views;

import controllers.TodosController.TodoIndexLocals;
import rails.action_view.HtmlNode;
import rails.action_view.Template;
import shared.TodoHooks;
import views.TodoComposerView.TodoComposerLocals;
import views.TodoListView.TodoListLocals;
import views.TodoDashboardView;
import views.UserSwitcherView.UserSwitcherLocals;

// Todo index page authored as typed HHX.
//
// Demonstrates: a full Rails page composed from typed partials, typed locals,
// content-for layout slots, DOM hooks for Haxe-authored JS, and static markup.
// Type safety: `TodoIndexLocals` drives `locals.*` completion; each
// `Template.of(...) : Template<...Locals>` cast validates the partial class and
// the locals object passed to it.
// IntelliSense: editors should complete `locals.todoCount`,
// `locals.typedColumnCount`, `Template.of`, and partial-local field names.
// Ruby/Rails output: `index.html.erb` with ordinary Rails `content_for` and
// `render partial:` calls.
@:railsTemplate("controllers/todos/index")
@:railsTemplateAst("render")
class TodoIndexView {
	public static function render(locals:TodoIndexLocals):HtmlNode {
		return <>
			<content_for name=${TodoHooks.headSlot}>
				<meta name=${TodoHooks.templateMetaName} content=${TodoHooks.templateMetaContent} />
			</content_for>
			<main class=${TodoHooks.shellClass}>
				<div class=${TodoHooks.flashClass} data-railshx-flash role="status" aria-live="polite" hidden></div>
				<section class="hero">
					<div class="card">
						<span class="eyebrow">RailsHx sample</span>
						<h1>Typed Rails, polished Ruby.</h1>
						<p class="hero-copy">
							This todo app is authored in Haxe with typed ActiveRecord metadata,
							strong params, route helpers, and a Haxe-owned Rails template artifact.
						</p>
					</div>

					<aside class="card" aria-label="Todo stats">
						<div class="stat">
							<strong>${locals.todoCount}</strong>
							<span>open tasks</span>
						</div>
						<div class="stat">
							<strong>${locals.typedColumnCount}</strong>
							<span>typed columns</span>
						</div>
					</aside>
				</section>

				<partial template=${(Template.of(UserSwitcherView) : Template<UserSwitcherLocals>)} locals=${{
					users: locals.users,
					currentUser: locals.currentUser
				}} />

				<section class="workspace">
					<div class="card">
						<h2>Add a task</h2>
						<partial template=${(Template.of(TodoComposerView) : Template<TodoComposerLocals>)} locals=${{sampleUser: locals.sampleUser}} />
					</div>

					<div id=${TodoHooks.openWorkId} class="card open-work-card" tabindex="-1">
						<h2>Open work</h2>
						<partial template=${(Template.of(TodoListView) : Template<TodoListLocals>)} locals=${{todos: locals.todos}} />
					</div>
				</section>

				<partial template=${(Template.of(TodoDashboardView) : Template<TodoIndexLocals>)} locals=${{
					todos: locals.todos,
					users: locals.users,
					todoCount: locals.todoCount,
					typedColumnCount: locals.typedColumnCount,
					sampleUser: locals.sampleUser,
					currentUser: locals.currentUser
				}} />
			</main></>;
	}
}
