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

- Enabled: `IntIterator`, `Lambda`, `Math`, `String`, `StringBuf`, `StringTools`,
  `haxe.io.BytesBuffer`.
- Adapted: `Std`. The local copy preserves the upstream assertions that matter
  for this lane, while avoiding macro-expansion local-name collisions and
  ignoring upstream `unspec(...)` markers.
- Tracked but staged: `Array`, `Date`, `EReg`, and `Map`. These have
  upstream fixtures in the local reference checkout, but they also expose wider
  Ruby target semantics such as array structural equality/mutation, Ruby
  timezone behavior, regexp replacement/group behavior, and map key
  identity/order. Keep them in the manifest until each is enabled or split into
  a focused follow-up. Current focused follow-ups are `haxe.ruby-bjv.25`
  (`Array`), `haxe.ruby-bjv.26` (`Date`), `haxe.ruby-bjv.27` (`EReg`), and
  `haxe.ruby-bjv.28` (`Map`).

`Lambda` is enabled directly. It exercises the Ruby-first iterator bridge:
generated `.iterator()` calls use a compact runtime helper that delegates to
Haxe iterators when present and wraps native Ruby arrays otherwise. The local
fixture adapter also makes array-literal comparisons explicit structural
assertions so compiler equality can keep Haxe's array identity semantics.

The first lane is intentionally narrow. It proves the harness, provenance, sync
workflow, and runtime execution shape without pretending broad Ruby stdlib parity
is already complete. Expand the lane fixture-by-fixture as Ruby std support
hardens.

Use `scripts/sync-upstream-unitstd-specs.sh` to refresh enabled, unadapted specs
from a local Haxe reference checkout. The sync normalizes fixture whitespace
with the repo Haxe formatter so normal formatting gates stay green. Adapted
specs must be reviewed manually so their local target changes are not
overwritten.
