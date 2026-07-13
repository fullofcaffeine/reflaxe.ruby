# Getting Started

This guide contains the setup and compiler details intentionally kept out of
the project README. Start with the source checkout when evaluating the current
major-zero release line; packaged installation is covered in
[Packages And Installation](packages-and-installation.md).

## Choose An Adoption Direction

- **Haxe-first:** use Haxe as the normal source language for a Ruby library,
  service, CLI, framework layer, or Rails application. Start with the smallest
  Ruby program and direct compiler setup below. For Rails, the todo application
  shows nearly all owned app source in Haxe/HHX.
- **Ruby-first:** keep an existing Ruby or Rails system authoritative and add a
  typed component or boundary. Start with Ruby interop or the gradual-adoption
  example below.

Both paths emit ordinary Ruby artifacts and use the normal Ruby runtime and
ecosystem. Haxe-first minimizes day-to-day Ruby authoring, but target-level Ruby
knowledge remains useful for gem integration, operations, and debugging.

## Prerequisites

The exact supported versions live in the
[Compatibility Matrix](compatibility-matrix.md). The current CI baseline is:

- Haxe `4.3.7`
- Node.js `22.14.0` with npm `10.9.2`
- Ruby `3.2`, `3.3`, or `4.0`

The Rails examples also need the generated app bundles. The mandatory Rails
runtime task installs them when needed.

## Try The Smallest Ruby Program

From a source checkout:

```bash
npm install
npm run test:hello-world
```

The command compiles [`examples/hello_world/Main.hx`](../examples/hello_world/Main.hx),
runs the generated Ruby entrypoint, and compares real stdout with the committed
fixture.

Run the broad default suite with:

```bash
npm test
```

## Compile A Haxe Entrypoint Directly

Set `ruby_output`, include the compiler and vendored Reflaxe source, load the
bootstrap/init macros, and select the Haxe main class:

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

ruby out/ruby/main.rb
```

For an installed Haxelib-compatible package, use `-lib reflaxe.ruby` instead of
source-checkout classpaths and macro wiring. See
[Haxelib Packaging](haxelib-packaging.md) for the exact consumer form.

## Compiler Defines

- `ruby`: injected automatically so application/library code can use
  conventional `#if ruby` target branches.
- `ruby_output=<dir>`: generated Ruby output directory.
- `reflaxe_runtime`: emits/copies required `hxruby` helpers.
- `reflaxe_ruby_profile=ruby_first|portable`: selects the semantic profile.
  `ruby_first` is the default; `idiomatic` remains a compatibility alias.
- `reflaxe_ruby_rails`: enables Rails artifact layout under `app/haxe_gen` and
  emits the Rails autoload initializer.
- `reflaxe_ruby_rails_output_root=<path>`: chooses a safe relative Rails output
  root, including engine/plugin layouts.
- `reflaxe_ruby_strict_examples`: rejects raw `__ruby__` injection in repository
  examples and snapshots.
- `reflaxe_ruby_strict`: rejects raw `__ruby__` injection in user/project
  sources.
- `reflaxe_ruby_strict_policy=auto|on|off`: controls the strict boundary policy.

See [Ruby Profiles](profiles.md) before choosing a non-default profile and
[Compiler Metadata](compiler-metadata.md) before using target metadata.

## Try Ruby Interop

The callable example proves Haxe-owned APIs can expose ordinary Ruby blocks,
keywords, forwarding, and method values to handwritten Ruby callers:

```bash
npm run test:ruby-callable-abi-example
```

Continue with:

- [`examples/ruby_callable_abi`](../examples/ruby_callable_abi)
- [Ruby Callable And Method ABI](ruby-callable-abi.md)
- [Ruby Extension Interop](ruby-extension-interop.md)
- [Ruby Stdlib Facades](ruby-stdlib-facades.md)

## Try RailsHx

To use RailsHx as a Haxe-first authoring path, prepare and run the canonical
generated Rails app:

```bash
rake todoapp:start
```

For the integrated edit loop:

```bash
rake todoapp:start:watch
```

The reference app demonstrates a workflow where nearly all owned application
source is Haxe/HHX: models, controllers, migrations,
routes, HHX views, Devise-backed auth, Turbo/ActionCable, Haxe-authored browser
code, Rails tests, Playwright, and a production build. See the
[RailsHx Skeleton And Todoapp Tutorial](railshx-skeleton-and-todoapp-tutorial.md).

To prove gradual adoption instead:

```bash
npm run test:rails-interop
```

That example keeps existing Ruby/ERB source authoritative while typed Haxe
consumes it and Ruby callers consume generated Haxe artifacts. See
[RailsHx Gradual Adoption](railshx-gradual-adoption.md).

## Generate Or Adopt An App

Rails-facing commands are normal Rails generators and Rake tasks. Common
entrypoints are:

```bash
bin/rails generate hxruby:install MyApp
bin/rails generate hxruby:scaffold Todo title:String isCompleted:Bool --controller
bin/rails generate hxruby:adopt --service LegacyPriceFormatter
bundle exec rake hxruby:start:watch
bundle exec rake hxruby:doctor
bundle exec rake hxruby:check
RAILS_ENV=production bundle exec rake hxruby:production
```

The complete command and ownership contract lives in
[RailsHx Generator Workflows](railshx-generator-workflows.md).

## Where To Go Next

- [Why RubyHx](why-rubyhx.md) for the product model and tradeoffs.
- [Docs Index](README.md) for all RubyHx/RailsHx guides.
- [Production Readiness](railshx-production-readiness.md) for supported scope
  and mandatory gates.
- [Packages And Installation](packages-and-installation.md) for release ZIP/gem
  consumption.
- [Repository Development](development.md) for contributor checks and layout.
