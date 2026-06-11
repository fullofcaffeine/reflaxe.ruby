package views;

import controllers.TodosController.TodoIndexLocals;
import rails.action_view.HtmlNode;
import rails.action_view.Template;
import views.TodoComposerView.TodoComposerLocals;
import views.TodoListView.TodoListLocals;

@:railsTemplate("controllers/todos/index")
@:railsTemplateAst("render")
class TodoIndexView {
	public static function render(locals:TodoIndexLocals):HtmlNode {
		return <>
			<content_for name="head">
				<meta name="railshx-template" content="todo-index" />
			</content_for>
			<main class="todo-shell">
				<div class="railshx-flash" data-railshx-flash role="status" aria-live="polite" hidden></div>
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

				<section class="workspace">
					<div class="card">
						<h2>Add a task</h2>
						<partial template=${(Template.named("controllers/todos/composer") : Template<TodoComposerLocals>)} locals=${{sampleUser: locals.sampleUser}} />
					</div>

					<div id="open-work" class="card open-work-card" tabindex="-1">
						<h2>Open work</h2>
						<partial template=${(Template.named("controllers/todos/list") : Template<TodoListLocals>)} locals=${{todos: locals.todos}} />
					</div>
				</section>

				<partial template=${(Template.named("controllers/todos/dashboard") : Template<TodoIndexLocals>)} locals=${{
					todos: locals.todos,
					todoCount: locals.todoCount,
					typedColumnCount: locals.typedColumnCount,
					sampleUser: locals.sampleUser
				}} />
			</main></>;
	}
}
