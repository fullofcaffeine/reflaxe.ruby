package views;

import rails.action_view.HtmlNode;
import rails.action_view.Slot;

typedef TodoCardLocals = {
	var eyebrow:String;
	var title:String;
	var body:Slot;
}

// Reusable typed component partial.
//
// Demonstrates: Rails-native component composition using a typed partial local
// (`body:Slot`) rather than copying Phoenix slot syntax. The small
// `cardClass` function is a view-local helper: pure presentation logic lives
// beside the HHX that uses it and is inlined into Rails ERB.
// Type safety: callers must pass `TodoCardLocals`; `body` is a typed captured
// slot value and `locals.eyebrow/title` are checked as `String`.
// IntelliSense: editors should complete `TodoCardLocals` fields at call sites
// and `locals.*` plus `cardClass` inside the HHX body.
// Ruby/Rails output: `_card.html.erb` with normal Rails captured-buffer locals.
@:railsTemplate("todos/_card")
@:railsTemplateAst("render")
class TodoCardView {
	public static function render(locals:TodoCardLocals):HtmlNode {
		return <section class=${cardClass()}>
			<div class="typed-dashboard-header">
				<span class="eyebrow">${locals.eyebrow}</span>
				<h2>${locals.title}</h2>
			</div>
			${locals.body}
		</section>;
	}

	static function cardClass():String {
		return "card " + "typed-dashboard";
	}
}
