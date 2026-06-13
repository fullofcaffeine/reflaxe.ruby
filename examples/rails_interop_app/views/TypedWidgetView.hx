package views;

import rails.action_view.HtmlNode;

typedef TypedSummaryLocals = {
	var title:String;
	var count:Int;
	var note:String;
}

// Haxe-owned partial consumed by both Haxe and legacy Rails.
//
// Demonstrates: a reusable Rails partial authored in typed HHX.
// Type safety: `TypedSummaryLocals` defines the required locals and their
// types; wrong/missing locals fail when Haxe renders this partial.
// IntelliSense: editors should complete `locals.title`, `locals.count`, and
// `locals.note` in the HHX body and show the typedef to callers.
// Ruby/Rails output: a conventional `_summary.html.erb` partial that existing
// ERB can render without a RailsHx adapter.
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
