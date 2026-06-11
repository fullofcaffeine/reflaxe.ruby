package views;

import models.Todo;
import rails.action_view.HtmlAttr;
import rails.action_view.HtmlNode;

@:railsTemplate("controllers/todos/_summary")
@:railsTemplateAst("render")
class TodoSummaryView {
	public static function render(todos:Array<Todo>):HtmlNode {
		return HtmlNode.Element("aside", [
			HtmlAttr.Static("class", "card typed-template-card"),
			HtmlAttr.Static("aria-label", "Typed RailsHx template summary")
		], [
			HtmlNode.Element("span", [HtmlAttr.Static("class", "eyebrow")], [HtmlNode.Text("Typed template partial")]),
			HtmlNode.Element("p", [HtmlAttr.Static("class", "hero-copy")], [
				HtmlNode.Text("This block is authored as a typed Haxe HtmlNode tree and emitted as Rails ERB.")
			]),
			HtmlNode.Element("div", [HtmlAttr.Static("class", "stat")], [
				HtmlNode.Element("strong", [], [HtmlNode.ExprText(todos.length)]),
				HtmlNode.Element("span", [], [HtmlNode.Text("todos seen by typed AST")])
			]),
			HtmlNode.Element("ul", [HtmlAttr.Static("class", "todo-list typed-template-list")], [
				HtmlNode.For(todos, function(todo) {
					return HtmlNode.Element("li", [HtmlAttr.Static("class", "todo-item")], [
						HtmlNode.Element("span", [HtmlAttr.Static("class", "todo-dot"), HtmlAttr.Static("aria-hidden", "true")], []),
						HtmlNode.Element("span", [], [HtmlNode.ExprText(todo.title)])
					]);
				})
			])
		]);
	}
}
