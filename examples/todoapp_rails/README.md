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
- Haxe-authored ActionController logic with typed model calls, `ParamsMacro.requirePermit(...)` strong-params generation, and `ViewMacro.renderTemplate(...)` typed locals for Rails rendering.
- Haxe-owned ActionView artifact generation through `@:railsTemplate(...)`, which materializes the Rails-native ERB file under `app/views`.
- Haxe-authored typed ActionView partials through `@:railsTemplateAst(...)`, Rails HHX inline markup, `H`, `HtmlNode`, and `HtmlAttr`; the compiler type-checks embedded expressions such as `todo.title`, typed conditionals/loops, typed partial locals, route helper calls, and typed form locals before emitting ERB.
- HHX-first ActionView authoring: the index page and all extracted view pieces are authored as typed HHX, while Rails-native ERB is compiler output.
- Haxe-authored JavaScript compiled into the Rails importmap/Turbo flow, so progressive behavior can stay in typed Haxe while Rails serves standard `app/javascript/**` assets.
- Generated route helper externs under `src_haxe/routes/Routes.hx`.
- A Rails migration template matching the Haxe model metadata.
- CI smoke coverage that compiles the Haxe app, checks generated Rails Ruby, and runs Rails runtime tests when local Rails gems are available.

## Source Layout

- `models/Todo.hx` and `models/User.hx` are RailsHx ActiveRecord models.
- `controllers/TodosController.hx` is a RailsHx controller using typed params and route helpers.
- `views/ApplicationLayoutView.hx` owns the Rails layout as typed HHX, including the doctype, Rails CSRF/CSP helper tags, stylesheet/importmap tags, and `<rails_yield />`; generated ERB lands at `app/views/layouts/application.html.erb`.
- `views/TodoIndexView.hx` declares the typed Rails template artifact and owns the full page shell as HHX; scalar locals project from Haxe names such as `todoCount` to Rails locals such as `todo_count`.
- `views/TodoComposerView.hx` owns the typed sample-user branch and composes the form through typed `<partial>` locals, then generates `app/views/controllers/todos/_composer.html.erb`.
- `views/TodoSummaryView.hx` declares a typed HHX partial with `<if>` empty-state branching and `<for ${todo in todos}>` loop syntax, then generates `app/views/controllers/todos/_summary.html.erb`.
- `views/TodoDashboardView.hx` composes the summary partial through typed `<partial>` locals, emits a typed `<link_to>` route helper with nested HHX block content, and generates `app/views/controllers/todos/_dashboard.html.erb`, which the index renders with normal Rails locals.
- `views/TodoListView.hx` is the index's typed open-work list island: HHX validates the `todos` local, `<if>` branch, `<for>` loop binder, and `todo.title`/`todo.notes` expressions before generating `app/views/controllers/todos/_list.html.erb`.
- `views/TodoFormView.hx` uses HHX inline markup (`<form_with>`, `<hidden_field>`, `<field_label>`, `<text_field>`, `<text_area>`, `<submit>`) for a typed Rails form partial and generates `app/views/controllers/todos/_typed_form.html.erb`, which the index renders with `sample_user_id`.
- `std/rails/turbo/Turbo.hx` provides a small typed Haxe facade over Turbo lifecycle events and `Turbo.visit`, so client code uses Rails-native Turbo semantics without stringly-typed app logic.
- `client/TodoClient.hx` compiles to `app/javascript/railshx/todo_client.js` and owns progressive enhancement: typed Turbo submit handling, smooth same-page navigation, scroll-position preservation after create, and a transient typed-status flash.
- `assets/stylesheets/application.css` is copied into Rails' asset path; HHX owns structure, CSS owns presentation.
- Generated `app/views/controllers/todos/index.html.erb` is materialized from that Haxe template marker.
- `src_haxe/routes/Routes.hx` is generated from Rails route output.
- `db/migrate/20260101000000_create_todos.rb` is the Rails migration template for the sample app.

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
npm run rails:app -- --output path/to/rails-app --name MyApp
```

That writes `build.hxml`, `build-client.hxml`, `src_haxe/**`, `app/javascript/**`, `app/assets/stylesheets/application.css`, `config/importmap.rb`, `lib/tasks/hxruby.rake`, `Procfile.railshx.dev`, and `bin/railshx-dev`. In an installed app, the same generator is exposed as:

```bash
bundle exec rake hxruby:gen:app NAME=MyApp
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

Generated app-owned Ruby lands under `app/haxe_gen/**`, with Rails autoload setup in `config/initializers/hxruby_autoload.rb`.

The Haxe-authored client lane compiles through `examples/todoapp_rails/build-client.hxml`, which adds `-cp std` so `rails.turbo.Turbo` is available while emitting JavaScript for Rails importmap assets.

## Test

```bash
npm run test:todoapp-rails
npm run test:rails-integration
npm run todoapp:test
```

`test:rails-integration` always syntax-checks generated Ruby. It runs `rails db:migrate` and `rails test` when Rails gems are installed; set `REQUIRE_RAILS=1` in CI to make that runtime lane mandatory.

## Current Boundary

RailsHx does not yet generate migrations from `@:railsColumn` metadata. This sample keeps the migration as Rails-owned Ruby for now, but the model schema metadata is shaped so the future migration DSL/generator can consume it.

RailsHx has the first typed ActionView seams: controllers render through `ViewMacro.renderTemplate(this, (Template.named("...") : Template<TLocals>), locals)`, which type-checks locals in Haxe and lowers to a normal Rails `render(template:, locals:)` call. `@:railsTemplate(...)` classes materialize Rails-native ERB artifacts into generated output from Haxe-owned template bodies. `@:railsTemplateAst("render")` is the default HXX-style typed template path: a static method returns `HtmlNode` authored as Rails HHX inline markup such as `return <div>${todo.title}</div>`. `RailsInlineMarkup` rewrites that markup into the same typed `HtmlNode`/`HtmlAttr` AST that `H` can build manually, Haxe validates embedded expressions/branch conditions/loop binders/partial locals/route helpers/form locals, and the compiler emits ERB. Current HHX tags include normal HTML, `${...}` text/attribute splices, `<if>`, `<for>`, `<link_to>`, `<partial>`, and the initial form-builder tags, including `<text_field>`, `<text_area>`, and `<check_box>`; helper labels can be static text or `${...}` expression children, and `<link_to>` supports nested HHX via Rails block-form links. Raw ERB requires explicit `@:railsAllowRawErb` and is an escape hatch, not the canonical authoring path; the destination is a fuller typed Rails template layer inspired by `../haxe.elixir.codex`'s HXX/HEEx architecture.
Rails layout helper tags are typed HHX too: `<doctype_html />`, `<csrf_meta_tags />`, `<csp_meta_tag />`, `<stylesheet_link_tag />`, `<javascript_importmap_tags />`, and `<rails_yield />` lower to Rails-native ERB helpers. Layouts must follow the same rule as partials: author in HHX, generate ERB.
