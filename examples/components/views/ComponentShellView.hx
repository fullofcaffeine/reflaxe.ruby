package views;

import rails.action_view.Component as RailsComponent;
import rails.action_view.HtmlNode;
import rails.action_view.Slot;
import shared.CardSlots;
import views.ComponentCardView.ComponentCardLocals;

// Component caller authored in HHX.
//
// Demonstrates: `RailsComponent.of(ComponentCardView, CardSlots.body)` centralizes
// the Rails partial path and slot name, while `locals={{...}}` remains the typed
// locals contract for `ComponentCardLocals`.
// Type safety: misspelling `body`, omitting `title`, or passing the wrong field
// types fails during Haxe compilation before Rails renders the ERB.
// IntelliSense: editors should complete `RailsComponent.of`, `CardSlots.body`,
// `Slot.content()`, and the required locals object fields.
// Ruby/Rails output: `capture do ... end` followed by `render partial:`.
@:railsTemplate("components/show")
@:railsTemplateAst("render")
class ComponentShellView {
	public static function render():HtmlNode {
		return <component component=${(RailsComponent.of(ComponentCardView, CardSlots.body) : RailsComponent<ComponentCardLocals>)} locals=${{
			title: "Typed components, Rails output",
			tone: "warm",
			body: Slot.content()
		}}>
			<p>Children stay HHX and are captured into an ActionView buffer.</p>
			<strong>Rails still receives a normal partial local.</strong>
		</component>;
	}
}
