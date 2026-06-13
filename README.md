# reflaxe.ruby

`reflaxe.ruby` is a Reflaxe-based Haxe target that emits idiomatic Ruby and provides Rails-first typed APIs.

The current `1.37.0` baseline supports executable Ruby smoke fixtures, shared `hxruby` runtime files and gem packaging, Ruby interop metadata, and a Rails MVP with typed ActiveRecord models, ActionController helpers, params macros, routes generation, and scaffold tooling.

## Quick Start

```bash
npm install
npm test
```

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

## Target Defines

- `ruby_output=<dir>`: output directory used by Reflaxe.
- `reflaxe_runtime`: emits/copies shared `hxruby` runtime helpers.
- `reflaxe_ruby_profile=ruby_first|portable`: declares the Ruby profile contract; default is `ruby_first`. The legacy `idiomatic` value remains accepted.
- `reflaxe_ruby_rails`: writes app-owned code under `app/haxe_gen` and emits a Rails autoload initializer.
- `reflaxe_ruby_rails_output_root=<path>`: overrides the Rails output root; default is `app/haxe_gen`.
- `reflaxe_ruby_strict_examples`: rejects raw `__ruby__` injection in repo examples/snapshots.
- `reflaxe_ruby_strict`: rejects raw `__ruby__` injection in user/project sources.
- `reflaxe_ruby_strict_policy=auto|on|off`: policy hook for strict user boundaries.

See [Ruby Profiles](docs/profiles.md) for the profile contract: both profiles should emit idiomatic Ruby where safe, `portable` preserves Haxe semantics first, and `ruby_first` is the Ruby-first default. Profiles are semantic guardrails in one compiler pipeline, not separate backends.

## Ruby Interop

Interop is typed through metadata and small std surfaces:

- `@:native("RubyName")` maps Haxe symbols to Ruby constants or methods.
- `@:rubyRequire("json")` emits `require "json"`.
- `@:rubyRequireRelative("./support/foo")` emits `require_relative "./support/foo"`.
- `@:rubyKwargs` lowers trailing object literals into Ruby keyword args.
- `@:rubyBlockArg` lowers trailing function args into Ruby blocks.
- `@:rubyMixin`, `@:rubyInclude`, `@:rubyPrepend`, and `@:rubyExtend` model Ruby module extension APIs as typed Haxe contracts while emitting normal Ruby `include`/`prepend`/`extend`.
- `@:rubyPatch(ReceiverType)` plus Haxe `using` models monkey-patched receiver APIs, including ActiveSupport-style extensions, as typed Haxe calls that lower to direct Ruby receiver dispatch.
- `@:rubyModule("Name")` and `@:rubyConcern("Name")` let Haxe author Ruby modules and ActiveSupport::Concern-style modules directly.
- `ruby.Symbol.of("ready")` lowers to `:ready`.

Rails/ActiveSupport facades are typed std contracts over real Rails APIs:

```haxe
using rails.active_support.ObjectPresence;
using rails.active_support.StringFilters;

var normalized = "  Ship   typed Rails  ".squish();
var maybeTitle = normalized.presence();
if (maybeTitle.present()) trace(maybeTitle);
```

Generated Ruby requires the matching ActiveSupport core extension files and calls the patched receivers directly.

Raw `__ruby__` injection exists as an escape hatch, but examples and production-style code should prefer typed externs or std/runtime wrappers. The strict boundary defines enforce that policy.

See [Ruby Extension Interop](docs/ruby-extension-interop.md) for examples ranging from simple module include/extend through existing gem wrapping, gradual adoption, Haxe-owned libraries, and metaprogramming-heavy contract generation.

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

Run the generated Rails todo app locally:

```bash
npm run todoapp:prepare
npm run todoapp:server
```

Then open `http://127.0.0.1:3000/`. For the RailsHx development loop, keep Rails running and start `npm run todoapp:watch` in another terminal; Haxe/HHX and Haxe-authored JS changes refresh the generated Rails files while Rails continues serving the app.

For a real-browser RailsHx smoke, run the Playwright sentinel lane:

```bash
npm run test:todoapp-playwright
```

That prepares the generated Rails app, boots Rails on a dedicated port, runs `examples/todoapp_rails/e2e/*.spec.ts`, and tears the server down.

For gradual adoption of an existing Rails app or a quick Ruby/ERB PoC, use typed boundaries instead of an all-at-once rewrite:

```bash
npm run test:rails-interop
```

That lane proves Haxe can render existing ERB through `Template.external("path") : Template<TLocals>`, call existing Ruby through typed externs, and let legacy ERB consume generated Haxe services/partials as normal Rails artifacts. See [docs/railshx-gradual-adoption.md](docs/railshx-gradual-adoption.md).

To force the generated Rails runtime apps to install their bundles and execute Rails tests, run:

```bash
npm run test:rails-runtime
```

This is the mandatory CI lane for Rails runtime coverage. Plain `npm test` keeps the compiler loop fast and still syntax-checks generated Rails artifacts; the Rails runtime lanes skip only when Rails gems are unavailable in a local environment.

For a Rails app adoption scaffold, generate the RailsHx source layout, compile config, rake hook, and dev process files:

```bash
npm run rails:app -- --output path/to/rails-app --name MyApp
```

Rails-facing generators are implemented in Ruby and exposed through both npm convenience scripts and `hxruby` rake tasks, following the same host-framework-native generator lesson as PhoenixHx Mix tasks. The Haxe compiler is required to compile generated Haxe sources, not to run basic Rails adoption generators.

In an installed Rails app, prefer the Rails generator entrypoints:

```bash
bin/rails generate hxruby:install MyApp
bin/rails generate hxruby:routes
bin/rails generate hxruby:scaffold Todo title:String isCompleted:Bool --controller
bin/rails generate hxruby:adopt --service LegacyPriceFormatter --template legacy/badge --locals label:String,tone:String
bin/rails generate hxruby:adopt --service RbsPriceFormatter --rbs sig/rbs_price_formatter.rbs
bin/rails generate hxruby:adopt --discover
```

Inside a generated/adopted RailsHx app, the recommended development flow is:

```bash
bundle exec rake hxruby:compile
bundle exec rake hxruby:compile:client
bundle exec rails server
bundle exec rake hxruby:watch # in another terminal, or use bin/railshx-dev with foreman/overmind
bundle exec rake hxruby:watch:client # if not using bin/railshx-dev
```

For production builds, compile Haxe/HHX before the normal Rails build/release steps so generated `app/haxe_gen/**`, generated ActionView templates, generated `db/migrate/**` files, and `config/initializers/hxruby_autoload.rb` exist in the release artifact:

```bash
RAILS_ENV=production bundle exec rake hxruby:compile
RAILS_ENV=production bundle exec rake hxruby:compile:client
RAILS_ENV=production bundle exec rails zeitwerk:check
RAILS_ENV=production bundle exec rails assets:precompile
```

The current Rails surface is an MVP. The next Rails-first compiler layer is tracked as RailsHx; see [docs/railshx-roadmap.md](docs/railshx-roadmap.md) for the typed ActiveRecord, migration, controller, route, generator, and integration-test roadmap inspired by the Phoenix/Ecto implementation in `../haxe.elixir.codex`. See [docs/railshx-controller-guide.md](docs/railshx-controller-guide.md) for typed controllers/params, [docs/railshx-action-mailer-guide.md](docs/railshx-action-mailer-guide.md) for typed ActionMailer classes and HHX mail templates, [docs/railshx-active-job-guide.md](docs/railshx-active-job-guide.md) for typed ActiveJob classes and enqueue helpers, [docs/railshx-active-storage-guide.md](docs/railshx-active-storage-guide.md) for typed ActiveStorage refs, [docs/railshx-turbo-guide.md](docs/railshx-turbo-guide.md) for typed Turbo client helpers, [docs/railshx-action-cable-guide.md](docs/railshx-action-cable-guide.md) for typed ActionCable channels/subscriptions, [docs/railshx-instrumentation-guide.md](docs/railshx-instrumentation-guide.md) for typed ActiveSupport instrumentation, and [docs/railshx-gradual-adoption.md](docs/railshx-gradual-adoption.md) for mixed Ruby/ERB and Haxe adoption patterns.

Useful tooling:

```bash
npm run rails:generate-routes -- --input routes.txt --output src_haxe/routes/Routes.hx
npm run rails:scaffold -- --model Todo --fields title:String,isCompleted:Bool --validate title --controller --output tmp/todo
npm run rails:adopt -- --service LegacyPriceFormatter --template legacy/badge --locals label:String,tone:String --output tmp/rails_app
npm run rails:app -- --output tmp/rails_app --name TodoApp
```

`npm run test:rails-integration` materializes a generated Rails app and always syntax-checks Ruby files. It runs `rails db:migrate` and `rails test` when Rails gems are installed. `npm run test:rails-runtime` sets `REQUIRE_RAILS=1`, installs generated app bundles when needed, and makes both Rails integration and mixed-interop runtime execution mandatory.

Route sync is phase 1 routing support: Rails-owned `config/routes.rb` stays the source of truth, and RailsHx generates typed Haxe externs from `rails routes`. Haxe-owned route emission is intentionally deferred until route-helper sync is fully deterministic; see [docs/railshx-routing-design.md](docs/railshx-routing-design.md).

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
npm run test:rails-runtime
```

`npm test` will run Rails runtime checks when generated app bundles are already available. `npm run test:rails-runtime` makes missing Rails gems a hard failure and installs the generated bundles first, matching the dedicated CI lane.

## Quality Gates

```bash
npm test
npm run test:snapshots
npm run test:strict-boundaries
npm run test:rails-runtime
npm run ci:version-sync
npm run ci:release-contracts
npm run test:gem-package
```

Snapshot tests compile with `reflaxe_ruby_strict_examples`, compare committed Ruby output, reject CRLF/trailing-newline/path leaks, and compile each snapshot case twice to catch non-deterministic output.

## Haxelib Package

Build the release zip locally with:

```bash
npm run release:haxelib-package
```

Validate the package contents, compile the extracted `examples/hello_world` fixture, and smoke-test an installed `-lib reflaxe.ruby` consumer with:

```bash
npm run test:haxelib-package
```

Semantic-release runs the same package builder during release preparation and attaches `dist/reflaxe.ruby-*.zip` to the GitHub release.

## Ruby Gem Package

Build the `hxruby` runtime gem locally with:

```bash
npm run release:gem-package
```

Validate the gem contents, runtime require path, rake task registration, and local gem install behavior with:

```bash
npm run test:gem-package
```

The gem exposes `require "hxruby"` for runtime helpers and `require "hxruby/tasks"` for Rails-oriented rake tasks:

```bash
bin/rails generate hxruby:install MyApp
bin/rails generate hxruby:routes
bin/rails generate hxruby:scaffold Todo title:String isCompleted:Bool --controller
bin/rails generate hxruby:adopt --service LegacyPriceFormatter --template legacy/badge --locals label:String,tone:String
bin/rails generate hxruby:adopt --service RbsPriceFormatter --rbs sig/rbs_price_formatter.rbs
rake hxruby:compile
rake hxruby:compile:client
rake hxruby:watch
rake hxruby:watch:client
rake hxruby:gen:app
rake hxruby:gen:adopt SERVICE=LegacyPriceFormatter TEMPLATE=legacy/badge LOCALS=label:String,tone:String
rake hxruby:gen:adopt SERVICE=RbsPriceFormatter RBS=sig/rbs_price_formatter.rbs
rake hxruby:gen:routes
rake hxruby:gen:model MODEL=Todo FIELDS=title:String CONTROLLER=1
```

Plain `require "hxruby"` has no gem runtime dependencies. The task entrypoint requires `rake`, which is available in the supported CI Rubies and normal Rails applications.

Semantic-release builds the gem during release preparation and attaches `dist/hxruby-*.gem` to the GitHub release.

## Gap Report

The std/runtime gap report is generated from `docs/stdlib-inventory.json`.

```bash
npm run test:gap-report
UPDATE_GAP_REPORT=1 npm run test:gap-report
```

See [docs/gap-report-guidance.md](docs/gap-report-guidance.md) for how to update inventory entries and interpret remaining gaps.

## Repository Map

- `src/reflaxe/ruby`: compiler, build context, naming, macros, and Ruby AST printer.
- `std`: additive Ruby/Rails Haxe APIs and target std surfaces.
- `std/_std`: upstream Haxe std overrides that must take classpath precedence.
- `runtime/hxruby`: shared Ruby runtime helpers copied into generated output.
- `examples`: executable compiler/Rails fixtures.
- `scripts/ci`: smoke, snapshot, inventory, release, and hardening checks.
- `scripts/rails`: Rails-oriented generators.
- `test/snapshots`: committed generated Ruby contracts.
