# Ruby Stdlib Parity Audit

This audit is the planning ledger for upstream Haxe stdlib parity on the Ruby
target. It does not claim that the full Haxe stdlib is complete. It records
which surfaces are already covered, which should fall through to upstream Haxe
stdlib source, which need Ruby-owned semantics, and which fixtures are outside
the current Ruby runtime contract.

The canonical machine-readable ledger is
`docs/ruby-stdlib-parity-audit.json`. Validate it with:

```bash
npm run test:ruby-stdlib-parity-audit
```

The guard checks that:

- every `test/upstream_unitstd/manifest.json` module appears in the audit;
- enabled/adapted manifest entries keep matching source and status metadata;
- every upstream unitstd fixture in the local reference checkout appears in the
  audit when `../haxe.compilerdev.reference` or `HAXE_RUBY_UNITSTD_REFERENCE`
  is available;
- covered Ruby overrides name the owning std/runtime surface.

## Classification Buckets

| Classification | Count | Meaning |
| --- | ---: | --- |
| `covered-ruby-override` | 12 | Ruby owns the override, lowering, or runtime seam and current tests have direct evidence. |
| `covered-upstream-fallback` | 17 | The Ruby lane covers the surface while using upstream Haxe std source, sometimes over lower-level Ruby-owned dependencies. |
| `upstream-fallback-candidate` | 9 | No Ruby override is indicated yet. Add a fixture or smoke before promoting to covered. |
| `ruby-override-needed` | 28 | Ruby-owned lowering, runtime support, or `std/ruby/_std` replacement is needed or already exists but lacks upstream parity accounting. |
| `unsupported-target-specific` | 6 | The fixture is not a Ruby runtime parity surface or is outside the current target contract. |

Unitstd status today:

| Status | Count |
| --- | ---: |
| `enabled` | 24 |
| `adapted` | 1 |
| `no-upstream-spec` | 3 |
| `not-tracked` | 44 |

## Reading The Buckets

`covered-*` means the current repository has parity evidence for that surface.
For example, `Array`, `Date`, `EReg`, `Lambda`, `Map`, `Math`, `Std`, and
`StringTools` are Ruby-owned or compiler-lowered surfaces with upstream unitstd
coverage. `DateTools`, `IntIterator`, `List`, `String`, `StringBuf`,
`haxe.crypto.Base64`, `haxe.crypto.Crc32`, `haxe.crypto.Hmac`,
`haxe.DynamicAccess`, `haxe.crypto.Md5`, `haxe.crypto.Sha1`,
`haxe.crypto.Sha224`, `haxe.Template`, `haxe.crypto.Sha256`,
`haxe.ds.GenericStack`, `haxe.io.BytesBuffer`, and `haxe.io.Path` are covered
while falling through to upstream Haxe source or using upstream source over
lower-level Ruby-owned primitives.

`upstream-fallback-candidate` is deliberately conservative. It means the next
move should be to compile and run the upstream fixture before adding a Ruby
override. It does not mean parity has already been proven.

`ruby-override-needed` includes two cases:

- implemented surfaces that still need upstream parity accounting, such as
  `Reflect`, `Type`, `haxe.Json`, `sys.FileSystem`, `sys.io.File`, and
  `haxe.io.FPHelper`;
- unimplemented or deferred semantic surfaces where Ruby behavior cannot be
  assumed to match Haxe, such as atomics, typed arrays, weak maps, Unicode
  iterators, and fixed-width integer behavior.

`unsupported-target-specific` keeps disabled network fixtures, macro/eval
fixtures, and parser/language fixtures out of Ruby runtime parity accounting
until a separate target contract exists.

## Next Slices

Prefer these small follow-up slices over broad stdlib rewrites:

1. Promote one upstream-fallback candidate such as `haxe.ds.BalancedTree`,
   `haxe.EnumFlags`, or `haxe.zip.Compress` through
   `test/upstream_unitstd/manifest.json`.
2. Add upstream parity coverage for an implemented Ruby-owned surface, starting
   with `Reflect` or `Type`.
3. Add focused filesystem parity coverage for `sys.FileSystem` and
   `sys.io.File`, because those are Ruby-owned Haxe sys surfaces.
4. Audit numeric binary surfaces together: `Float`, `haxe.Int32`, and
   `haxe.io.FPHelper`.
5. Grow Ruby-native facades separately under `std/ruby/**`, starting with
   `Pathname`, `Dir`, `FileUtils`, `Tempfile`, or `URI`. Those facades are not
   substitutes for Haxe std parity unless Haxe semantics explicitly consume
   them.

## Policy

Do not copy upstream Haxe std modules into this repo only to reduce the audit
gap. If upstream source compiles and behaves correctly on Ruby, use upstream
fallback and record the fixture evidence. Add Ruby overrides only when the target
owns a real semantic gap, direct Ruby output shape, or deterministic runtime
contract.
