# RailsHx Gradual Adoption

RailsHx should make mixed Rails apps boring. A team can start with a quick pure Rails/Ruby/ERB PoC, wrap the stable seams in typed Haxe, and later convert pieces to Haxe/HHX without breaking normal Rails callers.

## Boundary Model

RailsHx-authored UI is HHX-first. Existing Rails UI is external Rails source.

- Use HHX and `@:railsTemplateAst(...)` for new Haxe-owned templates, partials, and layouts.
- Use `Template.external("path") : Template<TLocals>` when Haxe renders an existing ERB partial/template.
- Use `@:native("RubyConstant") extern class ...` for existing Ruby services, helpers, components, and framework objects.
- Let Ruby consume generated Haxe through normal Rails constants and normal `render partial:` calls.

This keeps the Haxe side typed while preserving the core Rails promise: generated Ruby and generated views look like ordinary Rails artifacts.

## Haxe Consumes Existing ERB

Define the locals contract in Haxe:

```haxe
typedef LegacyBadgeLocals = {
	var label:String;
	var tone:String;
}
```

Render the existing partial from HHX:

```haxe
<partial template=${(Template.external("legacy/badge") : Template<LegacyBadgeLocals>)} locals=${{
	label: locals.legacyBadgeLabel,
	tone: "warm"
}} />
```

RailsHx emits a normal Rails render call and does not emit or overwrite `app/views/legacy/_badge.html.erb`.

## Haxe Consumes Existing Ruby

Wrap Ruby with a typed extern:

```haxe
@:native("LegacyPriceFormatter")
extern class LegacyPriceFormatter {
	public static function call(cents:Int):String;

	@:native("badge_label")
	public static function badgeLabel(kind:String, cents:Int):String;
}
```

The generated Ruby remains direct and recognizable:

```ruby
LegacyPriceFormatter.badge_label("poc", 1299)
```

Prefer externs and typed facades over raw `__ruby__` so app code remains searchable, type-checkable, and portable where it matters.

## Ruby Consumes Generated Haxe

Generated Haxe services/classes are normal Rails constants under `app/haxe_gen`.

```erb
<%= Services::TypedStats.summary(["legacy shell", "typed service"]) %>
```

Generated HHX partials are normal Rails partials:

```erb
<%= render partial: "typed_widgets/summary", locals: {
  title: "HHX island rendered from ERB",
  count: 2,
  note: Services::TypedStats.confidence_label
} %>
```

Ruby callers do not need a RailsHx adapter. If a generated Haxe API needs a nicer Ruby-facing surface, add a small stable facade rather than exposing unstable internal names.

## Example App

`examples/rails_interop_app` demonstrates four adoption paths:

- Haxe shell renders a legacy ERB partial through `Template.external`.
- Haxe controller calls a legacy Ruby service through a typed extern.
- Legacy ERB shell renders a RailsHx-generated HHX partial.
- Legacy ERB calls a generated Haxe service as a normal Ruby constant.

Run the smoke lane:

```bash
npm run test:rails-interop
```

The smoke compiles Haxe, materializes `test/.generated/rails_interop`, copies the Rails-owned Ruby/ERB files, checks the generated artifacts, verifies a wrong external-template locals object fails at Haxe compile time, and runs Rails request tests when the local Rails bundle is available.
