# Why RubyHx

RubyHx is a typed way to author Ruby software without replacing the Ruby
runtime or ecosystem. The short version is:

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
a non-Ruby runtime:

- Haxe supplies static types, inference, algebraic enums, pattern matching,
  macros, editor tooling, and multiple compilation targets.
- RubyHx lowers that program to inspectable Ruby and models Ruby blocks,
  keywords, modules, mixins, patched receivers, exceptions, gems, and stdlib
  APIs through typed contracts.
- RailsHx moves Rails facts such as model fields, associations, params,
  templates, routes, migrations, and helper names into checked Haxe surfaces
  where practical, while emitting Rails-native artifacts.
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

## The Ruby Developer Value Proposition

| Need | RubyHx/RailsHx approach | What remains normal Ruby/Rails |
| --- | --- | --- |
| Add types where mistakes are expensive | Compile a selected service, domain module, library, or Rails feature from Haxe | Ruby callers invoke ordinary constants and methods |
| Modernize gradually | Wrap existing Ruby, ERB, gems, RBS, YARD, routes, and schemas through checked contracts | Existing source stays Ruby-owned until deliberately migrated |
| Catch framework drift earlier | Generate typed field, route, template, params, association, and helper references | Rails remains authoritative for runtime behavior and final artifacts |
| Reduce stringly repetition | Derive names and contracts with macros and generators | Output uses familiar Rails names, symbols, paths, and calls |
| Share selected full-stack behavior | Compile portable Haxe types and logic to Ruby and JavaScript | Server-only Rails code and browser-only DOM code stay target-specific |
| Keep the ecosystem | Consume installed gems through typed externs or generated companion contracts | Bundler and the gems still own installation and runtime semantics |
| Review and debug the result | Prefer direct, readable Ruby lowering and committed output snapshots | Ruby syntax checks, Rails tests, logs, and production tooling still apply |

The strongest positioning is not “Ruby is obsolete.” It is:

> RubyHx can be a better way to write the Ruby-bound parts of a system where
> types, compile-time framework checks, generated references, or cross-target
> reuse are worth more than the added build step.

That boundary may be one critical component, a new bounded context, a shared
domain package, a Rails engine, or an entire application. The rest can remain
Ruby.

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

## Full-Stack Sharing Without A Shared-Code Trap

Ruby/JavaScript applications commonly share OpenAPI, JSON Schema, GraphQL, or
generated client contracts. Those approaches are useful and remain valid with
RailsHx. They primarily share a protocol; they do not normally let ordinary
Ruby implementation source become browser JavaScript.

Haxe can share selected source across the Ruby and JavaScript targets, including
domain enums, serializable payload types, pure validation rules, formatting,
constants, state transitions, test fixtures, and typed DOM/route hooks. The
canonical todo application also proves that Haxe-authored server and browser
code can coexist in a normal Rails production build.

The boundary should stay deliberate:

- share deterministic domain behavior with a real two-target contract;
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
compiler should prefer native constructs—classes, modules, methods, blocks,
keywords, arrays, hashes, exceptions, `require`, Rails declarations, and direct
receiver calls—when they preserve the selected profile contract. Generated
Rails artifacts should look recognizable to a Rails developer and remain
consumable by Ruby-owned code.

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
explicit reviewed escapes—not `Dynamic` everywhere and not invented certainty.
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

The current public claim is **production-ready beta for the documented and
tested surface**. It means supported workflows have compiler, snapshot,
runtime, browser, production, packaging, and security evidence. It does not mean
the public API has a stable `1.x` compatibility guarantee or that every
production dimension has completed an independent stable-release audit.

Use these wording rules:

- Say **“emits readable, ordinary Ruby”**, not “has no runtime support.”
- Say **“adopts gradually”**, not “automatically types arbitrary Ruby.”
- Say **“moves supported Rails mistakes to compile time”**, not “makes Rails
  bugs impossible.”
- Say **“can share selected implementation across Ruby and JavaScript”**, not
  “Ruby and JavaScript cannot share anything today.”
- Say **“a better authoring option where its guarantees pay off”**, not “a
  universal replacement for Ruby.”
- Say **“production-ready beta for the documented surface”** until the stable
  `1.0` evidence gates are independently reviewed and closed.

Stable `1.0` is a compatibility and operating commitment, not a synonym for
“many features.” Its cross-dimensional gate is defined in
[RailsHx Production Readiness](railshx-production-readiness.md), and the
independent review packet lives in
[RubyHx/RailsHx GPT 5.6 Pro 1.0 Review](rubyhx-railshx-gpt56-1.0-review.md).

## Reusable Pitch

One sentence:

> RubyHx lets teams write typed Haxe and ship readable Ruby, adopting it one
> component or Rails feature at a time while keeping Ruby, Rails, Bundler, gems,
> and deployment workflows in charge at runtime.

Short form:

> RubyHx is a typed Ruby authoring path, not a replacement runtime. Use Haxe’s
> inference, enums, pattern matching, macros, and multi-target compiler to catch
> supported mistakes earlier and share selected browser/server behavior. The
> result is ordinary Ruby that works with existing code and gems. RailsHx adds
> typed Rails APIs and HHX while still emitting native Rails artifacts, so teams
> can start with one critical component, modernize an existing app gradually,
> or author a complete Rails application without abandoning the Ruby ecosystem.

## Evidence Entry Points

- [Ruby Compiler Correctness](compiler-correctness.md)
- [Ruby Callable And Method ABI](ruby-callable-abi.md)
- [Ruby Extension Interop](ruby-extension-interop.md)
- [Ruby Profiles](profiles.md)
- [RailsHx Gradual Adoption](railshx-gradual-adoption.md)
- [RailsHx Testing Strategy](railshx-testing-strategy.md)
- [RailsHx Production Readiness](railshx-production-readiness.md)
- [Compatibility Matrix](compatibility-matrix.md)
- [`examples/ruby_callable_abi`](../examples/ruby_callable_abi)
- [`examples/rails_interop_app`](../examples/rails_interop_app)
- [`examples/todoapp_rails`](../examples/todoapp_rails)
