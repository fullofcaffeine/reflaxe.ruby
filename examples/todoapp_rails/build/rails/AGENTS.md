# Generated Rails App Instructions

This Rails app is generated from the RailsHx todoapp source in `examples/todoapp_rails/src/**`.

- Treat Haxe/HHX in `../../src/**` as the source of truth for controllers, models, routes, views, migrations, Haxe-authored tests, and Haxe-authored client/browser code.
- Treat this directory as deployable Rails output: inspect it freely, but make durable behavior changes in `../../src/**` or the RailsHx compiler/materializer.
- Generated Ruby/Rails files should look like idiomatic hand-written Rails code. Visible Haxe/compiler scaffolding, synthetic temp names, duplicated metadata, or `__hx_*` methods are bugs unless there is a very specific semantic/runtime reason.
- If generated scaffolding is genuinely unavoidable, the generated file must include a concise inline comment explaining why that code exists and what RailsHx feature owns or consumes it.
- Runtime files such as SQLite databases, logs, tmp files, storage, local bundles, and precompiled assets are local state and should not be committed.
- If generated Rails output looks wrong, update the Haxe source, compiler, or materializer, then run `npm run todoapp:compile` from the repository root.
