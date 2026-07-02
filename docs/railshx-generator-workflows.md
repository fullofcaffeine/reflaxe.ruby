# RailsHx Generator Workflows

This guide is the app-facing companion to
[RailsHx Generators And Rails Tasks Design](railshx-generators-and-tasks-design.md).
The design doc explains ownership and architecture; this page shows what to run,
what Haxe source is created, what Rails artifacts are generated, and which Rails
task consumes those artifacts.

RailsHx is a typed Rails authoring layer. Rails remains the runtime owner for
database migrations, tests, Zeitwerk, assets, and boot. RailsHx owns typed Haxe
source, HHX templates, generated route contracts, generated Ruby/ERB/JS
artifacts, and the checks that keep those artifacts fresh.

## Daily App Loop

Start from a Rails app:

```bash
bin/rails generate hxruby:install MyApp
bundle exec rake hxruby:start
```

For active development:

```bash
bundle exec rake hxruby:start:watch
```

That compiles server Haxe/HHX, compiles Haxe-authored client JS, starts Rails,
and keeps generated target artifacts current. Raw Rails commands still work
after artifacts are current, but the RailsHx wrappers are safer because they
compile first and then delegate:

```bash
bundle exec rake hxruby:db:migrate   # compile migrations, then rails db:migrate
bundle exec rake hxruby:test         # compile server/client artifacts, then rails test
bundle exec rake hxruby:rails TASK=zeitwerk:check
```

For production:

```bash
RAILS_ENV=production bundle exec rake hxruby:production
```

This compiles RailsHx outputs and then runs Rails-owned production checks such
as `zeitwerk:check` and `assets:precompile`.

## Generator Summary

| Command | Haxe source of truth | Rails artifact after compile | Rails consumer |
| --- | --- | --- | --- |
| `hxruby:install` | `src_haxe/**`, `client_haxe/**`, route skeleton | `app/haxe_gen/**`, generated views, JS/importmap wiring | Rails boot/server |
| `hxruby:routes` | Rails-owned `config/routes.rb` or Haxe-owned `@:railsRoutes` | `src_haxe/routes/Routes.hx` externs | Haxe compile |
| `hxruby:model` | `src_haxe/models/*.hx` plus migration snapshot | model Ruby and `db/migrate/*.rb` | ActiveRecord, `db:migrate` |
| `hxruby:migration` | `src_haxe/migrations/*.hx` operation snapshot | timestamped ActiveRecord migration | `db:migrate` |
| `hxruby:controller` | `src_haxe/controllers/*.hx`, optional HHX views | Rails controller Ruby and `.html.erb` views | Rails request/render |
| `hxruby:scaffold` | model, migration, controller, HHX, tests, routes | ordinary Rails app slice | Rails app/test/runtime |
| `hxruby:adopt` | typed contracts for existing Ruby/Rails assets | Haxe externs/wrappers; no owned Rails rewrite | Haxe compile |

All generators follow manifest/header-backed ownership. They refuse to overwrite
Rails-owned files unless the file is already RailsHx-owned or the command uses
an explicit documented force/repair path.

## Install

```bash
bin/rails generate hxruby:install MyApp
```

Creates:

```text
src_haxe/controllers/HomeController.hx
src_haxe/views/layouts/ApplicationLayoutView.hx
src_haxe/views/home/IndexView.hx
src_haxe/routes/AppRoutes.hx
src_haxe/routes/Routes.hx
client_haxe/Application.hx
build.hxml
client.hxml
Rakefile hxruby tasks
bin/railshx-dev
bin/railshx-prod
```

The starter source uses typed controllers, typed HHX layout/view classes, a
Haxe-owned root route by default, and Haxe-authored client JS. Compile with:

```bash
bundle exec rake hxruby:compile
bundle exec rake hxruby:compile:client
```

Failure example: if required Haxe build files are missing, `hxruby:doctor` and
`hxruby:production` fail instead of silently shipping stale generated Ruby.

## Routes

Rails-owned adoption mode:

```bash
bin/rails generate hxruby:routes
bundle exec rake hxruby:routes MODE=rails-owned
```

Haxe-owned greenfield mode:

```haxe
package routes;

import controllers.TodosController;
import rails.macros.RoutesDsl.*;

@:railsRoutes
class AppRoutes {
	static final routes = {
		root(to(TodosController, index));
		resources(models.Todo, TodosController);
	};
}
```

Compile/sync:

```bash
bundle exec rake hxruby:routes MODE=haxe-owned
```

RailsHx emits normal `config/routes.rb`, boots Rails, reads `rails routes`, and
generates typed `Routes.hx` externs from the actual Rails route table. Rails is
always the helper-name oracle.

Failure example: a typed route target such as `to(TodosController, missing)`
fails at Haxe compile time because the controller action does not exist.

## Model

```bash
bin/rails generate hxruby:model Todo title:string! completed:boolean user:references!
```

Creates typed current model source:

```haxe
package models;

@:railsModel("todos")
@:railsTimestamps
class Todo extends rails.active_record.Base<Todo> {
	@:railsColumn({nullable: false})
	public var title:String;

	public var completed:Null<Bool>;

	@:railsColumn({nullable: false})
	public var userId:Int;

	@:belongsTo({foreignKey: "userId", optional: false})
	public var user:rails.ActiveRecord.BelongsTo<User>;
}
```

Also creates a migration snapshot source. After compile, Rails receives ordinary
ActiveRecord model/migration artifacts. Consume them with:

```bash
bundle exec rake hxruby:db:migrate
bundle exec rake hxruby:test
```

Failure example: rerunning over a non-owned model file fails unless ownership is
explicit, preventing a generator from rewriting a hand-written app model.

## Migration

```bash
bin/rails generate hxruby:migration AddStatusToTodos status:string:index \
  --known-models models.Todo
```

Creates an immutable Haxe operation snapshot:

```haxe
package migrations;

import rails.migration.Migration;
import rails.migration.MigrationOperation;
import rails.migration.MigrationOperation.*;

@:railsMigration({
	className: "AddStatusToTodos",
	knownModels: ["models.Todo"]
})
class AddStatusToTodos extends Migration {
	static final operations:Array<MigrationOperation> = [
		AddColumn("todos", "status", StringColumn({})),
		AddIndex("todos", ["status"], {})
	];
}
```

The Ruby compiler emits a normal timestamped Rails migration under
`db/migrate/**`. Rails executes it:

```bash
bundle exec rake hxruby:db:migrate
```

Failure example: `--timestamp` fails if any existing migration already uses that
timestamp, and duplicate migration class names are rejected before Rails runs.

## Controller And HHX

```bash
bin/rails generate hxruby:controller Todos index show --templates
```

Creates a typed controller:

```haxe
package controllers;

@:railsController
class TodosController extends ApplicationController {
	public function index():Void {
		render(Template.of(views.todos.IndexView));
	}
}
```

With `--templates`, it also creates typed HHX view classes:

```haxe
@:railsTemplate("controllers/todos/index")
@:railsTemplateAst("render")
class IndexView {
	public static function render(locals:IndexLocals):HtmlNode {
		return <main><h1>Todos</h1></main>;
	}
}
```

RailsHx-authored views are HHX source. ERB is compiler output. Rails consumes
the generated controller and `.html.erb` files through normal request/render
paths.

Failure example: missing template refs or wrong typed locals fail at Haxe compile
time instead of becoming late ActionView errors.

For focused template work without generating a controller, use:

```bash
bin/rails generate hxruby:template controllers/todos/_card \
  --locals title:String,count:Int
```

This writes `src_haxe/views/controllers/todos/CardView.hx`, not ERB. The
generated source uses `@:railsTemplate("controllers/todos/_card")` and
`@:railsTemplateAst("render")`, so app authors keep editing typed HHX while the
compiler emits the Rails-native `app/views/controllers/todos/_card.html.erb`
artifact. Use this when Haxe owns the template. For existing Rails-owned ERB,
prefer adoption contracts such as `Template.existing("controllers/todos/card")`
instead of rewriting the file blindly.

Failure example: paths such as `../admin` or `controllers/todos/show.html.erb`
are rejected because generator-owned Haxe sources must map to checked Rails
template paths, not arbitrary filesystem writes.

## Haxe-Authored Rails Tests

```bash
bin/rails generate hxruby:test models/todo
bin/rails generate hxruby:test controllers/todos_request --type request
bin/rails generate hxruby:test models/todo --adapter=rspec
```

These commands create `test_haxe/**/*.hx` sources using the canonical
compiler-erased test DSL:

```haxe
@:railsTest("models/todo_haxe_test")
class TodoHaxeTest extends ModelTestCase {
	@:railsTests
	static function define():Void {
		test("generated model test works", () -> {
			truthy(true);
		});
	}
}
```

Minitest is the default adapter and emits `test/generated/**/*_test.rb`.
`--adapter=rspec` emits `@:railsTestAdapter("rails.rspec")` and compiles to
`spec/generated/**/*_spec.rb`. `--adapter=auto` chooses RSpec when the app has
`spec/rails_helper.rb`, `spec/spec_helper.rb`, or `rspec-rails` in
`Gemfile`/`Gemfile.lock`; otherwise it stays on Minitest.

Rails still runs the generated Ruby test:

```bash
bundle exec rake hxruby:test
bundle exec rake hxruby:test HXRUBY_TEST_ADAPTER=rspec
```

Generated RailsHx app and scaffold tests should use this Haxe-authored path by
default. Use it when the test benefits from typed model fields, route helpers,
request params, DeviseHx scopes, template refs, shared hooks, or other RailsHx
contracts. Keep vanilla Rails/Minitest tests first-class for Rails-owned
behavior, third-party gem runtime behavior, or cases where a plain Ruby test is
clearer; the choice is per test, not per app.

## Scaffold

```bash
bin/rails generate hxruby:scaffold Todo title:string! completed:boolean \
  --controller --routes=haxe
```

Composes model, migration snapshot, controller, HHX views, route declarations,
and a Haxe-authored Rails test. The generated test compiles into ordinary
Minitest output under `test/generated/**` by default. Pass
`--test-adapter=rspec` or `TEST_ADAPTER=rspec` when generating to target
RSpec output under `spec/generated/**`.

Run:

```bash
bundle exec rake hxruby:db:migrate
bundle exec rake hxruby:test
```

Route modes:

- `--routes=haxe`: generate typed `@:railsRoutes` as source of truth.
- `--routes=rails`: keep Rails-owned routes and regenerate externs.
- `--routes=snippet`: write reviewable instructions, no mutation.
- `--routes=none`: leave route files untouched.

Failure example: `--routes=patch`-style silent mutation is intentionally not the
default; unowned `config/routes.rb` files are not overwritten.

## Adopt Existing Rails Code

Schema discovery:

```bash
bin/rails generate hxruby:adopt --schema --discover
bin/rails generate hxruby:adopt --schema --models Todo,User
```

Creates typed Haxe model contracts from `db/schema.rb` without translating old
migrations or rewriting Rails-owned models.

Migration-history report:

```bash
bin/rails generate hxruby:adopt --migrations --discover
```

Reports migration timestamps/classes, RailsHx ownership, duplicate collisions,
and why current-schema adoption is preferred for typed model contracts.

Ruby/ERB seams:

```bash
bin/rails generate hxruby:adopt \
  --service LegacyPriceFormatter \
  --template legacy/badge \
  --locals label:String,tone:String
```

Generates checked Haxe wrappers around existing Ruby services and Rails-owned
ERB partials so Haxe code can consume them safely during gradual migration.

Failure examples: missing `db/schema.rb`, unsafe paths, unknown DB types without
`--allow-dynamic`, and non-owned output collisions fail closed.

## Health, Clean, And CI

Use non-mutating diagnostics while developing:

```bash
bundle exec rake hxruby:doctor
```

Use generated-artifact checks in CI:

```bash
bundle exec rake hxruby:check CLIENT=1 ROUTES=1 ZEITWERK=1
```

Clean only RailsHx-owned generated files:

```bash
bundle exec rake hxruby:clean
```

Repository gates that keep these docs honest include:

```bash
npm run test:rails-generators
npm run test:model-generator
npm run test:migration-generator
npm run test:controller-generator
npm run test:scaffold-cli
npm run test:rails-adopt-generator
npm run test:todoapp-rails
npm run test:todoapp-playwright
```

The focused examples are:

- `examples/todoapp_rails`: canonical RailsHx dogfood app.
- `examples/rails_interop_app`: mixed Ruby/ERB adoption.
- `examples/rails_routes_dsl`: Haxe-owned route DSL snapshot fixture.
