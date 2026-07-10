# Upstream Haxe `unitstd` Runtime Specs

This directory contains a curated, checked-in subset of Haxe upstream
`tests/unit/src/unitstd/**/*.unit.hx` specs for the Ruby target.

Why this exists:

- Snapshot tests validate generated Ruby shape.
- These specs validate Ruby runtime behavior against Haxe's stdlib contract.
- CI must be deterministic, so it cannot depend on a sibling Haxe checkout.

Source provenance:

- Upstream source: Haxe `tests/unit/src/unitstd`
- Haxe standard library/tests are distributed under the Haxe Foundation MIT
  license; see the upstream `extra/LICENSE.txt`.

Coverage policy:

- `manifest.json` tracks high-leverage stdlib surfaces and whether an upstream
  fixture is enabled, adapted, skipped for Ruby triage, unsupported, or absent.
- Enabled fixtures compile through haxe.ruby and run as plain Ruby via
  `npm run test:unitstd-ruby`.
- Non-enabled entries must explain whether no upstream spec exists, the spec is
  unsupported for this target, or target-specific triage is still required.

Current upstream runtime fixtures:

- Enabled: `Array`, `Date`, `DateTools`, `EReg`, `IntIterator`, `Lambda`,
  `List`, `Map`, `Math`, `String`, `StringBuf`, `StringTools`,
  `haxe.DynamicAccess`, `haxe.EnumFlags`, `haxe.crypto.Base64`,
  `haxe.crypto.Crc32`, `haxe.crypto.Hmac`, `haxe.crypto.Md5`,
  `haxe.crypto.Sha1`, `haxe.crypto.Sha224`, `haxe.crypto.Sha256`,
  `haxe.ds.BalancedTree`, `haxe.ds.GenericStack`, `haxe.extern.EitherType`,
  `haxe.io.BytesBuffer`, `haxe.io.Path`, `haxe.Log`, `haxe.Template`,
  `haxe.rtti.Rtti`, `sys.io.File`.
- Adapted: `Reflect`, `Std`, and `Type`. `Reflect` and `Type` add lexical blocks
  around upstream sections whose locals collide when expanded into one method;
  `Type` also uses upstream-package helpers and explicit Dynamic parameter
  arrays. `Std` avoids similar macro-expansion collisions and ignores upstream
  `unspec(...)` markers; all retain the assertions owned by this lane.
- No direct unitstd spec: `haxe.Json` is covered separately by the
  provenance-backed `npm run test:json-parity` broader-suite lane;
  `sys.FileSystem` is covered by `npm run test:filesystem-parity`.
- `Map` is enabled directly. RubyHx backs `StringMap` and `IntMap` with normal
  Ruby `Hash`, and backs `ObjectMap` with `Hash#compare_by_identity` so object
  keys keep Haxe identity semantics while preserving Ruby insertion order.

`Date` is enabled directly. The Ruby lane models Haxe `Date` as a small wrapper
around Ruby `Time`: local constructors and component getters use local time,
UTC getters use `getutc`, `getTimezoneOffset()` follows the JavaScript/Haxe
minute offset sign, and `Date.fromString()` accepts the exact upstream Haxe
date-time, date-only, and UTC time-only shapes through generated Ruby.

`DateTools` is enabled directly. It proves upstream fallback over the Ruby-owned
`Date` surface for month-day, seconds, and delta helpers.

`haxe.Json` is tracked as `no-upstream-spec` because its authoritative cases
live in the broader Haxe unit suite instead of `unitstd`. The dedicated Ruby
lane adapts `TestJson`, Issue4592, and Issue11560 to cover scalar and structured
round trips, Unicode escapes, invalid-input throws, non-finite numbers,
replacer traversal, pretty printing, and generated-class fields while checking
that Ruby's native JSON library remains the final parser and encoder.

`sys.io.File` is enabled directly. It covers write, overwrite, append, update,
seek, and create-on-update behavior through direct Ruby `File`/`IO` calls.
`sys.FileSystem` has no direct unitstd fixture, so the provenance-backed broader
filesystem lane covers its upstream path, directory, stat, rename, deletion,
and native-error behavior alongside binary and EOF cases for the typed
`FileInput`/`FileOutput` carriers.

`haxe.rtti.Rtti` is enabled directly. The upstream fixture parses compiler-
generated `@:rtti` XML through the unchanged upstream `Rtti`, `CType`, and
`XmlParser` implementation, checking static and instance fields, rights,
function types, inheritance, and overrides. Its focused Ruby shape assertions
also lock in typed enum-abstract static initialization, absolute `::Xml`
resolution across the root-class/`haxe.xml` package collision, and direct Hash
construction/writes for XML parser static maps.

`haxe.io.Path` is enabled directly. It proves the portable Haxe path parser,
formatter, joiner, and normalizer can fall through unchanged on Ruby while
remaining separate from any Ruby-native `Pathname` facade.

`haxe.crypto.Base64` is enabled directly. It proves the portable Haxe Base64
implementation can execute over RubyHx `Bytes` for padded and unpadded standard
and URL-safe encode/decode behavior. Ruby `Base64` remains a separate facade or
optimization concern.

`haxe.crypto.Crc32` is enabled directly. It proves the portable Haxe Crc32
implementation can execute over RubyHx `Bytes`; Ruby `Zlib.crc32` remains a
separate facade or optimization concern.

`haxe.crypto.Hmac` is enabled directly. It proves the portable Haxe Hmac
implementation can execute over RubyHx `Bytes` and the already-covered
MD5/SHA-1/SHA-256 implementations; Ruby `OpenSSL::HMAC` remains a separate
facade or optimization concern.

`haxe.ds.GenericStack` is enabled directly. It proves the portable Haxe linked
stack implementation can fall through unchanged on Ruby, including null values,
LIFO order, and removal behavior.

`haxe.ds.BalancedTree` is enabled directly. It proves the portable ordered tree
map implementation can fall through unchanged on Ruby, including integer and
string key ordering, ordered values, copy isolation, removal, key-value
iteration, and clear semantics. It also guards Haxe default argument lowering
through the upstream tree node height default.

`haxe.extern.EitherType` is enabled directly. It proves the type-system surface
needs no Ruby-owned runtime override for this lane: accepted Int/String
assignments compile and run, while invalid Bool/Float assignments are rejected
at compile time through the unitstd `HelperMacros.typeError` shim.

`haxe.Log` is enabled directly. It proves upstream fallback over compiler-owned
dynamic-method lowering: `trace` can be replaced and restored, receives the
fixture's injected `haxe.PosInfos`, and raises when rebound to null without a
Ruby-specific Log override. Its upstream whitespace is preserved verbatim and
excluded from repo formatting because the spec intentionally asserts the source
line number injected into `trace`.

`Reflect` is adapted with lexical section blocks while retaining upstream field,
property, method, compare, copy, delete, object, and enum-value assertions. It
proves Haxe-owned camelCase names map to generated Ruby members without changing
open anonymous-object/Hash keys, Strings retain Haxe object classification, and
optional enum constructor payloads default to null in generated Ruby.

`Type` is adapted with lexical section blocks, upstream-package helper types,
and explicit `Array<Dynamic>` expectations for enum parameters. It retains the
upstream class/enum lookup, naming, superclass, construction, field-list,
equality, parameter, index, and `allEnums` assertions. It proves generated Haxe
classes retain compact source-name metadata, inherited instance fields remain
discoverable without leaking Ruby/Object methods, and target-referenced
`haxe.macro` enums are emitted for runtime reflection.

`haxe.Template` is enabled directly. It proves the portable Haxe template
parser/executor can fall through unchanged on Ruby, including context lookup,
globals, nested macro callbacks, and string output. This is separate from
RailsHx HHX and ActionView template authoring.

`haxe.DynamicAccess` is enabled directly. It proves the portable Haxe
dynamic-access abstraction can fall through unchanged on Ruby for
exists/get/set/bracket access, anonymous-object conversion, key iteration, value
iteration, key-value iteration, and removal without expanding the public Dynamic
surface beyond this contained std boundary.

`haxe.EnumFlags` is enabled directly. It proves the portable Haxe enum-flag
helper can fall through unchanged on Ruby over enum constructor indexes and
integer bit masks, including the 31st-bit flag case.

`haxe.crypto.Md5` is enabled directly. It proves the portable Haxe digest
implementation can execute over RubyHx `Bytes`; Ruby `Digest` remains a
separate facade or optimization concern.

`haxe.crypto.Sha1` is enabled directly. It proves the portable Haxe SHA-1
implementation can execute over RubyHx `Bytes` and the Ruby compiler's
Haxe-compatible 32-bit integer lowering.

`haxe.crypto.Sha224` is enabled directly. It proves the portable Haxe SHA-224
implementation can execute over RubyHx `Bytes` and the Ruby compiler's
Haxe-compatible 32-bit integer lowering.

`haxe.crypto.Sha256` is enabled directly. It proves the portable Haxe SHA-256
implementation can execute over RubyHx `Bytes` and the Ruby compiler's
Haxe-compatible 32-bit integer lowering.

`EReg` is enabled directly. The Ruby lane wraps Ruby `Regexp` while preserving
Haxe stateful match accessors, non-global versus global split/replace/map
behavior, `$1`/`$$` replacement expansion, capture-group access, `matchSub`
offsets, and `EReg.escape()`.

`Lambda` is enabled directly. It exercises the Ruby-first iterator bridge:
generated `.iterator()` calls use a compact runtime helper that delegates to
Haxe iterators when present and wraps native Ruby arrays otherwise. The local
fixture adapter also makes array-literal comparisons explicit structural
assertions so compiler equality can keep Haxe's array identity semantics.

`List` is enabled directly. It proves the upstream linked-list implementation
can fall through unchanged on Ruby, covering mutation, string/join behavior,
map/filter, and key/value iteration.

`Array` is enabled directly in the portable unitstd lane. It locks in Haxe array
mutation, slicing/splicing, sorting with method references, dynamic array calls,
anonymous-object field reads in array callbacks, sparse resize contents, and
key/value iteration while keeping normal generated `Array ==` as identity.

`Map` is enabled directly in the portable unitstd lane. It exercises
`StringMap`, `IntMap`, hash-code object keys, plain object identity keys, map
literals, `[]` map access, copying, removal, and `KeyValueIterable` unification
through Ruby's native hash-backed map implementation.

The first lane is intentionally narrow. It proves the harness, provenance, sync
workflow, and runtime execution shape without pretending broad Ruby stdlib parity
is already complete. Expand the lane fixture-by-fixture as Ruby std support
hardens.

Use `docs/ruby-stdlib-parity-audit.json` and
`docs/ruby-stdlib-parity-audit.md` to choose the next fixture. The audit
separates covered surfaces, upstream fallback candidates, Ruby override
candidates, and unsupported target-specific fixtures so fixture promotion stays
deliberate.

Use `scripts/sync-upstream-unitstd-specs.sh` to refresh enabled, unadapted specs
from a local Haxe reference checkout. The sync normalizes fixture whitespace
with the repo Haxe formatter so normal formatting gates stay green. Adapted
specs must be reviewed manually so their local target changes are not
overwritten.
