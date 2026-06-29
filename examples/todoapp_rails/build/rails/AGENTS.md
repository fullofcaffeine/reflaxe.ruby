# Generated Rails App Instructions

This Rails app is generated from the RailsHx todoapp source in `examples/todoapp_rails/src/**`.

- Treat Haxe/HHX in `../../src/**` as the source of truth for controllers, models, routes, views, migrations, Haxe-authored tests, and Haxe-authored client/browser code.
- Treat this directory as deployable Rails output: inspect it freely, but make durable behavior changes in `../../src/**` or the RailsHx compiler/materializer.
- Runtime files such as SQLite databases, logs, tmp files, storage, local bundles, and precompiled assets are local state and should not be committed.
- If generated Rails output looks wrong, update the Haxe source, compiler, or materializer, then run `npm run todoapp:compile` from the repository root.
