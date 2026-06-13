# RailsHx Engines And Plugins Guide

RailsHx engine/plugin support starts with a conservative contract:

- Engine or gem authors keep Haxe/HHX as source.
- Generated Ruby lands in a Rails-recognizable output root.
- Rails loads generated constants through normal autoload/eager-load paths.
- Host apps consume generated Ruby as ordinary Rails/Ruby constants, or through
  typed Haxe extern/adoption contracts when Haxe code calls back into the host.

This is not a separate engine DSL. Rails remains the packaging, routing, and
autoloading authority.

## Engine-Local Output Root

Use `reflaxe_ruby_rails_output_root` when generated code should live under an
engine/plugin subtree instead of the app default `app/haxe_gen`:

```hxml
-lib reflaxe.ruby
-D ruby_output=.
-D reflaxe_runtime
-D reflaxe_ruby_rails
-D reflaxe_ruby_rails_output_root=engines/blog/app/haxe_gen
-cp engine_haxe
--macro reflaxe.ruby.CompilerBootstrap.Start()
--macro reflaxe.ruby.CompilerInit.Start()
-main Boot
```

The compiler emits:

```text
engines/blog/app/haxe_gen/**
config/initializers/hxruby_autoload.rb
run.rb
```

The initializer points Rails at the configured root:

```ruby
hxruby_root = Rails.root.join("engines/blog/app/haxe_gen")
Rails.application.config.autoload_paths << hxruby_root
Rails.application.config.eager_load_paths << hxruby_root
```

For a real packaged engine, keep this initializer in the engine/dummy app shape
that matches how the engine is tested and shipped. The generated Ruby remains
normal namespaced Ruby code, so an engine can also add the generated root from
its own `Engine < Rails::Engine` class if that is the project convention.

## Generator Install Path

The Rails-native install generator accepts the same root:

```bash
bin/rails generate hxruby:install BlogEngine \
  --source engine_haxe \
  --main Boot \
  --rails-output-root engines/blog/app/haxe_gen
```

The rake wrapper uses `RAILS_OUTPUT_ROOT`:

```bash
RAILS_OUTPUT_ROOT=engines/blog/app/haxe_gen bundle exec rake hxruby:gen:app
```

Both write `build.hxml` with the matching
`-D reflaxe_ruby_rails_output_root=...` define.

## Host App Consumption

When a host Rails app consumes an engine/plugin that ships generated RailsHx
Ruby, it should consume it like hand-written Ruby:

```ruby
BlogEngine::Services::EngineGreeting.message("host app")
```

When Haxe code in the host calls engine/plugin Ruby, model the boundary as a
typed extern or adoption wrapper:

```haxe
@:native("BlogEngine::Services::EngineGreeting")
extern class EngineGreeting {
	public static function message(name:String):String;
}
```

That gives host Haxe code IntelliSense and compile-time arity/type checks while
the generated Ruby still calls the normal engine constant.

## Fail-Closed Path Policy

Compiler and generator path options are checked by default:

- absolute paths are rejected;
- `..`, `.`, empty segments, backslashes, and duplicate separators are rejected;
- use a project-relative Rails path such as `app/haxe_gen`,
  `engines/blog/app/haxe_gen`, or `lib/my_engine/haxe_gen`.

This keeps generated engine/plugin artifacts inside the project checkout and
gives clear feedback to humans and LLM-assisted workflows when a path is wrong.

## Smoke

Run the focused lane:

```bash
npm run test:rails-engine
```

It verifies engine-local output, generated autoload configuration, generated
Ruby syntax/execution, app generator `--rails-output-root`, and unsafe path
failures.

