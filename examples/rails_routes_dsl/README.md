# RailsHx Route DSL Snapshot Fixture

This fixture is intentionally small and compiler-focused. It demonstrates the
Haxe-owned routing authoring surface without the rest of a Rails app.

## What It Proves

- `@:railsRoutes` plus `static final routes = { ... }` is the canonical
  Haxe-owned route declaration host.
- Typed controller/action refs such as `to(PostsController, index)` give
  completion and fail at Haxe compile time when an action is missing.
- Typed model refs such as `resources(Post, PostsController, ...)` let RailsHx
  derive the Rails resource name instead of repeating `"posts"`.
- Checked route literals cover optional path segments, glob segments, route
  helper aliases, regex constraints, mounted Rack app constants, and external
  Rails controller targets.
- The compiler emits normal Rails `config/routes.rb` and a
  `.railshx/routes.haxe.json` manifest; it does not emit a Ruby route runtime.

## Output

The committed snapshots live under:

- `test/snapshots/m1/rails_routes_dsl/config/routes.rb`
- `test/snapshots/m1/rails_routes_dsl/.railshx/routes.haxe.json`

Run the snapshot gate from the repository root:

```bash
rake test:snapshots
```

Use `examples/todoapp_rails` for the end-to-end Rails app workflow. This
fixture exists to keep the route compiler output focused and easy to review.
