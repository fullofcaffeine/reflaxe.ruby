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
Construction and canonical writes inline to `{}` and `hash[key] = value`, so a
static upstream map literal does not depend on a later-generated adapter file.
The Ruby-owned `haxe.zip` overrides similarly consume typed `ruby.ArrayPacking`
and `ruby.Zlib` contracts so binary conversion and compression stay direct
without exposing `Dynamic` or raw Ruby injection. The Ruby-owned
`haxe.io.FPHelper` override shares `ruby.ArrayPacking` and adds
`ruby.BinaryFormat`/`ruby.BinaryString` contracts so exact floating-point bit
reinterpretation stays direct and statically typed as well.

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
- `haxe/zip/*` surfaces where Ruby's standard Zlib library owns compression and
  one-shot decompression behavior.
- `sys/*` and `sys/io/*` modules once Ruby filesystem/process support exists.

The filesystem implementation keeps stateless `sys.FileSystem` and
`sys.io.File` facades erased and inlined to ordinary Ruby `File`, `Dir`, and
`FileUtils` calls. Stateful `FileInput`, `FileOutput`, and `FileSeek` values are
emitted as the minimal nested `Sys::Io` carriers because Haxe code must retain
their handle state across calls. Ruby permits reopening the existing `Sys`
class to own those constants, so this does not require a parallel filesystem
runtime or `HXRuby` wrappers.

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

`haxe.Json` has no direct upstream unitstd fixture. Its separate
`npm run test:json-parity` lane adapts parser/writer cases from upstream
`tests/unit/src/unit/TestJson.hx` plus the invalid-input and class-field issue
regressions. Ruby's `JSON.parse`, `JSON.generate`, and `JSON.pretty_generate`
remain the actual parser/generator; `HXRuby.json_prepare` only projects Haxe
replacer, non-finite-number, enum, function, and generated-class semantics into
native JSON-ready values. Invalid Ruby parser errors cross Haxe `try/catch`
directly through the compiler's native `StandardError` rescue; no heterogeneous
Dynamic result tuple or JSON-specific exception wrapper is needed.

`sys.io.File` is enabled from the direct upstream unitstd fixture. The separate
`npm run test:filesystem-parity` lane adapts authoritative broader-suite cases
for `sys.FileSystem`, `File`, and `FileInput`, including path-segment behavior,
directories, stat values, copy/rename/delete failures, binary streaming,
seek/tell, and latched EOF. Native Ruby `StandardError` values cross Haxe
`try/catch` through compiler lowering, while normal generated file operations
remain direct Ruby calls.

`haxe.rtti.Rtti` is enabled directly from upstream. It proves generated
`@:rtti` XML for base and derived classes can flow through upstream `Rtti`,
`CType`, and `XmlParser` without a Ruby override. The compiler preserves typed
static initializers such as `XmlType.Element = 0`, emits the root Haxe `Xml`
class as absolute `::Xml` where the `haxe.xml` package would otherwise shadow
it, and lets static XML parser maps initialize through direct Ruby Hash writes.

`haxe.zip.Compress` and `haxe.zip.Uncompress` run adapted upstream fixtures
whose assertions are unchanged; only the upstream target guards are extended
to Ruby. RubyHx defines the conventional `ruby` target before typing, and the
target-owned overrides emit `require "zlib"`, direct `Array#pack`, and
`Zlib::Deflate/Inflate` calls through typed extern contracts. The upstream
exact-byte and one-shot `execute` cases run alongside focused arbitrary-binary
round trips and invalid-input coverage, without a runtime shim or `Dynamic`.

`Float`, `haxe.Int32`, and `haxe.io.FPHelper` run their upstream fixtures
directly, but they exercise different ownership decisions. Ruby's native Float
already supplies the required IEEE-754 arithmetic and special values; focused
bit assertions still prove signed zero, infinities, and NaN because equality
alone cannot establish those representations. Ruby's arbitrary-precision
Integer does not natively implement Haxe Int32 overflow, so the compiler applies
a centered modulo at typed Int32 result boundaries and masks shift counts to
five bits. Values remain ordinary readable Ruby integers rather than a boxed
runtime type, and ordinary Haxe `Int` is not normalized. FPHelper owns the exact
bit reinterpretation seam through typed `ruby.BinaryFormat`,
`ruby.ArrayPacking`, and `ruby.BinaryString` contracts, generating direct
`pack`, `byteslice`, and `unpack1` calls without `Dynamic`, casts, or raw Ruby.

The current baseline intentionally enables a focused set of fixtures and tracks
broader high-leverage fixtures separately. `Array`, `Date`, `DateTools`,
`EReg`, `Float`, `IntIterator`, `Lambda`, `List`, `Map`, `Math`, `String`,
`StringBuf`, `StringTools`, `haxe.DynamicAccess`, `haxe.Int32`,
`haxe.crypto.Base64`, `haxe.crypto.Crc32`, `haxe.crypto.Hmac`, `haxe.crypto.Md5`,
`haxe.crypto.Sha1`, `haxe.crypto.Sha224`, `haxe.crypto.Sha256`,
`haxe.ds.BalancedTree`, `haxe.ds.EnumValueMap`, `haxe.ds.GenericStack`,
`haxe.ds.IntMap`, `haxe.ds.ObjectMap`, `haxe.ds.StringMap`, `haxe.EnumFlags`,
`haxe.extern.EitherType`, `haxe.io.BytesBuffer`, `haxe.io.FPHelper`,
`haxe.io.Path`, `haxe.Log`, `haxe.Template`, `haxe.rtti.Rtti`, and `sys.io.File`
run directly. `Reflect`, `Type`, `haxe.ds.Vector`, `haxe.zip.Compress`, and
`haxe.zip.Uncompress` run through adapted fixtures. The Vector adaptation only
selects Ruby's dynamic neutral values; the ZIP adaptations only extend upstream
target guards. `Reflect` and
`Type` need macro-lane accommodation for section-local names, and `Type` also
uses upstream-package helpers and explicit Dynamic parameter arrays. `Std`
remains adapted for its assertion syntax, duplicate locals, and `unspec(...)`
markers.

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

`Reflect` runs through an adapted upstream fixture whose assertions remain
aligned with upstream while lexical blocks preserve section-local names in the
macro-expanded Ruby lane. It covers anonymous-object keys plus Haxe-owned field,
property, and method names; function/method identity; compare/copy/delete;
String object classification; enum-value detection; and optional enum
constructor defaults over `std/ruby/_std/Reflect.hx` and compact HXRuby helpers.

`Type` runs through an adapted upstream fixture with lexical section blocks and
upstream-package helper types. It covers class/enum lookup and names,
superclasses, instance and enum construction, exact source-level field names,
inherited instance fields, enum structure/equality, and `allEnums`. The fixture
also locks in target emission for referenced `haxe.macro` enums while compact
`__hx_fields` metadata keeps public generated Ruby members native-looking.

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

`haxe.crypto.Hmac` is enabled as a direct upstream fixture. It proves the
portable Haxe Hmac implementation can execute over RubyHx `Bytes` and the
already-covered MD5/SHA-1/SHA-256 implementations, while Ruby's native
`OpenSSL::HMAC` stays a separate typed facade or optimization concern.

`haxe.ds.GenericStack` is enabled as a direct upstream fixture. It proves the
portable Haxe linked stack implementation can fall through unchanged on Ruby,
including null values, LIFO order, and removal behavior.

`haxe.ds.BalancedTree` is enabled as a direct upstream fixture. It proves the
portable ordered tree map implementation can fall through unchanged on Ruby,
including integer and string key ordering, ordered values, copy isolation,
removal, key-value iteration, and clear semantics. It also guards Haxe default
argument lowering through the upstream tree node height default.

`haxe.extern.EitherType` is enabled as a direct upstream fixture. It proves the
type-system surface needs no Ruby-owned runtime override for this lane: accepted
Int/String assignments compile and run, while invalid Bool/Float assignments are
rejected at compile time through the unitstd `HelperMacros.typeError` shim.

`haxe.Log` is enabled as a direct upstream fixture. It proves the portable Log
implementation can fall through unchanged while Ruby compiler lowering keeps
Haxe `static dynamic function` semantics: trace callbacks can be replaced and
restored, receive compiler-injected source positions, and fail on invocation
after being rebound to null.

`haxe.Template` is enabled as a direct upstream fixture. It proves the portable
Haxe template parser/executor can fall through unchanged on Ruby, including
context lookup, globals, nested macro callbacks, and string output. This is
separate from RailsHx HHX and ActionView template authoring.

`haxe.DynamicAccess` is enabled as a direct upstream fixture. It proves the
portable Haxe dynamic-access abstraction can fall through unchanged on Ruby for
exists/get/set/bracket access, anonymous-object conversion, key iteration, value
iteration, key-value iteration, and removal without expanding the public Dynamic
surface beyond this contained std boundary.

`haxe.EnumFlags` is enabled as a direct upstream fixture. It proves the
portable Haxe enum-flag helper can fall through unchanged on Ruby over enum
constructor indexes and integer bit masks, including the 31st-bit flag case.

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
object-key identity while retaining Ruby insertion-order iteration. Their
dedicated direct fixtures additionally prove clear/removal, normal and key/value
iteration, and IMap unification; generated normal/identity Hash construction and
writes remain direct Ruby syntax.

`haxe.ds.EnumValueMap` is enabled directly over upstream `BalancedTree`. Its
fixture proves value equality for generated enum constructors and recursive
enum/array parameters, so Ruby does not need a target override or hash-key
canonicalizer. `haxe.ds.Vector` runs an adapted fixture whose only changes make
neutral-value guards treat generated Ruby as dynamic despite Reflaxe's static
typing host. Vector values remain native Ruby arrays; the compiler maps the
portable internal Array-length assignment to the existing resize semantic helper
and maps Vector equality to `equal?`. This preserves null fill, zero-copy data,
copy identity, overlap-safe blit, iteration, fill, join, map, and sort without a
boxed Vector value or new unchecked Haxe seam.

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
