# Ruby Stdlib Ownership

This repo keeps target stdlib work split by ownership and classpath behavior.

## Classpath Precedence

Ruby target builds see these directories in this order:

1. `std/ruby/_std`
2. `std`
3. `vendor/reflaxe/src`

That order is intentional. Source-checkout overrides in `std/ruby/_std` must
win over additive Ruby std surfaces in `std`, and both must be visible before
Reflaxe compiler internals are typed. `haxe_libraries/reflaxe.ruby.hxml`
declares the same source-mode layout directly, matching Reflaxe-generated
compiler conventions and the sibling Rust/OCaml compilers.

RailsHx browser/client builds use `-lib railshx.client` instead of
`-lib reflaxe.ruby`. That client library includes the shared/browser-safe
`std/` surface but does not include Ruby compiler macros or `std/ruby/_std`.
Reflaxe package build still owns `_std` to `.cross.hx` flattening for released
haxelib packages.

## Layering Contract

RubyHx has two std-facing layers that intentionally compose:

- `std/ruby/_std/**` source files provide Haxe std semantics for portable Haxe
  code. Reflaxe build packages them as `src/**/*.cross.hx`.
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

## Shared RailsHx Types

Shared RailsHx value types belong in `std/` as a single source of truth when
both server-side Ruby code and browser-side JavaScript code need the same typed
contract. Examples include `rails.turbo.StreamName`,
`rails.turbo.StreamTarget`, and `rails.turbo.TurboStreamAction`: ActionView,
Turbo Streams, compiler lowerings, and Haxe-authored browser code all benefit
from one package path and one set of conversions.

Do not duplicate shared tokens into separate server/client packages just to
make the physical tree look stricter. Prefer library entrypoint separation:
`reflaxe.ruby` sees `std` plus Ruby `_std` overrides and compiler macros, while
`railshx.client` sees only `std`. If a module is genuinely server-only or
browser-only, document that at the module/API level and keep tests compiling it
through the appropriate hxml. Move files into separate classpath roots only when
the existing package path can be preserved and the move removes real ambiguity
without weakening compiler lowerings.

## `std/`

Use `std/` for additive Ruby target surfaces:

- Ruby-native externs and facades, for example `ruby/File.hx` or `ruby/JSON.hx`.
- RailsHx shared/server/browser APIs such as `rails.*` and
  `reflaxe.js.Async`, selected by the consuming hxml and compile target.

Files in `std/` should not shadow upstream Haxe std modules unless the replacement is deliberate and documented in `docs/stdlib-inventory.json`.

## `std/ruby/_std/`

Use `std/ruby/_std/` only for upstream Haxe std overrides that must take
precedence in source checkouts:

- root std modules such as `Std`, `Array`, `Date`, `Math`, `StringTools`, and
  `Type` when Ruby owns target-specific semantics;
- `haxe/ds/*` map implementations when Ruby runtime semantics differ from upstream assumptions.
- `haxe/io/*` surfaces that require Ruby-backed bytes, streams, or file behavior.
- `sys/*` and `sys/io/*` modules once Ruby filesystem/process support exists.

Any new file in `std/ruby/_std/` must have an inventory entry with
`"owner": "std/ruby/_std"` and a reason. Do not place README or other
non-Haxe files in `_std`; Reflaxe build converts every file copied from an
`_std` path to `.cross.hx`.

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
broader high-leverage fixtures separately. `Array`, `Date`, `DateTools`,
`EReg`, `IntIterator`, `Lambda`, `List`, `Map`, `Math`, `String`, `StringBuf`,
`StringTools`, `haxe.crypto.Base64`, `haxe.crypto.Crc32`, `haxe.crypto.Md5`,
`haxe.crypto.Sha1`, `haxe.crypto.Sha224`, `haxe.crypto.Sha256`,
`haxe.io.BytesBuffer`, and `haxe.io.Path` run directly; `Std` runs through an
adapted fixture because upstream assertion syntax and duplicate local names
need macro-lane accommodation.

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

`DateTools` is enabled as a direct upstream fixture. It proves upstream fallback
over the Ruby-owned `Date` surface for month-day, seconds, and delta helpers.

`haxe.io.Path` is enabled as a direct upstream fixture. It proves the portable
Haxe path parser, formatter, joiner, and normalizer can fall through unchanged
on Ruby without coupling Haxe `Path` semantics to Ruby's `Pathname`.

`haxe.crypto.Base64` is enabled as a direct upstream fixture. It proves the
portable Haxe Base64 implementation can execute over RubyHx `Bytes`, while
Ruby's native `Base64` stays a separate typed facade or optimization concern.

`haxe.crypto.Crc32` is enabled as a direct upstream fixture. It proves the
portable Haxe Crc32 implementation can execute over RubyHx `Bytes`, while
Ruby's native `Zlib.crc32` stays a separate typed facade or optimization
concern.

`haxe.crypto.Md5` is enabled as a direct upstream fixture. It proves the
portable Haxe digest implementation can execute over RubyHx `Bytes`; a
Ruby-native `Digest` facade remains a separate interop or optimization layer.

`haxe.crypto.Sha1` is enabled as a direct upstream fixture. It proves the
portable Haxe SHA-1 implementation can execute over RubyHx `Bytes` and the Ruby
compiler's Haxe-compatible 32-bit integer lowering.

`haxe.crypto.Sha224` is enabled as a direct upstream fixture. It proves the
portable Haxe SHA-224 implementation can execute over RubyHx `Bytes` and the
Ruby compiler's Haxe-compatible 32-bit integer lowering.

`haxe.crypto.Sha256` is enabled as a direct upstream fixture. It proves the
portable Haxe SHA-256 implementation can execute over RubyHx `Bytes` and the
Ruby compiler's Haxe-compatible 32-bit integer lowering.

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
- `std/ruby/_std/*`, `std/ruby/_std/haxe/ds/*`, and
  `std/ruby/_std/haxe/io/*` target-owned std overrides.

Run:

```bash
npm run test:stdlib-inventory
npm run test:unitstd-ruby
```

to validate the inventory schema, that committed std/runtime files are
represented, and that the curated upstream runtime fixture lane still passes.
