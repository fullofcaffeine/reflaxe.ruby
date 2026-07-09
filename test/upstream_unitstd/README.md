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
  `haxe.DynamicAccess`, `haxe.crypto.Base64`, `haxe.crypto.Crc32`,
  `haxe.crypto.Hmac`, `haxe.crypto.Md5`, `haxe.crypto.Sha1`,
  `haxe.crypto.Sha224`, `haxe.crypto.Sha256`, `haxe.ds.GenericStack`,
  `haxe.io.BytesBuffer`, `haxe.io.Path`, `haxe.Template`.
- Adapted: `Std`. The local copy preserves the upstream assertions that matter
  for this lane, while avoiding macro-expansion local-name collisions and
  ignoring upstream `unspec(...)` markers.
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

`haxe.Template` is enabled directly. It proves the portable Haxe template
parser/executor can fall through unchanged on Ruby, including context lookup,
globals, nested macro callbacks, and string output. This is separate from
RailsHx HHX and ActionView template authoring.

`haxe.DynamicAccess` is enabled directly. It proves the portable Haxe
dynamic-access abstraction can fall through unchanged on Ruby for
exists/get/set/bracket access, anonymous-object conversion, key iteration, value
iteration, key-value iteration, and removal without expanding the public Dynamic
surface beyond this contained std boundary.

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
