# reflaxe.ruby

`reflaxe.ruby` is a Reflaxe-based Haxe target that emits idiomatic Ruby and provides Rails-first typed APIs.

The current `1.32.0` baseline supports executable Ruby smoke fixtures, shared `hxruby` runtime files and gem packaging, Ruby interop metadata, and a Rails MVP with typed ActiveRecord models, ActionController helpers, params macros, routes generation, and scaffold tooling.

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
- `ruby.Symbol.of("ready")` lowers to `:ready`.

Raw `__ruby__` injection exists as an escape hatch, but examples and production-style code should prefer typed externs or std/runtime wrappers. The strict boundary defines enforce that policy.

## Rails Workflow

Rails mode is enabled with `-D reflaxe_ruby_rails`. It emits Haxe-owned app files under `app/haxe_gen`, plus:

- `config/initializers/hxruby_autoload.rb`
- Rails-friendly constant/file paths for Zeitwerk
- typed `rails.active_record.Base<T>` model classes
- generated ActiveRecord schema metadata via `Model.__hx_rails_schema`
- generated Rails migrations from Haxe-authored `@:railsMigration(...)` classes
- typed `rails.action_controller.Base` controller classes
- `ParamsMacro.requirePermit(...)` for strong params
- model metadata for `@:belongsTo`, `@:hasMany`, `@:hasOne`, and `@:validates`

The canonical RailsHx end-to-end example is `examples/todoapp_rails`.

Run the generated Rails todo app locally:

```bash
npm run todoapp:prepare
npm run todoapp:server
```

Then open `http://127.0.0.1:3000/`. For the RailsHx development loop, keep Rails running and start `npm run todoapp:watch` in another terminal; Haxe/HHX and Haxe-authored JS changes refresh the generated Rails files while Rails continues serving the app.

For a Rails app adoption scaffold, generate the RailsHx source layout, compile config, rake hook, and dev process files:

```bash
npm run rails:app -- --output path/to/rails-app --name MyApp
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

The current Rails surface is an MVP. The next Rails-first compiler layer is tracked as RailsHx; see [docs/railshx-roadmap.md](docs/railshx-roadmap.md) for the typed ActiveRecord, migration, controller, route, generator, and integration-test roadmap inspired by the Phoenix/Ecto implementation in `../haxe.elixir.codex`.

Useful tooling:

```bash
npm run rails:generate-routes -- --input routes.txt --output src_haxe/routes/Routes.hx
npm run rails:scaffold -- --model Todo --fields title:String,isCompleted:Bool --validate title --controller --output tmp/todo
npm run rails:app -- --output tmp/rails_app --name TodoApp
```

`npm run test:rails-integration` materializes a generated Rails app and always syntax-checks Ruby files. It runs `rails db:migrate` and `rails test` when Rails gems are installed; set `REQUIRE_RAILS=1` in CI environments where Rails runtime execution must be mandatory.

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

For the Rails runtime integration lane, install the Rails gems into the active rbenv Ruby:

```bash
gem install rails -v 7.2.3.1 --no-document
gem install sqlite3 -v 1.7.3 --no-document
rbenv rehash
REQUIRE_RAILS=1 npm run test:rails-integration
```

`npm test` will run the Rails integration app when these gems are available. `REQUIRE_RAILS=1` makes missing Rails gems a hard failure instead of a local-prerequisite skip.

## Quality Gates

```bash
npm test
npm run test:snapshots
npm run test:strict-boundaries
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
rake hxruby:compile
rake hxruby:compile:client
rake hxruby:watch
rake hxruby:watch:client
rake hxruby:gen:app
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
