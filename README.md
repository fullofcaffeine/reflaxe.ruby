# reflaxe.ruby

`reflaxe.ruby` is a Reflaxe-based Haxe target that emits readable,
idiomatic Ruby from typed Haxe. It also includes RailsHx, a Rails-native typed
authoring layer for ActiveRecord, ActionController, ActionView/HHX, routing,
Turbo, ActionCable, generators, migrations, tests, and installed-gem companion
contracts such as DeviseHx.

The current `0.1.0-beta.2` baseline supports executable Ruby smoke fixtures,
shared `hxruby` runtime files and gem packaging, Ruby interop
metadata, typed extension/mixin contracts, and a RailsHx dogfood app with typed
models, relations, migrations, controllers, params, HHX templates, Haxe-owned
routes, Devise-backed sessions, Turbo Streams, Haxe-authored browser code,
Rails tests, Playwright, and production smoke coverage.

That baseline is the historical prerelease tag. Normal releases from `main`
use conventional `0.x` SemVer: fix commits advance patch, features and
major-zero breaking changes advance minor, and `1.0.0` plus each later stable
major require independent policy approval. Major zero already communicates
initial development, so the normal channel does not add a `-beta` suffix. See
[Release Version Policy](docs/release-version-policy.md).

There are two first-class layers:

- **RubyHx / pure Ruby**: compile Haxe to normal Ruby, consume Ruby gems through typed externs/contracts, author Ruby modules/concerns from Haxe, and keep generated Ruby readable to Ruby developers.
- **RailsHx**: a Rails-native typed authoring layer on top of the same Ruby compiler. Haxe/HHX is source of truth; Rails still owns runtime tasks such as `db:migrate`, `test`, Zeitwerk, and assets.

Rails is the flagship framework target because it is the dominant Ruby framework, but it is not the only intended use of `haxe.ruby`. Other framework layers can live in this monorepo or in separate repos that consume the published haxelib/gem and add their own typed std/macros/generators.

## Quick Start

Install repository dependencies and run the default compiler/test suite:

```bash
npm install
npm test
```

`npm test` is intentionally broad: it runs compiler snapshots, smoke tests,
example compilation, package checks, strict-boundary policy checks, and fast
RailsHx materialization checks. Full Rails runtime/browser/production lanes are
documented below.

Compile a Haxe entrypoint by setting `ruby_output` and loading the compiler macros:

```bash
haxe \
  -D ruby_output=out/ruby \
  -D reflaxe_runtime \
  -cp src \
  -cp examples/hello_world \
  -cp vendor/reflaxe/src \
  --macro "reflaxe.ruby.CompilerBootstrap.Start()" \
  --macro "reflaxe.ruby.CompilerInit.Start()" \
  -main Main

ruby out/ruby/run.rb
```

For a guided public entrypoint, start with:

- Pure Ruby: [examples/hello_world](examples/hello_world),
  [examples/ruby_callable_abi](examples/ruby_callable_abi) for typed blocks,
  keywords, forwarding, externs, and Ruby callers, [Ruby Extension
  Interop](docs/ruby-extension-interop.md), and
  [examples/ruby_extensions](examples/ruby_extensions).
- RailsHx: [examples/todoapp_rails](examples/todoapp_rails) for a full app, [examples/rails_routes_dsl](examples/rails_routes_dsl) for focused Haxe-owned route snapshots, and [examples/rails_interop_app](examples/rails_interop_app) for gradual adoption from existing Ruby/ERB.
- DeviseHx: [docs/railshx-devisehx-design.md](docs/railshx-devisehx-design.md) for the companion-layer design and [examples/todoapp_rails](examples/todoapp_rails) for the current app-local auth contract in a real Rails flow.
- Documentation map: [docs/README.md](docs/README.md).

Compiler lowering is fail-closed: a typed Haxe expression without an explicit
Ruby representation produces a source-positioned compiler diagnostic, never a
generated `nil`/TODO placeholder. See [Ruby Compiler Correctness](docs/compiler-correctness.md).

## Target Defines

- `ruby`: injected automatically for RubyHx builds, enabling conventional
  `#if ruby` target branches in application and library code.
- `ruby_output=<dir>`: output directory used by Reflaxe.
- `reflaxe_runtime`: emits/copies shared `hxruby` runtime helpers.
- `reflaxe_ruby_profile=ruby_first|portable`: declares the Ruby profile contract; default is `ruby_first`. The legacy `idiomatic` value remains accepted.
- `reflaxe_ruby_rails`: writes app-owned code under `app/haxe_gen` and emits a Rails autoload initializer.
- `reflaxe_ruby_rails_output_root=<path>`: overrides the Rails output root; default is `app/haxe_gen`. Use safe relative paths such as `engines/blog/app/haxe_gen` for engine/plugin output; see [RailsHx Engines And Plugins Guide](docs/railshx-engines-plugins-guide.md).
- `reflaxe_ruby_strict_examples`: rejects raw `__ruby__` injection in repo examples/snapshots.
- `reflaxe_ruby_strict`: rejects raw `__ruby__` injection in user/project sources.
- `reflaxe_ruby_strict_policy=auto|on|off`: policy hook for strict user boundaries.

See [Ruby Profiles](docs/profiles.md) for the profile contract: both profiles should emit idiomatic Ruby where safe, `portable` preserves Haxe semantics first, and `ruby_first` is the Ruby-first default. Profiles are semantic guardrails in one compiler pipeline, not separate backends.

## Ruby Interop

Interop is typed through metadata and small std surfaces:

The authoritative placement, arguments, lowering, interaction, diagnostic, and
safety contracts for all RubyHx/RailsHx compiler metadata live in
[`docs/compiler-metadata.md`](docs/compiler-metadata.md). CI rejects newly
recognized target metadata that is absent from that reference.
The symmetric call/definition rules for blocks, keywords, rest arguments,
method values, and forwarding are specified in the
[`Ruby Callable And Method ABI`](docs/ruby-callable-abi.md).

- `@:native("RubyName")` maps Haxe symbols to Ruby constants or methods.
- `@:rubyRequire("json")` emits `require "json"`.
- `@:rubyRequireRelative("./support/foo")` emits `require_relative "./support/foo"`.
- `@:rubyKwargs` is symmetric for calls and Haxe-owned definitions: its required
  typed fields become required Ruby keywords, optional fields preserve omission
  versus explicit `nil`, and stored carriers are projected through the declared
  schema so wider runtime objects cannot leak unknown keywords.
- `@:rubyBlockArg` maps one final typed callback symmetrically: call sites emit
  native blocks/`&callback`, while Haxe-owned definitions choose direct `yield`
  or captured `&block` from usage without exposing that Ruby detail to authors.
- Keyword/block metadata is inherited through overrides and interfaces.
  Direct calls remain wrapper-free; a genuine Haxe method-value capture emits
  one documented adapter and evaluates an effectful receiver exactly once.
- A final Haxe `haxe.Rest<T>` parameter emits Ruby `*args`; Haxe `...values`
  calls emit native Ruby splats without Ruby-specific rest metadata.
- Behavior-preserving Array calls that reach the backend use native Ruby
  `map`/`select` blocks. Stored callbacks and callbacks with non-tail Haxe
  returns remain strict lambdas passed with `&`; no `array_map` or
  `array_filter` runtime helper is emitted.
- `@:rubyMixin`, `@:rubyInclude`, `@:rubyPrepend`, and `@:rubyExtend` model Ruby module extension APIs as typed Haxe contracts while emitting normal Ruby `include`/`prepend`/`extend`.
- `@:rubyPatch(ReceiverType)` plus Haxe `using` models monkey-patched receiver APIs, including ActiveSupport-style extensions, as typed Haxe calls that lower to direct Ruby receiver dispatch.
- `@:rubyModule("Name")` and `@:rubyConcern("Name")` let Haxe author Ruby modules and ActiveSupport::Concern-style modules directly.
- `ruby.Symbol.of("ready")` lowers to `:ready`.
- `ruby.Pathname` provides typed, chainable Ruby path operations and emits
  `require "pathname"`, `Pathname.new(...)`, and direct receiver calls.
- `ruby.Dir` provides typed directory queries, globbing, and explicit
  process-working-directory changes while emitting direct core `Dir.*` calls
  without a require or wrapper.
- `ruby.FileUtils` provides typed single-path copy, move, creation, removal,
  touch, comparison, and freshness operations. Recursive deletion defaults to
  Ruby's TOCTTOU-resistant `remove_entry_secure` operation.
- `ruby.Tempfile.create*` provides typed resource-scoped callbacks that emit
  native Ruby blocks and deterministically close and unlink temporary files;
  explicit `ruby.Tempfile` values expose a documented `closeAndUnlink()` path.
- `ruby.BinaryFormat`, `ruby.ArrayPacking`, and `ruby.BinaryString` provide a
  checked binary interop seam: nominal pack/unpack directives keep Int and Float
  results aligned while generated Ruby remains direct `pack`, `byteslice`, and
  `unpack1` calls without `Dynamic` or raw injection.

Rails/ActiveSupport facades are typed std contracts over real Rails APIs:

```haxe
using rails.active_support.ObjectPresence;
using rails.active_support.StringFilters;

var normalized = "  Ship   typed Rails  ".squish();
var maybeTitle = normalized.presence();
if (maybeTitle.present()) trace(maybeTitle);
```

Generated Ruby requires the matching ActiveSupport core extension files and calls the patched receivers directly.

Raw `__ruby__` injection exists as an escape hatch, but examples and
production-style code should prefer typed externs, generated contracts, or
std/runtime wrappers. The strict boundary defines enforce that policy.

See [Ruby Extension Interop](docs/ruby-extension-interop.md) for examples ranging from simple module include/extend through existing gem wrapping, gradual adoption, Haxe-owned libraries, and metaprogramming-heavy contract generation. For installed Rails gems such as Devise, see [RailsHx Gem Layers](docs/railshx-gem-layers.md): Ruby/Bundler owns the runtime gem, while RailsHx provides typed contracts, macros, generators, and reusable companion packages when a gem is common enough. The reusable DeviseHx layer starts from the [folded design review](docs/railshx-devisehx-design.md), which was produced from the [GPT 5.5 Pro design prompt](docs/railshx-devisehx-gpt55-prompt.md).

## Rails Workflow

Rails mode is enabled with `-D reflaxe_ruby_rails`. It emits Haxe-owned app files under `app/haxe_gen`, plus:

- `config/initializers/hxruby_autoload.rb`
- Rails-friendly constant/file paths for Zeitwerk
- typed `rails.active_record.Base<T>` model classes
- generated ActiveRecord schema metadata via `Model.__hx_rails_schema`
- generated Rails migrations from Haxe-authored `@:railsMigration(...)` classes
- typed `rails.action_controller.Base` controller classes
- `ParamsMacro.requirePermit(...)` for strong params
- model metadata for `@:belongsTo`, `@:hasMany`, `@:hasOne`, `@:validates`, `@:railsEnum`, and typed callback metadata such as `@:beforeValidation`

The canonical RailsHx end-to-end example is `examples/todoapp_rails`. The mixed Rails adoption example is `examples/rails_interop_app`.

RailsHx is not a Rails replacement. Rails still owns runtime execution:
`bin/rails db:migrate`, `bin/rails test`, Zeitwerk, assets, ActionCable,
Devise/Warden, and app boot remain ordinary Rails. RailsHx owns typed Haxe/HHX
source, compile-time validation, generated Rails-shaped artifacts, and a better
developer workflow around those artifacts.

Run the generated Rails todo app locally:

```bash
rake todoapp:start
```

Then open `http://127.0.0.1:3000/`. The app now demonstrates a protected
Devise-backed board, guest sign-in, user-scoped todos, admin-only user
management, typed ActiveRecord relations, Haxe-authored HHX views,
Turbo Streams chat, Haxe-authored browser code, Rails request/model tests, and
Playwright UX checks.

For the RailsHx development loop, start the app with the integrated watcher:

```bash
rake todoapp:start:watch
# or:
WATCH=1 rake todoapp:start
# or:
rake 'todoapp:start[watch]'
```

That prepares the app once, runs Rails and the RailsHx watcher together, and refreshes generated Rails files when Haxe/HHX or Haxe-authored JS changes.

For a real-browser RailsHx smoke, run the Playwright sentinel lane:

```bash
rake todoapp:playwright
```

That prepares the generated Rails app, boots Rails on a dedicated port, runs `examples/todoapp_rails/e2e/*.spec.ts`, and tears the server down.
The browser lane also compiles the optional Haxe-authored Playwright spec from
`examples/todoapp_rails/e2e_haxe/**` into disposable ES-module specs under
`examples/todoapp_rails/e2e/generated/**`; vanilla TypeScript specs remain
first-class. For the lightweight compile/output-shape check without booting
Rails, run `npm run test:haxe-playwright`.

For the tutorial-style walkthrough of the generated skeleton and todoapp
patterns, see
[RailsHx Skeleton And Todoapp Tutorial](docs/railshx-skeleton-and-todoapp-tutorial.md).

For gradual adoption of an existing Rails app or a quick Ruby/ERB PoC, use typed boundaries instead of an all-at-once rewrite:

```bash
npm run test:rails-interop
```

That lane proves Haxe can render existing ERB through `Template.external("path") : Template<TLocals>`, call existing Ruby through typed externs, and let legacy ERB consume generated Haxe services/partials as normal Rails artifacts. See [docs/railshx-gradual-adoption.md](docs/railshx-gradual-adoption.md).

To force the generated Rails runtime apps to install their bundles and execute Rails tests, run:

```bash
rake test:rails:runtime
```

This is the mandatory runtime lane for Rails coverage across the supported Ruby matrix (`3.2`, `3.3`, `4.0`). Plain `rake test`/`npm test` keeps the compiler loop fast and still syntax-checks generated Rails artifacts; the Rails runtime lanes skip only when Rails gems are unavailable in a local environment. CI runs the underlying npm script, so missing generated-app Rails gems become hard failures there.

For a Rails app adoption scaffold, generate the RailsHx source layout, compile config, rake hook, dev process files, and a small typed starter app:

```bash
rake rails:app ARGS="--output path/to/rails-app --name MyApp"
```

The generated starter includes a typed `HomeController`, HHX layout, HHX home
page, Haxe-owned root route, route-helper extern placeholder, Haxe-authored
client JS, CSS/importmap wiring, app-local Rake tasks, `bin/railshx-*` helpers,
and `docs/railshx/gem_layers.md` for deterministic-first installed-gem
wrapping. Rails-facing generators are implemented in Ruby and exposed through
`bin/rails generate hxruby:*`, repository Rake wrappers, and installed-app
`hxruby` rake tasks, following the same host-framework-native generator lesson
as PhoenixHx Mix tasks. npm remains repo infrastructure for Lix, Playwright,
semantic-release, and Node-based CI scripts; the RailsHx user-facing path is
Rake/Rails.

In an installed Rails app, prefer the Rails generator entrypoints:

```bash
bin/rails generate hxruby:install MyApp
bin/rails generate hxruby:routes
bin/rails generate hxruby:controller Todos index show --templates
bin/rails generate hxruby:mailer UserMailer welcome
bin/rails generate hxruby:scaffold Todo title:String isCompleted:Bool --controller
bin/rails generate hxruby:scaffold Todo title:String --controller --skip-tests
bin/rails generate hxruby:adopt --service LegacyPriceFormatter --template legacy/badge --locals label:String,tone:String
bin/rails generate hxruby:adopt --service RbsPriceFormatter --rbs sig/rbs_price_formatter.rbs
bin/rails generate hxruby:adopt --schema --discover
bin/rails generate hxruby:adopt --schema --models Todo,User
bin/rails generate hxruby:adopt --migrations --discover
bin/rails generate hxruby:adopt --discover
```

Inside a generated RailsHx app, the recommended development flow is one command:

```bash
bundle exec rake hxruby:start
```

For the edit loop, run Rails and both Haxe watchers together:

```bash
bundle exec rake hxruby:start:watch
# or:
WATCH=1 bundle exec rake hxruby:start
# or:
bundle exec rake 'hxruby:start[watch]'
```

Generated apps also include `bin/railshx-dev`, which starts Rails, the server Haxe watcher, and the client Haxe watcher through `foreman` or `overmind` when either tool is installed. Without those tools it falls back to `bundle exec rake hxruby:start:watch`. If you need the lower-level pieces for CI debugging, use `bundle exec rake hxruby:compile`, `bundle exec rake hxruby:compile:client`, `bundle exec rake hxruby:watch`, and `bundle exec rake hxruby:watch:client` directly.

For Rails tasks that consume generated artifacts, use the RailsHx-prefixed
compile-then-delegate tasks:

```bash
bundle exec rake hxruby:db:migrate   # compile Haxe migrations, then rails db:migrate
bundle exec rake hxruby:db:prepare   # compile Haxe artifacts, then rails db:prepare
bundle exec rake hxruby:test         # compile server/client artifacts, then rails test
bundle exec rake hxruby:rails TASK=zeitwerk:check
bundle exec rake hxruby:doctor       # non-mutating health report for Haxe/build files/manifests
bundle exec rake hxruby:check        # compile and ruby -c generated Ruby
bundle exec rake hxruby:clean        # remove manifest-owned generated artifacts
```

Raw `bin/rails db:migrate`, `bin/rails test`, and other Rails tasks still work
when artifacts are already current. The `hxruby:*` variants are the safer daily
path because they refresh generated Ruby, ERB, migrations, route files, and
client JS before Rails consumes them.

Use `hxruby:doctor` when onboarding or debugging a generated app: it verifies
Haxe availability, build files, JSON manifests, Rails command availability, and
configured output roots without mutating the app. It also reports manifest output
drift/missing files, stale Haxe-owned route externs, duplicate Rails migration
timestamps/classes, and likely Haxe-authored client JS/importmap gaps. Use
`hxruby:check` in CI for a fast generated-artifact gate; add `CLIENT=1`,
`ROUTES=1`, or `ZEITWERK=1` when that CI lane should also compile Haxe-authored
JavaScript, sync route externs, or delegate to Rails' `zeitwerk:check`.

For production builds, compile Haxe/HHX before the normal Rails build/release steps so generated `app/haxe_gen/**`, generated ActionView templates, generated `db/migrate/**` files, and `config/initializers/hxruby_autoload.rb` exist in the release artifact:

```bash
bin/railshx-prod
# or, in CI/buildpacks:
RAILS_ENV=production bundle exec rake hxruby:production
```

`hxruby:production` runs the server Haxe compile, client Haxe compile, `rails zeitwerk:check`, and `rails assets:precompile` with production defaults. It intentionally fails closed if required Haxe build files are missing, so releases do not accidentally ship stale generated Ruby, ERB, migrations, or JavaScript.

The canonical dogfood app has a production smoke that exercises the same shape end to end:

```bash
rake todoapp:production
```

That command compiles Haxe/HHX, compiles Haxe-authored JS, materializes the generated Rails app, runs Rails migrations/tests, runs `zeitwerk:check`, precompiles production assets, creates `test/.generated/rails_integration_release.tgz`, and verifies the release artifact includes generated RailsHx files.

RailsHx satisfies the production-readiness gate for the documented major-zero
initial-development contract without making a stable `1.x` compatibility
promise. The readiness contract and required gates are documented in
[docs/railshx-production-readiness.md](docs/railshx-production-readiness.md).

The RailsHx work is tracked in [docs/railshx-roadmap.md](docs/railshx-roadmap.md), covering typed ActiveRecord, migrations, controllers, routes, generators, and integration tests inspired by the Phoenix/Ecto implementation in `../haxe.elixir.codex`. Start with [docs/railshx-generator-workflows.md](docs/railshx-generator-workflows.md) for app-facing generator commands, generated artifacts, runtime handoff, diagnostics, and CI gates. See [docs/railshx-generators-and-tasks-design.md](docs/railshx-generators-and-tasks-design.md) for the generated app skeleton and Rake/Rails task contract, [docs/railshx-routing-design.md](docs/railshx-routing-design.md) for Haxe-owned and Rails-owned route source-of-truth modes, [docs/railshx-controller-guide.md](docs/railshx-controller-guide.md) for typed controllers/params, [docs/railshx-action-mailer-guide.md](docs/railshx-action-mailer-guide.md) for typed ActionMailer classes and HHX mail templates, [docs/railshx-active-job-guide.md](docs/railshx-active-job-guide.md) for typed ActiveJob classes and enqueue helpers, [docs/railshx-active-storage-guide.md](docs/railshx-active-storage-guide.md) for typed ActiveStorage refs, [docs/railshx-turbo-guide.md](docs/railshx-turbo-guide.md) for typed Turbo client and server-side stream helpers, [docs/railshx-action-cable-guide.md](docs/railshx-action-cable-guide.md) for typed ActionCable channels/subscriptions, [docs/railshx-instrumentation-guide.md](docs/railshx-instrumentation-guide.md) for typed ActiveSupport instrumentation, [docs/railshx-components-guide.md](docs/railshx-components-guide.md) for typed Rails-native components, [docs/railshx-engines-plugins-guide.md](docs/railshx-engines-plugins-guide.md) for engine/plugin output roots and host-app consumption, [docs/railshx-gradual-adoption.md](docs/railshx-gradual-adoption.md) for mixed Ruby/ERB and Haxe adoption patterns, and [docs/railshx-haxe-authored-testing-design.md](docs/railshx-haxe-authored-testing-design.md) for the optional Haxe-authored Ruby/JS test-layer design.

Useful tooling:

```bash
rake rails:routes ARGS="--input routes.txt --output src_haxe/routes/Routes.hx"
rake rails:controller ARGS="Todos index show --templates --output tmp/todo"
rake rails:scaffold ARGS="--model Todo --fields title:String,isCompleted:Bool --validate title --controller --output tmp/todo"
rake rails:adopt ARGS="--service LegacyPriceFormatter --template legacy/badge --locals label:String,tone:String --output tmp/rails_app"
rake rails:app ARGS="--output tmp/rails_app --name TodoApp"
```

`rake test:rails:integration` materializes a generated Rails app and always syntax-checks Ruby files. It runs `rails db:migrate` and `rails test` when Rails gems are installed. `rake test:rails:runtime` sets `REQUIRE_RAILS=1`, installs generated app bundles when needed, and makes both Rails integration and mixed-interop runtime execution mandatory.

RailsHx routing supports both ownership directions. Existing Rails apps can keep Rails-owned `config/routes.rb` and generate typed Haxe externs from `rails routes`. Greenfield RailsHx apps can use Haxe-owned `@:railsRoutes` sources that emit normal `config/routes.rb`; Rails still remains the route-helper naming oracle by feeding `rails routes` back into `Routes.hx`. See [docs/railshx-routing-design.md](docs/railshx-routing-design.md) and the focused [examples/rails_routes_dsl](examples/rails_routes_dsl) snapshot fixture.

Devise routes follow the same principle. A Haxe-owned route file can declare
`DeviseRoutes.deviseFor(UserAuth.scope)` for the supported no-options MVP; the
compiler emits ordinary `devise_for :users`, validates the Devise mapping by
booting Rails, and still generates typed route helpers from actual
`rails routes` output. More complex Devise route options remain Rails-owned
until their typed DSL phases land.

## Compatibility

See [docs/compatibility-matrix.md](docs/compatibility-matrix.md).

The CI contract targets:

- Haxe `4.3.7`
- Node `20`
- Ruby `3.2`, `3.3`, and `4.0`

Local Ruby `2.6` can still run some non-Rails smoke tests, but it is not the supported runtime baseline for Rails-oriented work.

### Local Ruby Setup

Use `rbenv` for local Rails/compiler work. The repo pins Ruby with `.ruby-version`; install that version and initialize rbenv in your shell:

```bash
brew install rbenv ruby-build
rbenv install
eval "$(rbenv init - zsh)"
ruby -v
```

For mandatory Rails runtime integration, use the pinned Ruby and let the generated apps install their own bundles:

```bash
rake test:rails:runtime
```

`rake test`/`npm test` will run Rails runtime checks when generated app bundles are already available. `rake test:rails:runtime` makes missing Rails gems a hard failure and installs the generated bundles first, matching the dedicated CI lane. Runtime logs are stage-labeled (`compiler`, `materialization`, `migration`, `request tests`, and browser stages) so CI failures point at the failing boundary.

## Quality Gates

```bash
npm test
npm run test:examples-compile
rake format:haxe:check
rake security:gitleaks
rake test:snapshots
rake test:strict_boundaries
rake test:rails:runtime
rake ci:version_sync
rake ci:release_contracts
rake package:gem:test
```

Snapshot tests compile with `reflaxe_ruby_strict_examples`, compare committed
Ruby output, reject CRLF/trailing-newline/path leaks, and compile each snapshot
case twice to catch non-deterministic output.

`npm run test:examples-compile` compiles every `examples/*/Main.hx` entrypoint
and known example client builds, then verifies each example has an explicit
snapshot/smoke/runtime/browser coverage contract. This keeps examples useful as
living documentation and as an additional compiler QA lane.

Snapshots are the primary compiler/codegen contract: they show the exact Ruby,
ERB, JS, migration, initializer, and runtime-support artifacts that Rails/Ruby
users should be able to review as hand-written-looking output. Smoke tests are
supporting gates for focused invariants such as required files, syntax checks,
negative Haxe compile failures, package/generator flows, and thin Rails
consumption seams. Runtime Rails tests should prove that Rails can load/render/
migrate/deliver/subscribe to generated artifacts; they should not broadly
retest Rails itself unless RailsHx adds custom runtime behavior. See
[RailsHx Testing Strategy](docs/railshx-testing-strategy.md) for the
snapshot-vs-smoke decision rules.

### Local Hooks

Install the repo-managed pre-commit hook:

```bash
haxelib install formatter
brew install gitleaks # or use another gitleaks install method
rake hooks:install
```

The hook runs a staged `gitleaks` scan and formats staged `.hx` files with [haxe-formatter](https://github.com/HaxeCheckstyle/haxe-formatter). CI runs the full Haxe formatter check and a dedicated gitleaks workflow, so local hooks catch the same class of issues before review.

## Haxelib Package

Build the release zip locally with:

```bash
rake package:haxelib:build
```

Validate the package contents, compile the extracted `examples/hello_world`
fixture, and smoke-test an installed Ruby-target `-lib reflaxe.ruby` consumer
with:

```bash
rake package:haxelib:test
```

Semantic-release runs the same package builder during release preparation and attaches `dist/reflaxe.ruby-*.zip` to the GitHub release.

Packaging follows Reflaxe build conventions: source std overrides live in
`std/ruby/_std/**/*.hx`, while the release zip contains generated
`src/**/*.cross.hx` files produced by Reflaxe's build runner. Ruby's package
script is only a thin wrapper that adds Ruby/Rails extras after Reflaxe builds
`_Build`. Browser builds should use `-lib railshx.client` from the `hxruby`
gem/source layout, not the haxelib package's flattened Ruby-target
`.cross.hx` sources. See [Haxelib Packaging](docs/haxelib-packaging.md).

The incubated DeviseHx Haxe API currently ships inside this haxelib package
under `std/devisehx/**`. Its release contract is documented in
[DeviseHx Release Lane](docs/railshx-devisehx-release-lane.md): Rails apps keep
the Devise gem in their own Bundler environment, while `reflaxe.ruby` ships the
typed Haxe companion API and checks package contents in
`npm run test:haxelib-package`.

## Ruby Gem Package

Build the `hxruby` runtime gem locally with:

```bash
rake package:gem:build
```

Validate the gem contents, runtime require path, rake task registration, and local gem install behavior with:

```bash
rake package:gem:test
```

The gem exposes `require "hxruby"` for runtime helpers and `require "hxruby/tasks"` for Rails-oriented rake tasks:

```bash
bin/rails generate hxruby:install MyApp
bin/rails generate hxruby:routes
bin/rails generate hxruby:scaffold Todo title:String isCompleted:Bool --controller
bin/rails generate hxruby:adopt --service LegacyPriceFormatter --template legacy/badge --locals label:String,tone:String
bin/rails generate hxruby:adopt --service RbsPriceFormatter --rbs sig/rbs_price_formatter.rbs
bin/rails generate hxruby:adopt --schema --discover
bin/rails generate hxruby:adopt --schema --models Todo,User
bin/rails generate hxruby:adopt --migrations --discover
rake hxruby:compile
rake hxruby:compile:client
rake hxruby:db:migrate
rake hxruby:db:prepare
rake hxruby:db:rollback
rake hxruby:start
rake hxruby:start:watch
rake hxruby:routes
rake hxruby:doctor
rake hxruby:check
rake hxruby:clean
rake hxruby:test
rake hxruby:rails TASK=zeitwerk:check
rake hxruby:production
rake hxruby:watch
rake hxruby:watch:client
rake hxruby:gen:app
rake hxruby:gen:adopt SERVICE=LegacyPriceFormatter TEMPLATE=legacy/badge LOCALS=label:String,tone:String
rake hxruby:gen:adopt SERVICE=RbsPriceFormatter RBS=sig/rbs_price_formatter.rbs
rake hxruby:gen:routes
rake hxruby:gen:model MODEL=Todo FIELDS=title:String CONTROLLER=1
rake hxruby:gen:mailer MAILER=UserMailer ACTION=welcome
rake hxruby:gen:template PATH=controllers/todos/_card LOCALS=title:String,count:Int
rake hxruby:gen:test NAME=models/todo
```

Greenfield app/scaffold generators default to Haxe-owned routes. Pass
`--routes=haxe|snippet|rails|none` to choose the route source-of-truth mode:
`haxe` emits typed `@:railsRoutes`, `rails` keeps route helper extern generation
for an existing Rails-owned `config/routes.rb`, `snippet` writes reviewable
instructions, and `none` leaves route files untouched.

Scaffolds also generate a small Haxe-authored Rails model test by default under
`test_haxe/**`. The Haxe test compiles through `@:railsTest` into normal
Minitest output under `test/generated/**`, so the starter app exercises both
typed source and Rails-native test artifacts. Use `--skip-tests` only when an
existing test layout owns that boundary already.

When `--controller` is enabled, the scaffold composes the controller generator's
typed HHX view path too: the index action renders `Template.of(IndexView)` with
typed locals, and the compiler emits ordinary Rails ERB under `app/views/**`.

Plain `require "hxruby"` has no gem runtime dependencies. The task entrypoint requires `rake`, which is available in the supported CI Rubies and normal Rails applications.

RailsHx browser builds generated by the gem use `-lib railshx.client` plus
`-lib genes`. The client library resolves typed Hotwire/Turbo and
`reflaxe.js.Async` helpers from the browser-safe shared `std/` source shipped
with `hxruby`, while Ruby server builds keep using `-lib reflaxe.ruby`.

For DeviseHx, `hxruby` is the generator bridge rather than an auth runtime: it
exposes `bin/rails generate hxruby:adopt --gem devise`, writes deterministic
inventory/contracts/docs under app ownership, and does not add a Devise runtime
dependency to the `hxruby` gem. See
[DeviseHx Release Lane](docs/railshx-devisehx-release-lane.md) for the split
criteria before publishing a standalone `devisehx` or `hxruby-devise` package.

Semantic-release builds the gem during release preparation and attaches `dist/hxruby-*.gem` to the GitHub release.

## Gap Report

The std/runtime gap report is generated from `docs/stdlib-inventory.json`.
Upstream behavioral parity is tracked separately in
`test/upstream_unitstd/manifest.json`; the Ruby lane includes dedicated
StringMap, IntMap, ObjectMap, EnumValueMap, and Vector coverage while preserving
native Ruby Hash/Array storage.

```bash
npm run test:gap-report
UPDATE_GAP_REPORT=1 npm run test:gap-report
```

See [docs/gap-report-guidance.md](docs/gap-report-guidance.md) for how to update inventory entries and interpret remaining gaps.

## Repository Map

- `src/reflaxe/ruby`: compiler, build context, naming, macros, and Ruby AST printer.
- `std`: additive Ruby/Rails Haxe APIs and target std surfaces.
- `std/ruby/_std`: source-checkout upstream Haxe std overrides; packaged as `src/**/*.cross.hx` by Reflaxe build.
- `haxe_libraries/railshx.client.hxml`: browser-safe RailsHx client helper library used by generated Rails apps.
- `runtime/hxruby`: shared Ruby runtime helpers copied into generated output.
- `examples`: executable compiler/Rails fixtures.
- `scripts/ci`: smoke, snapshot, inventory, release, and hardening checks.
- `scripts/rails`: Rails-oriented generators.
- `scripts/hooks`, `scripts/lint`, `scripts/security`: local hook installer, Haxe formatter guard, and secret scanning wrapper.
- `test/snapshots`: committed generated Ruby contracts.
