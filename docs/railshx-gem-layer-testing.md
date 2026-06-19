# RailsHx Gem-Layer Testing

Reusable RailsHx companion layers wrap Ruby gems without reimplementing them.
That means their tests should prove typed contract generation, compile-time
safety, generated artifact shape, and the seams where Rails consumes those
artifacts. They should not retest the gem's own runtime.

DeviseHx is the first production-grade example of this pattern, but the same
testing pyramid applies to future layers such as `sidekiqhx`, `pundithx`, or
framework-specific packages built on top of RubyHx.

## Core Principle

Test the RailsHx layer, not the Ruby gem.

For DeviseHx, Devise/Warden already own password hashing, session storage,
mailer behavior, mapping expansion, and route semantics. RailsHx should test
that it discovers Devise deterministically, emits sound Haxe contracts, lowers
typed Haxe calls into ordinary Devise/Rails code, and fails closed when the app
shape is ambiguous.

The useful split is:

- **Deterministic inventory tests** prove discovery is safe and conservative.
- **Snapshots** prove generated Haxe/Ruby/JSON/docs shape is stable and
  idiomatic.
- **Haxe compile and negative compile tests** prove the typed contract catches
  misuse.
- **Thin Rails runtime tests** prove Rails can consume the generated artifacts
  at real framework seams.
- **Dogfood browser tests** prove the user-visible integration works in one or
  two happy paths.

## Pyramid

### 1. Inventory And Generator Smoke

Use smoke tests for fail-closed adoption and generator behavior that snapshots
cannot prove by themselves.

Cover:

- gem missing from `Gemfile` / Bundler
- unsafe or missing gem path
- missing app files such as `config/routes.rb`, `db/schema.rb`, or expected RBS
  when the generator mode requires them
- supported deterministic discovery inputs
- unsupported dynamic app shapes producing review markers instead of confident
  contracts
- non-owned output collisions
- explicit `--write contracts` / `--force` / unsafe flags

DeviseHx examples:

- `devise_for :users` with no options is route-authorable.
- `devise_for :accounts, class_name: "User"` is not route-authorable until a
  typed option phase supports it.
- a missing `users.encrypted_password` column fails module/schema validation
  instead of generating a false-safe `UserAuth`.

### 2. Snapshots

Snapshots are the primary contract for generated shape. If a maintainer should
review the generated artifact, commit a snapshot for it.

Snapshot:

- generated app-local Haxe contracts such as `UserAuth.hx`
- generated typed externs and facades
- generated inventory JSON and diagnostics JSON
- generated route manifest entries
- generated Ruby output for lowered helper calls
- generated HHX/ERB output for companion helpers
- generated docs or review packets when the generator emits them

For DeviseHx, snapshots should show that `UserAuth.currentRequired(this)` lowers
to `current_user`, `beforeAction(UserAuth.authenticate)` lowers to
`before_action :authenticate_user!`, and `DeviseRoutes.deviseFor(UserAuth.scope)`
emits ordinary `devise_for :users` without inventing a Devise helper matrix.

### 3. Haxe Compile And Negative Compile Tests

Use Haxe compile tests to prove the public typed surface is useful before Rails
boots.

Positive tests should compile:

- generated scope tokens and helper facades
- lifecycle filters
- model metadata / mixin metadata
- typed route declarations
- typed HHX helpers
- typed test helpers

Negative tests should fail with source-positioned diagnostics:

- wrong scope in a controller
- `currentRequired` without a proven auth guard under strict mode
- unknown model field in params/sanitizer helpers
- unsupported gem options presented as if they were safe
- non-authorable adopted route mappings used in Haxe-owned routes
- missing generated metadata
- app-facing `Dynamic` at an unreviewed boundary

### 4. Thin Rails Runtime Tests

Runtime tests are seam tests. They prove Rails can boot, autoload, route,
render, migrate, and execute generated artifacts. They should not duplicate the
gem's own suite.

Use Rails runtime tests for:

- Zeitwerk/autoload consumption of generated Ruby
- generated routes and route helpers
- generated migrations and schema assumptions
- generated controllers calling real gem helpers
- generated HHX/ERB template lookup and locals
- generated test helper usage
- custom Rails integration points, such as ActionCable/Turbo/ActionMailer

For DeviseHx, a small runtime suite is enough for the core layer:

- unauthenticated request redirects to sign-in
- sign-in reaches a protected page
- sign-out clears access to a protected page
- generated `UserAuth` calls resolve to Devise helpers
- route externs generated from `rails routes` are usable from Haxe output

Do not test Devise password hashing, Warden internals, or every route generated
by every Devise module. Devise owns that. RailsHx should test its typed
integration with one representative flow and rely on snapshots/parity for
generated code shape.

### 5. Dogfood Browser Tests

Browser tests should be few and user-visible. They belong in a dogfood app once
the layer has enough behavior to show a realistic app path.

For DeviseHx, a dogfood browser app should cover:

- guest sees the designed login/sign-in path
- real sign-in reaches the protected RailsHx page
- sign-out returns to the protected-login flow
- optional guest/demo sign-in if the sample provides it
- one protected typed feature that uses the current user, such as todoapp
  per-user todos or admin-only user management

The canonical `examples/todoapp_rails` can carry the first DeviseHx sentinel.
A larger dedicated app can be added later for registrations, password reset,
confirmable, OmniAuth, multi-scope, and custom controller matrices.

## What Not To Test

Avoid broad tests that simply re-run the Ruby gem's own responsibilities:

- Devise/Warden password hashing implementation
- Rails route expansion matrices that Rails/Devise already own
- Sidekiq job execution semantics in a future Sidekiq companion
- Pundit policy semantics in a future Pundit companion
- Rails built-in form, mailer, or controller behavior unless RailsHx generated
  the artifact being consumed

If RailsHx introduces custom runtime code, then test that runtime code directly.
Otherwise prefer snapshots and seam tests over framework reimplementation tests.

## Release Gate For A Reusable Gem Layer

Before a RailsHx gem layer is called reusable, require:

- deterministic discovery smoke tests
- generated artifact snapshots
- Haxe positive and negative compile tests
- at least one Rails runtime seam test
- docs for ownership, unsafe boundaries, and LLM-assisted review
- escape-hatch audit entries for raw Ruby, unchecked routes, `Dynamic`, or
  generated guesses
- one dogfood example or an explicit bead explaining why the runtime/browser
  example is deferred

This keeps the package honest: typed Haxe improves the Ruby gem authoring
surface, while the original Ruby gem remains the runtime authority.
