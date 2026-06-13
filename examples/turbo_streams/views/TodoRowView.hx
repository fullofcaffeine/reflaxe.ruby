package views;

import rails.action_view.HtmlNode;

typedef TodoRowLocals = {
	var domId:String;
	var title:String;
	var completed:Bool;
}

// Typed Turbo Stream partial.
//
// Demonstrates: a RailsHx-owned HHX partial that can be rendered by
// `TurboStreams.*` helpers instead of passing a raw partial string.
// Type safety: callers use `Template.of(TodoRowView) : Template<TodoRowLocals>`,
// so stream append/replace/update/broadcast calls must provide `domId`, `title`,
// and `completed` with the expected Haxe types.
// IntelliSense: editors complete `TodoRowLocals`, `locals.domId`,
// `locals.title`, and `locals.completed` both inside the view and at call sites.
// Ruby/Rails output: `_todo.html.erb`, renderable by normal Rails
// `turbo_stream.append/replace/update` and `Turbo::StreamsChannel.broadcast_*`.
@:railsTemplate("todos/_todo")
@:railsTemplateAst("render")
class TodoRowView {
	public static function render(locals:TodoRowLocals):HtmlNode {
		return <li id=${locals.domId} class=${locals.completed ? "todo-row is-complete" : "todo-row"}>
			<span class="todo-row__dot" aria-hidden="true"></span>
			<span class="todo-row__title">${locals.title}</span>
		</li>;
	}
}
