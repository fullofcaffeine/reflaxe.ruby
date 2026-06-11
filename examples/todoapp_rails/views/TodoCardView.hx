package views;

import rails.action_view.HtmlNode;
import rails.action_view.Slot;

typedef TodoCardLocals = {
	var eyebrow:String;
	var title:String;
	var body:Slot;
}

@:railsTemplate("controllers/todos/_card")
@:railsTemplateAst("render")
class TodoCardView {
	public static function render(locals:TodoCardLocals):HtmlNode {
		return <section class="card typed-dashboard">
			<div class="typed-dashboard-header">
				<span class="eyebrow">${locals.eyebrow}</span>
				<h2>${locals.title}</h2>
			</div>
			${locals.body}
		</section>;
	}
}
