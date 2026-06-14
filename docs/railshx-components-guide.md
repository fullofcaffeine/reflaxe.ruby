# RailsHx Components Guide

RailsHx components are typed HHX partial composition over Rails ActionView. They
do not introduce a custom component runtime and they do not copy Phoenix slots.
Generated output is normal Rails ERB: `capture do ... end` plus
`render partial:`.

## Component Contract

Create a reusable component partial with typed locals. Slot content is modeled
as a typed `Slot` local:

```haxe
import rails.action_view.HtmlNode;
import rails.action_view.Slot;

typedef CardLocals = {
	var title:String;
	var body:Slot;
}

@:railsTemplate("components/_card")
@:railsTemplateAst("render")
class CardView {
	public static function render(locals:CardLocals):HtmlNode {
		return <article>
			<h2>${locals.title}</h2>
			${locals.body}
		</article>;
	}
}
```

## Rendering

Prefer `Component.of(...)` for RailsHx-owned components:

```haxe
import rails.action_view.Component as RailsComponent;
import rails.action_view.HtmlNode;
import rails.action_view.Slot;

class CardSlots {
	public static inline var body:String = "body";
}

@:railsTemplate("components/show")
@:railsTemplateAst("render")
class CardShellView {
	public static function render():HtmlNode {
		return <component component=${(RailsComponent.of(CardView, CardSlots.body) : RailsComponent<CardLocals>)} locals=${{
			title: "Typed component",
			body: Slot.content()
		}}>
			<p>Captured HHX children.</p>
		</component>;
	}
}
```

This lowers to Rails-native ERB:

```erb
<% railshx_component_body = capture do %>
  <p>Captured HHX children.</p>
<% end %>
<%= render partial: "components/card", locals: {title: "Typed component", body: railshx_component_body} %>
```

## Type Safety

- `RailsComponent.of(CardView, ...)` checks that `CardView` exists and has
  `@:railsTemplate("...")`.
- The cast to `RailsComponent<CardLocals>` makes the `locals={{...}}` object
  type-check against the component locals contract.
- `Slot.content()` may only be used as the matching component slot local.
- The slot name must match a field in the locals object, so changing `"body"` to
  `"content"` without changing the locals contract fails during Haxe compile.
- Editors should complete `RailsComponent.of`, `Slot.content()`, and the locals
  fields at the call site, and `locals.*` inside the component partial.

## Existing Rails Partials

For existing Rails-owned partials, use `Component.existing(...)` so the macro
checks the ERB file before compile succeeds. The slot name is also checked as a
safe Haxe/Ruby local identifier, so use a shared typed constant where the slot is
part of a reusable component contract:

```haxe
var card = (RailsComponent.existing("legacy/card", "body") : RailsComponent<CardLocals>);
```

If the file is not discoverable under `app/views` or `rails/app/views`, use a
lower-level explicit template/slot form only as an interop escape hatch:

```haxe
<component template=${Template.external("legacy/card")} slot="body" locals=${{title: title, body: Slot.content()}}>
	<p>Captured child content.</p>
</component>
```

## Smoke

Run the focused component lane:

```bash
npm run test:components
```

It verifies generated Rails output, Ruby syntax for generated support files,
wrong slot names, wrong local types, `Component.of` on non-template classes,
missing `Component.existing(...)` files, and unsafe component slot identifiers.
