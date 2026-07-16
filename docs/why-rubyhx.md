# Why RubyHx

RubyHx is a typed way to author software for the Ruby ecosystem without
replacing its runtime. It supports two first-class directions: add Haxe
selectively to an existing Ruby system, or make Haxe/HHX the primary source
language and use Ruby mainly as the generated deployment target. The short
version is:

> **Write typed Haxe. Ship ordinary Ruby.**

RailsHx applies that model to Rails. Haxe and HHX provide the checked authoring
surface; the compiler emits normal Ruby, ERB, migrations, routes, and browser
JavaScript; Rails, Bundler, gems, and the deployment environment retain their
normal runtime responsibilities.

This document defines the product thesis and the claims the project can make.
It is intentionally more precise than marketing copy: a compelling pitch is
only durable when generated output, examples, compatibility policy, and CI can
keep proving it.

## The Product Thesis

Ruby is productive because it is expressive, cohesive, and supported by a rich
ecosystem. Its dynamic model is also a tradeoff in code where a team needs
strong refactoring guarantees, closed domain states, checked framework
metadata, or one implementation shared with a browser client.

RubyHx lets a team opt into those properties without moving the application to
a non-Ruby runtime or requiring Ruby to remain its main authoring language:

- Haxe supplies static types, inference, algebraic enums, pattern matching,
  macros, editor tooling, and multiple compilation targets.
- RubyHx lowers that program to inspectable Ruby and models Ruby blocks,
  keywords, modules, mixins, patched receivers, exceptions, gems, and stdlib
  APIs through typed contracts.
- RailsHx moves Rails facts such as model fields, associations, params,
  templates, routes, migrations, and helper names into checked Haxe surfaces
  where practical, while emitting Rails-native artifacts.
- Haxe-first teams can keep nearly all owned application or library source in
  Haxe/HHX while using the Ruby runtime, Bundler, gems, Rails, and established
  deployment infrastructure.
- Existing Ruby remains callable from Haxe, and generated Haxe remains callable
  from Ruby. Adoption can therefore be component-by-component rather than a
  rewrite.

The product is not a new VM, a Ruby compatibility server, or a framework that
reimplements Rails. It is a compiler and typed authoring layer whose runtime
result stays in the Ruby ecosystem.

## Names And Ownership

- **`reflaxe.ruby`** is the compiler package and Haxe target.
- **RubyHx** names the framework-independent product surface: the compiler,
  Ruby std/runtime support, typed interop, and Ruby authoring APIs.
- **RailsHx** is the Rails layer built on that same compiler pipeline.
- **`hxruby`** is the Ruby gem/tooling namespace used for runtime helpers,
  generators, and Rails tasks.

RubyHx must remain useful without Rails. RailsHx must remain Rails-native rather
than becoming a separate backend or application runtime.

## Two First-Class Starting Points

**Ruby-first adoption** starts with an existing Ruby or Rails system. A team can
compile one critical component from Haxe, wrap existing Ruby through typed
contracts, and migrate only where the extra guarantees repay the build step.

**Haxe-first authoring** starts with Haxe as the normal source language. A team
can build a Ruby library, CLI, or Rails application
with nearly all owned code in Haxe/HHX, then use generated Ruby artifacts with
the normal Ruby ecosystem. This is useful even for developers who do not enjoy
writing Ruby but want access to Ruby runtimes, gems, Rails, or deployment
platforms.

Haxe-first does not mean Ruby disappears. Generated output is Ruby, runtime
libraries and framework behavior remain Ruby-owned, and enough Ruby knowledge
to integrate gems, operate the application, and diagnose target-level failures
is still valuable. The promise is that writing Ruby can be uncommon in the
day-to-day authoring loop, not that the target ecosystem becomes invisible.

## The Value Proposition

| Need | RubyHx/RailsHx approach | What remains normal Ruby/Rails |
| --- | --- | --- |
| Add types where mistakes are expensive | Compile a selected service, domain module, library, or Rails feature from Haxe | Ruby callers invoke ordinary constants and methods |
| Prefer Haxe as the main language | Keep nearly all owned source in Haxe/HHX and generate Ruby libraries, CLIs, or Rails artifacts | Ruby runtimes, gems, Bundler, Rails, deployment, and target-level operations |
| Modernize gradually | Wrap existing Ruby, ERB, gems, RBS, YARD, routes, and schemas through checked contracts | Existing source stays Ruby-owned until deliberately migrated |
| Catch framework drift earlier | Generate typed field, route, template, params, association, and helper references | Rails remains authoritative for runtime behavior and final artifacts |
| Type server-rendered views | Author TSX-like HHX with typed locals, expressions, helpers, routes, fields, partials, and components | Rails still renders ordinary generated ERB through ActionView |
| Reduce stringly repetition | Derive names and contracts with macros and generators | Output uses familiar Rails names, symbols, paths, and calls |
| Share selected full-stack behavior | Compile portable Haxe types and logic to Ruby and JavaScript | Server-only Rails code and browser-only DOM code stay target-specific |
| Keep the ecosystem | Consume installed gems through typed externs or generated companion contracts | Bundler and the gems still own installation and runtime semantics |
| Use Ruby itself without untyped calls | Import supported `ruby.*` core and stdlib facades with completion and checked signatures | Native Ruby constants and libraries still own runtime behavior |
| Review and debug the result | Prefer direct, readable Ruby lowering and committed output snapshots | Ruby syntax checks, Rails tests, logs, and production tooling still apply |

The strongest positioning is not “Ruby is obsolete.” It is:

> RubyHx can be a better way to write the Ruby-bound parts of a system where
> types, compile-time framework checks, generated references, or cross-target
> reuse are worth more than the added build step.

That boundary may be one critical component, a new bounded context, a shared
domain package, a Rails engine, or an entire application. The rest can remain
Ruby, or Haxe can be the default for new owned source.

## Why Haxe Fits The Job

Haxe is statically typed, but it does not require every local expression to be
ceremonially annotated. Inference, structural anonymous records, first-class
functions, closures, properties, module-level declarations, algebraic enums,
and pattern matching support compact and expressive code. Macros can turn
checked application facts into generated references and diagnostics instead of
asking authors to repeat strings.

That does not make Haxe “Ruby with types,” and RubyHx should not pretend the
languages are identical. The useful affinity is at the programming-model level:

- both support an expressive object-oriented and functional blend rather than
  forcing one style;
- Haxe functions and closures map naturally onto Ruby callables, while
  `@:rubyBlockArg` preserves native Ruby block APIs where a block is the real
  ABI;
- typed keyword, rest, module, mixin, concern, and patched-receiver contracts
  let Haxe describe Ruby-shaped APIs without turning them into untyped calls;
- Haxe enums and pattern matching give closed domain states a concise form that
  generated Ruby can still represent clearly;
- the `ruby_first` profile chooses Ruby/Rails conventions when they conflict
  with portable Haxe semantics, while `portable` preserves Haxe behavior.

Compared with introducing TypeScript only at the browser edge, Haxe can cover
both sides of a selected boundary. The reason is not that JavaScript lacks
functions or that Ruby and JavaScript cannot share schemas. They can. The
additional capability is compiling the same suitable implementation source to
both Ruby and JavaScript when keeping behavior aligned is valuable.

## Typed Views Without A New View Runtime

RailsHx views use HHX, a TSX-like markup syntax embedded in valid Haxe. The
analogy is about authoring and tooling: markup and expressions live together in
one typed source file. The runtime model remains Rails. The compiler emits
ordinary `.html.erb`, and ActionView still owns escaping, helpers, partials,
layouts, rendering, caching, and request behavior.

This moves several common view failures earlier:

- malformed HHX structure and invalid Haxe syntax fail in the parser;
- embedded expressions, branch conditions, loop values, and typed locals fail
  during Haxe type checking;
- supported Rails helper tags validate argument types;
- typed template, route, model-field, params-field, and component references
  catch many rename and composition mistakes;
- editors can complete and refactor locals, model values, helpers, components,
  and shared hooks instead of treating an ERB body as loosely connected text.

Standard Rails ERB does not combine all of those checks in one static language
contract. Ruby and Rails have useful template parsers, linters, tests, and
third-party typing tools, but HHX can check the markup structure and the typed
Haxe expressions that produce it in the same compile.

HHX is still server-rendered Rails, not a virtual DOM or hydration framework.
It can therefore improve view authoring without adding a browser rendering
runtime or preventing Ruby-owned helpers and partials from participating.
Browser tests remain necessary for HTML semantics, accessibility, CSS, Turbo,
and runtime data that compilation cannot prove. See
[Typed Views And HHX](railshx-typed-views.md) for the exact guarantees and
limits.

## Full-Stack Sharing Without A Shared-Code Trap

Ruby/JavaScript applications commonly share OpenAPI, JSON Schema, GraphQL, or
generated client contracts. Those approaches are useful and remain valid with
RailsHx. They primarily share a protocol; they do not normally let ordinary
Ruby implementation source become browser JavaScript.

Haxe can share selected source across the Ruby and JavaScript targets. The
maintained [`shared_domain`](../examples/shared_domain) example is the current
substantive proof: one typed todo-draft module owns normalization, validation,
closed error data, and deterministic serialization, and seven common vectors
must produce byte-identical generated Ruby and JavaScript output. The canonical
todo application separately proves that Haxe-authored server and browser code
can coexist in a normal Rails production build.

That evidence supports selected deterministic behavior; it does not prove that
arbitrary application code, Rails persistence, or browser behavior is
isomorphic. Additional domain enums, payloads, state transitions, or formatting
rules need their own two-target vectors before they widen the maintained claim.

The canonical RailsHx browser lane uses the Haxe JavaScript target with Genes
installed as its custom emitter. Genes produces readable ES modules for Rails
importmap/Propshaft instead of the stock Haxe emitter's flattened output. This
client build is separate from Reflaxe.Ruby and optional for Ruby-only programs.
See [Client JavaScript And Genes](railshx-client-javascript.md).

The boundary should stay deliberate:

- share deterministic domain behavior with a real two-target contract such as
  [`shared_domain`](../examples/shared_domain);
- keep database, Rails lifecycle, filesystem, secrets, and other server-only
  concerns in Ruby-target modules;
- keep DOM, browser lifecycle, and client-library concerns in JavaScript-target
  modules;
- use wire schemas when sharing a contract is clearer than sharing an
  implementation;
- test both compiled targets instead of assuming portable source guarantees
  identical runtime behavior.

“One language where it helps” is the benefit. “Everything must be isomorphic”
is not the goal.

## What Ordinary Ruby Output Means

The compiler output is Ruby source that Ruby tools can parse and execute. The
compiler should prefer native constructs such as classes, modules, methods,
blocks, keywords, arrays, hashes, exceptions, `require`, Rails declarations,
and direct receiver calls when they preserve the selected profile contract.
Generated Rails artifacts should look recognizable to a Rails developer and
remain consumable by Ruby-owned code.

“Ordinary Ruby” does not promise zero support code in every program. Some Haxe
semantics need small, versioned `hxruby` helpers. Those helpers are explicit,
packaged, tested, and subject to the same compatibility and security gates as
the compiler. There is no alternate application runtime hidden underneath the
generated Ruby.

Readable generation matters for more than aesthetics. It supports code review,
Ruby syntax validation, Rails autoloading, runtime diagnosis, gradual adoption,
and trust from a team that still owns the deployed Ruby system. Exact generated
shape is therefore covered by snapshots, with runtime and browser tests proving
the seams that snapshots cannot.

## Adoption Modes

### Typed island in a Ruby application

Start with a high-change or correctness-sensitive component. Export a normal
Ruby constant and typed callable ABI, keep its callers in Ruby, and expand only
if the boundary proves useful.

### Typed consumer of existing Ruby

Keep existing services and gems in Ruby. Describe their public surface with
externs, extension contracts, RBS/YARD-backed adoption, or conservative
generated gem contracts. Ruby and Bundler remain the source of truth.

### Rails feature or bounded context

Own selected models, controllers, routes, migrations, and HHX views in Haxe.
Generate Rails-native files under explicit ownership rules and let the rest of
the application remain Rails-owned.

### Haxe-first Ruby library or CLI

Use Haxe as the source of truth for nearly all owned library and CLI code. Treat
generated Ruby as the deployable artifact, consume Ruby libraries through typed
contracts, and keep Ruby-specific adapters at explicit edges. Services and other
framework-independent application shapes can use the same compiler foundations,
but are not yet maintained reference workflows. Rails is optional in this mode.

### Greenfield RailsHx application

Use Haxe/HHX as the default source of truth, generated Rails files as build
artifacts, and the normal Rails runtime for migrations, tests, autoloading,
assets, jobs, mail, storage, and deployment.

### Shared server/browser package

Extract only the payloads and pure behavior that genuinely belong on both
targets. Compile them in both server and client gates and keep target-specific
adapters at the edges.

These modes can coexist. A team does not need to decide between “all Ruby” and
“all Haxe” before receiving value.

## Honest Costs And Non-Goals

RubyHx adds a compiler and build pipeline. Teams must learn enough Haxe to own
the source, pin and upgrade the target, and include generated-artifact checks in
CI and deployment. Generated-code debugging, stack-trace/source correlation,
compile times, runtime performance, memory use, and editor workflows must be
measured and documented rather than assumed.

Ruby metaprogramming can expose behavior that no static contract can infer
perfectly. RubyHx should use deterministic metadata, conservative externs, and
explicit reviewed escapes, not `Dynamic` everywhere or invented certainty.
Some highly dynamic code will remain clearer in Ruby.

RubyHx also has a smaller authoring ecosystem than Ruby. It should leverage
Ruby gems at runtime instead of recreating them, while reusable companion
packages and generated app-local contracts improve typed consumption over time.

The project does not promise that every Haxe library is Ruby-compatible, every
Ruby/Rails API already has a typed facade, every shared function belongs on two
targets, or generated Ruby is byte-for-byte what a particular human would have
written. Unsupported surfaces must fail clearly or remain explicitly outside
the documented contract.

## Maturity And Claim Policy

The current public claim is **stable `1.x` for the documented and tested
surface**. It means supported workflows have compiler, snapshot, runtime,
browser, production, packaging, security, and independent-review evidence, and
the classified public boundaries carry the `1.x` compatibility guarantee. It
does not mean every Ruby gem, Rails API, Haxe library, database, browser, or
deployment platform is supported.

Use these wording rules:

- Say **“emits readable, ordinary Ruby”**, not “has no runtime support.”
- Say **“adopts gradually”**, not “automatically types arbitrary Ruby.”
- Say **“moves supported Rails mistakes to compile time”**, not “makes Rails
  bugs impossible.”
- Say **“can share selected implementation across Ruby and JavaScript”**, not
  “Ruby and JavaScript cannot share anything today.”
- Say **“a better authoring option where its guarantees pay off”**, not “a
  universal replacement for Ruby.”
- Say **“stable `1.x` for the documented and tested surface”** and keep the
  support-matrix limits adjacent to broader production claims.

Stable `1.0` is a compatibility and operating commitment, not a synonym for
“many features.” Major 1 was approved only after the cross-dimensional gate in
[RailsHx Production Readiness](railshx-production-readiness.md) and the
[independent readiness review](reviews/rubyhx-railshx-1.0-readiness-review.md)
were reconciled with exact-SHA evidence.

## Reusable Pitch

One sentence:

> RubyHx lets teams write typed Haxe and ship readable Ruby, either one
> component at a time or with Haxe as the primary source language, while Ruby,
> Rails, Bundler, gems, and deployment workflows stay in charge at runtime.

Short form:

> RubyHx is a typed Ruby authoring path, not a replacement runtime. Use Haxe’s
> inference, enums, pattern matching, macros, and multi-target compiler to catch
> supported mistakes earlier and share selected browser/server behavior. The
> result is ordinary Ruby that works with existing code and gems. RailsHx adds
> typed Rails APIs and TSX-like HHX views while still emitting native Rails
> artifacts, so teams can catch supported controller, model, route, params, and
> view mistakes before runtime. Teams can start with one critical component,
> modernize an existing app gradually, or author a complete Rails application
> without abandoning the Ruby ecosystem.

## Evidence Entry Points

- [Ruby Compiler Correctness](compiler-correctness.md)
- [Ruby Callable And Method ABI](ruby-callable-abi.md)
- [Ruby Extension Interop](ruby-extension-interop.md)
- [Ruby Profiles](profiles.md)
- [RailsHx Gradual Adoption](railshx-gradual-adoption.md)
- [RailsHx Typed Views And HHX](railshx-typed-views.md)
- [RailsHx Client JavaScript And Genes](railshx-client-javascript.md)
- [RailsHx Testing Strategy](railshx-testing-strategy.md)
- [RailsHx Production Readiness](railshx-production-readiness.md)
- [Compatibility Matrix](compatibility-matrix.md)
- [`examples/ruby_callable_abi`](../examples/ruby_callable_abi)
- [`examples/rails_interop_app`](../examples/rails_interop_app)
- [`examples/todoapp_rails`](../examples/todoapp_rails)
