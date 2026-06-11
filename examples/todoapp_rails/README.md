# RailsHx Todo App

This is the end-to-end RailsHx sample for `reflaxe.ruby`. It shows typed Haxe authoring for Rails code while keeping the generated Ruby recognizable to a Rails app.

## What The Sample Proves

- Haxe-authored ActiveRecord models with `@:railsModel`, typed `@:railsColumn(...)` metadata, associations, validations, and timestamps.
- Generated Rails model Ruby with `self.__hx_rails_schema` metadata for later query/migration tooling.
- Haxe-authored ActionController logic with typed model calls and `ParamsMacro.requirePermit(...)` strong-params generation.
- A polished Rails-owned Action View page for the current runnable sample.
- Generated route helper externs under `src_haxe/routes/Routes.hx`.
- A Rails migration template matching the Haxe model metadata.
- CI smoke coverage that compiles the Haxe app, checks generated Rails Ruby, and runs Rails runtime tests when local Rails gems are available.

## Source Layout

- `models/Todo.hx` and `models/User.hx` are RailsHx ActiveRecord models.
- `controllers/TodosController.hx` is a RailsHx controller using typed params and route helpers.
- `app/views/controllers/todos/index.html.erb` is the current Rails-owned presentation layer.
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

RailsHx also does not yet provide typed ActionView templates. The visual page is intentionally Rails-native ERB for now. The destination is a typed Rails template layer inspired by `../haxe.elixir.codex`'s HXX/HEEx architecture; that work is tracked by bead `haxe.ruby-wpi.12`.
