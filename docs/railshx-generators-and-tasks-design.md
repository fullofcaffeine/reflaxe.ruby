# RailsHx Generators And Rails Tasks Design

RailsHx is a typed Rails authoring layer, not a Rails replacement. Rails remains
the runtime owner; RailsHx owns Haxe source, typed contracts, compiler
validation, and generated Rails-shaped artifacts.

## Public Workflow

Greenfield RailsHx code should feel like normal Rails with a typed authoring
step:

```bash
bin/rails generate hxruby:model Todo title:string completed:boolean
bundle exec rake hxruby:compile
bin/rails db:migrate
bin/rails test
```

Existing Rails apps should adopt incrementally:

```bash
bin/rails generate hxruby:install
bin/rails generate hxruby:adopt --schema --discover
bin/rails generate hxruby:adopt --schema --models Todo,User
bin/rails generate hxruby:routes
bundle exec rake hxruby:compile
bin/rails test
```

Production and CI should compose RailsHx compilation before Rails-owned checks:

```bash
bundle exec rake hxruby:compile
bundle exec rake hxruby:compile:client
bin/rails db:migrate
bin/rails test
bin/rails zeitwerk:check
RAILS_ENV=production bundle exec rake hxruby:production
```

Do not add a canonical `hxruby:migrate` task. That name suggests RailsHx owns
database execution. Rails owns migration execution; RailsHx emits normal
timestamped ActiveRecord migration files that Rails runs.

## Ownership Model

Rails-owned surfaces:

- `bin/rails db:migrate`, `db:rollback`, `db:migrate:status`, and schema dumps.
- `bin/rails test`, Minitest/RSpec runtime, and Rails fixture/runtime behavior.
- `zeitwerk:check`, `assets:precompile`, Rails boot, and Rails autoloading.
- `config/routes.rb` by default; RailsHx may patch only through safe explicit
  marker blocks or print snippets.
- Existing `app/models/**/*.rb`, `app/controllers/**/*.rb`,
  `app/views/**/*.erb`, and `db/migrate/**/*.rb` files unless a RailsHx manifest
  proves ownership.

RailsHx-owned surfaces:

- Haxe source under `src_haxe/**`, `test_haxe/**`, and generator-owned Haxe
  paths.
- Compiler output such as `app/haxe_gen/**/*.rb`, generated HHX `.html.erb`
  files, generated test files, generated client JS, and generated migrations.
- Generated route externs derived from Rails routes.
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
bin/rails generate hxruby:controller Todos index show
bin/rails generate hxruby:scaffold Todo title:string completed:boolean
```

Do not override `bin/rails generate model`, `migration`, or `scaffold` by
default. A future explicit install profile may configure Rails generator
fallbacks, but gradual adoption depends on vanilla Rails generators remaining
valid.

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
boundary explicit for gradual adoption. `--from-schema db/schema.rb` is accepted
as a fail-closed checked input boundary and reserved for richer schema-backed
validation.

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
- `hxruby:watch` and `hxruby:watch:client`: developer loops.
- `hxruby:routes`: route extern regeneration alias.
- `hxruby:doctor`: environment, manifest, output-root, route freshness, and
  collision diagnostics.
- `hxruby:check`: compile, syntax-check generated Ruby, and optionally run
  Rails-owned checks such as `zeitwerk:check`.
- `hxruby:clean`: remove only manifest-owned generated artifacts.
- `hxruby:production`: compile RailsHx outputs, then delegate to Rails-owned
  production checks and asset compilation.

Avoid task names that imply RailsHx owns Rails runtime behavior, especially
database migration execution.

## Adoption Direction

Schema adoption should read the current Rails schema and generate typed Haxe
contracts. It should not try to translate all historical migrations by default.
Rails itself treats `db/schema.rb` or `db/structure.sql` as the current database
shape snapshot, and historical migrations can depend on changed app code.

The adoption generator should support:

```bash
bin/rails generate hxruby:adopt --schema --discover
bin/rails generate hxruby:adopt --schema --models Todo,User
bin/rails generate hxruby:adopt --template legacy/badge --locals label:String,tone:String
bin/rails generate hxruby:adopt --service LegacyPriceFormatter --rbs sig/legacy_price_formatter.rbs
```

Unknown DB types, ambiguous associations, unsupported `structure.sql` input, and
missing metadata should fail or produce review-marked contracts only with an
explicit opt-in such as `--allow-dynamic`.

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
