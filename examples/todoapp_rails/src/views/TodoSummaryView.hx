package views;

import models.Todo;
import rails.action_view.HtmlNode;

typedef TodoSummaryLocals = {
	var todos:Array<Todo>;
}

// Typed summary partial.
//
// Demonstrates: a partial can accept a directly typed argument (`Array<Todo>`)
// instead of only a locals object when the template shape is simple.
// Type safety: `todos` is an `Array<Todo>`, so loop bodies get typed `Todo`
// fields and bad property names fail in Haxe.
// IntelliSense: editors should complete array members (`length`) and `Todo`
// fields (`title`, `notes`) inside the HHX body.
// Ruby/Rails output: a normal `_summary.html.erb` partial generated from HHX.
@:railsTemplate("todos/_summary")
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
							<div>
								<span>${todo.title}</span>
								<if ${todo.notes != ""}>
									<p class="todo-notes">${todo.notes}</p>
								</if>
							</div>
						</li>
					</for>
				</ul>
			</if>
		</aside>;
	}
}
