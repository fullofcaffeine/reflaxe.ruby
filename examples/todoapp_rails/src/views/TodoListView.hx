package views;

import models.Todo;
import rails.action_view.HtmlNode;
import shared.TodoHooks;

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
// Turbo safety: the outer `railshx-todo-list` target is always present, even
// when the list is empty, so Rails `turbo_stream.replace(...)` has a stable
// target after the first task is created.
@:railsTemplate("todos/_list")
@:railsTemplateAst("render")
class TodoListView {
	public static function render(locals:TodoListLocals):HtmlNode {
		return <div id=${TodoHooks.todoListId} class="todo-list-frame">
			<if ${locals.todos.length > 0}>
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
			</if>
		</div>;
	}
}
