# Ruby Stdlib Ownership

This repo keeps target stdlib work split by ownership and classpath behavior.

## Classpath Precedence

`CompilerBootstrap` prepends these directories for Ruby builds when they exist:

1. `std/_std`
2. `std`
3. `vendor/reflaxe/src`

That order is intentional. Overrides in `std/_std` must win over additive Ruby std surfaces in `std`, and both must be visible before Reflaxe compiler internals are typed.

## Layering Contract

RubyHx has two std-facing layers that intentionally compose:

- `std/_std/**` and `.cross.hx` files provide Haxe std semantics for portable
  Haxe code.
- `std/ruby/**` provides typed Ruby-shaped facades for Ruby libraries and runtime
  values.

Haxe std overrides may consume the lower-level RubyHx facades when that keeps the
implementation direct and typed. For example, `haxe.ds.*Map` uses
`ruby.NativeHashData<K, V>` internally so map implementations emit ordinary Ruby
`Hash` operations without exposing a broad `Dynamic` hash to Haxe callers.

Those RubyHx facades are also valid public authoring surfaces for developers who
want a typed Ruby layer instead of a Haxe-stdlib-first abstraction. Keep that
surface typed with generics, abstracts, externs, typedefs, or narrow unchecked
wrappers; do not make Ruby-shaped APIs loose just because they are closer to the
target runtime.

## `std/`

Use `std/` for additive Ruby target surfaces:

- Ruby-native externs and facades, for example `ruby/File.hx` or `ruby/JSON.hx`.
- Haxe std surfaces that can be implemented without replacing upstream modules wholesale, for example `StringTools.cross.hx`.
- Target-owned helper APIs under `reflaxe/ruby/**`.
- Cross-target-style `.cross.hx` files when the implementation is intentionally target-specific but does not need upstream classpath replacement.

Files in `std/` should not shadow upstream Haxe std modules unless the replacement is deliberate and documented in `docs/stdlib-inventory.json`.

## `std/_std/`

Use `std/_std/` only for upstream Haxe std overrides that must take precedence:

- `haxe/ds/*` map implementations when Ruby runtime semantics differ from upstream assumptions.
- `haxe/io/*` surfaces that require Ruby-backed bytes, streams, or file behavior.
- `sys/*` and `sys/io/*` modules once Ruby filesystem/process support exists.

Any new file in `std/_std/` must have an inventory entry with `"owner": "std/_std"` and a reason.

## `runtime/`

Use `runtime/hxruby/` for Ruby files copied or required by generated output:

- Shared runtime classes such as `HxException`.
- Data/enum compatibility helpers.
- Future array/string/hash dynamic helpers that should not be duplicated per generated file.

Compiler-generated one-off shims are allowed during bring-up, but stable runtime behavior should move into `runtime/hxruby/` and be tracked in the inventory.
Keep these helpers namespaced under `HXRuby` unless there is a documented reason
to patch a Ruby core class. For example, Haxe `String.substr` needs UTF-16-style
code-unit overlap semantics for some upstream stdlib cases, so the compiler
routes it through `HXRuby.string_substr(...)` instead of adding methods to
Ruby's `String`.

## Upstream `unitstd` Runtime Parity

The Ruby target carries a curated copy of upstream Haxe
`tests/unit/src/unitstd/**/*.unit.hx` fixtures under
`test/upstream_unitstd/upstream`. These fixtures are provenance-tracked in
`test/upstream_unitstd/manifest.json` and synchronized from the local reference
checkout with:

```bash
scripts/sync-upstream-unitstd-specs.sh
```

Run the Ruby parity lane with:

```bash
npm run test:unitstd-ruby
```

This lane complements snapshots and inventory checks. Snapshots prove generated
Ruby shape, `docs/stdlib-inventory.json` proves ownership, and upstream unitstd
fixtures prove selected Haxe std semantics actually execute on Ruby. When an
upstream fixture exposes a real target gap, prefer fixing the compiler/std/runtime
layer over editing the fixture. If a fixture must be adapted or skipped for a
Ruby-specific reason, record that decision in the manifest with a short reason.

The current baseline intentionally enables a focused set of fixtures and tracks
broader high-leverage fixtures separately. `Array`, `Date`, `EReg`,
`IntIterator`, `Lambda`, `List`, `Map`, `Math`, `String`, `StringBuf`,
`StringTools`, and `haxe.io.BytesBuffer` run directly; `Std` runs through an
adapted fixture because upstream assertion syntax and duplicate local names need
macro-lane accommodation.

Ruby's broader upstream stdlib candidate accounting lives in
`docs/ruby-stdlib-parity-audit.json` and the human summary in
`docs/ruby-stdlib-parity-audit.md`. The audit distinguishes covered Ruby-owned
surfaces, covered upstream fallbacks, unproven upstream fallback candidates,
Ruby override candidates, and unsupported or target-specific fixtures. Validate
it with:

```bash
npm run test:ruby-stdlib-parity-audit
```

Use that audit before creating new stdlib implementation beads so the next slice
promotes one fixture or facade deliberately instead of implying broad stdlib
completion.

`Lambda` is enabled as a direct upstream fixture. It locks in the Ruby-first
iterator bridge for native arrays plus Haxe iterator-bearing objects, and the
fixture adapter now uses explicit structural assertions for array literals so
compiler-level `Array` equality can remain Haxe identity semantics.

`List` is enabled as a direct upstream fixture. It proves the upstream Haxe
linked-list implementation can fall through unchanged on Ruby, including
mutation, string/join behavior, map/filter, and key/value iteration.

`Array` is enabled as a direct upstream fixture in the portable unitstd lane. It
exercises Ruby lowering for Haxe array mutation and copy semantics,
slice/splice/index bounds, comparator method references, dynamic Array calls,
anonymous object field reads inside callbacks, sparse resize contents, and
key/value iterator surfaces.

`Date` is enabled as a direct upstream fixture. It models Haxe `Date` with Ruby
`Time`, preserving local constructor/getter behavior, UTC getter behavior,
timezone offset sign, millisecond timestamps, and the accepted Haxe
`fromString()` input shapes.

`EReg` is enabled as a direct upstream fixture. It wraps Ruby `Regexp` while
preserving Haxe stateful match accessors, `matchSub` offsets, global versus
non-global split/replace/map behavior, capture expansion with `$1`/`$$`, and
`EReg.escape()`.

`Map` is enabled as a direct upstream fixture. `StringMap` and `IntMap` use
normal Ruby `Hash`; `ObjectMap` uses `Hash#compare_by_identity` to preserve Haxe
object-key identity while retaining Ruby insertion-order iteration.

## Current Baseline

The repo now has committed stdlib and runtime surfaces for the Ruby/Rails MVP:

- `runtime/hxruby/*` shared runtime helpers.
- `std/ruby/*` Ruby interop helpers.
- `std/rails/*` Rails model/controller/params surfaces.
- `std/_std/haxe/ds/*` and `std/_std/haxe/io/*` target-owned std overrides.

Run:

```bash
npm run test:stdlib-inventory
npm run test:unitstd-ruby
```

to validate the inventory schema, that committed std/runtime files are
represented, and that the curated upstream runtime fixture lane still passes.
