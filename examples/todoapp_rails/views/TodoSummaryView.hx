package views;

import models.Todo;
import rails.action_view.HtmlNode;

typedef TodoSummaryLocals = {
	var todos:Array<Todo>;
}

@:railsTemplate("controllers/todos/_summary")
@:railsTemplateAst("render")
class TodoSummaryView {
	public static function render(todos:Array<Todo>):HtmlNode {
		return <aside class="card typed-template-card" aria-label="Typed RailsHx template summary">
			<span class="eyebrow">Typed template partial</span>
			<p class="hero-copy">This block is authored with typed Rails HHX and emitted as Rails ERB.</p>
			<div class="stat">
				<strong>${todos.length}</strong>
				<span>todos seen by typed HHX</span>
			</div>
			<if ${todos.length == 0}>
				<p class="empty-state">No typed HHX todos yet.</p>
			<else>
				<ul class="todo-list typed-template-list">
					<for ${todo in todos}>
						<li class="todo-item">
							<span class="todo-dot" aria-hidden="true"></span>
							<span>${todo.title}</span>
						</li>
					</for>
				</ul>
			</if>
		</aside>;
	}
}
