package views;

import models.Todo;
import rails.action_view.H;
import rails.action_view.HtmlNode;

typedef TodoSummaryLocals = {
	var todos:Array<Todo>;
}

@:railsTemplate("controllers/todos/_summary")
@:railsTemplateAst("render")
class TodoSummaryView {
	public static function render(todos:Array<Todo>):HtmlNode {
		return H.el("aside", [
			H.className("card typed-template-card"),
			H.attr("aria-label", "Typed RailsHx template summary")
		], [
			H.el("span", [H.className("eyebrow")], [H.text("Typed template partial")]),
			H.el("p", [H.className("hero-copy")], [
				H.text("This block is authored with typed Haxe template helpers and emitted as Rails ERB.")
			]),
			H.el("div", [H.className("stat")], [
				H.el("strong", [], [H.expr(todos.length)]),
				H.el("span", [], [H.text("todos seen by typed helpers")])
			]),
			H.el("ul", [H.className("todo-list typed-template-list")], [
				H.each(todos, function(todo) {
					return H.el("li", [H.className("todo-item")], [
						H.el("span", [H.className("todo-dot"), H.attr("aria-hidden", "true")], []),
						H.el("span", [], [H.expr(todo.title)])
					]);
				})
			])
		]);
	}
}
