package views;

import rails.action_view.HtmlNode;

typedef TypedSummaryLocals = {
	var title:String;
	var count:Int;
	var note:String;
}

@:railsTemplate("typed_widgets/_summary")
@:railsTemplateAst("render")
class TypedWidgetView {
	public static function render(locals:TypedSummaryLocals):HtmlNode {
		return <aside class="typed-widget">
			<span class="eyebrow">RailsHx generated partial</span>
			<div>
				<h2>${locals.title}</h2>
				<p>${locals.note}</p>
			</div>
			<strong>${locals.count}</strong>
		</aside>;
	}
}
