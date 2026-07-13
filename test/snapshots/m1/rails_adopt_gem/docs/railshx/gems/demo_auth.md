# RailsHx Gem Layer: demo_auth

- Gem: `demo_auth`
- Version: `0.1.0`
- Metadata source: Bundler app Gemfile plus parsed Ruby source and automatically discovered YARD tags.
- Runtime owner: the Ruby gem and Bundler.
- Haxe owner: app-local reviewed extern/contracts under `src_haxe/interop/gems/demo_auth`.

## Constants Found

- `DemoAuth`
- `DemoAuth::ControllerHelpers`
- `DemoAuth::SessionManager`

## Generated Contract Sources

- `DemoAuth::ControllerHelpers`: Ruby-shape skeleton; `Dynamic` placeholders remain explicit review boundaries until deterministic type metadata is available.
- `DemoAuth::SessionManager`: strict deterministic YARD contract; supported signatures are precise and uncertain methods are omitted for review.

## Review Checklist

- Strict YARD contracts never synthesize broad fallback types; review omitted-method comments and add deterministic metadata before exposing those APIs.
- Replace any generated `Dynamic` placeholders with precise Haxe types where the app relies on that API.
- Keep runtime setup in Ruby/Rails: Gemfile, initializers, migrations, routes, and gem generators.
- Run `bundle exec rake hxruby:compile`, Rails tests, route parity, and browser/runtime gates relevant to this gem.
- Treat LLM-generated edits as reviewable patches; do not remove TODO/review markers without deterministic coverage.
