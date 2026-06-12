# RailsHx Mixed Ruby/ERB Interop App

This sample shows the gradual adoption path for an existing Rails app or a quick Rails PoC that later gets typed Haxe layers.

## What It Proves

- Haxe can render an existing ERB partial through `Template.existing("legacy/badge")` while type-checking the locals object and checking that the Rails-owned ERB file exists.
- Haxe can call existing Ruby through a typed extern such as `@:native("LegacyPriceFormatter")`.
- Existing ERB can render a RailsHx-generated HHX partial through normal Rails `render partial:`.
- Existing Ruby/ERB can call a generated Haxe service as a normal Ruby constant, for example `Services::TypedStats.summary(...)`.

## Workflow

Start with plain Rails for a PoC if that is fastest. When a boundary becomes valuable, wrap it instead of rewriting it immediately:

```haxe
typedef LegacyBadgeLocals = {
	var label:String;
	var tone:String;
}

<partial template=${(Template.existing("legacy/badge") : Template<LegacyBadgeLocals>)} locals=${{
	label: locals.legacyBadgeLabel,
	tone: "warm"
}} />
```

The external ERB stays Rails-owned source. RailsHx only owns the typed contract and the generated render call.

## Dev Loop

```bash
npm run test:rails-interop
```

The smoke lane compiles the Haxe sources, materializes a disposable Rails app under `test/.generated/rails_interop`, copies the legacy Ruby/ERB files, and runs Rails request tests when Rails gems are available.
