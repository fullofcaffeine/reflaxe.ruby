package views;

import models.Todo;
import rails.action_view.HtmlNode;

typedef TodoListLocals = {
	var todos:Array<Todo>;
}

// Typed todo list partial.
//
// Demonstrates: HHX loops and conditionals over typed model instances.
// Type safety: `locals.todos` is `Array<Todo>`, so `todo.title` and `todo.notes`
// are checked against the ActiveRecord model fields.
// IntelliSense: editors should complete `locals.todos`, loop variable `todo`,
// and `Todo` model fields inside the `<for>` body.
// Ruby/Rails output: ERB conditional/iteration over the Rails local `todos`.
@:railsTemplate("controllers/todos/_list")
@:railsTemplateAst("render")
class TodoListView {
	public static function render(locals:TodoListLocals):HtmlNode {
		return <if ${locals.todos.length > 0}>
			<ul class="todo-list">
				<for ${todo in locals.todos}>
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
		<else>
			<div class="empty-state">
				No open tasks. Serene, but suspicious.
			</div>
		</if>;
	}
}
