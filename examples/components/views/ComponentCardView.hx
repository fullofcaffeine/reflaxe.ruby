package views;

import rails.action_view.HtmlNode;
import rails.action_view.Slot;

typedef ComponentCardLocals = {
	var title:String;
	var tone:String;
	var body:Slot;
}

// Reusable RailsHx component partial.
//
// Demonstrates: component locals are a normal typed Haxe typedef, and the slot
// is an ActionView captured buffer represented as `Slot`.
// Type safety: callers must pass `title`, `tone`, and `body`; `body` must be
// supplied through `Slot.content()` at the matching component call.
// IntelliSense: editors should complete `locals.title`, `locals.tone`, and
// `locals.body` here, plus `Component.of(...)` at call sites.
// Ruby/Rails output: a conventional `_card.html.erb` partial, not a custom
// runtime component object.
@:railsTemplate("components/_card")
@:railsTemplateAst("render")
class ComponentCardView {
	public static function render(locals:ComponentCardLocals):HtmlNode {
		return <article class=${"component-card component-card--" + locals.tone}>
			<header>
				<span class="component-eyebrow">RailsHx component</span>
				<h2>${locals.title}</h2>
			</header>
			<section class="component-body">
				${locals.body}
			</section>
		</article>;
	}
}
