# RailsHx Client JavaScript And Genes

RailsHx uses Genes for its canonical Haxe-authored browser lane. Browser code is
not compiled by Reflaxe.Ruby, and the generated Rails app does not use Haxe's
stock JavaScript emitter for this lane.

The precise relationship is:

- the build still invokes Haxe's JavaScript target with `-js`, so Haxe parses,
  types, applies macros, performs dead-code elimination, and exposes `js.*`
  browser types;
- `genes.Generator.use()` registers Genes through Haxe's custom JavaScript
  generator API, so Genes performs the final code emission instead of Haxe's
  stock single-file emitter;
- Genes writes readable split ES6 modules that Rails can serve through
  importmap and Propshaft;
- the Ruby/Rails server build remains a separate `-lib reflaxe.ruby` compile.

Genes is therefore a compile-time JavaScript emitter, not a Ruby runtime, Rails
runtime, browser server, or second application framework.

## Build Architecture

```text
server Haxe / HHX
  -> -lib reflaxe.ruby
  -> Reflaxe.Ruby
  -> generated Ruby, Rails artifacts, and ERB

shared or client Haxe
  -> Haxe -js + -lib railshx.client
  -> genes.Generator custom emitter
  -> split ES modules under app/javascript/railshx
  -> hxruby importmap rewrite
  -> Rails importmap / Propshaft / browser
```

The two compiles can share browser-safe Haxe types and constants, but neither
loads the other's target compiler. In particular, `railshx.client` excludes the
Ruby compiler macros and `std/ruby/_std` overrides.

## The Generated-App Contract

The starter and todoapp share this `build-client.hxml` contract:

```hxml
-cp src_haxe
-lib railshx.client
-lib genes
-D js-es=6
--macro genes.Generator.use()
--macro addMetadata('@:genes.disableNativeAccessors', 'haxe.Exception')
-main client.Boot
-js app/javascript/railshx/app.js
-D source-map
-D js-unflatten
--dce=full
```

The todoapp also enables `--macro reflaxe.js.Async.enable()` because it uses
the parser-valid `@:await expression` convenience. The generated starter uses
the typed `await(expression)` helper directly, so it does not need that extra
syntax macro. Both forms emit native JavaScript `await` inside a Genes-emitted
`@:async` function.

`-lib railshx.client` supplies the shared/browser-safe RailsHx APIs, including
typed Turbo helpers and shared hooks. `-lib genes` resolves the vendored Genes
source. The `-js` path tells Haxe and Genes where to root the module graph.

Compile through the RailsHx task:

```bash
bundle exec rake hxruby:compile:client
```

The task sets `HXRUBY_GEM_ROOT`, invokes Haxe, and then rewrites Genes' relative
module imports such as `./shared/Hooks.js` to bare importmap specifiers such as
`railshx/shared/Hooks`. Rails can then digest nested modules without breaking
their imports. Generated apps pin the entry module and module tree from
`app/javascript/railshx` in `config/importmap.rb`.

Direct `haxe build-client.hxml` compilation emits the Genes graph but does not
perform the RailsHx importmap rewrite. Use the Rake task for a deployable Rails
asset tree unless an app deliberately owns an equivalent post-process.

## Why Genes Is The Default

- **Rails-friendly modules.** Split ES modules fit importmap/Propshaft better
  than one flattened generated file.
- **No mandatory JavaScript bundler.** A default Rails app can serve the module
  graph through its existing asset conventions.
- **Readable generated code.** Modules, imports, classes, and native browser
  calls remain easier to inspect and diagnose than a monolithic compiler blob.
- **Typed Haxe authoring.** Haxe still owns type checking, completion, macros,
  target guards, extern contracts, and dead-code elimination before Genes emits.
- **Native async/await.** Genes consumes `@:async`; RailsHx's typed
  `reflaxe.js.Async` helper lowers `@:await` or `await(...)` to normal JavaScript
  `await` without a RailsHx async runtime.
- **Normal Rails runtime ownership.** Turbo, ActionCable, importmap, Propshaft,
  the DOM, and browser APIs remain the runtime rather than a parallel client
  framework.
- **Server/client sharing where useful.** Typed payloads, enums, stream names,
  route/DOM hooks, and pure behavior can be shared while server-only and
  browser-only code stays separated by target boundaries.
- **Deterministic package setup.** RailsHx pins and vendors Genes `0.4.14`; the
  generated app does not depend on an ambient global Haxelib install.

Genes depends on `helder.set` `0.3.1` for compiler implementation support.
Neither dependency is loaded by the generated Ruby server at runtime.

## Why Not Reflaxe.Ruby Or The Stock Haxe Emitter?

Reflaxe.Ruby owns the Ruby target and cannot emit browser JavaScript. Client
code must use Haxe's JavaScript target or another JavaScript toolchain.

The stock Haxe JavaScript emitter is a valid general Haxe tool, but it is not
the canonical generated RailsHx client contract today. Its normal flattened
output needs a different Rails asset strategy, and Genes-specific features such
as the documented `@:async` emission and split-module graph would not apply.

An application may deliberately own another browser setup, including:

- the stock Haxe JavaScript emitter plus an app-owned bundler or asset mapping;
- plain JavaScript or TypeScript alongside RailsHx server code;
- a separate frontend application that consumes RubyHx/RailsHx APIs.

RailsHx does not require all browser code to be Haxe. Those alternatives are
valid application ownership choices, but the generated starter, importmap
rewrite, async helpers, examples, and production evidence specifically test the
Genes path. A different emitter or bundler needs its own build and runtime
tests rather than being treated as equivalent automatically.

The focused [`shared_domain`](../examples/shared_domain) example deliberately
owns one such separate test: it uses the stock emitter under Node only to compare
portable domain semantics with generated Ruby. It is not evidence that stock
emitter output is the RailsHx importmap asset contract; the todoapp's Genes,
browser, and production lanes continue to own that contract.

## Runtime Shape And Boundaries

Genes runs during compilation. Its output can include generated support modules
for Haxe semantics and module registration, but there is no Genes process in
production. Rails serves static ES modules, and the browser executes them.

Haxe-authored client code should remain progressive enhancement around normal
Rails and Hotwire behavior. If Rails can render a partial or Turbo Stream, keep
that rendering in typed HHX instead of rebuilding the same HTML in JavaScript.
Use client Haxe for genuinely browser-owned behavior such as DOM events,
navigation polish, local state, and typed custom protocols.

## Packaging And Upgrade Ownership

Both the Haxelib-compatible ZIP and `hxruby` gem contain the pinned
`vendor/genes/**` source. Generated apps resolve it through their scoped
`haxe_libraries/genes.hxml`, while `railshx.client.hxml` points at the packaged
browser-safe `std/` surface.

A Genes upgrade is a compiler-output change. It must retain source provenance,
rebuild exact client snapshots, validate the importmap rewrite, compile the
generated app, run the real browser sentinel, and pass the production asset
lane before the pinned version changes.

## Evidence

```bash
npm run test:examples-compile
npm run test:full-stack-shared-behavior
npm run test:todoapp-rails
npm run test:haxe-playwright
npm run test:rails-app-generator
npm run test:haxelib-package
npm run test:gem-package
rake todoapp:playwright
rake todoapp:production
```

See [RailsHx Turbo](railshx-turbo-guide.md) for the app-facing Hotwire APIs and
[RailsHx Full-Stack Hotwire](railshx-full-stack-hotwire-design.md) for shared
server/browser ownership boundaries.
