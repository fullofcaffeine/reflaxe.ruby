# RailsHx Todo App

This is the end-to-end RailsHx sample for `reflaxe.ruby`. It shows typed Haxe authoring for Rails code while keeping the generated Ruby recognizable to a Rails app.

## Quick Start

From the repository root:

```bash
eval "$(rbenv init - zsh)" # if your shell has not initialized rbenv yet
npm run todoapp:prepare
npm run todoapp:server
```

Open [http://127.0.0.1:3000/](http://127.0.0.1:3000/). The generated Rails app is materialized under `test/.generated/rails_integration`; treat it as disposable output. The source of truth is the Haxe/HHX code in `examples/todoapp_rails/**` plus compiler/std code in `src/**` and `std/**`.

For the RailsHx edit loop, keep Rails running and start the Haxe watcher in another terminal:

```bash
npm run todoapp:watch
```

The watcher recompiles Haxe/HHX and refreshes generated Rails files when sources change. Rails serves those files through normal ActionController/ActionView, so a browser refresh is enough for most template/controller changes.

## What The Sample Proves

- Haxe-authored ActiveRecord models with `@:railsModel`, typed `@:railsColumn(...)` metadata, associations, validations, and timestamps.
- Generated Rails model Ruby with `self.__hx_rails_schema` metadata for later query/migration tooling.
- Haxe-authored ActionController logic with inferred typed `Relation<Todo, criteria>` query chaining, `ParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.title, ...])` strong-params generation, and `ViewMacro.renderTemplate(...)` typed locals for Rails rendering.
- Haxe-owned ActionView artifact generation through `@:railsTemplate(...)`, which materializes the Rails-native ERB file under `app/views`.
- Haxe-authored typed ActionView partials through `@:railsTemplateAst(...)`, Rails HHX inline markup, `H`, `HtmlNode`, and `HtmlAttr`; the compiler type-checks embedded expressions such as `todo.title`, typed conditionals/loops, typed partial locals, route helper calls, and typed form locals before emitting ERB.
- HHX-first ActionView authoring: the index page and all extracted view pieces are authored as typed HHX, while Rails-native ERB is compiler output.
- Haxe-authored JavaScript compiled into the Rails importmap/Turbo flow, so progressive behavior can stay in typed Haxe while Rails serves standard `app/javascript/**` assets.
- Haxe-authored Rails migrations through `@:railsMigration(...)`; the compiler emits standard timestamped `db/migrate/*.rb` ActiveRecord migration files from typed model metadata.
- Generated route helper externs under `src_haxe/routes/Routes.hx`.
- CI smoke coverage that compiles the Haxe app, checks generated Rails Ruby, and runs Rails runtime tests when local Rails gems are available.

## Source Layout

- `models/Todo.hx` and `models/User.hx` are RailsHx ActiveRecord models.
- `migrations/CreateTodos.hx` is the Haxe-authored Rails migration source; generated Ruby lands at `db/migrate/20260101000000_create_todos.rb`.
- `controllers/TodosController.hx` is a RailsHx controller using typed params and route helpers.
- `Todo.incomplete()` returns an inferred typed relation shape, and the controller keeps the query chain typed with `includes(Todo.a.user).order(Todo.f.title.asc()).limit(10).toArray()` before handing an array to HHX templates.
- `views/ApplicationLayoutView.hx` owns the Rails layout as typed HHX, including the doctype, Rails CSRF/CSP helper tags, stylesheet/importmap tags, and `<rails_yield />`; generated ERB lands at `app/views/layouts/application.html.erb`.
- `views/TodoIndexView.hx` declares the typed Rails template artifact and owns the full page shell as HHX; scalar locals project from Haxe names such as `todoCount` to Rails locals such as `todo_count`.
- `views/TodoComposerView.hx` owns the typed sample-user branch and composes the form through typed `<partial>` locals, then generates `app/views/controllers/todos/_composer.html.erb`.
- `views/TodoSummaryView.hx` declares a typed HHX partial with `<if>` empty-state branching and `<for ${todo in todos}>` loop syntax, then generates `app/views/controllers/todos/_summary.html.erb`.
- `views/TodoDashboardView.hx` composes the summary partial through typed `<partial>` locals, emits a typed `<link_to>` route helper with nested HHX block content, and generates `app/views/controllers/todos/_dashboard.html.erb`, which the index renders with normal Rails locals.
- `views/TodoListView.hx` is the index's typed open-work list island: HHX validates the `todos` local, `<if>` branch, `<for>` loop binder, and `todo.title`/`todo.notes` expressions before generating `app/views/controllers/todos/_list.html.erb`.
- `views/TodoFormView.hx` uses HHX inline markup (`<form_with>`, `<hidden_field>`, `<field_label>`, `<text_field>`, `<text_area>`, `<submit>`) plus model-owned refs such as `Todo.railsParamKey`, `Todo.f.title`, and `Todo.f.notes` for a typed Rails form partial. It generates `app/views/controllers/todos/_typed_form.html.erb`, which the index renders with `sample_user_id`.
- `std/rails/turbo/Turbo.hx` provides a small typed Haxe facade over Turbo lifecycle events and `Turbo.visit`, so client code uses Rails-native Turbo semantics without stringly-typed app logic.
- `client/TodoClient.hx` compiles to `app/javascript/railshx/todo_client.js` and owns progressive enhancement: typed Turbo submit handling, smooth same-page navigation, scroll-position preservation after create, and a transient typed-status flash.
- `assets/stylesheets/application.css` is copied into Rails' asset path; HHX owns structure, CSS owns presentation.
- Generated `app/views/controllers/todos/index.html.erb` is materialized from that Haxe template marker.
- `src_haxe/routes/Routes.hx` is generated from Rails route output.
- `db/migrate/20260101000000_create_todos.rb` is generated Rails migration output from `migrations/CreateTodos.hx`.

## Command Guide

```bash
npm run todoapp:compile
```

Compiles the RailsHx sample and refreshes generated Rails files in `test/.generated/rails_integration` without touching bundle state or the SQLite DB.

```bash
npm run todoapp:prepare
```

Compiles Haxe/HHX, materializes the Rails app, runs `bundle check || bundle install`, prepares the development database, and seeds demo data. Run this once before using the app, and rerun it after dependency or migration changes.

```bash
npm run todoapp:server
```

Starts Rails through the generated app-local `bin/rails` entrypoint with `127.0.0.1:3000` defaults. Override with normal environment variables:

```bash
PORT=3001 BIND=0.0.0.0 npm run todoapp:server
```

```bash
npm run todoapp:watch
```

Runs a lightweight watcher for `src/**`, `std/**`, and `examples/todoapp_rails/**`. The recommended RailsHx dev workflow is Rails server in one terminal and this watcher in another; it refreshes generated Ruby/ERB plus the Haxe-authored JS client while Rails keeps serving the app.

```bash
npm run todoapp:test
```

Compiles, materializes, prepares the test DB, and runs the generated Rails test suite.

```bash
npm run test:todoapp-playwright
```

Runs the RailsHx browser sentinel: compile/materialize the generated app, prepare and seed the SQLite DB, boot Rails on a dedicated port, run Playwright specs from `examples/todoapp_rails/e2e/*.spec.ts`, and shut Rails down. Override the port or spec when debugging:

```bash
RAILSHX_PLAYWRIGHT_PORT=3101 RAILSHX_PLAYWRIGHT_SPEC=examples/todoapp_rails/e2e/todoapp.spec.ts npm run test:todoapp-playwright
```

## Production Build Shape

For a real RailsHx app, Haxe/HHX compilation is a build step before the normal Rails production bundle is finalized:

```bash
RAILS_ENV=production bundle exec rake hxruby:compile
RAILS_ENV=production bundle exec rake hxruby:compile:client
RAILS_ENV=production bundle exec rails zeitwerk:check
RAILS_ENV=production bundle exec rails assets:precompile
```

The production artifact must include generated `app/haxe_gen/**`, generated ActionView templates under `app/views/**`, generated Haxe JS under `app/javascript/railshx/**`, and `config/initializers/hxruby_autoload.rb`. The canonical source remains Haxe/HHX/Haxe JS; generated Rails files are build output.

## App Generator

RailsHx app/adoption files can be generated into a Rails app with:

```bash
bin/rails generate hxruby:install MyApp
npm run rails:app -- --output path/to/rails-app --name MyApp
```

That writes `build.hxml`, `build-client.hxml`, `src_haxe/**`, `app/javascript/**`, `app/assets/stylesheets/application.css`, `config/importmap.rb`, `lib/tasks/hxruby.rake`, `Procfile.railshx.dev`, and `bin/railshx-dev`. In an installed app, the same generator is exposed as:

```bash
bundle exec rake hxruby:gen:app NAME=MyApp
```

The Rails-facing generators are Ruby-native and package with the `hxruby` gem. For gradual adoption of existing Rails code, scaffold typed wrappers without touching Rails-owned ERB/Ruby:

```bash
bin/rails generate hxruby:adopt --service LegacyPriceFormatter --template legacy/badge --locals label:String,tone:String
bin/rails generate hxruby:adopt --discover
npm run rails:adopt -- --service LegacyPriceFormatter --template legacy/badge --locals label:String,tone:String
bundle exec rake hxruby:gen:adopt SERVICE=LegacyPriceFormatter TEMPLATE=legacy/badge LOCALS=label:String,tone:String
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

The Haxe-authored client lane compiles through `examples/todoapp_rails/build-client.hxml`, which adds `-cp std` so `rails.turbo.Turbo` is available while emitting JavaScript for Rails importmap assets.

## Test

```bash
npm run test:todoapp-rails
npm run test:rails-integration
npm run test:rails-runtime
npm run todoapp:test
npm run test:todoapp-playwright
```

`test:rails-integration` always syntax-checks generated Ruby. It runs `rails db:migrate` and `rails test` when the generated Rails app bundle is available. `test:rails-runtime` is the mandatory runtime lane: it sets `REQUIRE_RAILS=1`, installs generated app bundles when needed, and runs both the todoapp Rails integration tests and the mixed Rails/RailsHx interop runtime tests.

`test:todoapp-playwright` is the real-browser layer, modeled after the PhoenixHx sentinel approach but Rails-native: Playwright validates browser-rendered ActionView, importmap/Turbo/Haxe-client behavior, form submission, and same-page link enhancement against a running generated Rails app.

## Current Boundary

RailsHx now has an initial Haxe-authored migration lane: `@:railsMigration(...)` classes can emit create-table ActiveRecord migrations from referenced `@:railsModel` and `@:railsColumn` metadata, including timestamps, simple indexes, defaults, nullability, and `belongs_to` references. Follow-up migrations can also expose `public static final operations:Array<MigrationOperation>` with typed operations such as `AddColumn`, `RemoveColumn`, `ChangeColumn`, `AddIndex`, `RemoveIndex`, `AddForeignKey`, `RemoveForeignKey`, `DropTable`, and `Reversible`; the compiler lowers those into normal Rails `change` statements, including `reversible do |dir|` blocks where needed. The compiler rejects duplicate migration timestamps and known foreign-key tables that are created by later migrations. `test:rails-integration` syntax-checks generated migrations and runs `rails db:migrate`/`rails test` when the generated app bundle is available; `test:rails-runtime` makes that runtime lane mandatory.

RailsHx has the first typed ActionView seams: controllers render through `ViewMacro.renderTemplate(this, (Template.of(TodoIndexView) : Template<TLocals>), locals)`, which type-checks locals in Haxe and lowers to a normal Rails `render(template:, locals:)` call. Layouts use `Template.layout(ApplicationLayoutView)`, and owned partials/components use `Template.of(ViewClass)` so missing or renamed HHX view classes fail during Haxe compilation instead of becoming stale Rails strings. `@:railsTemplate(...)` classes materialize Rails-native ERB artifacts into generated output from Haxe-owned template bodies. `@:railsTemplateAst("render")` is the default HXX-style typed template path: a static method returns `HtmlNode` authored as Rails HHX inline markup such as `return <div>${todo.title}</div>`. `RailsInlineMarkup` rewrites that markup into the same typed `HtmlNode`/`HtmlAttr` AST that `H` can build manually, Haxe validates embedded expressions/branch conditions/loop binders/partial locals/route helpers/form locals, and the compiler emits ERB. Current HHX tags include normal HTML, `${...}` text/attribute splices, `<if>`, `<for>`, `<link_to>`, `<partial>`, `<component>`, and the initial form-builder tags, including `<text_field>`, `<text_area>`, and `<check_box>`; helper labels can be static text or `${...}` expression children, and `<link_to>` supports nested HHX via Rails block-form links. `<component template=... slot="body" locals=${{body: Slot.content(), ...}}>...</component>` captures typed HHX children and passes the captured ActionView buffer through a typed partial local. Raw ERB requires explicit `@:railsAllowRawErb` and is an escape hatch, not the canonical authoring path; the destination is a fuller typed Rails template layer inspired by `../haxe.elixir.codex`'s HXX/HEEx architecture.
Rails layout helper tags are typed HHX too: `<doctype_html />`, `<csrf_meta_tags />`, `<csp_meta_tag />`, `<stylesheet_link_tag />`, `<javascript_importmap_tags />`, `<rails_yield />`, `<yield_content name="..." />`, and `<content_for name="...">...</content_for>` lower to Rails-native ERB helpers. Layouts and named slots must follow the same rule as partials: author in HHX, generate ERB.

RailsHx ActiveRecord field refs are the default form/params seam. `@:railsColumn` fields generate `Todo.fields.title` / `Todo.f.title : Field<Todo, String>` and `Todo.railsParamKey : ModelKey<Todo>`. HHX form helpers accept those refs and lower them to Rails-native field names, while `ParamsMacro.requirePermit(...)` validates that permitted fields belong to the same typed params root before emitting Rails symbols.

RailsHx ActiveRecord queries now have the first typed relation seam. Model and relation `where({...})` checks object-literal keys and value types against `@:railsColumn` metadata, returns an inferred `Relation<Todo, criteria>`, and preserves that criteria through Rails-shaped chains such as `Todo.where({isCompleted: false}).where({title: "ship"}).order(Todo.f.title.asc()).limit(10).toArray()`. Association refs are generated as `Todo.associations.user` with `Todo.a.user` as the terse alias, so `Todo.includes(Todo.associations.user).joins(Todo.a.user)` lowers to normal Rails `includes(:user).joins(:user)` while Haxe rejects associations from the wrong model. `find(...)` uses the typed primary key and `findBy({...})` uses the same typed criteria object. The compiler lowers this to normal ActiveRecord calls such as `where(is_completed: false).order(title: :asc).limit(10).to_a`.

RailsHx association metadata accepts the first typed Rails option set directly on association annotations: `@:belongsTo({optional: false, foreignKey: "userId", inverseOf: "todos"})`, `@:hasMany({dependent: "destroy", inverseOf: "user"})`, and `@:hasMany({through: "todos", source: "user"})`. Haxe validates option names and literal shapes, checks explicit `foreignKey` values against `@:railsColumn` fields for `belongsTo`, verifies `through` references another association on the same model, and lowers Haxe field names such as `userId` into Rails-native names such as `foreign_key: "user_id"`.

RailsHx model metadata stays Rails-native while adding compile-time checks. `@:validates` targets must resolve to `@:railsColumn` fields, `@:railsEnum({...})` emits Rails `enum :field, {...}` only when literal values match the field type, and method-level callbacks such as `@:beforeValidation` lower to ordinary Rails callback macros like `before_validation :normalize_title`. `@:railsCallback("after_commit")` exists for Rails callback names that do not yet have a Haxe shorthand, but it is still validated against the supported callback set.
