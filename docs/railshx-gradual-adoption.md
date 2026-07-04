# RailsHx Gradual Adoption

RailsHx should make mixed Rails apps boring. A team can start with a quick pure Rails/Ruby/ERB PoC, wrap the stable seams in typed Haxe, and later convert pieces to Haxe/HHX without breaking normal Rails callers.

## Boundary Model

RailsHx-authored UI is HHX-first. Existing Rails UI is external Rails source.

- Use HHX and `@:railsTemplateAst(...)` for new Haxe-owned templates, partials, and layouts.
- Use `Template.existing("path") : Template<TLocals>` when Haxe renders an existing ERB partial/template that is discoverable under `app/views` or `rails/app/views`.
- Reserve lower-level `Template.external("path") : Template<TLocals>` for unusual/test layouts where the macro cannot discover the file, and document why the filesystem check cannot apply.
- Missing `Template.existing(...)` / `Component.existing(...)` files fail during Haxe compilation; use this as the default for gradual conversion from Rails-owned ERB to typed HHX.
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
<partial template=${(Template.existing("legacy/badge") : Template<LegacyBadgeLocals>)} locals=${{
	label: locals.legacyBadgeLabel,
	tone: "warm"
}} />
```

RailsHx emits a normal Rails render call and does not emit or overwrite `app/views/legacy/_badge.html.erb`.

To scaffold this boundary in an existing app, use the Ruby-native adoption generator:

```bash
bin/rails generate hxruby:adopt --template legacy/badge --locals label:String,tone:String
rake rails:adopt ARGS="--template legacy/badge --locals label:String,tone:String"
```

Inside a Rails app with the gem tasks loaded, the equivalent host-framework command is:

```bash
bundle exec rake hxruby:gen:adopt TEMPLATE=legacy/badge LOCALS=label:String,tone:String
```

The generated Haxe wrapper owns only the typed `Template.existing(...)`/`Template.external(...)` contract. The existing ERB file remains Rails-owned source.

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

The adoption generator can also scaffold the extern shell:

```bash
bin/rails generate hxruby:adopt --service LegacyPriceFormatter
rake rails:adopt ARGS="--service LegacyPriceFormatter"
```

For an explicit Ruby source file, it can also infer starter signatures:

```bash
bin/rails generate hxruby:adopt \
  --service LegacyPriceFormatter \
  --service-source app/services/legacy_price_formatter.rb

rake rails:adopt ARGS="--service LegacyPriceFormatter --service-source app/services/legacy_price_formatter.rb"
```

The service source path is checked to stay inside the app/output root and parsed with `Ripper`; app code is not executed. The generator emits constructors from `initialize`, instance methods from `def method`, and static methods from `def self.method`. Required arguments default to `Dynamic`; optional arguments with obvious scalar defaults become `String`, `Int`, `Float`, or `Bool`. Ambiguous splats, keyword-heavy signatures, and blocks are marked as TODO comments instead of guessed unsafely.

If a service already has RBS, prefer that as the deterministic type source:

```bash
bin/rails generate hxruby:adopt \
  --service RbsPriceFormatter \
  --rbs sig/rbs_price_formatter.rbs

rake rails:adopt ARGS="--service RbsPriceFormatter --rbs sig/rbs_price_formatter.rbs"

bundle exec rake hxruby:gen:adopt \
  SERVICE=RbsPriceFormatter \
  RBS=sig/rbs_price_formatter.rbs
```

RBS-backed adoption is file-backed and fail-closed: a missing `--rbs` path is a generator error, and the path must stay inside the app/output root. The first deterministic subset supports class declarations, `initialize`, instance methods, and `self.method` signatures with simple required and optional positional arguments. Known scalar types lower to Haxe types, while unsupported or application-specific RBS types lower to `Dynamic` with TODO/review comments in the generated extern. LLM-generated suggestions may help draft contracts later, but they must remain advisory patches; they do not bypass generator validation, Haxe compilation, Ruby syntax checks, or Rails runtime gates.

Add or tighten method signatures as the Ruby boundary stabilizes, then let Haxe enforce those calls from app code.

For Ruby extension modules, the generator can inspect a checked source file and scaffold `@:rubyMixin` contracts:

```bash
bin/rails generate hxruby:adopt \
  --extension-source app/models/concerns/sluggable.rb \
  --extension-module Sluggable

rake rails:adopt ARGS="--extension-source app/models/concerns/sluggable.rb --extension-module Sluggable"

bundle exec rake hxruby:gen:adopt \
  EXTENSION_SOURCE=app/models/concerns/sluggable.rb \
  EXTENSION_MODULE=Sluggable
```

This reads Ruby source through `Ripper`; it does not execute app code. Source paths must stay inside the app/output root. It emits instance and class-method contracts such as `SluggableInstance` and `SluggableClassMethods`, using `Dynamic` placeholders plus review comments when Ruby source has no type metadata. Simple required/optional arguments are emitted; splats, keyword-heavy signatures, and blocks are skipped with a comment so the generated Haxe remains compileable. Missing source files fail closed.

Generator inputs that become Haxe source are validated before files are written:
`--package` must be a safe Haxe package path, `--service` and
`--extension-module` must be Ruby constant paths, `--template` must be a safe
forward-slash relative Rails template path, and `--locals` entries must use safe
Haxe field names and type references. Existing generated wrappers are not
overwritten unless `--force` is explicit.

Use discovery as an advisory report before choosing wrappers:

```bash
bin/rails generate hxruby:adopt --discover
```

Discovery prints candidate Ruby constants and ERB templates but does not write guessed contracts.

Schema adoption uses the same discover-first workflow for the current
Rails-owned database snapshot:

```bash
bin/rails generate hxruby:adopt --schema --discover
bin/rails generate hxruby:adopt --schema --models Todo,User
```

The generated Haxe models are typed contracts over conventional `db/schema.rb`
snapshots; Rails still owns the database, historical migrations, and
`bin/rails db:migrate`. `structure.sql`, unsafe table/column names, and Haxe
field-name collisions fail closed. Ambiguous associations are emitted as review
comments instead of guessed `belongsTo` metadata, and unsupported DB types fail
unless `--allow-dynamic` is explicit.

Historical migrations can be inventoried, but RailsHx does not translate them
by default:

```bash
bin/rails generate hxruby:adopt --migrations --discover
```

That report classifies Rails-owned versus RailsHx-owned migration files and
prints duplicate timestamps/classes before you generate new Haxe migration
snapshots. Prefer schema adoption for current model contracts; keep old
Rails migrations as history.

## Generator Design

RailsHx public generators are Ruby-native because they run inside Rails projects, package with the `hxruby` gem, and should feel like normal Rails tooling. Prefer `bin/rails generate hxruby:*` inside Rails apps. This mirrors the PhoenixHx split: host-app scaffolding is implemented as Mix tasks, while Haxe project creation is a separate bootstrap path.

Haxe->Ruby self-hosted generators may be useful later for dogfooding and greenfield project creation, but they should not be required for gradual adoption in an existing Rails app. A Rails team should be able to install the gem, run a rake task, and receive Haxe contracts around existing Ruby/ERB without installing extra Node generator code or rewriting Rails-owned source.

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

- Haxe shell renders a legacy ERB partial through `Template.existing`.
- Haxe controller calls a legacy Ruby service through a typed extern.
- Legacy ERB shell renders a RailsHx-generated HHX partial.
- Legacy ERB calls a generated Haxe service as a normal Ruby constant.

Run the smoke lane:

```bash
npm run test:rails-interop
npm run test:rails-adopt-generator
```

The smoke compiles Haxe, materializes `test/.generated/rails_interop`, copies the Rails-owned Ruby/ERB files, checks the generated artifacts, verifies a wrong external-template locals object fails at Haxe compile time, and runs Rails request tests when the local Rails bundle is available.
