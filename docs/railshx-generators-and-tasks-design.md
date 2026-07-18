# RailsHx Generators And Rails Tasks Design

RailsHx is a typed Rails authoring layer, not a Rails replacement. Rails remains
the runtime owner; RailsHx owns Haxe source, typed contracts, compiler
validation, and generated Rails-shaped artifacts.

## Public Workflow

Greenfield RailsHx code should feel like normal Rails with a typed authoring
step. A newly installed RailsHx app should be runnable immediately:

```bash
bin/rails generate hxruby:install MyApp
bundle exec rake hxruby:start
```

For local editing, use the integrated Rails + Haxe watcher loop:

```bash
bin/railshx-dev
# or:
bundle exec rake hxruby:dev
# compatibility aliases:
bundle exec rake hxruby:start:watch
WATCH=1 bundle exec rake hxruby:start
bundle exec rake 'hxruby:start[watch]'
```

The runner builds server/client once before Rails starts, then delegates to one
change-aware, debounced watcher. See
[RailsHx Development Loop](railshx-development-loop.md) for input discovery,
failure recovery, and tuning.

After the starter, RailsHx generators should continue to compose with normal
Rails tasks through compile-then-delegate Rake wrappers:

```bash
bin/rails generate hxruby:model Todo title:string completed:boolean
bundle exec rake hxruby:db:migrate
bundle exec rake hxruby:test
```

Raw `bin/rails db:migrate` and `bin/rails test` remain valid when generated
artifacts are already current. The `hxruby:*` wrappers are the recommended
RailsHx path because they compile Haxe-owned Ruby, ERB, migrations, routes, and
client artifacts before Rails consumes them.

Existing Rails apps should adopt incrementally:

```bash
bin/rails generate hxruby:install
bin/rails generate hxruby:adopt --schema --discover
bin/rails generate hxruby:adopt --schema --models Todo,User
bin/rails generate hxruby:routes
bundle exec rake hxruby:compile
bundle exec rake hxruby:test
```

Production and CI should compose RailsHx compilation before Rails-owned checks:

```bash
bundle exec rake hxruby:compile
bundle exec rake hxruby:compile:client
bundle exec rake hxruby:db:migrate
bundle exec rake hxruby:test
bin/rails zeitwerk:check
RAILS_ENV=production bundle exec rake hxruby:production
```

Do not override raw Rails tasks or add ambiguous names such as `hxruby:migrate`.
Rails owns migration execution; RailsHx emits normal timestamped ActiveRecord
migration files that Rails runs. RailsHx-prefixed task names should be explicit
composition helpers: compile artifacts first, then delegate to Rails.

## Ownership Model

Rails-owned surfaces:

- `bin/rails db:migrate`, `db:rollback`, `db:migrate:status`, and schema dumps.
- `bin/rails test`, Minitest/RSpec runtime, and Rails fixture/runtime behavior.
- `zeitwerk:check`, `assets:precompile`, Rails boot, and Rails autoloading.
- Existing/adopted `config/routes.rb` files by default; RailsHx may patch only
  through safe explicit marker blocks or print snippets.
- Existing `app/models/**/*.rb`, `app/controllers/**/*.rb`,
  `app/views/**/*.erb`, and `db/migrate/**/*.rb` files unless a RailsHx manifest
  proves ownership.

RailsHx-owned surfaces:

- Haxe source under `src_haxe/**`, `test_haxe/**`, and generator-owned Haxe
  paths.
- Compiler output such as `app/haxe_gen/**/*.rb`, generated HHX `.html.erb`
  files, generated test files, generated client JS, and generated migrations.
- Generated route externs derived from Rails routes.
- Haxe-owned route declarations such as `src_haxe/routes/AppRoutes.hx` in
  greenfield RailsHx apps, which emit normal `config/routes.rb` artifacts.
- Adoption wrappers for Ruby services, ERB partials, schema contracts, routes,
  RBS/YARD contracts, and extension/mixin externs.
- A manifest and generated-file headers that record which source produced which
  Rails artifact.

The invariant is simple: RailsHx creates Rails-native artifacts, but Rails
runtime semantics remain Rails semantics.

## Generator Shape

Public Rails app integration should stay Ruby/Rails-native:

- Rails generator adapters live under `lib/generators/hxruby/**`.
- Shared implementation lives under `lib/hxruby/generators/**`.
- Scripts under `scripts/rails/**` may call the same shared library.
- Haxe->Ruby generator dogfooding can come later, after the Ruby generator
  contract is stable and tested.

The app-facing commands should be namespaced:

```bash
bin/rails generate hxruby:install
bin/rails generate hxruby:routes
bin/rails generate hxruby:adopt
bin/rails generate hxruby:migration AddStatusToTodos status:string
bin/rails generate hxruby:model Todo title:string completed:boolean
bin/rails generate hxruby:controller Todos index show --templates
bin/rails generate hxruby:scaffold Todo title:string completed:boolean
```

Do not override `bin/rails generate model`, `migration`, or `scaffold` by
default. A future explicit install profile may configure Rails generator
fallbacks, but gradual adoption depends on vanilla Rails generators remaining
valid.

## Install Generator Starter Skeleton

`bin/rails generate hxruby:install MyApp` and the repository wrapper
`rake rails:app ARGS="--output path/to/app --name MyApp"` should create a
starter that is useful before the user adds a model. The generator writes the
RailsHx build files, app-local Rake entrypoints, and a small typed app graph:

- `src_haxe/Boot.hx`: compile sentinel that references the starter controller,
  views, and routes so refactors fail during Haxe compilation instead of leaving
  stale Rails artifacts.
- `src_haxe/controllers/HomeController.hx`: typed `@:railsController` example
  with `static final lifecycle = []` and typed template/layout rendering.
- `src_haxe/views/ApplicationLayoutView.hx`: typed HHX layout that emits
  `app/views/layouts/application.html.erb` with Rails CSRF/CSP, stylesheet, and
  importmap helpers.
- `src_haxe/views/HomeIndexView.hx`: typed HHX page with a `HomeIndexLocals`
  object, proving locals/completion before Rails receives ERB.
- `src_haxe/routes/AppRoutes.hx`: Haxe-owned `@:railsRoutes` root route that
  emits normal `config/routes.rb`.
- `src_haxe/routes/Routes.hx`: placeholder typed route-helper extern file. It
  should be regenerated from Rails output with
  `bundle exec rake hxruby:gen:routes` after route changes.
- `src_haxe/client/Boot.hx`: Haxe-authored browser entrypoint compiled into the
  Rails importmap asset path.
- `.haxerc`: app-local scoped dependency resolution so `haxe_libraries/**`
  entries are used instead of requiring global haxelib installs.
- `build.hxml` and `build-client.hxml`: server and client compile contracts.
  The client build should use Genes so generated apps get readable ES module
  output for Rails importmap/Propshaft instead of one flattened JavaScript file.
  It should also use `-lib railshx.client` so generated apps consume typed
  Turbo and `reflaxe.js.Async` helpers from the browser-safe `hxruby` client
  library instead of loading the Ruby target compiler package.
- `haxe_libraries/railshx.client.hxml`, `haxe_libraries/genes.hxml`, and
  `haxe_libraries/helder.set.hxml`: app-local dependency stubs for the client
  lane. `hxruby` rake tasks set `HXRUBY_GEM_ROOT`, so generated apps resolve
  RailsHx browser helpers and vendored Genes source from the installed package
  or checkout.
- `lib/tasks/hxruby.rake`: app-local task bridge that loads `hxruby/tasks`.
- `bin/railshx-dev` and `bin/railshx-prod`: developer and production wrappers.
- `Procfile.railshx.dev`: optional process-manager entrypoint that delegates to
  the same canonical `hxruby:dev` runner; the built-in loop does not require a
  process-manager dependency.

The starter defaults to Haxe-owned source of truth for the generated
controller, HHX layout/page, client JS, and root route because it is greenfield
RailsHx. Existing Rails apps remain first-class: if a team already owns
`config/routes.rb`, controllers, ERB, or Ruby services, generators must consume
them through route sync, typed externs, `Template.existing(...)`, or adoption
wrappers rather than regenerating unowned files.

Route generation is explicit:

```bash
bin/rails generate hxruby:install MyApp --routes=haxe    # default greenfield mode
bin/rails generate hxruby:install MyApp --routes=snippet # reviewable instructions
bin/rails generate hxruby:install MyApp --routes=rails   # Rails-owned routes
bin/rails generate hxruby:install MyApp --routes=none    # leave routes untouched
```

`haxe` writes `AppRoutes.hx` plus a placeholder `Routes.hx`; `rails` writes only
the helper extern placeholder; `snippet` writes the placeholder plus
`docs/railshx/routes.md`; `none` writes no route files.

The generated app-level Rake UX is:

```bash
bundle exec rake hxruby:start         # compile server/client, then run Rails
bundle exec rake hxruby:dev           # compile once, then Rails + one watcher
bundle exec rake hxruby:start:watch   # compatibility alias for hxruby:dev
bundle exec rake hxruby:compile       # lower-level server compile
bundle exec rake hxruby:compile:client
bundle exec rake hxruby:db:migrate    # compile server/migrations, then rails db:migrate
bundle exec rake hxruby:db:prepare    # compile server/migrations, then rails db:prepare
bundle exec rake hxruby:test          # compile server/client, then rails test
bundle exec rake hxruby:rails TASK=zeitwerk:check
bundle exec rake hxruby:gen:routes    # regenerate typed Routes.hx from Rails
bundle exec rake hxruby:doctor        # non-mutating environment/artifact health report
bundle exec rake hxruby:check         # compile and ruby -c generated Ruby
bundle exec rake hxruby:clean         # remove manifest-owned generated artifacts
bundle exec rake hxruby:production    # compile, zeitwerk:check, assets
```

`bin/railshx-dev` delegates directly to `bundle exec rake hxruby:dev`, so the
generated app has the same deterministic process and build ordering without a
Foreman, Overmind, or native file-watcher dependency. The optional generated
Procfile exposes that same built-in runner as one `dev` process.

## Model Generator Contract

`hxruby:model` creates typed Haxe ActiveRecord source and, by default, delegates
to `hxruby:migration` to create a production-safe create-table snapshot:

```bash
bin/rails generate hxruby:model Todo \
  title:string! completed:boolean:index price:decimal{10,2} user:references! \
  --validate title,presence \
  --timestamp 20260616012000 \
  --migration-version 8.1
```

The generated model is current API:

```haxe
package models;

@:railsModel("todos")
@:railsTimestamps
class Todo extends rails.active_record.Base<Todo> {
	@:railsColumn({nullable: false})
	public var title:String;

	@:railsColumn({index: true})
	public var completed:Null<Bool>;

	@:railsColumn({dbType: "decimal"})
	public var price:Null<Float>;

	@:railsColumn({nullable: false})
	public var userId:Int;

	@:belongsTo({foreignKey: "userId", optional: false})
	public var user:rails.ActiveRecord.BelongsTo<User>;

	@:validates({presence: true})
	public var titleValidation:rails.ActiveRecord.Validation<String>;
}
```

The generated migration is history:

```haxe
class CreateTodos extends Migration {
	public static final operations:Array<MigrationOperation> = [
		CreateTable("todos", {
			columns: [
				Column("title", StringColumn({nullable: false})),
				Column("completed", BooleanColumn({})),
				Index(["completed"], {}),
				Column("price", DecimalColumn({precision: 10, scale: 2})),
				Reference("user", {nullable: false, foreignKey: true})
			],
			timestamps: true
		})
	];
}
```

This split is deliberate: users get a current typed model contract for
relations, params, templates, and IntelliSense, while migration history remains
an explicit snapshot that does not drift when the model later changes.

Options:

- `--skip-migration` writes only the typed model.
- `--validate field,presence` and `--validate field,uniqueness` emit typed
  `@:validates(...)` metadata against generated fields.
- `--known-models models.User` is passed to the migration generator for
  validation context when useful.
- `--haxe-dir`, `--migration-dir`, `--package`, and `--migration-package`
  customize source layout.
- `--pretend` prints generated Haxe without writing.
- `--force` follows the manifest/header-backed ownership rules.

## Migration Generator Contract

Migrations are history. Models are current API.

That means generator-produced Haxe migrations should be operation snapshots, not
live references to mutable model metadata. A model generator may infer the first
migration from attributes, but the migration source must contain explicit
operations so later edits to `models.Todo` do not rewrite old migration history.

Implemented command:

```bash
bin/rails generate hxruby:migration AddStatusToTodos status:string:index \
  --timestamp 20260616013000 \
  --known-models models.Todo \
  --migration-version 8.1
```

The same implementation is available outside Rails for smoke tests and bootstrap
scripts:

```bash
ruby -I lib scripts/rails/migration.rb AddStatusToTodos status:string:index \
  --timestamp 20260616013000 \
  --known-models models.Todo \
  --output .
```

Supported first-line attribute shapes mirror common Rails generator input:

- `title:string` emits `StringColumn({})`.
- `title:string!` emits `StringColumn({nullable: false})`.
- `completed:boolean:index` emits a boolean column plus an index.
- `email:string:uniq` emits a unique index.
- `price:decimal{10,2}` emits decimal precision/scale.
- `user:references` and `user:belongs_to` emit typed reference operations.
- `supplier:references{polymorphic}` emits a polymorphic reference option.

The generator supports `CreateTodos`, `AddStatusToTodos`,
`RemoveStatusFromTodos`, and `AddUserRefToTodos` naming patterns. Alter-table
migrations use `knownModels: [...]` when supplied; otherwise the inferred target
table is recorded in `externalTables: [...]`, making the Rails-owned table
boundary explicit for gradual adoption. `--from-schema db/schema.rb` validates
the target table plus add/remove column presence against the current conventional
schema snapshot before generating the Haxe operation snapshot; it does not
translate historical migrations or change public migration DSL semantics.

`knownModels` validates against the current typed model contract, but migrations
are historical snapshots. An `AddColumn("todos", "status", ...)` migration remains
valid after `models.Todo` grows a `status` field because the current model is used
to prove the table and follow-up references are real, not to rewrite migration
history. RailsHx still rejects duplicate additions inside the same migration
snapshot, so a generator cannot emit the same column twice by accident.

Example Haxe source:

```haxe
package migrations;

import rails.migration.Migration;
import rails.migration.MigrationOperation;
import rails.migration.MigrationOperation.*;

@:railsMigration({
	timestamp: "20260616013000",
	className: "AddStatusToTodos",
	knownModels: ["models.Todo"]
})
class AddStatusToTodos extends Migration {
	static final operations:Array<MigrationOperation> = [
		AddColumn("todos", "status", StringColumn({}))
	];
}
```

Generated Ruby should be ordinary Rails:

```ruby
# Generated by RailsHx from src_haxe/migrations/AddStatusToTodos.hx.
# Do not edit this file directly.
class AddStatusToTodos < ActiveRecord::Migration[8.1]
  def change
    add_column :todos, :status, :string
  end
end
```

Keep the older `models: [...]` migration path for compatibility and quick
scaffolds where it is already supported, but prefer snapshot operations for
production generators.

## Safety And Manifest

RailsHx generators and the compiler should fail closed:

- Do not overwrite non-owned Rails files without `--force`.
- Do not overwrite existing Ruby migrations unless a RailsHx manifest and header
  prove ownership.
- Reject unsafe app-relative paths: absolute paths, `..`, backslashes, symlink
  escapes, empty segments, or files outside the app root.
- When reading schema, RBS, Ruby source, routes, templates, or directories,
  error if the input is missing unless the API is explicitly named unchecked or
  external.
- Raw SQL, destructive migrations, data migrations, `DropTable`, `RemoveColumn`,
  and irreversible changes need explicit rollback or an auditable unsafe escape
  name.

The manifest should record source/output pairs, generated kind, and checksum so
`hxruby:clean`, collision checks, and drift diagnostics are deterministic. See
[RailsHx Generated Artifact Ownership](railshx-generated-artifact-ownership.md)
for the concrete manifest and overwrite policy.

## Rails Tasks

Keep RailsHx tasks as composition and validation helpers:

- `hxruby:compile`: compile server Haxe into Rails artifacts.
- `hxruby:compile:client`: compile Haxe-authored JS into Rails asset/importmap
  friendly output.
- `hxruby:start`: compile server/client Haxe and start Rails.
- `hxruby:dev`: compile server/client once, then run Rails and one coordinated,
  change-aware watcher. `hxruby:start:watch` remains an alias.
- `hxruby:watch`, `hxruby:watch:client`, and `hxruby:watch:all`: standalone
  server, client, and coordinated developer loops. They compile once, stay idle
  while checked HXML inputs are unchanged, and debounce edit bursts.
- `hxruby:db:migrate`, `hxruby:db:prepare`, and `hxruby:db:rollback`: compile
  RailsHx server/migration artifacts, then delegate to the corresponding Rails
  database task. Rails still performs the database operation.
- `hxruby:test`: compile RailsHx server/client artifacts, then delegate to
  `rails test`.
- `hxruby:rails TASK=... ARGS='...'`: generic compile-then-delegate escape for
  Rails tasks not covered by a named helper. Set `CLIENT=1` when the task also
  needs freshly compiled Haxe-authored JavaScript.
- `hxruby:routes`: route extern regeneration and route parity. Use
  `MODE=rails-owned` for adoption apps where `config/routes.rb` is the source of
  truth, `MODE=haxe-owned` to compile Haxe-owned `@:railsRoutes` first and then
  compare Rails output with `.railshx/routes.haxe.json`, or `MODE=auto` to use
  the Haxe-owned lane when `src_haxe/routes/AppRoutes.hx` or an existing route
  manifest is present.
- `hxruby:doctor`: environment, manifest, output-root, route freshness, and
  collision diagnostics. It is intentionally non-mutating: it checks Haxe,
  build files, JSON manifests, Rails command availability, and configured
  generated Ruby roots without compiling. It also reports manifest-owned output
  drift/missing files, Haxe-owned route manifest/extern freshness, duplicate
  Rails migration timestamps/classes, and common Haxe-authored client JS/importmap
  setup gaps.
- `hxruby:check`: compile, syntax-check generated Ruby, and optionally run
  Rails-owned checks such as `zeitwerk:check`. Set `CLIENT=1` to compile the
  Haxe-authored JavaScript lane, `ROUTES=1` to run route extern/parity sync, and
  `ZEITWERK=1` to delegate to Rails' `zeitwerk:check` after generated Ruby
  passes `ruby -c`.
- `hxruby:clean`: remove only manifest-owned generated artifacts.
- `hxruby:production`: compile RailsHx outputs, then delegate to Rails-owned
  production checks and asset compilation.
- `hxruby:gen:template`: generate a typed Rails HHX source skeleton for a view
  or partial. It creates Haxe only; ERB remains compiler output.
- `hxruby:gen:test`: generate a Haxe-authored Rails test source using
  `@:railsTests static function define():Void`. Minitest is the default output
  adapter; RSpec is explicit through adapter metadata/generator config. Rails
  still runs the generated Ruby test through `hxruby:test` / `bin/rails test`
  or RSpec when selected. Generated RailsHx app, scaffold, mailer, and focused
  test templates should default to Haxe-authored tests unless an explicit
  option such as `--skip-tests` or a target-language flag says otherwise; raw
  Ruby/Rails tests remain supported beside them.

Avoid task names that imply RailsHx owns Rails runtime behavior, especially
database migration execution. The pattern is always: compile generated artifacts
first, then run ordinary Rails.

## Adoption Direction

Schema adoption should read the current Rails schema and generate typed Haxe
contracts. It should not try to translate all historical migrations by default.
Rails itself treats `db/schema.rb` or `db/structure.sql` as the current database
shape snapshot, and historical migrations can depend on changed app code.

The adoption generator should support:

```bash
bin/rails generate hxruby:adopt --schema --discover
bin/rails generate hxruby:adopt --schema --models Todo,User
bin/rails generate hxruby:adopt --migrations --discover
bin/rails generate hxruby:adopt --template legacy/badge --locals label:String,tone:String
bin/rails generate hxruby:adopt --service LegacyPriceFormatter --rbs sig/legacy_price_formatter.rbs
```

Explicit RBS service adoption is strict and fail-closed. It canonicalizes the
signature file inside the app root and emits only fully supported positional
scalar, nilable, `Symbol`, and `Array<T>` signatures. Unsupported/open types,
overloads, and complex method shapes remain review-marked omissions rather than
`Dynamic` extern methods.

Unknown DB types, ambiguous associations, unsupported `structure.sql` input,
unsafe schema identifiers, Haxe field-name collisions, and missing metadata
should fail or produce review-marked contracts only with an explicit opt-in such
as `--allow-dynamic`.

Migration-history discovery is deliberately report-only. It should classify
Rails-owned and RailsHx-owned files, flag duplicate timestamps/classes, and
point users back to current-schema adoption rather than translating old
migrations. New `hxruby:migration --timestamp ...` runs must refuse timestamps
and classes already present under `db/migrate`.

Broad schema-history inference, historical migration translation, and public
migration DSL semantic expansion are blocked behind `haxe_ruby-zsf`, which
requires a GPT 5.5 Pro review/planning pass before design or implementation.

## PhoenixHx Comparison

Use `../haxe.elixir.codex` as architectural inspiration, not as an API template:

- PhoenixHx Mix generators map to Rails generator adapters.
- Ecto migrations map to ActiveRecord migration operation snapshots.
- Ecto schemas map to ActiveRecord model metadata and schema adoption.
- Phoenix router tooling maps to Rails-owned `config/routes.rb` plus generated
  route externs.
- Mix compile aliases map to `hxruby:compile` and `hxruby:check`, not to
  replacements for Rails runtime tasks.

The shared lesson is compile-time typed Haxe authoring that emits normal
framework-native artifacts.

## Route Generator Modes

Generator-created greenfield RailsHx apps should prefer Haxe-owned routes:

```haxe
@:railsRoutes
class AppRoutes {
	static final routes = {
		root(to(HomeController, index));
	};
}
```

That source emits normal `config/routes.rb`. The next `hxruby:routes
MODE=haxe-owned` pass runs Rails, reads the authoritative route table, and
regenerates typed `Routes.hx` externs. Rails-owned apps skip the Haxe route
compile and run `MODE=rails-owned` against the existing `config/routes.rb`
instead.

Do not silently merge generated Haxe routes into a hand-written Rails route
file. Use explicit source-of-truth modes, generated headers, manifest entries,
or future marker blocks. The focused compiler fixture is
`examples/rails_routes_dsl`; the full app fixture is `examples/todoapp_rails`.

Scaffold follows the same mode names:

```bash
bin/rails generate hxruby:controller Todos index show --templates
```

The controller generator writes a typed `@:railsController` source file and,
with `--templates`, matching typed HHX view skeletons. Those view classes use
`@:railsTemplateAst("render")`; ERB remains compiler output, not the generator's
authoring format. Standalone controller generation defaults to not mutating
routes, while scaffold can still opt into Haxe-owned, Rails-owned, snippet, or
none route modes.

## Mailer Generator Contract

```bash
bin/rails generate hxruby:mailer UserMailer welcome
```

The mailer generator writes only Haxe-owned source:

- `src_haxe/mailers/UserMailer.hx` with `@:railsMailer` and
  `@:railsMailerParams(WelcomeMailerParams)`.
- Typed HHX html/text mail templates under `src_haxe/views/user_mailer/**`.
- A Haxe-authored `@:railsMailerPreview` under `src_haxe/previews/**` unless
  `--skip-preview` is passed.
- A Haxe-authored `@:railsTest` under `test_haxe/mailers/**` unless
  `--skip-test` is passed.

After `bundle exec rake hxruby:compile`, Rails receives normal
`ActionMailer::Base`, `ActionMailer::Preview`, ERB template, and Minitest
artifacts. The generator does not replace Rails preview servers or test
runners; it gives app authors a typed Haxe source path for the same Rails
workflow.

```bash
bin/rails generate hxruby:scaffold Todo title:String --controller --routes=haxe
bin/rails generate hxruby:scaffold Todo title:String --controller --routes=snippet
bin/rails generate hxruby:scaffold Todo title:String --controller --routes=rails
bin/rails generate hxruby:scaffold Todo title:String --controller --routes=none
bin/rails generate hxruby:scaffold Todo title:String --controller --skip-tests
```

The scaffold default is `haxe` for greenfield code and emits a typed
`resources(Model, Controller, ...)` declaration. Use `rails` when adopting an
existing Rails-owned `config/routes.rb`; use `snippet` when you want a
reviewable patch instead of generated route ownership.

Scaffolded projects generate Haxe-authored tests by default under
`test_haxe/**`. This mirrors the RailsHx testing strategy: app authors keep
typed test source in Haxe, while the compiler emits ordinary Rails/Minitest
files under `test/generated/**` for Rails to run. `--skip-tests` is an explicit
adoption option for apps that already have a different test source of truth,
and target-native Ruby/Rails tests can still live beside the Haxe source.

With `--controller`, scaffold composes the controller generator's typed HHX
view path: the index action renders `Template.of(IndexView)` with typed locals,
and Rails receives normal `app/views/**/*.html.erb` output from the compiler.
