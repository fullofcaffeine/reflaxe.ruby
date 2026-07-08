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
  `haxe.io.BytesBuffer`, `haxe.io.Path`.
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
