# RubyHx testing scorecards

These scorecards keep five independently claim-bearing product surfaces separate.
A **scorecard** means the evidence and remaining gaps for one public surface.
Passing one card never changes another card's status.

## Haxe-to-Ruby compiler conformance

| Field | Contract |
| --- | --- |
| Surface ID / status | `compiler-conformance` / **partial** |
| Owner | Ruby compiler, `portable` profile, Haxe lowering and diagnostics |
| Claim | The admitted Haxe language and std behavior compiles through the custom backend and executes as Ruby. This is the only scorecard allowed to carry an official Haxe target-qualification claim. |
| Inputs / outputs | Typed Haxe source -> structural Ruby AST -> generated Ruby |
| Focused owners | AST, lowering, profile, diagnostics, naming, loop, callable, and historical regression tests |
| Vertical/runtime owners | `test:hello-world`, `test:core-subset`, `test:exception-flow`, `test:json-parity`, `test:filesystem-parity`, `test:unitstd-ruby`, `test:public-install-official` |
| Oracle | Haxe 4.3.7 at `e0b355c6be312c1b17382603f018cf52522ec651`, manually reviewed stdout/diagnostics, and runtime invariants |
| Examples | Compiler-conformance entries in `test/example-contracts.json` |
| Backstop / release | `npm run test:queued`; exact-SHA canonical CI and release dependency graph |
| Last clean proof | CI 30586074436 for `79b6ebde3f580cde8f9d69581e12876adc9b6b11` before this delta |
| Residual risk | This is not complete official Haxe qualification. The public-install tracer covers one shared top-level class, one general issue, and one active unitstd fixture; the remaining shared classes, general issue corpus, and 24 currently inactive official unitstd files remain outside active proof. Public wording stays partial. |

## Ruby runtime and standard-library semantics

| Field | Contract |
| --- | --- |
| Surface ID / status | `ruby-runtime-stdlib` / **admitted slice** |
| Owner | Ruby runtime helpers and Haxe/Ruby std facades |
| Claim | Documented Haxe std/runtime behavior and Ruby-specific runtime seams execute correctly on supported MRI versions. |
| Inputs / outputs | Generated Ruby plus `hxruby` helpers and typed std facades -> Ruby values, I/O, exceptions, collections, time/date, JSON, and related effects |
| Focused owners | `test:runtime-core`, `test:runtime-minitest`, facade tests, negative diagnostics, stdlib inventory/parity checks |
| Vertical/runtime owners | `test:runtime-usage`, `test:stdlib-mvp`, JSON/filesystem/unitstd runtime lanes |
| Oracle | Haxe semantics, Ruby standard-library behavior, manually authored minimal expectations, round trips, and pinned differential references where behavior is ambiguous |
| Examples | `exception_flow` and `stdlib_mvp` contracts |
| Backstop / release | `npm run test:queued`; MRI 3.3/3.4/4.0 canonical matrix |
| Last clean proof | CI 30586074436 before this delta |
| Residual risk | A compiler-conformance pass does not prove every Ruby runtime/helper ABI, and facade coverage does not imply every Ruby stdlib API is supported. |

## Ruby-native, gem, package, and interop behavior

| Field | Contract |
| --- | --- |
| Surface ID / status | `ruby-native-gem-package` / **admitted slice** |
| Owner | `ruby.*` facades, block/keyword ABI, extension contracts, generators, Haxelib ZIP, gem, and clean consumers |
| Claim | Documented Ruby-shaped APIs remain typed for Haxe authors and consumable as ordinary Ruby/gem/package artifacts. |
| Inputs / outputs | Typed native contracts and package metadata -> direct Ruby calls, normal blocks/keywords/modules, ZIP/gem artifacts, and consumer installs |
| Focused owners | native mapping, call shapes, interop, extensions, RBS, facade, generator, manifest, and package contract tests |
| Vertical/runtime owners | `test:ruby-callable-abi-example`, `test:rubyhx-cli`, Rails runtime seams, `test:haxelib-package`, `test:public-install-official`, `test:gem-package`, public-upgrade rehearsal |
| Oracle | MRI/gem behavior, handwritten Ruby consumers, package manifests, independent embedded hashes, and reviewed Ruby/Rails contracts |
| Examples | Ruby-native and package entries in `test/example-contracts.json` |
| Backstop / release | Full local contract, package/security jobs, cold exact-SHA release rebuild |
| Last clean proof | CI 30586074436 and immutable v1.22.0 evidence before this delta |
| Residual risk | Package success does not prove general Haxe conformance; Rails/gem success remains limited to documented, executed seams. |

## Official, adapted, and repository-authored fixture provenance

| Field | Contract |
| --- | --- |
| Surface ID / status | `upstream-provenance` / **partial** |
| Owner | `test/upstream_unitstd/manifest.json`, active assertion inventory, adaptation patches, and review-only sync |
| Claim | Every official fixture byte used by the bounded lane has an exact source identity, an honest transformation classification, and active post-macro assertion accounting. Provenance quality is not a runtime pass. |
| Active inventory | Haxe 4.3.7 contains 67 official `.unit.hx` files: 43 active here and 24 explicitly inactive. Of the 43 active copies, 1 is byte-identical, 36 are formatter-only adaptations, and 6 are Ruby-lane adaptations with reviewed patches. Repository-authored regressions are counted separately. |
| Oracle / pin | Official Haxe tag 4.3.7 and commit `e0b355c6be312c1b17382603f018cf52522ec651`; upstream/local/diff SHA-256; Haxe std MIT license bytes |
| Active proof | `test/upstream_unitstd/active-assertions.json` locks 2,248 unique assertion identities visible after macro expansion and Ruby emission |
| Static owner | `npm run test:unitstd-provenance` |
| Vertical owner | `npm run test:unitstd-ruby` compiles active official-derived source with the custom backend and runs Ruby |
| Public-install tracer | `test/public_install_official/manifest.json` separately pins two byte-identical official sources and one formatter-adapted unitstd source; `npm run test:public-install-official` installs the release-shaped ZIP in an isolated Haxelib repository and executes all three on MRI. |
| Update owner | `scripts/sync-upstream-unitstd-specs.sh` verifies and reports only; it cannot overwrite local adaptations |
| Backstop / release | Full local contract and exact-SHA canonical CI |
| Residual risk | Active identity proves registration, not semantic correctness. Inactive fixtures are not passes, and the six adapted fixtures are never counted as unmodified official coverage. |

## Executable examples and downstream consumers

| Field | Contract |
| --- | --- |
| Surface ID / status | `examples-downstream` / **admitted slice** |
| Owner | `test/example-contracts.json` and the example inventory gate |
| Claim | Each maintained example compiles and may support only the generation, Ruby syntax, real runtime, package/framework, browser, production, or downstream level its contract actually executes. |
| Tiers | One flagship application (`todoapp_rails`), 30 capability showcases, and one compile-only snippet (`rails_test_adapters`) |
| Static/focused owner | `npm run test:examples-compile` validates every entrypoint, tier, surface, command, proof level, and snapshot declaration |
| Vertical/runtime owners | Per-example commands in the manifest; Rails runtime, package consumers, shared Ruby/JS vectors, and handwritten Ruby consumers where declared |
| System/browser owner | Todoapp Playwright and production dogfood only; other examples do not borrow those claims |
| Oracle | Manually authored stdout, reviewed snapshots, real Ruby/Rails/gem consumers, common cross-target vectors, and browser-visible behavior |
| Backstop / release | Full examples gate, canonical Rails/browser/production/package jobs, and exact-SHA release dependencies |
| Last clean proof | All 32 examples passed CI 30586074436 before this delta |
| Residual risk | A compile-only or generation-only example is not runtime evidence. A flagship pass does not automatically qualify every showcase. |
