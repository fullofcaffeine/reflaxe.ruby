<h1 align="center">reflaxe.ruby</h1>

<p align="center">
  <strong>Write typed Haxe. Ship ordinary Ruby.</strong><br>
  A typed Ruby authoring path and a Rails-native framework layer, without a new runtime.
</p>

<p align="center">
  <a href="https://github.com/fullofcaffeine/reflaxe.ruby/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/fullofcaffeine/reflaxe.ruby/actions/workflows/ci.yml/badge.svg?branch=main"></a>
  <img alt="Maturity: production-ready beta" src="https://img.shields.io/badge/maturity-production--ready_beta-7c3aed">
  <img alt="Haxe 4.3.7" src="https://img.shields.io/badge/Haxe-4.3.7-ea8220?logo=haxe&logoColor=white">
  <img alt="Ruby 3.3, 3.4, and 4.0" src="https://img.shields.io/badge/Ruby-3.3_%7C_3.4_%7C_4.0-cc342d?logo=ruby&logoColor=white">
  <a href="LICENSE"><img alt="GPL-3.0 license" src="https://img.shields.io/badge/license-GPL--3.0-2563eb"></a>
</p>

<p align="center">
  <a href="docs/why-rubyhx.md">Why RubyHx?</a> ·
  <a href="#try-it">Try it</a> ·
  <a href="#railshx">RailsHx</a> ·
  <a href="docs/railshx-gradual-adoption.md">Gradual adoption</a> ·
  <a href="docs/getting-started.md">Getting started</a> ·
  <a href="docs/README.md">Docs</a>
</p>

`reflaxe.ruby` compiles typed Haxe to readable Ruby. **RubyHx** is the
framework-independent compiler and interop layer. **RailsHx** adds typed Rails
authoring while Rails remains the runtime.

You can add one typed Haxe island to an existing Ruby system. You can also go
Haxe-first: write nearly all application or library code in Haxe/HHX, emit Ruby
artifacts, and use the Ruby runtime, gems, Bundler, Rails, and deployment
ecosystem without making Ruby your day-to-day authoring language.

Keep Ruby, Rails, Bundler, gems, and deployment conventions. Add static types,
closed domain states, compile-time Rails checks, generated references, and
selected Ruby/JavaScript code sharing where they are worth the build step.

The deployable result is Ruby source, not a hidden VM or parallel app server.
When Haxe semantics need support, they use explicit, versioned `hxruby` helpers.

## Why It Exists

- **Type the risky parts.** Start with one high-change service, domain module,
  Rails feature, or shared package; the rest can remain Ruby.
- **Make Haxe the primary language.** Build libraries, CLIs, or Rails
  apps almost entirely in Haxe/HHX when you want the Ruby ecosystem and runtime
  but prefer not to write much Ruby.
- **Catch drift earlier.** Supported fields, params, routes, templates,
  associations, migrations, and helpers become checked Haxe contracts.
- **Type the view layer.** Author Rails views in TSX-like HHX so markup,
  embedded expressions, locals, helpers, partials, routes, and form fields can
  fail during Haxe compilation before Rails renders ERB.
- **Adopt in either direction.** Ruby can call Haxe-generated Ruby, while Haxe
  can consume existing Ruby, gems, RBS, YARD, routes, schemas, and ERB.
- **Type native Ruby APIs.** Supported Ruby core and stdlib contracts remain
  direct Ruby calls while Haxe supplies completion and compile-time checking.
- **Share behavior, not just schemas.** Suitable types and pure logic can compile
  to both Ruby and JavaScript; target-specific code stays at the edges.
- **Keep the output recognizable.** Ruby blocks, keywords, modules, mixins,
  exceptions, Rails declarations, and native library calls stay Ruby-shaped.

RubyHx is not “Ruby is obsolete.” It supports both selective adoption inside a
Ruby system and Haxe-first authoring. In either mode, the deployed target is
still Ruby, so Ruby familiarity remains useful for ecosystem integration,
operations, and debugging even when most source is Haxe.

## One Ruby Pipeline, Two Product Layers

| RubyHx | RailsHx |
| --- | --- |
| Pure Ruby target, Haxe std/runtime semantics, typed stdlib and gem interop, modules, concerns, blocks, keywords, and extension APIs. | Rails-native models, queries, controllers, params, routes, migrations, HHX views, Hotwire, jobs, mailers, storage, tests, and generators. |
| Useful for pure Ruby programs, libraries, CLIs, or one typed island inside Ruby. | Built on RubyHx; Rails still owns migrations, tests, Zeitwerk, assets, jobs, gems, and app boot. |

```text
server Haxe / HHX  →  reflaxe.ruby  →  Ruby + Rails + ERB       →  Ruby/Rails runtime
shared/client Haxe →  Haxe + Genes  →  Rails importmap modules  →  browser
```

## Start Where It Pays

| Goal | Start here |
| --- | --- |
| See Haxe compile and run as Ruby | [`examples/hello_world`](examples/hello_world) |
| Author a Ruby library or CLI primarily in Haxe | [`examples/rubyhx_cli`](examples/rubyhx_cli) |
| Expose native blocks, keywords, and methods to Ruby | [`examples/ruby_callable_abi`](examples/ruby_callable_abi) |
| Add Haxe to an existing Ruby/ERB app | [`examples/rails_interop_app`](examples/rails_interop_app) |
| Author a Rails app primarily in Haxe/HHX | [`examples/todoapp_rails`](examples/todoapp_rails) |
| Install packages or generate an app | [Packages And Installation](docs/packages-and-installation.md) |

No all-at-once rewrite is required.

## A Ruby-Native ABI From Typed Haxe

Haxe authors use an ordinary typed function parameter:

```haxe
class CallableApi {
  @:rubyBlockArg
  public static function direct(value:Int, block:Int->Int):Int {
    return block(value);
  }
}
```

Handwritten Ruby sees a normal block API:

```ruby
puts CallableApi.direct(4) { |value| value * 3 }
```

The compiler chooses native `yield` or captured `&block` from actual usage.
Haxe authors keep one typed contract; Ruby callers keep familiar Ruby syntax.
The executable example covers blocks, keywords, forwarding, optional callbacks,
method values, and Ruby stdlib block lifecycles without semantic runtime helpers.

## Try It

```bash
git clone https://github.com/fullofcaffeine/reflaxe.ruby.git
cd reflaxe.ruby
npm install
npm run test:hello-world
```

That compiles the smallest Haxe entrypoint, runs the generated Ruby, and checks
its real stdout. Continue with [Getting Started](docs/getting-started.md) for
direct compiler use, profiles, defines, package consumption, and Rails setup.

## RailsHx

RailsHx authors Haxe and HHX, then emits ordinary Rails-shaped artifacts:

- ActiveRecord models, typed relations, associations, validations, and scopes;
- controllers, lifecycle hooks, strong params, statuses, and route helpers;
- migrations, Haxe-owned routes, HHX-to-ERB views, layouts, and components;
- Turbo, ActionCable, jobs, mailers, storage, instrumentation, and DeviseHx;
- Haxe-authored browser code emitted by Genes as readable ES modules, plus
  Rails tests, Playwright, and production assets.

HHX gives server-rendered Rails views a TSX-like typed authoring experience.
Haxe parses the markup and type-checks embedded expressions, locals, helper
arguments, template refs, routes, and model/form fields, then emits normal ERB.
There is no client view runtime or hydration layer.

This can be the default authoring path, not only an incremental migration tool.
A Haxe-first team can keep nearly all owned application source in Haxe/HHX while
Rails, Ruby, Bundler, and gems continue to own runtime and deployment behavior.

Run the canonical app:

```bash
rake todoapp:start
```

The app proves a protected Devise-backed board, scoped data, typed Rails APIs,
HHX views, Turbo Streams chat, browser code, runtime tests, and a production
build. See the [todoapp tutorial](docs/railshx-skeleton-and-todoapp-tutorial.md)
or [RailsHx guides](docs/README.md#railshx-guides).

Existing apps can keep Ruby/ERB as source of truth and adopt typed boundaries
incrementally. See [Gradual Adoption](docs/railshx-gradual-adoption.md).

## Evidence, Not Just A Pitch

- Unsupported typed lowering fails with a source-positioned diagnostic instead
  of silently generating a placeholder.
- Exact Ruby/Rails/ERB/JS output is snapshot-tested and rebuilt twice for
  determinism.
- Every example compiles under one inventory gate and owns an output, negative,
  runtime, or browser contract.
- Ruby runtime, Rails runtime, Playwright, production-build, security, package,
  and reproducible-release lanes cover what snapshots cannot prove.
- The supported baseline is Haxe `4.3.7`, Node.js `>= 22.14.0` and `< 23`,
  and MRI Ruby `3.3`, `3.4`, and `4.0`. Ruby `3.3` is transitional through
  2027-03-31; Ruby `3.4` and `4.0` are the primary branches.
- RailsHx supports the Rails `8.1` line and exercises Rails `8.1.3` in canonical
  CI. Other Rails lines may work and warn as unverified rather than being blocked.

Read the [compiler correctness contract](docs/compiler-correctness.md),
[testing strategy](docs/railshx-testing-strategy.md), and
[compatibility matrix](docs/compatibility-matrix.md).

## Maturity

The current claim is **production-ready beta for the documented and tested
surface**. It is not yet a stable `1.x` compatibility promise.

Teams using it today should pin a release, use the tested matrix as the
maintained guarantee, and run the documented compiler, Rails, browser,
production, and package gates when validating newer combinations.

Stable `1.0` requires a cross-dimensional evidence review covering compiler and
runtime correctness, Ruby/Rails interop, UX/API stability, gradual adoption,
security, performance, debugging, upgrades, packaging, docs, and maintenance.

See [Production Readiness](docs/railshx-production-readiness.md) and the
[independent GPT 5.6 Pro review packet](docs/rubyhx-railshx-gpt56-1.0-review.md).

## Explore

| Topic | Guide |
| --- | --- |
| Product thesis and honest tradeoffs | [Why RubyHx](docs/why-rubyhx.md) |
| Setup, compiler defines, and first apps | [Getting Started](docs/getting-started.md) |
| Blocks, keywords, modules, gems, and extensions | [Ruby Interop](docs/ruby-extension-interop.md) |
| Typed Ruby core and standard-library APIs | [Ruby Stdlib Facades](docs/ruby-stdlib-facades.md) |
| Rails APIs and workflows | [RailsHx Docs](docs/README.md#railshx-guides) |
| TSX-like typed Rails views and HHX | [Typed Views](docs/railshx-typed-views.md) |
| Haxe-authored browser JS and Genes | [Client JavaScript](docs/railshx-client-javascript.md) |
| Server backtraces, generated ownership, and browser source maps | [Debugging](docs/debugging.md) |
| Release ZIP, gem, and verified installation | [Packages And Installation](docs/packages-and-installation.md) |
| Support, reporting, and maintenance ownership | [Support And Maintenance](SUPPORT.md) |
| Contributor gates and repository map | [Repository Development](docs/development.md) |
| Everything else | [Documentation Index](docs/README.md) |

## Development

```bash
npm test
```

The full Rails/browser/production stack and contributor workflow live in
[Repository Development](docs/development.md).

## License

[GPL-3.0](LICENSE)
