# RailsHx Todo App

This is the end-to-end RailsHx sample for `reflaxe.ruby`. It shows typed Haxe authoring for Rails code while keeping the generated Ruby recognizable to a Rails app.

## What The Sample Proves

- Haxe-authored ActiveRecord models with `@:railsModel`, typed `@:railsColumn(...)` metadata, associations, validations, and timestamps.
- Generated Rails model Ruby with `self.__hx_rails_schema` metadata for later query/migration tooling.
- Haxe-authored ActionController logic with typed model calls, `ParamsMacro.requirePermit(...)` strong-params generation, and `ViewMacro.renderTemplate(...)` typed locals for Rails rendering.
- Haxe-owned ActionView artifact generation through `@:railsTemplate(...)`, which materializes the Rails-native ERB file under `app/views`.
- Haxe-authored typed ActionView partials through `@:railsTemplateAst(...)`, Rails HHX inline markup, `H`, `HtmlNode`, and `HtmlAttr`; the compiler type-checks embedded expressions such as `todo.title`, typed conditionals/loops, typed partial locals, route helper calls, and typed form locals before emitting ERB.
- Incremental raw ERB migration: the index template still owns the full page shell, but delegates the typed dashboard and typed form islands to generated HHX partials.
- Generated route helper externs under `src_haxe/routes/Routes.hx`.
- A Rails migration template matching the Haxe model metadata.
- CI smoke coverage that compiles the Haxe app, checks generated Rails Ruby, and runs Rails runtime tests when local Rails gems are available.

## Source Layout

- `models/Todo.hx` and `models/User.hx` are RailsHx ActiveRecord models.
- `controllers/TodosController.hx` is a RailsHx controller using typed params and route helpers.
- `views/TodoIndexView.hx` declares the typed Rails template artifact and owns the inline ERB body.
- `views/TodoSummaryView.hx` declares a typed HHX partial with `<if>` empty-state branching and `<for ${todo in todos}>` loop syntax, then generates `app/views/controllers/todos/_summary.html.erb`.
- `views/TodoDashboardView.hx` composes the summary partial through typed `<partial>` locals, emits a typed `<link_to>` route helper with nested HHX block content, and generates `app/views/controllers/todos/_dashboard.html.erb`, which the index renders with normal Rails locals.
- `views/TodoFormView.hx` uses HHX inline markup (`<form_with>`, `<hidden_field>`, `<field_label>`, `<text_field>`, `<submit>`) for a typed Rails form partial and generates `app/views/controllers/todos/_typed_form.html.erb`, which the index renders with `sample_user_id`.
- Generated `app/views/controllers/todos/index.html.erb` is materialized from that Haxe template marker.
- `src_haxe/routes/Routes.hx` is generated from Rails route output.
- `db/migrate/20260101000000_create_todos.rb` is the Rails migration template for the sample app.

## Compile

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

## Test

```bash
npm run test:todoapp-rails
npm run test:rails-integration
```

`test:rails-integration` always syntax-checks generated Ruby. It runs `rails db:migrate` and `rails test` when Rails gems are installed; set `REQUIRE_RAILS=1` in CI to make that runtime lane mandatory.

## Current Boundary

RailsHx does not yet generate migrations from `@:railsColumn` metadata. This sample keeps the migration as Rails-owned Ruby for now, but the model schema metadata is shaped so the future migration DSL/generator can consume it.

RailsHx has the first typed ActionView seams: controllers render through `ViewMacro.renderTemplate(this, (Template.named("...") : Template<TLocals>), locals)`, which type-checks locals in Haxe and lowers to a normal Rails `render(template:, locals:)` call. `@:railsTemplate(...)` classes materialize Rails-native ERB artifacts into generated output from Haxe-owned template bodies. `@:railsTemplateAst("render")` adds the first HXX-style typed template path: a static method returns `HtmlNode`, preferably authored as Rails HHX inline markup such as `return <div>${todo.title}</div>`. `RailsInlineMarkup` rewrites that markup into the same typed `HtmlNode`/`HtmlAttr` AST that `H` can build manually, Haxe validates embedded expressions/branch conditions/loop binders/partial locals/route helpers/form locals, and the compiler emits ERB. Current HHX tags include normal HTML, `${...}` text/attribute splices, `<if>`, `<for>`, `<link_to>`, `<partial>`, and the initial form-builder tags; helper labels can be static text or `${...}` child expressions, and `<link_to>` supports nested HHX via Rails block-form links. Raw ERB requires explicit `@:railsAllowRawErb`; the destination is a fuller typed Rails template layer inspired by `../haxe.elixir.codex`'s HXX/HEEx architecture.
