# Ruby Stdlib R&D Plan

This document turns the current stdlib/runtime audit into a staged plan for
RubyHx. It complements `docs/stdlib-ownership.md`,
`docs/ruby-stdlib-facades.md`, `docs/gap-report-guidance.md`, and
`docs/stdlib-inventory.json`.

## Goal

RubyHx should make Haxe-authored Ruby code feel typed and normal while emitting
Ruby that is as direct as possible. The runtime is allowed, but it should stay a
compact semantic layer, not a default wrapper around Ruby core APIs.

The working rule is:

- Emit direct Ruby when Ruby already has the same contract.
- Use `HXRuby` when Ruby's contract would drift from Haxe semantics.
- Keep Rails/Ruby library facades typed and target-shaped where that helps
  interop, but prefer Haxe's type system, macros, and diagnostics over stringly
  mirrors.
- Check compiler-special lowerings and std shell implementations together.
  They are two entry points to the same public std method.

Recent examples:

- `Math.exp` can lower to `::Math.exp` because Ruby preserves the needed
  behavior and emitting a generated `Math.exp` shell would shadow Ruby's module
  method.
- `Std.int` can lower to `to_i` for typed floats because Ruby truncates toward
  zero there.
- `Std.random(max)` can lower to `max <= 0 ? 0 : rand(max)`.
- `Std.parseInt` and `Std.parseFloat` must use compact `HXRuby` helpers because
  Haxe parses valid numeric prefixes while Ruby `Integer(...)` and `Float(...)`
  parse whole strings.
- UTF-16-style string indexing, enum/type reflection, Haxe array boundary
  behavior, stable `Std.string`, and Haxe math domain/NaN behavior remain real
  runtime-helper territory.

## Current Inventory

Tracked std/runtime ownership lives in `docs/stdlib-inventory.json` and is
validated by:

```bash
npm run test:stdlib-inventory
npm run test:gap-report
```

Current implemented domains:

- Core runtime: `runtime/hxruby/core.rb`, `HxException`, and `Data.define`
  compatibility.
- Haxe core std: `Std`, `Math`, `Type`, `Array`, `Lambda`, `Date`, `EReg`,
  `Reflect`, `StringTools`, `Sys`, `haxe.Json`, `haxe.ds.*`,
  `haxe.io.Bytes`/`FPHelper`, `sys.FileSystem`, and `sys.io.File`.
- Ruby interop: `ruby.Symbol`, `ruby.Kernel`, `ruby.File`, `ruby.Json`,
  `ruby.Prelude`, `ruby.StandardError`, `NativeHash`, and `NativeIterator`.
- RailsHx and DeviseHx typed facades, macros, and generated runtime support.

Implemented domains that still need broader upstream parity accounting:

- `Reflect`
- `Type`
- `haxe.Json`
- `sys.FileSystem`
- `sys.io.File`
- `haxe.io.FPHelper`

Upstream unitstd coverage is curated in `test/upstream_unitstd/manifest.json`
and run with:

```bash
npm run test:unitstd-ruby
```

Enabled today: `Array`, `Date`, `DateTools`, `EReg`, `IntIterator`, `Lambda`,
`List`, `Map`, `Math`, `String`, `StringBuf`, `StringTools`,
`haxe.crypto.Md5`, `haxe.crypto.Sha1`, `haxe.io.BytesBuffer`, and
`haxe.io.Path`. `Std` runs through an adapted upstream fixture, and local
focused fixtures cover adjacent semantic gaps such as numeric parsing.

Broader upstream candidate accounting lives in
`docs/ruby-stdlib-parity-audit.json` and
`docs/ruby-stdlib-parity-audit.md`, validated by:

```bash
npm run test:ruby-stdlib-parity-audit
```

## Coverage Tiers

Use these tiers when deciding what to implement next.

### Tier 0: Haxe Semantics Needed By Existing Output

These are required for current examples, RailsHx, and shared Haxe domain code.

- `Std`, `Math`, strings, arrays, maps, enums, exceptions, and bytes.
- Runtime helpers are acceptable only where tests prove Ruby differs.
- Every helper should be covered by a runtime test, a generated-shape snapshot
  where relevant, and unitstd parity when an upstream fixture exists.

### Tier 1: Implemented Portable Std Surfaces Needing Broader Parity

These surfaces now have Ruby target implementations, but should get stronger
upstream or focused parity evidence before broad Ruby library expansion.

- `Reflect`
- `Type`
- `haxe.Json`
- `sys.FileSystem`
- `sys.io.File`
- `haxe.io.FPHelper`

For each surface, prefer a typed Haxe facade that emits direct Ruby when safe and
uses `HXRuby` only for stable Haxe semantics.

### Tier 2: Ruby Stdlib Typed Facades

These are Ruby-owned libraries Haxe authors should consume through typed externs
or small facades rather than raw `Dynamic`/`__ruby__`.

Suggested first domains:

- `File`, `Pathname`, `Dir`, `Tempfile`, and `FileUtils`
- `JSON`
- `Time`, `Date`, and `DateTime`
- `URI`, `CGI`, `ERB::Util`
- `CSV`
- `Open3`/process helpers
- `Set`

These should generally live under `std/ruby/**` and lower to Ruby library calls.
Do not copy Ruby stdlib behavior into HXRuby unless Haxe compatibility requires
an adapter. See `docs/ruby-stdlib-facades.md` for package naming, API shape,
require metadata, examples, and tests for typed Ruby stdlib facades.

### Tier 3: Optimizer And Hot-Path Lowering

These are not public profiles. They should be explicit optimizer/runtime defines
or ordinary compiler improvements.

- Direct receiver/module calls for proven-safe std methods.
- Fewer generated temps where Ruby expression shape can remain clear.
- Optional frozen string literal emission.
- YJIT-friendly call shapes once measured.

Do not add a public `metal` profile for this work.

## Runtime Helper Policy

Before adding or keeping an `HXRuby` helper, answer these questions in code,
tests, or the bead:

- What Ruby-native expression was considered?
- Which Haxe behavior would drift?
- Is the helper needed in both `ruby_first` and `portable`, or only because of a
  portable contract?
- Does a compiler-special lowering also exist?
- Which test proves the helper is semantic and not just a wrapper?

Preferred outcomes:

| Case | Lowering |
| --- | --- |
| Ruby has the same behavior | Direct Ruby call |
| Ruby differs only for known typed subcases | Direct Ruby for proven subcase, helper for the gap |
| Ruby differs for the public Haxe method | `HXRuby` semantic helper |
| Ruby library interop | Typed `ruby.*` extern/facade |
| Rails/gem interop | Typed RailsHx/gem-layer facade or generated extern |

### Array/Lambda/Map Helper Audit

Current Array/Lambda/Map lowering follows the same rule: emit direct Ruby when
the receiver API is behavior-preserving, and keep helpers only where Haxe
semantics need an adapter.

- `Array.concat` lowers directly to Ruby `+`: both return a new array without
  mutating the receiver.
- `Array.contains` lowers directly to Ruby `include?`: both use equality
  comparison for membership.
- `Array.copy` lowers directly to Ruby `dup`: both produce a shallow copy.
- `Array.join` lowers directly in `ruby_first`, but remains a helper in
  `portable` because Haxe stringification of elements is stricter than Ruby's
  default `to_s`.
- `Array.slice`, `splice`, `insert`, `remove`, `indexOf`, `lastIndexOf`,
  `resize`, and `sort` stay on `HXRuby` helpers because they encode Haxe
  boundary normalization, return values, mutation contracts, or comparator
  calling shape.
- `Array.map` and `Array.filter` stay on helpers until the Ruby AST has a
  first-class block-call expression; the helper is currently the semantic bridge
  between Haxe function values and Ruby blocks.
- `Lambda` methods are plain Haxe loops today. Their generated Ruby should
  benefit from safe Array direct lowerings, but the public `Lambda` API should
  not be rewritten into Ruby `Enumerable` shortcuts until nullability,
  Iterable/Iterator shape, and callback return semantics are proven.
- `haxe.ds.*Map` currently uses typed `ruby.NativeHash`, not `HXRuby`.
  `StringMap` and `IntMap` use normal Ruby `Hash`; `ObjectMap` uses an identity
  hash so same-shape object keys do not collapse. Keep this direct Ruby backend
  unless another Haxe key-identity or iteration-order gap requires a documented
  helper.

## Testing Policy

Every std/runtime change should choose the smallest useful gate set:

- `npm run test:runtime-minitest` for `runtime/hxruby/**`.
- `npm run test:unitstd-ruby` for Haxe std semantics.
- `npm run test:ruby-stdlib-parity-audit` when changing upstream stdlib
  candidate accounting or the unitstd manifest.
- `UPDATE_SNAPSHOTS=1 npm run test:snapshots && npm run test:snapshots` for
  generated Ruby shape changes.
- `npm run test:stdlib-mvp` for broad std smoke coverage.
- `npm run test:m1` / `npm run test:m2` for compiler matrix smoke.
- `npm run test:todoapp-rails` when generated Rails output or Rails runtime
  requires change.
- `npm run test:stdlib-inventory && npm run test:gap-report` when inventory or
  docs change.
- `npm run public:precommit` and relevant CI checks before declaring done.

CI must be green before moving to another feature slice.

## Ruby Version Policy

RubyHx currently validates against the repository compatibility matrix and CI
Ruby jobs. Stdlib APIs should avoid relying on behavior that is only available
in a single Ruby minor unless the compatibility matrix is updated and the docs
say so.

For Ruby stdlib facades:

- Prefer APIs available across supported Ruby versions.
- If a newer Ruby API is useful, add a compatibility shim in `HXRuby` only when
  the shim is genuinely shared and tested.
- Keep runtime shims namespaced; do not patch Ruby core classes by default.
- Snapshot generated require paths when a facade introduces a new Ruby stdlib
  dependency.

## First Follow-Up Beads

Create work from `docs/ruby-stdlib-parity-audit.json` in small slices:

1. Promote one upstream-fallback candidate such as `haxe.Template`,
   `haxe.DynamicAccess`, or `haxe.crypto.Sha256` through
   `test/upstream_unitstd/manifest.json`.

2. Add upstream parity coverage for an implemented Ruby-owned surface, starting
   with `Reflect` or `Type`.

3. Add focused filesystem parity coverage for `sys.FileSystem` and
   `sys.io.File`, including exception and newline behavior.

4. Audit numeric binary surfaces together: `Float`, `haxe.Int32`, and
   `haxe.io.FPHelper`.

5. Expand dedicated map/collection fixtures after top-level `Map.unit.hx`
   remains green: `haxe.ds.StringMap`, `haxe.ds.IntMap`,
   `haxe.ds.ObjectMap`, `haxe.ds.Vector`, and `haxe.ds.EnumValueMap`.

6. Add Ruby stdlib facades separately under `std/ruby/**` for
   `ruby.Pathname`, `ruby.Dir`, `ruby.FileUtils`, `ruby.Tempfile`, `ruby.URI`,
   and later `ruby.CSV`/`ruby.Open3`/`ruby.Set` style packages.

## Non-Goals

- No broad runtime rewrite.
- No public `metal` profile.
- No hidden compiler globals for Ruby convenience names.
- No Rails-only assumptions in the pure Ruby std/runtime layer.
- No LLM-generated stdlib contracts without deterministic parsing, compilation,
  tests, and review markers.
