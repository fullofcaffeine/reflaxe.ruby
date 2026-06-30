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
// is an ActionView captured buffer represented as `Slot`. The small
// `cardClass`/`heading` helpers are view-local presentation helpers: they live
// next to the HHX that uses them, stay type-checked by Haxe, and inline into
// Rails-native ERB without a custom helper runtime.
// Type safety: callers must pass `title`, `tone`, and `body`; `body` must be
// supplied through `Slot.content()` at the matching component call.
// IntelliSense: editors should complete `locals.title`, `locals.tone`, and
// `locals.body` here, plus `cardClass`, `heading`, and `Component.of(...)`.
// Ruby/Rails output: a conventional `_card.html.erb` partial, not a custom
// runtime component object.
@:railsTemplate("components/_card")
@:railsTemplateAst("render")
class ComponentCardView {
	public static function render(locals:ComponentCardLocals):HtmlNode {
		return <article class=${cardClass(locals.tone)}>
			<header>
				<span class="component-eyebrow">RailsHx component</span>
				<h2>${heading(locals.title)}</h2>
			</header>
			<section class="component-body">
				${locals.body}
			</section>
		</article>;
	}

	static function cardClass(tone:String):String {
		return "component-card component-card--" + tone;
	}

	static function heading(title:String):String {
		return "Typed: " + title;
	}
}
