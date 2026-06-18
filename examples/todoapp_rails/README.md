# RailsHx Todo App

This is the end-to-end RailsHx sample for `reflaxe.ruby`. It shows typed Haxe authoring for Rails code while keeping the generated Ruby recognizable to a Rails app.

## Quick Start

From the repository root:

```bash
eval "$(rbenv init - zsh)" # if your shell has not initialized rbenv yet
rake todoapp:start
```

Open [http://127.0.0.1:3000/](http://127.0.0.1:3000/). The generated Rails app is materialized under `test/.generated/rails_integration`; treat it as disposable output. The source of truth is the Haxe/HHX code in `examples/todoapp_rails/**` plus compiler/std code in `src/**` and `std/**`.

For the RailsHx edit loop, start the app with the integrated watcher:

```bash
rake todoapp:start:watch
# or:
WATCH=1 rake todoapp:start
# or:
rake 'todoapp:start[watch]'
```

That prepares the app once, then runs Rails and the watcher together. The watcher recompiles Haxe/HHX and refreshes generated Rails files when sources change. Rails serves those files through normal ActionController/ActionView, so a browser refresh is enough for most template/controller changes.

## What The Sample Proves

- Haxe-authored ActiveRecord models with `@:railsModel`, typed `@:railsColumn(...)` metadata, associations, validations, and timestamps.
- Generated Rails model Ruby with `self.__hx_rails_schema` metadata for later query/migration tooling.
- Haxe-authored ActionController logic with inferred typed `Relation<Todo, criteria>` query chaining, `ParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.title, ...])` strong-params generation, and `ViewMacro.renderTemplate(...)` typed locals for Rails rendering.
- Haxe-owned ActionView artifact generation through `@:railsTemplate(...)`, which materializes the Rails-native ERB file under `app/views`.
- Haxe-authored typed ActionView partials through `@:railsTemplateAst(...)`, Rails HHX inline markup, `H`, `HtmlNode`, and `HtmlAttr`; the compiler type-checks embedded expressions such as `todo.title`, typed conditionals/loops, typed partial locals, route helper calls, and typed form locals before emitting ERB.
- HHX-first ActionView authoring: the index page and all extracted view pieces are authored as typed HHX, while Rails-native ERB is compiler output.
- Haxe-authored JavaScript compiled through the Genes ES-module lane into the Rails importmap/Turbo/ActionCable flow, so progressive behavior can stay in typed Haxe while Rails serves standard `app/javascript/**` assets. The client uses typed `@:async` methods plus `await(Async.delay(...))`; Genes emits native ES `async`/`await`, not a RailsHx runtime. The chatroom slice uses ActionCable for realtime transport and Turbo Stream rendering for DOM mutation, so it stays pleasant to Rails developers while Haxe owns safer selectors, payloads, and client behavior.
- Haxe-authored Rails migrations through `@:railsMigration(...)`; the compiler emits standard timestamped `db/migrate/*.rb` ActiveRecord migration files from typed snapshot operations.
- Haxe-owned Rails routing through `src_haxe/routes/AppRoutes.hx`; the compiler emits standard `config/routes.rb`, and generated route helper externs under `src_haxe/routes/Routes.hx` still come from Rails route output. The sample includes typed `todos`, `chat_messages`, `users`, and session routes, plus one Rails-owned `legacy_health` route to prove existing Rails routes can remain Rails-owned while Haxe consumes them through typed helpers.
- CI smoke coverage that compiles the Haxe app, checks generated Rails Ruby, and runs Rails runtime tests when local Rails gems are available.

## Source Layout

- `models/Todo.hx` and `models/User.hx` are RailsHx ActiveRecord models.
- `models/ChatMessage.hx` is the typed chatroom model: it owns the `chat_messages` table contract, `belongsTo` user association, validation metadata, and newest-first relation scope used by the controller and HHX.
- `migrations/CreateTodos.hx` is the Haxe-authored Rails migration snapshot source; generated Ruby lands at `db/migrate/20260101000000_create_todos.rb`.
- `migrations/UpdateUsers.hx` adds typed user profile/session columns as an immutable migration snapshot, while `models/User.hx` owns the current field/validation/helper contract.
- `migrations/CreateChatMessages.hx` adds the chatroom table as a migration snapshot. The generated Rails migration is ordinary ActiveRecord, while Haxe keeps the table, reference, index, and timestamp operations reviewable.
- `controllers/TodosController.hx` is a RailsHx controller using typed params, typed session-user lookup, typed relation queries, and route helpers.
- `controllers/SessionsController.hx` demonstrates first-party Rails session/flash access from Haxe. It is intentionally not Devise; installed-gem auth belongs to the separate gem-layer adoption path.
- `channels/ChatMessagesChannel.hx` is the typed ActionCable channel: a shared `ChatBroadcast` payload typedef is consumed by the Haxe JS client, `ChatCable.roomStream()` carries the stream payload type, and generated Ruby is an ordinary `ActionCable::Channel::Base` subclass.
- `controllers/ChatMessagesController.hx` demonstrates the Hotwire mutation seam: typed strong params create a chat message, the controller broadcasts a typed ActionCable payload for other browser sessions, Turbo Stream requests replace a typed HHX panel for the submitting session, and HTML fallback redirects through normal Rails.
- `controllers/UsersController.hx` renders a second typed page for user management through checked HHX locals.
- `Todo.incomplete()` returns an inferred typed relation shape, and the controller keeps the query chain typed with `includes(Todo.a.user).order(Todo.f.title.asc()).limit(10).toArray()` before handing an array to HHX templates.
- `views/ApplicationLayoutView.hx` owns the Rails layout as typed HHX, including the doctype, Rails CSRF/CSP helper tags, stylesheet/importmap tags, and `<rails_yield />`; generated ERB lands at `app/views/layouts/application.html.erb`.
- `views/TodoIndexView.hx` declares the typed Rails template artifact and owns the full page shell as HHX; scalar locals project from Haxe names such as `todoCount` to Rails locals such as `todo_count`.
- `views/TodoComposerView.hx` owns the typed sample-user branch and composes the form through typed `<partial>` locals, then generates `app/views/controllers/todos/_composer.html.erb`.
- `views/TodoSummaryView.hx` declares a typed HHX partial with `<if>` empty-state branching and `<for ${todo in todos}>` loop syntax, then generates `app/views/controllers/todos/_summary.html.erb`.
- `views/TodoDashboardView.hx` composes the summary partial through typed `<partial>` locals, emits a typed `<link_to>` route helper with nested HHX block content, and generates `app/views/controllers/todos/_dashboard.html.erb`, which the index renders with normal Rails locals.
- `views/TodoListView.hx` is the index's typed open-work list island: HHX validates the `todos` local, `<if>` branch, `<for>` loop binder, and `todo.title`/`todo.notes` expressions before generating `app/views/controllers/todos/_list.html.erb`.
- `views/TodoFormView.hx` uses HHX inline markup (`<form_with>`, `<hidden_field>`, `<field_label>`, `<text_field>`, `<text_area>`, `<submit>`) plus model-owned refs such as `Todo.railsParamKey`, `Todo.f.title`, and `Todo.f.notes` for a typed Rails form partial. It generates `app/views/controllers/todos/_typed_form.html.erb`, which the index renders with `sample_user_id`.
- `views/UserSwitcherView.hx` is the typed session/user panel: `User.f.id` drives the hidden form field, route helper externs drive sign-in/sign-out URLs, and `shared/TodoHooks` marks the Turbo-enhanced forms.
- `views/ChatPanelView.hx` is the typed chatroom panel: `ChatMessage.f.body` and `ChatMessage.f.userId` drive form fields, `Routes.chatMessagesPath()` drives submission, and the message loop type-checks `message.user.name`/`message.user.initials()` through the typed association.
- `views/UserManagementView.hx` is a second HHX page showing typed user fields, role helpers, and route-helper links.
- `std/rails/turbo/Turbo.hx` provides a typed Haxe facade over Turbo lifecycle events, `Turbo.visit` actions/options, frame helpers, and client-side stream rendering, so client code uses Rails-native Turbo semantics without stringly-typed app logic. `std/rails/action_cable/**` provides the typed consumer/channel/stream/payload boundary. Repeated behavior hooks live in `shared/TodoHooks.hx` and are exported to Playwright, which is the same source-of-truth pattern RailsHx should use for richer Turbo abstractions.
- `src_haxe/routes/AppRoutes.hx` is the Haxe-owned Rails routing source: `@:railsRoutes` plus typed controller/action refs emits normal `config/routes.rb` for todos, chat messages, users, and session routes.
- `rails/config/routes_rails_owned.rb` is a commented Rails-owned route snippet. It models an existing hand-written Rails route that stays outside `AppRoutes.hx`; `Routes.hx` still exposes it as typed `Routes.legacyHealthPath()` after route-helper generation.
- `shared/TodoHooks.hx` centralizes behavior-bearing slots, IDs, selectors, data attributes, and storage keys as typed Haxe constants shared by HHX templates, Haxe JS, and Playwright.
- `tools/ExportTodoHooks.hx` materializes those Haxe-owned hooks into `e2e/todo_hooks.ts`, so browser tests import the same selector contract instead of copying string literals.
- `client/TodoClient.hx` compiles through Genes to `app/javascript/railshx/todo_client.js` plus importmap-friendly ES modules under `app/javascript/railshx/**`. It owns progressive enhancement: typed Turbo lifecycle hooks, smooth same-page navigation, scroll-position preservation after create, chat/session form binding, typed ActionCable subscription setup, Turbo Stream rendering for received room broadcasts, and transient typed-status flashes. The flash timers use `@:async` Haxe methods and `await(Async.delay(...))`, which emit native JavaScript `async`/`await` while keeping completion typed in Haxe. Todo, chat, and session mutations return typed Turbo Stream updates for Turbo requests while retaining normal Rails redirects for HTML fallback.
- `assets/stylesheets/application.css` is copied into Rails' asset path; HHX owns structure, CSS owns presentation.
- Generated `config/routes.rb` is materialized from `src_haxe/routes/AppRoutes.hx`.
- Generated `app/views/controllers/todos/index.html.erb` is materialized from that Haxe template marker.
- `src_haxe/routes/Routes.hx` is generated from Rails route output and remains the typed route-helper extern used by controllers/templates.
- `db/migrate/20260101000000_create_todos.rb` is generated Rails migration output from the snapshot operations in `migrations/CreateTodos.hx`.

For the smallest possible route DSL example, see
`../rails_routes_dsl`. The todoapp intentionally shows the messier app shape:
Haxe-owned routes for greenfield code, one Rails-owned route for adoption, and
typed route helpers consumed from controllers, HHX templates, and tests.

## Command Guide

```bash
rake todoapp:start
```

Compiles Haxe/HHX, materializes the Rails app, prepares the development database, seeds demo data, and starts Rails. This is the normal one-command local start path.

```bash
WATCH=1 rake todoapp:start
# or:
rake todoapp:start:watch
# or:
rake 'todoapp:start[watch]'
```

Runs the same preparation step, then starts both Rails and the RailsHx watcher. Press Ctrl-C to stop both processes.

```bash
rake todoapp:compile
```

Compiles the RailsHx sample and refreshes generated Rails files in `test/.generated/rails_integration` without touching bundle state or the SQLite DB.

```bash
rake todoapp:prepare
```

Compiles Haxe/HHX, materializes the Rails app, runs `bundle check || bundle install`, prepares the development database, and seeds demo data. Run this once before using the app, and rerun it after dependency or migration changes.

```bash
rake todoapp:server
```

Starts Rails through the generated app-local `bin/rails` entrypoint with `127.0.0.1:3000` defaults. Override with normal environment variables:

```bash
PORT=3001 BIND=0.0.0.0 rake todoapp:server
```

```bash
rake todoapp:watch
```

Runs a lightweight watcher for `src/**`, `std/**`, and `examples/todoapp_rails/**`. The recommended RailsHx dev workflow is Rails server in one terminal and this watcher in another; it refreshes generated Ruby/ERB plus the Haxe-authored JS client while Rails keeps serving the app.

```bash
rake todoapp:test
```

Compiles, materializes, prepares the test DB, and runs the generated Rails test suite.
The generated suite is intentionally Rails-shaped: model tests cover
validations, scopes, and associations; controller/request tests cover route
wiring, typed strong params, invalid submissions, redirects, ordered open-work
rendering, and ActionView consumption.
Those Ruby tests live as ordinary Rails files under `rails/test/**`; the
materializer copies them into the disposable generated Rails app instead of
embedding Ruby test bodies inside build scripts.

```bash
rake todoapp:production
```

Runs the deployability dogfood lane for this sample: compile Haxe/HHX, compile Haxe-authored JS, materialize the Rails app, prepare the test database, run Rails tests, boot production for `zeitwerk:check`, precompile production assets, build `test/.generated/rails_integration_release.tgz`, and assert the archive contains generated `app/haxe_gen/**`, generated ERB views, generated Haxe JS, migrations, and the RailsHx initializer.

```bash
rake todoapp:playwright
```

Runs the RailsHx browser sentinel: compile/materialize the generated app, prepare and seed the SQLite DB, boot Rails on a dedicated port, run Playwright specs from `examples/todoapp_rails/e2e/*.spec.ts`, and shut Rails down. Override the port or spec when debugging:

```bash
RAILSHX_PLAYWRIGHT_PORT=3101 RAILSHX_PLAYWRIGHT_SPEC=examples/todoapp_rails/e2e/todoapp.spec.ts rake todoapp:playwright
```

## Production Build Shape

For a real RailsHx app, Haxe/HHX compilation is a build step before the normal Rails production bundle is finalized:

```bash
bin/railshx-prod
# or:
RAILS_ENV=production bundle exec rake hxruby:production
```

The generated production runner delegates to `hxruby:production`, which compiles server Haxe/HHX, compiles Haxe-authored JavaScript, runs `zeitwerk:check`, and precompiles assets before a release artifact is finalized.

The production artifact must include generated `app/haxe_gen/**`, generated ActionView templates under `app/views/**`, generated Haxe JS under `app/javascript/railshx/**`, and `config/initializers/hxruby_autoload.rb`. The canonical source remains Haxe/HHX/Haxe JS; generated Rails files are build output.

This sample proves that contract with `rake todoapp:production`, which is also wired into CI through the underlying RailsHx production dogfood lane.

## App Generator

RailsHx app/adoption files can be generated into a Rails app with:

```bash
bin/rails generate hxruby:install MyApp
rake rails:app ARGS="--output path/to/rails-app --name MyApp"
```

That writes `.haxerc`, `build.hxml`, `build-client.hxml`, `haxe_libraries/genes.hxml`, `haxe_libraries/helder.set.hxml`, `src_haxe/**`, `app/javascript/**`, `app/assets/stylesheets/application.css`, `config/importmap.rb`, `lib/tasks/hxruby.rake`, `Procfile.railshx.dev`, `bin/railshx-dev`, `bin/railshx-prod`, and `docs/railshx/gem_layers.md`. In an installed app, the same generator is exposed as:

```bash
bundle exec rake hxruby:gen:app NAME=MyApp
```

The generated app is intentionally not an empty Haxe project. It starts with a
typed `HomeController`, typed HHX `ApplicationLayoutView`, typed HHX
`HomeIndexView`, Haxe-owned `AppRoutes`, `Routes.hx` route-helper extern
placeholder, Haxe-authored client boot file, starter CSS/importmap wiring, and
the app-local `hxruby:start` / `hxruby:start:watch` Rake tasks. That mirrors the
shape exercised by this todoapp on a smaller scale: Haxe/HHX is the greenfield
source of truth, Rails receives normal generated Ruby/ERB/routes/assets, and
Rails-owned routes/templates/services can still be adopted later through typed
wrappers. See the top-level [README](../../README.md#rails-workflow) and
[RailsHx Generators And Rails Tasks Design](../../docs/railshx-generators-and-tasks-design.md)
for the full starter workflow.

Route ownership is explicit in generated starters and scaffolds:

```bash
bin/rails generate hxruby:install MyApp --routes=haxe
bin/rails generate hxruby:scaffold Todo title:String --controller --routes=snippet
```

Use `haxe` for greenfield RailsHx routes, `rails` when an existing
`config/routes.rb` remains the source of truth, `snippet` when you want
reviewable instructions only, and `none` when route setup is handled elsewhere.

The generated `docs/railshx/gem_layers.md` is a user-facing template for
wrapping installed gems such as Devise. It documents the recommended
deterministic-first flow: install/configure the Ruby gem normally, inventory
what RailsHx can prove, generate conservative Haxe contracts, optionally ask an
LLM to improve the reviewed gaps, then trust only the code that passes Haxe
compile, Rails tests, and parity checks. See
[RailsHx Gem Layers](../../docs/railshx-gem-layers.md).

The Rails-facing generators are Ruby-native and package with the `hxruby` gem. For gradual adoption of existing Rails code, scaffold typed wrappers without touching Rails-owned ERB/Ruby:

```bash
bin/rails generate hxruby:adopt --service LegacyPriceFormatter --template legacy/badge --locals label:String,tone:String
bin/rails generate hxruby:adopt --service LegacyPriceFormatter --service-source app/services/legacy_price_formatter.rb
bin/rails generate hxruby:adopt --extension-source app/models/concerns/sluggable.rb --extension-module Sluggable
bin/rails generate hxruby:adopt --discover
rake rails:adopt ARGS="--service LegacyPriceFormatter --template legacy/badge --locals label:String,tone:String"
bundle exec rake hxruby:gen:adopt SERVICE=LegacyPriceFormatter SERVICE_SOURCE=app/services/legacy_price_formatter.rb TEMPLATE=legacy/badge LOCALS=label:String,tone:String
```

## Manual Compile

```bash
haxe -D ruby_output=test/.generated/todoapp_rails \
  -D reflaxe_runtime \
  -D reflaxe_ruby_rails \
  -cp src \
  -cp examples/todoapp_rails \
  -cp examples/todoapp_rails/src_haxe \
  -cp vendor/reflaxe/src \
  --macro reflaxe.ruby.CompilerBootstrap.Start() \
  --macro reflaxe.ruby.CompilerInit.Start() \
  -main Main
```

Generated app-owned Ruby lands under `app/haxe_gen/**`, generated migrations land under `db/migrate/**`, and Rails autoload setup lands in `config/initializers/hxruby_autoload.rb`.

The Haxe-authored client lane compiles through `examples/todoapp_rails/build-client.hxml`, which adds `-cp std` so `rails.turbo.Turbo`, `reflaxe.js.Async`, and typed event/action modules are available. The build uses Genes (`-lib genes`, `--macro genes.Generator.use()`, and `-D js-es=6`) so Rails receives readable ES module assets under `app/javascript/railshx/**` instead of one flattened JavaScript blob. Genes also reads `@:async` metadata and the exact `await(...)` helper lowering, so Haxe-authored async code becomes normal ES `async`/`await`.

## Test

```bash
rake test:todoapp:static
rake test:rails:integration
rake test:rails:runtime
rake todoapp:test
rake todoapp:playwright
```

`test:rails:integration` always syntax-checks generated Ruby. It runs `rails db:migrate` and `rails test` when the generated Rails app bundle is available. `test:rails:runtime` is the mandatory runtime lane: it sets `REQUIRE_RAILS=1`, installs generated app bundles when needed, and runs both the todoapp Rails integration tests and the mixed Rails/RailsHx interop runtime tests.

`test:todoapp-playwright` is the real-browser layer, modeled after the PhoenixHx sentinel approach but Rails-native: Playwright validates browser-rendered ActionView, importmap/Turbo/Haxe-client boot, same-page link enhancement, and Turbo-backed form flows against a running generated Rails app.

The todoapp is the canonical RailsHx dogfood app. When a RailsHx feature is
demonstrated here, add coverage at the Rails layer that would catch a real app
regression:

| Layer | Command | What it owns |
| --- | --- | --- |
| Compiler/static | `rake test:todoapp:static` | Haxe/HHX compiles, generated Ruby/ERB/JS shape, negative type-safety checks, strict-boundary policy. |
| Rails model/request | `rake todoapp:test` or `rake test:rails:integration` | ActiveRecord validations/scopes/associations, strong params, redirects, rendered templates, migrations, Rails test harness consumption. |
| Mandatory runtime | `rake test:rails:runtime` | Rails gems present, generated app can migrate and run Rails tests under the required runtime lane. |
| Browser UX | `rake todoapp:playwright` | Real browser rendering, Turbo/importmap/Haxe-client behavior, same-page navigation, Turbo form mutation flows, visible UX regressions. |
| Production | `rake todoapp:production` | Zeitwerk, production boot, asset precompile, release archive contents. |

## Current Boundary

RailsHx has a Haxe-authored migration lane: `@:railsMigration(...)` classes emit standard timestamped ActiveRecord migrations. The todoapp now uses the production-preferred snapshot style directly: `migrations/CreateTodos.hx` owns explicit `CreateTable`, `Column`, `Reference`, and `Index` operations; `migrations/UpdateTodos.hx` owns reversible changes, a composite index, and a rollback-aware `DataMigration`. This is the same style produced by `bin/rails generate hxruby:migration CreateTodos title:string! notes:text user:references`. The compatibility path can still derive create-table output from referenced `@:railsModel` and `@:railsColumn` metadata, but production generators should prefer explicit snapshot operations in `public static final operations:Array<MigrationOperation>` so old migrations do not drift when model metadata changes. Snapshot operations include `CreateTable`, `Column`, `Reference`, `Index`, `AddColumn`, `RemoveColumn`, `ChangeColumn`, `AddIndex`, `AddCompositeIndex`, `AddReference`, `RemoveReference`, `AddCheckConstraint`, `RemoveCheckConstraint`, `AddForeignKey`, `RemoveForeignKey`, `RenameColumn`, `RenameTable`, `ChangeNull`, `DropTable`, `ExecuteSql`, `DataMigration`, and `Reversible`; the compiler lowers them into normal Rails `change` statements. `knownModels: ["models.Todo"]` validates table/column/index/foreign-key references against typed model metadata without re-emitting `create_table`; `externalTables: ["legacy_events"]` is the explicit escape for Rails-owned tables whose schema is not Haxe-owned. The compiler rejects duplicate migration timestamps, bad known table/column references, non-owned generated migration collisions, and known foreign-key tables that are created by later migrations. `version: "8.1"` can pin the generated `ActiveRecord::Migration[...]` superclass for a Rails app. `test:rails-integration` syntax-checks generated migrations and runs `rails db:migrate`/`rails test` when the generated app bundle is available; `test:rails-runtime` makes that runtime lane mandatory.

RailsHx has the first typed ActionView seams: controllers render through `ViewMacro.renderTemplate(this, (Template.of(TodoIndexView) : Template<TLocals>), locals)`, which type-checks locals in Haxe and lowers to a normal Rails `render(template:, locals:)` call. Layouts use `Template.layout(ApplicationLayoutView)`, and owned partials/components use `Template.of(ViewClass)` or `RailsComponent.of(ViewClass, slot)` so missing or renamed HHX view classes fail during Haxe compilation instead of becoming stale Rails strings. `@:railsTemplate(...)` classes materialize Rails-native ERB artifacts into generated output from Haxe-owned template bodies. `@:railsTemplateAst("render")` is the default HXX-style typed template path: a static method returns `HtmlNode` authored as Rails HHX inline markup such as `return <div>${todo.title}</div>`. `RailsInlineMarkup` rewrites that markup into the same typed `HtmlNode`/`HtmlAttr` AST that `H` can build manually, Haxe validates embedded expressions/branch conditions/loop binders/partial locals/route helpers/form locals, and the compiler emits ERB. Current HHX tags include normal HTML, `${...}` text/attribute splices, `<if>`, `<for>`, `<link_to>`, `<partial>`, `<component>`, and the initial form-builder tags, including `<text_field>`, `<text_area>`, and `<check_box>`; helper labels can be static text or `${...}` expression children, and `<link_to>` supports nested HHX via Rails block-form links. `<component component=${(RailsComponent.of(TodoCardView, TodoHooks.componentBodySlot) : RailsComponent<TodoCardLocals>)} locals=${{body: Slot.content(), ...}}>...</component>` captures typed HHX children and passes the captured ActionView buffer through a typed partial local. Raw ERB requires explicit `@:railsAllowRawErb` and is an escape hatch, not the canonical authoring path; the destination is a fuller typed Rails template layer inspired by `../haxe.elixir.codex`'s HXX/HEEx architecture.
Rails layout helper tags are typed HHX too: `<doctype_html />`, `<csrf_meta_tags />`, `<csp_meta_tag />`, `<stylesheet_link_tag />`, `<javascript_importmap_tags />`, `<rails_yield />`, `<yield_content name="..." />`, and `<content_for name="...">...</content_for>` lower to Rails-native ERB helpers. Layouts and named slots must follow the same rule as partials: author in HHX, generate ERB.
Behavior-bearing DOM hooks should follow the todoapp's `shared.TodoHooks` pattern: model slot names, IDs, data attributes, selectors, storage keys, and repeated behavior classes as typed Haxe constants, consume them from HHX and Haxe JS, and export them to Playwright with a Haxe tool when browser tests need the same contract. Styling-only classes can stay local to CSS/templates.

RailsHx ActiveRecord field refs are the default form/params seam. `@:railsColumn` fields generate `Todo.fields.title` / `Todo.f.title : Field<Todo, String>` and `Todo.railsParamKey : ModelKey<Todo>`. HHX form helpers accept those refs and lower them to Rails-native field names, while `ParamsMacro.requirePermit(...)` validates that permitted fields belong to the same typed params root before emitting Rails symbols.

RailsHx ActiveRecord queries now have the first typed relation seam. Model and relation `where({...})` checks object-literal keys and value types against `@:railsColumn` metadata, returns an inferred `Relation<Todo, criteria>`, and preserves that criteria through Rails-shaped chains such as `Todo.where({isCompleted: false}).where({title: "ship"}).order(Todo.f.title.asc()).limit(10).toArray()`. Association refs are generated as `Todo.associations.user` with `Todo.a.user` as the terse alias, so `Todo.includes(Todo.associations.user).joins(Todo.a.user)` lowers to normal Rails `includes(:user).joins(:user)` while Haxe rejects associations from the wrong model. `find(...)` uses the typed primary key and `findBy({...})` uses the same typed criteria object. The compiler lowers this to normal ActiveRecord calls such as `where(is_completed: false).order(title: :asc).limit(10).to_a`.

RailsHx association metadata accepts the first typed Rails option set directly on association annotations: `@:belongsTo({optional: false, foreignKey: "userId", inverseOf: "todos"})`, `@:hasMany({dependent: "destroy", inverseOf: "user"})`, and `@:hasMany({through: "todos", source: "user"})`. Haxe validates option names and literal shapes, checks explicit `foreignKey` values against `@:railsColumn` fields for `belongsTo`, verifies `through` references another association on the same model, and lowers Haxe field names such as `userId` into Rails-native names such as `foreign_key: "user_id"`.

RailsHx model metadata stays Rails-native while adding compile-time checks. `@:validates` targets must resolve to `@:railsColumn` fields, `@:railsEnum({...})` emits Rails `enum :field, {...}` only when literal values match the field type, and method-level callbacks such as `@:beforeValidation` lower to ordinary Rails callback macros like `before_validation :normalize_title`. `@:railsCallback("after_commit")` exists for Rails callback names that do not yet have a Haxe shorthand, but it is still validated against the supported callback set.
