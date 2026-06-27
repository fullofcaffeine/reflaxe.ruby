# RailsHx Todo App

This is the end-to-end RailsHx sample for `reflaxe.ruby`. It shows typed Haxe authoring for Rails code while keeping the generated Ruby recognizable to a Rails app.

For the guided walkthrough of the generated RailsHx skeleton and this larger
dogfood app, see [`docs/railshx-skeleton-and-todoapp-tutorial.md`](../../docs/railshx-skeleton-and-todoapp-tutorial.md).

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
- Haxe-authored JavaScript compiled through the Genes ES-module lane into the Rails importmap/Turbo flow, so progressive behavior can stay in typed Haxe while Rails serves standard `app/javascript/**` assets. The client uses typed `@:async` methods plus `@:await`/`await(...)` helpers; Genes emits native ES `async`/`await`, not a RailsHx runtime. The chatroom slice uses typed HHX `<turbo_stream_from>` plus server-rendered `TurboStreams.broadcastPrependTo(...)`, so Rails/Turbo owns realtime DOM mutation while Haxe owns safer stream names, targets, templates, locals, selectors, and form hooks.
- Haxe-authored Rails migrations through `@:railsMigration(...)`; the compiler emits standard timestamped `db/migrate/*.rb` ActiveRecord migration files from typed snapshot operations.
- Haxe-owned Rails routing through `src_haxe/routes/AppRoutes.hx`; the compiler emits standard `config/routes.rb`, and generated route helper externs under `src_haxe/routes/Routes.hx` still come from Rails route output. The sample includes typed `todos`, `chat_messages`, `users`, `DeviseRoutes.deviseFor(UserAuth.scope, {only: [Sessions]})`, and a Haxe-owned guest sign-in route, plus one Rails-owned `legacy_health` route to prove existing Rails routes can remain Rails-owned while Haxe consumes them through typed helpers.
- DeviseHx auth contracts in a real Rails flow: Devise owns Warden, encrypted passwords, sessions, and route expansion; Haxe owns `app/auth/UserAuth.hx`, typed `@:devise(...)` model metadata, `beforeAction(UserAuth.authenticate)`, typed `current/currentRequired/signIn` calls, and HHX composition around Devise route helpers.
- CI smoke coverage that compiles the Haxe app, checks generated Rails Ruby, and runs Rails runtime tests when local Rails gems are available.

## Source Layout

- `models/Todo.hx` and `models/User.hx` are RailsHx ActiveRecord models.
- `models/ChatMessage.hx` is the typed chatroom model: it owns the `chat_messages` table contract, `belongsTo` user association, validation metadata, and newest-first relation scope used by the controller and HHX.
- `migrations/CreateTodos.hx` is the Haxe-authored Rails migration snapshot source; generated Ruby lands at `db/migrate/20260101000000_create_todos.rb`.
- `migrations/UpdateUsers.hx` adds typed user profile columns as an immutable migration snapshot, while `migrations/AddDeviseToUsers.hx` adds Devise's encrypted password column in a later immutable snapshot. `models/User.hx` owns the current field/validation/helper contract and emits Devise's normal `devise :database_authenticatable, :validatable` macro.
- `migrations/CreateChatMessages.hx` adds the chatroom table as a migration snapshot. The generated Rails migration is ordinary ActiveRecord, while Haxe keeps the table, reference, index, and timestamp operations reviewable.
- `app/auth/UserAuth.hx` is the app-local DeviseHx contract: `scope` carries `DeviseScope<User>` plus compiler-readable route metadata, `authenticate` lowers to `before_action :authenticate_user!`, and `current/currentRequired/signIn/signOut` lower to ordinary Devise helpers while keeping Haxe type checking.
- `controllers/TodosController.hx` is a RailsHx controller using typed params, typed Devise current-user lookup, typed relation queries, and route helpers. The board itself is protected through `beforeAction(UserAuth.authenticate, {})`; Devise renders the login page first, while the Haxe-owned guest action creates a real Devise session for demos.
- `controllers/SessionsController.hx` demonstrates a Haxe-owned guest convenience action layered over real Devise. Regular login/logout routes come from Devise; the guest action calls typed `UserAuth.signIn(this, guest)` and emits ordinary `sign_in(:user, guest)`.
- `controllers/ChatMessagesController.hx` demonstrates the Hotwire mutation seam: typed strong params create a chat message, the controller broadcasts a typed server-rendered HHX partial with `TurboStreams.broadcastPrependTo(...)`, Turbo clients receive `head :no_content`, and HTML fallback redirects through normal Rails.
- `controllers/UsersController.hx` renders admin-only user CRUD through checked HHX locals, typed Devise current-user checks, typed params, and resourceful Rails routes.
- `Todo.incomplete()` returns an inferred typed relation shape, and the controller keeps the query chain typed with `includes(Todo.a.user).order(Todo.f.title.asc()).limit(10).toArray()` before handing an array to HHX templates.
- `views/ApplicationLayoutView.hx` owns the Rails layout as typed HHX, including the doctype, Rails CSRF/CSP helper tags, stylesheet/importmap tags, and `<rails_yield />`; generated ERB lands at `app/views/layouts/application.html.erb`.
- `views/TodoIndexView.hx` declares the typed Rails template artifact and owns the full page shell as HHX; scalar locals project from Haxe names such as `todoCount` to Rails locals such as `todo_count`.
- `views/TodoComposerView.hx` composes the form through typed `<partial>` locals, passing the authenticated user display name into the typed form partial while the controller keeps `user_id` server-owned.
- `views/TodoSummaryView.hx` declares a typed HHX partial with `<if>` empty-state branching and `<for ${todo in todos}>` loop syntax, then generates `app/views/controllers/todos/_summary.html.erb`.
- `views/TodoDashboardView.hx` composes the summary partial through typed `<partial>` locals, emits a typed `<link_to>` route helper with nested HHX block content, and generates `app/views/controllers/todos/_dashboard.html.erb`, which the index renders with normal Rails locals.
- `views/TodoListView.hx` is the index's typed open-work list island: HHX validates the `todos` local, `<if>` branch, `<for>` loop binder, and `todo.title`/`todo.notes` expressions before generating `app/views/controllers/todos/_list.html.erb`.
- `views/TodoFormView.hx` uses HHX inline markup (`<form_with>`, `<field_label>`, `<search_field>`, `<text_area>`, `<submit>`) plus model-owned refs such as `Todo.railsParamKey`, `Todo.f.title`, and `Todo.f.notes` for a typed Rails form partial. It intentionally does not render a `user_id` hidden field; `ParamsMacro.mergeField(attrs, Todo.f.userId, currentUser.id)` adds the authenticated owner in the controller.
- `views/DeviseLoginView.hx` is the typed Devise login page: Devise still owns Warden, password checking, sessions, and redirects, while RailsHx owns the HHX view, native `<email_field>` form helper, generated route helpers, and guest CTA. It generates `app/views/devise/sessions/new.html.erb`, so Devise consumes it exactly like a hand-written Rails view.
- `views/AppTopBarView.hx` is the authenticated app chrome: a typed `currentUser` local drives avatar/name/role/email, `Routes.usersPath()` targets the standard Turbo Frame for user management, and `Routes.destroyUserSessionPath()` drives the Rails `button_to` logout form.
- `views/ChatPanelView.hx` is the typed chatroom panel: `<turbo_stream_from>` subscribes to the typed stream, `ChatMessage.f.body` drives the form field, `Routes.chatMessagesPath()` drives submission, and the initial message loop composes the typed row partial through `Template.of(ChatMessageView)`. Like todos, chat authorship comes from `current_user` in the controller instead of a spoofable hidden field.
- `views/ChatMessageView.hx` is the server-rendered Turbo Stream row partial: `@:railsTemplate(...)` chooses the Rails partial path, `@:railsTemplateAst("render")` type-checks HHX before ERB emission, `locals.message.body`/`locals.message.userId` stay typed, and `roomStream()`/`roomTarget()` centralize the broadcast contract used by the controller and panel.
- `views/UserManagementView.hx` is a second HHX page showing typed user fields, typed `<select>` role options, route-helper links, and the matching `<turbo_frame>` response that Turbo extracts into the todo board while preserving direct `/users` fallback navigation.
- `std/rails/turbo/Turbo.hx` provides a typed Haxe facade over Turbo lifecycle events, `Turbo.visit` actions/options, client frame helpers, server-side stream helpers, and typed stream names/targets, while `rails.action_view.HtmlNode.TurboFrame` powers HHX `<turbo_frame>` authoring. App code uses Rails-native Turbo semantics without stringly-typed logic. `std/rails/action_cable/**` still provides typed consumer/channel/stream/payload boundaries for custom non-DOM protocols, but the canonical chatroom DOM update path is plain Turbo Streams. Repeated behavior hooks live in `shared/TodoHooks.hx` and are exported to Playwright, which is the same source-of-truth pattern RailsHx should use for richer Turbo abstractions.
- `src_haxe/routes/AppRoutes.hx` is the Haxe-owned Rails routing source: `@:railsRoutes` plus typed controller/action refs emits normal `config/routes.rb` for todos, chat messages, users, the Devise session mapping, and the guest route. Rails still remains the helper-name oracle; `Routes.hx` is generated from actual Rails route output.
- `rails/config/routes_rails_owned.rb` is a commented Rails-owned route snippet. It models an existing hand-written Rails route that stays outside `AppRoutes.hx`; `Routes.hx` still exposes it as typed `Routes.legacyHealthPath()` after route-helper generation.
- `shared/TodoHooks.hx` centralizes behavior-bearing slots, IDs, selectors, data attributes, and storage keys as typed Haxe constants shared by HHX templates, Haxe JS, and Playwright.
- `tools/ExportTodoHooks.hx` materializes those Haxe-owned hooks into `e2e/todo_hooks.ts`, so browser tests import the same selector contract instead of copying string literals.
- `client/TodoClient.hx` compiles through Genes to `app/javascript/railshx/todo_client.js` plus importmap-friendly ES modules under `app/javascript/railshx/**`. It owns progressive enhancement only where the browser owns behavior: typed Turbo lifecycle hooks, smooth same-page navigation, scroll-position preservation after create, chat/session form binding, and transient typed-status flashes. The chat composer uses `rails.hotwire.TextAreaComposer` so Enter submits through the normal Turbo form pipeline, Shift+Enter keeps newlines, and successful submits clear the textarea without app-local raw JS. It does not subscribe to the chat stream or duplicate chat-row HTML; `turbo_stream_from` and server-rendered Turbo Streams handle realtime DOM updates. Async methods use `@:async` plus `@:await expr` where that reads closest to JavaScript/TypeScript; the older `await(expr)` helper remains available for grouped expressions. Genes emits native JavaScript `async`/`await` while keeping completion typed in Haxe. Todo, chat, and session mutations retain normal Rails redirects or Turbo Stream responses where Rails owns them.
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

Runs the RailsHx browser sentinel: compile/materialize the generated app, compile the optional Haxe-authored Playwright spec from `e2e_haxe/**` into disposable ES modules under `e2e/generated/**`, prepare and seed the SQLite DB, boot Rails on a dedicated port, run Playwright specs from `examples/todoapp_rails/e2e`, and shut Rails down. Vanilla TypeScript specs remain first-class; Haxe-authored specs are useful when a browser test wants typed RailsHx hooks such as `shared.TodoHooks`.

Use the lightweight compile/output-shape lane when you only need to verify the Haxe-authored browser test artifact:

```bash
npm run test:haxe-playwright
```

Override the port or spec when debugging:

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

The Haxe-authored client lane compiles through `examples/todoapp_rails/build-client.hxml`, which adds `-cp std` so `rails.turbo.Turbo`, `reflaxe.js.Async`, and typed event/action modules are available. The build uses Genes (`-lib genes`, `--macro genes.Generator.use()`, `--macro reflaxe.js.Async.enable()`, and `-D js-es=6`) so Rails receives readable ES module assets under `app/javascript/railshx/**` instead of one flattened JavaScript blob. Genes reads `@:async` metadata, while `reflaxe.js.Async.enable()` desugars `@:await expr` to the same typed helper as `await(expr)`, so Haxe-authored async code becomes normal ES `async`/`await`.

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

RailsHx has a Haxe-authored migration lane: `@:railsMigration(...)` classes emit standard timestamped ActiveRecord migrations. The todoapp now uses the production-preferred snapshot style directly: `migrations/CreateTodos.hx` owns explicit `CreateTable`, `Column`, `Reference`, and `Index` operations; `migrations/UpdateTodos.hx` owns reversible changes, checked column bounds, idempotent table/column/reference operations, named reference foreign keys, named/idempotent indexes, named/idempotent index removal, named/idempotent foreign keys, named/idempotent foreign-key removal, safe named/idempotent check constraints, a composite index, and a rollback-aware `DataMigration`. This is the same style produced by `bin/rails generate hxruby:migration CreateTodos title:string! notes:text user:references`. The compatibility path can still derive create-table output from referenced `@:railsModel` and `@:railsColumn` metadata, but production generators should prefer explicit snapshot operations in `public static final operations:Array<MigrationOperation>` so old migrations do not drift when model metadata changes. Snapshot operations include `CreateTable`, `Column`, `Reference`, `Index`, `AddColumn`, `AddColumnIfNotExists`, `RemoveColumn`, `RemoveColumnIfExists`, `ChangeColumn`, `AddIndex`, `AddCompositeIndex`, `RemoveIndexByName`, `RemoveCompositeIndex`, `AddReference`, `AddReferenceIfNotExists`, `RemoveReference`, `RemoveReferenceIfExists`, `AddCheckConstraint`, `RemoveCheckConstraint`, `RemoveCheckConstraintIfExists`, `AddForeignKey`, `RemoveForeignKey`, `RemoveForeignKeyIfExists`, `RemoveForeignKeyByName`, `RemoveForeignKeyByNameIfExists`, `RenameColumn`, `RenameTable`, `ChangeNull`, `DropTable`, `DropTableIfExists`, `ExecuteSql`, `DataMigration`, and `Reversible`; the compiler lowers them into normal Rails `change` statements. `knownModels: ["models.Todo"]` validates table/column/index/foreign-key references against typed model metadata without re-emitting `create_table`; because migrations are historical snapshots, an old `AddColumn` may still add a field that exists on today's `models.Todo`, while duplicate additions inside the same migration are rejected. `externalTables: ["legacy_events"]` is the explicit escape for Rails-owned tables whose schema is not Haxe-owned. The compiler rejects duplicate migration timestamps, bad known table/column references, invalid column bounds, non-owned generated migration collisions, unsafe named reference foreign keys, and known foreign-key tables that are created by later migrations. `version: "8.1"` can pin the generated `ActiveRecord::Migration[...]` superclass for a Rails app. `test:rails-integration` syntax-checks generated migrations and runs `rails db:migrate`/`rails test` when the generated app bundle is available; `test:rails-runtime` makes that runtime lane mandatory.

RailsHx has the first typed ActionView seams: controllers render through `ViewMacro.renderTemplate(this, (Template.of(TodoIndexView) : Template<TLocals>), locals)`, which type-checks locals in Haxe and lowers to a normal Rails `render(template:, locals:)` call. Layouts use `Template.layout(ApplicationLayoutView)`, and owned partials/components use `Template.of(ViewClass)` or `RailsComponent.of(ViewClass, slot)` so missing or renamed HHX view classes fail during Haxe compilation instead of becoming stale Rails strings. `@:railsTemplate(...)` classes materialize Rails-native ERB artifacts into generated output from Haxe-owned template bodies. `@:railsTemplateAst("render")` is the default HXX-style typed template path: a static method returns `HtmlNode` authored as Rails HHX inline markup such as `return <div>${todo.title}</div>`. `RailsInlineMarkup` rewrites that markup into the same typed `HtmlNode`/`HtmlAttr` AST that `H` can build manually, Haxe validates embedded expressions/branch conditions/loop binders/partial locals/route helpers/form locals, and the compiler emits ERB. Current HHX tags include normal HTML, `${...}` text/attribute splices, `<if>`, `<for>`, `<link_to>`, `<button_to>`, `<partial>`, `<component>`, and the initial form-builder tags, including `<text_field>`, `<search_field>`, `<email_field>`, `<select>`, `<text_area>`, `<check_box>`, and `<field_errors>`; helper labels can use `text="..."`, static text children, or `${...}` expression children. `<select name=${User.f.role} options=${[{label: "Member", value: "member"}]}>` lowers to Rails `form.select` choices while keeping option labels/values typed in Haxe. `<field_errors name=${Todo.f.title}>` reads Rails' `form.object.errors[:title]` while keeping the field ref typed in Haxe. `<link_to>` and `<button_to>` both support nested HHX via Rails block-form helpers, so a Haxe block with child markup lowers to `link_to ... do` or `button_to ... do` instead of a custom runtime widget. `<component component=${(RailsComponent.of(TodoCardView, TodoHooks.componentBodySlot) : RailsComponent<TodoCardLocals>)} locals=${{body: Slot.content(), ...}}>...</component>` captures typed HHX children and passes the captured ActionView buffer through a typed partial local. Raw ERB requires explicit `@:railsAllowRawErb` and is an escape hatch, not the canonical authoring path; the destination is a fuller typed Rails template layer inspired by `../haxe.elixir.codex`'s HXX/HEEx architecture.
Rails layout helper tags are typed HHX too: `<doctype_html />`, `<csrf_meta_tags />`, `<csp_meta_tag />`, `<stylesheet_link_tag />`, `<javascript_importmap_tags />`, `<rails_yield />`, `<yield_content name="..." />`, and `<content_for name="...">...</content_for>` lower to Rails-native ERB helpers. Layouts and named slots must follow the same rule as partials: author in HHX, generate ERB.
Behavior-bearing DOM hooks should follow the todoapp's `shared.TodoHooks` pattern: model slot names, IDs, data attributes, selectors, storage keys, and repeated behavior classes as typed Haxe constants, consume them from HHX and Haxe JS, and export them to Playwright with a Haxe tool when browser tests need the same contract. Styling-only classes can stay local to CSS/templates.

RailsHx ActiveRecord field refs are the default form/params seam. `@:railsColumn` fields generate `Todo.fields.title` / `Todo.f.title : Field<Todo, String>` and `Todo.railsParamKey : ModelKey<Todo>`. HHX form helpers accept those refs and lower them to Rails-native field names, while `ParamsMacro.requirePermit(...)` validates that permitted fields belong to the same typed params root before emitting Rails symbols.

RailsHx ActiveRecord queries now have the first typed relation seam. Model and relation `where({...})` checks object-literal keys and value types against `@:railsColumn` metadata, returns an inferred `Relation<Todo, criteria>`, and preserves that criteria through Rails-shaped chains such as `Todo.where({isCompleted: false}).where({title: "ship"}).order(Todo.f.title.asc()).limit(10).toArray()`. Association refs are generated as `Todo.associations.user` with `Todo.a.user` as the terse alias, so `Todo.includes(Todo.associations.user).joins(Todo.a.user)` lowers to normal Rails `includes(:user).joins(:user)` while Haxe rejects associations from the wrong model. `find(...)` uses the typed primary key and `findBy({...})` uses the same typed criteria object. The compiler lowers this to normal ActiveRecord calls such as `where(is_completed: false).order(title: :asc).limit(10).to_a`.

RailsHx association metadata accepts the first typed Rails option set directly on association annotations: `@:belongsTo({optional: false, foreignKey: "userId", inverseOf: "todos"})`, `@:hasMany({dependent: "destroy", inverseOf: "user"})`, and `@:hasMany({through: "todos", source: "user"})`. Haxe validates option names and literal shapes, checks explicit `foreignKey` values against `@:railsColumn` fields for `belongsTo`, verifies `through` references another association on the same model, and lowers Haxe field names such as `userId` into Rails-native names such as `foreign_key: "user_id"`.

RailsHx model metadata stays Rails-native while adding compile-time checks. `@:validates` targets must resolve to `@:railsColumn` fields, `@:railsEnum({...})` emits Rails `enum :field, {...}` only when literal values match the field type, and method-level callbacks such as `@:beforeValidation` lower to ordinary Rails callback macros like `before_validation :normalize_title`. `@:railsCallback("after_commit")` exists for Rails callback names that do not yet have a Haxe shorthand, but it is still validated against the supported callback set.
