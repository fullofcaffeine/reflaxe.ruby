# Live Release Protocol Evidence

This page records the hosted proof for the RubyHx tested-commit release
protocol. It is evidence, not mutable version configuration: canonical
`v<SemVer>` Git tags still own version lineage, and the release workflow still
derives every new version from Conventional Commits.

## Stable 1.10.2 structural exception publication

The normal tested-commit workflow published immutable
[`v1.10.2`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.10.2)
on 2026-07-19 for structural Ruby exception lowering and ordered Haxe catch
dispatch.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `c7e75cf1fdd16b6591cdcbeb4b198d833f263b72` |
| Included implementation lineage | `d20f352` exhaustive Ruby AST child/traversal contract and `c7e75cf` structural typed exception dispatch |
| Canonical release tag | `v1.10.2`, a lightweight remote tag resolving directly to the tested source SHA |
| Same-run CI workflow | [`29676480880`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29676480880), `success`; all 14 security, formatter, Node compatibility, release-contract, browser, production, Ruby 3.3/3.4/4.0 compiler/package, Rails 8.1.3 runtime, and publication jobs passed |
| Privileged release job | [`88167861015`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29676480880/job/88167861015), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false`, and `immutable=true`; published at `2026-07-19T07:09:30Z` |
| Release notes | Version heading, `v1.10.1...v1.10.2` compare link, categorized bug-fix bullet, and exact `c7e75cf` commit link |

The completed release has exactly the four allowed assets. Values below were
checked against the GitHub Releases API and independently downloaded and
hashed:

| Hosted artifact | Label | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `hxruby-1.10.2.gem` | `hxruby 1.10.2 Ruby gem` | 275968 | `b4ba10b04b8ecb3f14067ecd9c0874649c9a7e36754bd8bda9987091e53900e0` |
| `hxruby-1.10.2.gem.sha256.json` | `hxruby 1.10.2 SHA-256 metadata` | 304 | `0df57cc8f66d95095a23be26ef2c640bb9fb8591260092eca5beee006edf0b02` |
| `reflaxe.ruby-1.10.2.zip` | `reflaxe.ruby 1.10.2 haxelib package` | 1304841 | `58b267fda291ac4b80955294998399f6a718bf48d8eedc7359a2d511d3f09268` |
| `reflaxe.ruby-1.10.2.zip.sha256.json` | `reflaxe.ruby 1.10.2 SHA-256 metadata` | 317 | `517fe0b4470a2ee09d87d8d5996e2d426e5606487523ec0cefe865bb7925e4a6` |

Each downloaded sidecar binds its artifact to version `1.10.2`, tag
`v1.10.2`, the tested source SHA, hosted filename, byte count, and matching
digest. The extracted ZIP and gem embed the same release provenance. Their
complete format-1 manifests verify 714 Haxelib payload entries and 334 gem
payload entries with no missing, altered, duplicate, or extra content. A fresh
release preparation from the clean tested commit under Ruby 3.4.10 and
RubyGems 3.6.9 reproduced all four hosted files byte-for-byte.

The compiler slice keeps the existing Pattern B architecture. Structural
`RubyBeginRescue` and `RubyRaise` nodes are exhaustive in the authoritative
child schema, validated before printing, and printed without semantic repair.
The one-way 133-line `RubyExceptionLowering` service retains pre-filter Haxe
catch types only until ordinary Ruby AST exists, reports request-local runtime
requirements explicitly, dispatches catch arms in source order, and preserves
native exception identity and backtraces through unmatched or explicit
rethrows. The checked raw/print-reembed inventory fell from 324 to 318 sites.
No general semantic IR, pass framework, metadata side channel, or unowned
`ensure` representation was added.

## Post-1.10.2 structural-refactor no-release continuity

The bounded loop and Int32 architecture slices after `v1.10.2` deliberately
preserved the public release contract. Each push ran the complete canonical
workflow on its exact source SHA, and each gated release job independently
classified the accumulated `refactor`/`docs` lineage as non-releasing:

| Slice | Exact tested SHA | Canonical workflow | Gated release job | Result |
| --- | --- | --- | --- | --- |
| Structural residual-loop lowering | `8473e5a81889e321cad702cb14cc01aa0aa6af5d` | [`29681012077`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29681012077) | [`88180018806`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29681012077/job/88180018806) | All 14 jobs passed; two commits analyzed, `no release` |
| Loop evidence closure | `0e4eb15a44b374f4bba56b3ee617ea527c2890b1` | [`29682199568`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29682199568) | [`88183201982`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29682199568/job/88183201982) | All 14 jobs passed; three commits analyzed, `no release` |
| Structural Int32 lowering | `cf1cbfcecc60b44ecc5e53f0a69dd5675ebc74eb` | [`29685310179`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29685310179) | [`88191589080`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29685310179/job/88191589080) | All 14 jobs passed; four commits analyzed, `no release` |

Every release job logged `There are no relevant changes, so no new version is
released.` After the Int32 run, neither a `v1.10.3` remote tag nor GitHub
Release exists. `v1.10.2` remains the latest release, remains natively
immutable, and still has exactly the four verified assets recorded above.

Both compiler slices use the existing structural Ruby AST rather than adding a
semantic IR, pass framework, or printer repair. The checked raw/print-reembed
inventory fell from 318 sites after exception lowering to 311 after residual
loop lowering and 300 after fixed-width Int32 lowering.

## Stable 1.10 structural lowering and development-loop publication

The normal tested-commit workflow first published
[`v1.10.0`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.10.0)
on 2026-07-18 for the bounded structural-lowering plan from GitHub issue 20
and the change-aware RailsHx development loop. Independent artifact
verification then found a local packaging-tool selection defect, not a defect
in the CI-pinned `v1.10.0` bytes. The follow-up tested-commit workflow
published immutable
[`v1.10.1`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.10.1)
with the packaging fix; `v1.10.1` is the final evidence baseline for this
slice.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `639701ae779764573633970d14b694314a20ca4b` |
| Included implementation lineage | `eddf957` structural Ruby lowering plans, `9ce3887` change-aware RailsHx development loop, `fc381a1` refreshed structural route-parity fixture, and `639701a` selected-Ruby gem packaging fix |
| Canonical release tag | `v1.10.1`, a lightweight remote tag resolving directly to the tested source SHA |
| Same-run CI workflow | [`29663936094`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29663936094), `success`; all 14 security, formatter, Node compatibility, release-contract, browser, production, Ruby 3.3/3.4/4.0 compiler/package, Rails 8.1.3 runtime, and publication jobs passed |
| Privileged release job | [`88134002479`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29663936094/job/88134002479), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false`, and `immutable=true`; published at `2026-07-18T23:21:09Z` |
| Release notes | Version heading, `v1.10.0...v1.10.1` compare link, categorized bug-fix bullet, and exact `639701a` commit link |

The completed release has exactly the four allowed assets. Values below were
checked against the GitHub Releases API and independently downloaded and
hashed:

| Hosted artifact | Label | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `hxruby-1.10.1.gem` | `hxruby 1.10.1 Ruby gem` | 275456 | `4642d04b10b9f87c944769b4fe4d5bc9bd0e58f1dac280a03fce680b57a046dd` |
| `hxruby-1.10.1.gem.sha256.json` | `hxruby 1.10.1 SHA-256 metadata` | 304 | `c3fc024597dfcf3a6f84d783cdce0511aed73e149fdddedf880f5c26d44fbe94` |
| `reflaxe.ruby-1.10.1.zip` | `reflaxe.ruby 1.10.1 haxelib package` | 1294928 | `b0f88dd0fd4bc7f482a9e1f341ef6523bb53a007e47fad064ed8d32f1a800779` |
| `reflaxe.ruby-1.10.1.zip.sha256.json` | `reflaxe.ruby 1.10.1 SHA-256 metadata` | 317 | `9c5f3e891c38fa61bbf031490e69c8c2795a8b6b9b1bdde9ec70a877fa0261f8` |

Each downloaded sidecar binds its artifact to version `1.10.1`, tag
`v1.10.1`, the tested source SHA, hosted filename, byte count, and
independently matching digest. The extracted ZIP and gem embed the same
release provenance. Their complete format-1 manifests verify 712 Haxelib
payload entries and 334 gem payload entries. A fresh local release preparation
from the clean tested commit, with no version-manager override, reproduced both
hosted artifacts byte-for-byte.

The compiler slice keeps one final Ruby AST print boundary, validates the
structural AST before printing, represents arrays, conditional/block
expressions, switch/case, and enum access structurally, composes callable
decisions into one per-method plan, and gives every `hxruby` helper call a
closed helper/intent contract. The checked inventory owns 322 remaining raw or
print-reembed sites. Runtime, snapshot, callable ABI, all 32 examples, browser,
and production evidence passed without a semantic output regression.

The development slice adds one packaged `hxruby:dev` loop with an initial
server/client build, target-directed HXML and transitive Lix resolver input
discovery, change snapshots, debounce/coalescing, affected-target rebuilds, and
recovery after compile failures. Generated RailsHx applications and the todo
dogfood app use the coordinated runner, while the existing watch aliases remain
compatible.

The independently downloaded `v1.10.0` assets were also correct: their API
digests, sidecars, embedded manifests, and an explicitly Ruby-3.4.10-selected
local rebuild all matched. The mismatch appeared only when the old local gem
builder entered a temporary directory and a cwd-sensitive rbenv shim fell back
from repository Ruby 3.4.10/RubyGems 3.6.9 to system RubyGems 3.0.3.1. The
`v1.10.1` builder now resolves `RbConfig.ruby` in repository context and runs
both the executable gemspec and `Gem::GemRunner` under that absolute
interpreter. An executable regression fixture places hostile cwd-sensitive
`ruby` and `gem` shims first on `PATH`; artifact reproducibility must still
pass. `v1.10.0` remains valid and immutable, while `v1.10.1` hardens future
local and hosted rebuild agreement.

## Stable 1.9 typed ActionCable client-channel publication

The normal tested-commit workflow published
[`v1.9.0`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.9.0)
on 2026-07-18 for inferred, typed ActionCable browser subscriptions.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `b1fba23972223a1da0a469c21402375c224192e0` |
| Release intent | `feat: infer typed ActionCable client channels`, followed by the generated stdlib-gap report refresh on the tested SHA |
| Canonical release tag | `v1.9.0`, a lightweight remote tag resolving directly to the tested source SHA |
| Same-run CI workflow | [`29653863727`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29653863727), `success`; all 14 security, formatter, Node compatibility, release-contract, browser, production, Ruby 3.3/3.4/4.0 compiler/package, Rails 8.1.3 runtime, and publication jobs passed |
| Privileged release job | [`88107898499`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29653863727/job/88107898499), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false`, and `immutable=true`; published at `2026-07-18T18:03:40Z` |
| Release notes | Version heading, `v1.8.0...v1.9.0` compare link, categorized feature bullet, and exact implementation commit link |

The completed release has exactly the four allowed assets. Values below were
checked against the GitHub Releases API and independently downloaded and
hashed:

| Hosted artifact | Label | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `hxruby-1.9.0.gem` | `hxruby 1.9.0 Ruby gem` | 271872 | `8c22667b3e52a3ad3e76691fdcc3f30887a5b23c841b56414e19eaccf04e7068` |
| `hxruby-1.9.0.gem.sha256.json` | `hxruby 1.9.0 SHA-256 metadata` | 301 | `c64e96cae257be715224628f04864e9e065b8307b3d89ade49d41bff0557aa1b` |
| `reflaxe.ruby-1.9.0.zip` | `reflaxe.ruby 1.9.0 haxelib package` | 1265077 | `4c305def72d09834a8f59c8d9bcc98be106a75ab09a65aacdeced8035166e012` |
| `reflaxe.ruby-1.9.0.zip.sha256.json` | `reflaxe.ruby 1.9.0 SHA-256 metadata` | 314 | `941de41fe4cc6addea43e323db909d2f904176e6a2e8512556f1c8de918cffe3` |

Each downloaded sidecar binds its artifact to version `1.9.0`, tag `v1.9.0`,
the tested source SHA, hosted filename, byte count, and independently matching
digest. The extracted ZIP and gem embed the same release provenance. Their
complete format-1 manifests verify 705 Haxelib payload entries and 333 gem
payload entries. Both contain `rails.action_cable.ChannelRef`, the compatible
`Consumer` escape surface, and the `ChannelMacro` that infers the channel
constant and both generic types; the Haxelib package places its class path under
`src/`, while the gem intentionally retains the repository's `std/` layout.

Focused generated-shape and Node runtime evidence proves that
`TodosChannel.client.subscribe(...)` emits a direct native
`consumer.subscriptions.create(...)` call without a client wrapper or compiled
server class. Negative compilation owns wrong params, wrong payload callbacks,
non-channel classes, and unchecked strings. Vendored Genes module output and
the real ActionCable/Rails runtime pass, while Ruby channel output remains
unchanged. GitHub reports the completed release as natively immutable, and the
active protected-tag ruleset still forbids deletion and non-fast-forward
updates to `refs/tags/v*` with no bypass actor.

## Stable 1.8 typed Regexp and MatchData publication

The normal tested-commit workflow published
[`v1.8.0`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.8.0)
on 2026-07-18 for the bounded typed native Ruby Regexp and MatchData facades.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `2cca60633bbff57a175f93524131547ef5cab3c9` |
| Release intent | `feat: add typed Ruby Regexp facades` |
| Canonical release tag | `v1.8.0`, a lightweight remote tag resolving directly to the tested source SHA |
| Same-run CI workflow | [`29630132266`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29630132266), `success`; all 14 security, formatter, Node compatibility, release-contract, browser, production, Ruby 3.3/3.4/4.0 compiler/package, Rails 8.1.3 runtime, and publication jobs passed |
| Privileged release job | [`88044807989`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29630132266/job/88044807989), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false`, and `immutable=true`; published at `2026-07-18T04:48:11Z` |
| Release notes | Version heading, `v1.7.0...v1.8.0` compare link, categorized feature bullet, and exact commit link |

The completed release has exactly the four allowed assets. Values below were
checked against the GitHub Releases API and independently downloaded and
hashed:

| Hosted artifact | Label | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `hxruby-1.8.0.gem` | `hxruby 1.8.0 Ruby gem` | 269824 | `bbaab3b97a9061319211a8ceaf2a926ff75b8b35a75d19d3faa3d032bef6943c` |
| `hxruby-1.8.0.gem.sha256.json` | `hxruby 1.8.0 SHA-256 metadata` | 301 | `2e48a3cf9b444bfd8f8db3c2620c5c4a9e2a9d5210f795b53089635de86045c0` |
| `reflaxe.ruby-1.8.0.zip` | `reflaxe.ruby 1.8.0 haxelib package` | 1260704 | `ead6f6130491162bafd8d9472822e9bb7c64e37f8a932bd5294239f1c2248f54` |
| `reflaxe.ruby-1.8.0.zip.sha256.json` | `reflaxe.ruby 1.8.0 SHA-256 metadata` | 314 | `9939cc982e27417acf683f90428c3cab492caf81c8dcf282d5ae4376f8de688e` |

Each downloaded sidecar binds its artifact to version `1.8.0`, tag `v1.8.0`,
the tested source SHA, hosted filename, byte count, and independently matching
digest. The extracted ZIP and gem embed the same release provenance. Their
complete format-1 manifests verify 704 ZIP payload entries and 332 gem payload
entries, including `ruby.Regexp`, `ruby.MatchData`, `ruby.RegexpOptions`,
`ruby.RegexpCompileOptions`, and `ruby.MatchOffset`.

The facade exposes Ruby's native regexp and match objects without a wrapper
runtime, limits flags and per-instance timeout configuration to typed closed
contracts, and deliberately leaves global last-match state, arbitrary integer
or encoding flags, byte offsets, unchecked named capture lookup, open ranges,
heterogeneous match unions, block overloads, and mutable class-wide timeout
configuration outside the bounded surface. Haxe `EReg` remains the separate
Haxe-semantics adapter; it reuses the native typed `Regexp.escape` and
`MatchData` contracts only where their semantics align. GitHub reports the
completed release as natively immutable.

## Stable 1.7 modern temporal publication

The normal tested-commit workflow published
[`v1.7.0`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.7.0)
on 2026-07-17 for the modern Ruby and Rails temporal facades.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `cdb9080c4ea4bbd8d95b682cd196dce314f237da` |
| Release intent | `feat: add modern Ruby and Rails temporal facades`, followed by `fix: update sanitizer dependencies for advisories` on the published tested SHA |
| Canonical release tag | `v1.7.0`, a lightweight remote tag resolving directly to the tested source SHA |
| Same-run CI workflow | [`29619029159`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29619029159), `success`; all 14 security, formatter, Node compatibility, release-contract, browser, production, Ruby 3.3/3.4/4.0 compiler/package, Rails 8.1.3 runtime, and publication jobs passed |
| Privileged release job | [`88015099224`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29619029159/job/88015099224), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false`, and `immutable=true`; published at `2026-07-17T23:27:55Z` |
| Release notes | Version heading, `v1.6.0...v1.7.0` compare link, categorized feature and bug-fix bullets, and exact links to both commits |

The completed release has exactly the four allowed assets. Values below were
checked against the GitHub Releases API and independently downloaded and
hashed:

| Hosted artifact | Label | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `hxruby-1.7.0.gem` | `hxruby 1.7.0 Ruby gem` | 266752 | `ed9df6dcd22a53e11063f9da7038c5e1eea28b2db9db75de6384518ae33dbf8c` |
| `hxruby-1.7.0.gem.sha256.json` | `hxruby 1.7.0 SHA-256 metadata` | 301 | `be7323dc320c408acfd91e1c41f0f005931f11336056c086d7b075f57befaaf0` |
| `reflaxe.ruby-1.7.0.zip` | `reflaxe.ruby 1.7.0 haxelib package` | 1251873 | `05dfa672f21e123def58737e934b33083f1144ad8ec35165f934c257f9e53864` |
| `reflaxe.ruby-1.7.0.zip.sha256.json` | `reflaxe.ruby 1.7.0 SHA-256 metadata` | 314 | `62c4414f0ca103e7afe38668887e003f429d703aed640e013a5318900b01bced` |

Each downloaded sidecar binds its artifact to version `1.7.0`, tag `v1.7.0`,
the tested source SHA, hosted filename, byte count, and independently matching
digest. The extracted ZIP and gem embed the same release provenance. Their
complete format-1 manifests verify 699 ZIP payload entries and 327 gem payload
entries, including `ruby.TimeParsing`, `rails.active_support.RailsTime`,
`rails.active_support.TimeZone`, and
`rails.active_support.TimeWithZone`. The Haxelib artifact also contains the
modern temporal API guide.

The facade keeps core `ruby.Time` require-free, loads Ruby's `time` default gem
only for strict `Time.iso8601` and `Time.strptime` parsing, and loads both
`active_support` and `active_support/time` for Rails zoned values. The base
ActiveSupport load is required outside a fully booted Rails application because
`TimeWithZone#to_time` reads ActiveSupport configuration initialized there.
Canonical Rails application code uses `Time.current`, `Time.zone`, and
`ActiveSupport::TimeWithZone`; a Rails `datetime` database column does not imply
Ruby's legacy `DateTime` class. `DateTime`, heuristic parsing, mutable global
zone configuration, open duration/calendar arithmetic, ambiguous-local-time
controls, and raw TZInfo contracts remain outside this bounded surface.

The tested source also updates `loofah` to `2.25.2` and
`rails-html-sanitizer` to `1.7.1`. The fresh ruby-advisory-db audit at
`5fdc4fb65d1fbc08c9ba5346d45dd619f6668c1e` found no vulnerable dependencies,
while its vulnerable control fixture was still detected. GitHub reports the
completed release as natively immutable.

## Stable 1.6 typed Time and Date publication

The normal tested-commit workflow published
[`v1.6.0`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.6.0)
on 2026-07-17 for the bounded native Ruby Time and Date facades.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `449770dcee471fc349db69149f8b48ffa43e3644` |
| Release intent | `feat: add typed Ruby Time and Date facades`, followed by `fix: preserve generated feature resolution` on the published tested SHA |
| Canonical release tag | `v1.6.0`, a lightweight remote tag resolving directly to the tested source SHA |
| Same-run CI workflow | [`29564630637`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29564630637), `success`; all 14 security, formatter, Node compatibility, release-contract, browser, production, Ruby 3.3/3.4/4.0 compiler/package, Rails 8.1.3 runtime, and publication jobs passed |
| Privileged release job | [`87841193089`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29564630637/job/87841193089), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false`, and `immutable=true`; published at `2026-07-17T08:33:48Z` |
| Release notes | Version heading, `v1.5.0...v1.6.0` compare link, categorized feature and bug-fix bullets, and exact links to both commits |

The completed release has exactly the four allowed assets. Values below were
checked against the GitHub Releases API and independently downloaded and
hashed:

| Hosted artifact | Label | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `hxruby-1.6.0.gem` | `hxruby 1.6.0 Ruby gem` | 264192 | `a56e5a1d214f741fb67f650f01762752a1b6ec11816be49cac8cf3f66546e86d` |
| `hxruby-1.6.0.gem.sha256.json` | `hxruby 1.6.0 SHA-256 metadata` | 301 | `adc7dcad2c44a61024a6c834530dd9db23a94f6a17e2ced9d70d667627fc052f` |
| `reflaxe.ruby-1.6.0.zip` | `reflaxe.ruby 1.6.0 haxelib package` | 1241445 | `1a38381de339f8c428043b1b8acdc08e702afc8b4b8d8d9aa5afe419c5bc83ea` |
| `reflaxe.ruby-1.6.0.zip.sha256.json` | `reflaxe.ruby 1.6.0 SHA-256 metadata` | 314 | `5e5beb13c0c754fb19379d1c78345aef1ee16613bbe7f494ea2659045e63ea57` |

Each downloaded sidecar binds its artifact to version `1.6.0`, tag `v1.6.0`,
the tested source SHA, hosted filename, byte count, and independently matching
digest. The extracted ZIP and gem embed the same release provenance. Their
complete format-1 manifests verify 694 ZIP payload entries and
323 gem payload entries. Both contain `ruby.Time` and `ruby.Date`; the Haxelib
artifact also contains the collision policy that emits portable Haxe `Date` as `HxDate` from
`hx_date.rb`, leaving native `ruby.Date` bound to Ruby's `Date` and
`require "date"`.

The first implementation push at `6c41fdd307529a546b501d4e4234c4aebfda2014`
failed closed in workflow
[`29560749968`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29560749968):
the Ruby 3.3/3.4/4.0 compiler jobs reproduced an over-broad require-order
change, the publication job was never created, and no tag or draft was
published. The tested fix restored load-path-first feature resolution while
retaining the narrower `HxDate`/`hx_date.rb` collision boundary. Open Numeric
and timezone protocols, subsecond units, Rational values, permissive parsing,
timezone databases, mutating conversion, calendar-reform controls,
enumerators, unchecked option bags, and `ruby.DateTime` remain outside the
bounded contract. GitHub reports the completed release as natively immutable.

## Stable 1.5 typed Set publication

The normal tested-commit workflow published
[`v1.5.0`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.5.0)
on 2026-07-17 for the bounded typed native Ruby Set facade.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `4fb3bfef55f6c5382fddfb569f8fa21527078bd2` |
| Release intent | `feat: add typed Ruby Set facade` |
| Canonical release tag | `v1.5.0`, a lightweight remote tag resolving directly to the tested source SHA |
| Same-run CI workflow | [`29542618466`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29542618466), `success`; all 14 security, formatter, Node compatibility, release-contract, browser, production, Ruby 3.3/3.4/4.0 compiler/package, Rails 8.1.3 runtime, and publication jobs passed |
| Privileged release job | [`87772812982`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29542618466/job/87772812982), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false`, and `immutable=true`; published at `2026-07-17T00:15:13Z` |
| Release notes | Version heading, `v1.4.0...v1.5.0` compare link, categorized feature bullet, and exact commit link |

The completed release has exactly the four allowed assets. Values below were
checked against the GitHub Releases API and independently downloaded and
hashed:

| Hosted artifact | Label | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `hxruby-1.5.0.gem` | `hxruby 1.5.0 Ruby gem` | 261632 | `5dff6d1f868b6f5790b347b81be1e743c6a18172f14067456bae2d9849fad7ff` |
| `hxruby-1.5.0.gem.sha256.json` | `hxruby 1.5.0 SHA-256 metadata` | 301 | `2a89f12c16892a352b26c30922423d3a10b3fe34d00fe8c26e4b6f0af8d43b86` |
| `reflaxe.ruby-1.5.0.zip` | `reflaxe.ruby 1.5.0 haxelib package` | 1233888 | `1ca13027cdbb2c8c2976a6f43da7272f8623ca25c7e05f2a827687736347bb7c` |
| `reflaxe.ruby-1.5.0.zip.sha256.json` | `reflaxe.ruby 1.5.0 SHA-256 metadata` | 314 | `e4864df593b6a4c84cd0ae05c6bbac86d6c0730e319aef26c77c6246e2785273` |

Each downloaded sidecar binds its artifact to version `1.5.0`, tag `v1.5.0`,
the tested source SHA, hosted filename, byte count, and independently matching
digest. The extracted ZIP and gem embed the same release provenance. Their
complete format-1 manifests verify 691 ZIP payload entries and 321 gem payload entries.
Both contain `ruby.Set`; the facade deliberately keeps open
Enumerable inputs, variadic construction and merge, type-changing transforms,
classify/divide/flatten, identity-comparison mode, mutable-element reset,
subclass/CoreSet contracts, implicit Haxe iteration, raw operators, and
unchecked values outside this bounded same-element native Set contract. GitHub
reports the completed release as natively immutable.

## Stable 1.4 typed Open3 publication

The normal tested-commit workflow published
[`v1.4.0`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.4.0)
on 2026-07-16 for the bounded typed Ruby Open3 direct-exec capture facade.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `7cfc67c49485c7993404cb5347371984891b2de3` |
| Release intent | `feat: add typed Ruby Open3 capture facade` |
| Canonical release tag | `v1.4.0`, a lightweight remote tag resolving directly to the tested source SHA |
| Same-run CI workflow | [`29527916051`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29527916051), `success`; all 14 security, formatter, Node compatibility, release-contract, browser, production, Ruby 3.3/3.4/4.0 compiler/package, Rails 8.1.3 runtime, and publication jobs passed |
| Privileged release job | [`87728835448`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29527916051/job/87728835448), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false`, and `immutable=true`; published at `2026-07-16T20:02:03Z` |
| Release notes | Version heading, `v1.3.0...v1.4.0` compare link, categorized feature bullet, and exact commit link |

The completed release has exactly the four allowed assets. Values below were
checked against the GitHub Releases API and independently downloaded and
hashed:

| Hosted artifact | Label | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `hxruby-1.4.0.gem` | `hxruby 1.4.0 Ruby gem` | 260096 | `d35e419f60d5e4caaac19980fd7a68679bc6b66793e51269c2f413c4deb46820` |
| `hxruby-1.4.0.gem.sha256.json` | `hxruby 1.4.0 SHA-256 metadata` | 301 | `3ad0b5de4991f0f56eabadf8104240e44472acac7590d20c0d1aa8778ddbc832` |
| `reflaxe.ruby-1.4.0.zip` | `reflaxe.ruby 1.4.0 haxelib package` | 1230120 | `46922a0f586344ac41f14dc28e4154ba01762deb19fd3060d6ff4b2486c91476` |
| `reflaxe.ruby-1.4.0.zip.sha256.json` | `reflaxe.ruby 1.4.0 SHA-256 metadata` | 314 | `bc52cadcfdafb9b8b3c5f6aa6fc5e63b88ba1ddd55805cd238d43fc144b1df38` |

Each downloaded sidecar binds its artifact to version `1.4.0`, tag `v1.4.0`,
the tested source SHA, hosted filename, byte count, and independently matching
digest. The extracted ZIP and gem embed the same release provenance. Their
complete format-1 manifests verify
690 ZIP payload entries and 320 gem payload entries. Both contain `ruby.Open3`,
`ruby.Open3Executable`,
`ruby.Open3Capture`, and `ruby.Open3Status`. The facade deliberately accepts
only direct-exec capture input and omits shell command strings,
environment/process option hashes, stdin/binmode keywords, popen streams,
pipelines, and unchecked argument bags. GitHub reports the completed release
as natively immutable.

## Stable 1.3 typed CSV publication

The normal tested-commit workflow published
[`v1.3.0`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.3.0)
on 2026-07-16 for the bounded typed Ruby CSV facade.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `26d65f1f5d46ebe0e6a4b98ffc412986dbe3bcb5` |
| Release intent | `feat: add typed Ruby CSV facade` |
| Canonical release tag | `v1.3.0`, a lightweight remote tag resolving directly to the tested source SHA |
| Same-run CI workflow | [`29516435128`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29516435128), `success`; all 14 security, formatter, Node compatibility, release-contract, browser, production, Ruby 3.3/3.4/4.0 compiler/package, Rails 8.1.3 runtime, and publication jobs passed |
| Privileged release job | [`87690920663`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29516435128/job/87690920663), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false`, and `immutable=true`; published at `2026-07-16T17:15:01Z` |
| Release notes | Version heading, `v1.2.0...v1.3.0` compare link, categorized feature bullet, and exact commit link |

The completed release has exactly the four allowed assets. Values below were
checked against the GitHub Releases API and independently downloaded and
hashed:

| Hosted artifact | Label | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `hxruby-1.3.0.gem` | `hxruby 1.3.0 Ruby gem` | 258048 | `1665f3880486886cdc655c1e79cfb0138779951959cc595901b289a166d45cb0` |
| `hxruby-1.3.0.gem.sha256.json` | `hxruby 1.3.0 SHA-256 metadata` | 301 | `0f319ec18d9ef3e7403418b9eec10897832b948fb3854cbccf6e9976a755109a` |
| `reflaxe.ruby-1.3.0.zip` | `reflaxe.ruby 1.3.0 haxelib package` | 1225098 | `866d7d9a56baffa2fb3395385a93fbff13cd5dc845e786aeb2e6423f02f63103` |
| `reflaxe.ruby-1.3.0.zip.sha256.json` | `reflaxe.ruby 1.3.0 SHA-256 metadata` | 314 | `1ad2cbcea5ce089b5d5103db38f3910d0a5e60a3f381bf4bae8baeb437426809` |

Each downloaded sidecar binds its artifact to version `1.3.0`, tag `v1.3.0`,
the tested source SHA, hosted filename, byte count, and independently matching
digest. The extracted ZIP and gem embed the same release provenance. Their
complete format-1 manifests verify
686 ZIP payload entries and 316 gem payload entries. Both contain `ruby.CSV`,
`ruby.CSVRow`, `ruby.CSVParseOptions`, and
`ruby.CSVGenerateOptions`; the facade deliberately keeps headers, tables,
converters, arbitrary field objects, IO inputs, encodings, and unchecked
keyword splats outside this bounded string-row contract. GitHub reports the
completed release as natively immutable.

## Stable 1.2 deterministic RBS publication

The normal tested-commit workflow published
[`v1.2.0`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.2.0)
on 2026-07-16 for the packaged strict deterministic RBS-to-Haxe extern
generator foundation.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `ffec2b5993e557bc72ea6fe9a18dd3a4623db9fa` |
| Release intent | `feat: add deterministic RBS extern generation` |
| Canonical release tag | `v1.2.0`, a lightweight remote tag resolving directly to the tested source SHA |
| Same-run CI workflow | [`29485362922`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29485362922), `success`; all 14 security, formatter, Node compatibility, release-contract, browser, production, Ruby 3.3/3.4/4.0 compiler/package, Rails 8.1.3 runtime, and publication jobs passed |
| Privileged release job | [`87585643211`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29485362922/job/87585643211), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false`, and `immutable=true`; published at `2026-07-16T09:34:08Z` |
| Release notes | Version heading, `v1.1.0...v1.2.0` compare link, categorized feature bullet, and exact commit link |

The completed release has exactly the four allowed assets. Values below were
checked against the GitHub Releases API and independently downloaded and
hashed:

| Hosted artifact | Label | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `hxruby-1.2.0.gem` | `hxruby 1.2.0 Ruby gem` | 256512 | `91ad1664cac4da435cbaad1d6e1eb2003c6da76cbdcc8201bde650f5ce888e80` |
| `hxruby-1.2.0.gem.sha256.json` | `hxruby 1.2.0 SHA-256 metadata` | 301 | `7d51c200f24d46d4fc8cefb80c5ef8deca3d3de05d583aab529c28ea80daa1ac` |
| `reflaxe.ruby-1.2.0.zip` | `reflaxe.ruby 1.2.0 haxelib package` | 1219799 | `c09207cb849f6c56b4f029a81a0672f5e3ffd3c227854943e952b798a06de205` |
| `reflaxe.ruby-1.2.0.zip.sha256.json` | `reflaxe.ruby 1.2.0 SHA-256 metadata` | 314 | `130a9d1b68f65c6b5e0dbfbab5a1529daca0c1d271a154f72f7f1b7b4f9cf83b` |

Each downloaded sidecar binds its artifact to version `1.2.0`, tag `v1.2.0`,
the tested source SHA, hosted filename, byte count, and independently matching
digest. The extracted ZIP and gem embed the same release provenance. Their
format-1 manifests verify 682 ZIP payload entries and 312 gem payload entries.
Both contain the shared `HXRuby::Rbs` parser, canonical renderer, checked source
selector, and CLI library. The gem additionally contains the maintainer wrapper;
the Haxelib ZIP retains its reviewed no-`scripts/` layout. `CSV`, `Open3`, and
`Set` remain planned rather than acquiring support by generator inference.
GitHub reports the completed release as natively immutable.

## Stable 1.1 typed stdlib publication

The normal tested-commit workflow published
[`v1.1.0`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.1.0)
on 2026-07-16 for the first versioned Ruby stdlib-catalog slice and typed URI
facade.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `9404b5e5f71f268153c59e1943e615e5d2eb6eaf` |
| Release intent | `feat: add typed Ruby URI catalog slice` |
| Canonical release tag | `v1.1.0`, a lightweight remote tag resolving directly to the tested source SHA |
| Same-run CI workflow | [`29474882954`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29474882954), `success`; all 14 security, formatter, Node compatibility, release-contract, browser, production, Ruby 3.3/3.4/4.0 compiler/package, Rails 8.1.3 runtime, and publication jobs passed |
| Privileged release job | [`87551001411`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29474882954/job/87551001411), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false`, and `immutable=true`; published at `2026-07-16T06:26:01Z` |
| Release notes | Version heading, `v1.0.0...v1.1.0` compare link, categorized feature bullet, and exact commit link |

The completed release has exactly the four allowed assets. Values below were
checked against the GitHub Releases API and independently downloaded and
hashed:

| Hosted artifact | Label | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `hxruby-1.1.0.gem` | `hxruby 1.1.0 Ruby gem` | 251392 | `a854c8357c76a2831e5be04d9eb7726b124b7b335679286257204365c1898c41` |
| `hxruby-1.1.0.gem.sha256.json` | `hxruby 1.1.0 SHA-256 metadata` | 301 | `da1c5971cc45f7f0bd5a8f215bf4d37a6ca4b605ca030c48a70799f342d4d1be` |
| `reflaxe.ruby-1.1.0.zip` | `reflaxe.ruby 1.1.0 haxelib package` | 1208622 | `048afed2aead8a4933813d157b3f4a530183e3a646cd91d7485711daf0312b22` |
| `reflaxe.ruby-1.1.0.zip.sha256.json` | `reflaxe.ruby 1.1.0 SHA-256 metadata` | 314 | `fffd6605c3a669b64958fd23ab53c493350b844a67a03188ce6847bf9ffdc11e` |

Each downloaded sidecar binds its artifact to version `1.1.0`, tag `v1.1.0`,
the tested source SHA, hosted filename, byte count, and independently matching
digest. The extracted ZIP and gem embed the same release provenance. Their
format-1 manifests verify 676 ZIP payload entries and 306 gem payload entries;
the packaged catalog contains 20 bounded domains, and both artifacts contain
the new `ruby.URI` and `ruby.URIValue` contracts. GitHub reports the completed
release as natively immutable.

## Stable 1.0 publication

The maintainer approved stable major 1 under RHX-1.0-011, and the normal
tested-commit workflow published
[`v1.0.0`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v1.0.0)
on 2026-07-15. This was the first release under the combined stable `1.x`
RubyHx and RailsHx compatibility contract.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `82f7b09d807bd468febd98bf540a391d3484857a` |
| Release intent | `feat: graduate RubyHx and RailsHx to stable 1.0`, with an explicit `BREAKING CHANGE` establishing the documented stable `1.x` contract |
| Canonical release tag | `v1.0.0`, a lightweight tag whose local ref, fetched origin ref, and remote ref all resolve directly to the tested source SHA |
| Same-run CI workflow | [`29452140844`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29452140844), `success`; all 13 security, formatter, release-contract, browser, production, Ruby compiler/package, and Rails 8.1.3 runtime prerequisite jobs passed |
| Privileged release job | [`87483615576`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29452140844/job/87483615576), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false`, and `immutable=true`; published at `2026-07-15T22:06:03Z` |
| Release notes | Version heading, `v0.9.0...v1.0.0` compare link, categorized feature bullet with the exact commit link, and an explicit breaking-changes section |

The completed release has exactly the four allowed assets. Values below were
checked against the GitHub Releases API and independently downloaded and
hashed:

| Hosted artifact | Label | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `hxruby-1.0.0.gem` | `hxruby 1.0.0 Ruby gem` | 247296 | `13d09d13347dff13c4fa8969fdecd6196a9392d29373edbbca7935d172a12ec9` |
| `hxruby-1.0.0.gem.sha256.json` | `hxruby 1.0.0 SHA-256 metadata` | 301 | `56274eda7fa8feef915e57e63821fb67ab8d1e9aaae9b003e1ae3aa0e06d3cde` |
| `reflaxe.ruby-1.0.0.zip` | `reflaxe.ruby 1.0.0 haxelib package` | 1186388 | `cb9c1fb6d97c4e1c7f2016915c28ba99eb1c70ddd19b480ef8300119e2d787d4` |
| `reflaxe.ruby-1.0.0.zip.sha256.json` | `reflaxe.ruby 1.0.0 SHA-256 metadata` | 314 | `2440e4f1f518040e598332206a4c171fec319e609eaeadaba957f742ab4b285f` |

Each sidecar records version `1.0.0`, tag `v1.0.0`, the tested source SHA,
the hosted filename, byte count, and matching consumer-artifact digest. The
extracted ZIP and gem both embed the same release provenance, `1.0.0` package
and runtime version metadata, and complete format-1 manifests. The maintained
manifest verifier accepted all 663 ZIP entries and all 303 gem entries with no
missing, altered, duplicate, or extra content. Native immutable releases remain
enabled, and active tag ruleset `18851281` still protects `refs/tags/v*` from
deletion and non-fast-forward changes with no bypass actor. GitHub Releases is
the only distribution host claimed for these bytes.

## First protocol publication

The first live publication was
[`v0.1.0`](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v0.1.0).
It promoted the historical prerelease lineage to the normal major-zero channel
without rewriting the historical tag.

| Evidence | Recorded value |
| --- | --- |
| Tested source SHA | `56c65adedf0a56b24a32a4161f9235171eac6cbe` |
| Canonical release tag | `v0.1.0`, a lightweight tag resolving directly to the tested source SHA |
| Same-run CI workflow | [`29215071466`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29215071466), `success` |
| Privileged release job | [`86712738698`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29215071466/job/86712738698), `success` |
| GitHub channel flags | `draft=false`, `prerelease=false` |
| GitHub native immutable flag | `false`; native immutability was enabled after this publication |

The exact two consumer artifacts were:

| Hosted artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `hxruby-0.1.0.gem` | 238592 | `281bab21677bb7dd24762baa612430d4a066ce25518b4e5467394009d76ba5da` |
| `reflaxe.ruby-0.1.0.zip` | 1073801 | `cfa2f0c74d727974cc9849758254aabfec6dae3e4efbd1ed226ef6ee003c0de1` |

Their required sidecars were also hosted as
`hxruby-0.1.0.gem.sha256.json` (301 bytes, SHA-256
`1d0933225255e1861c7ea8fd99961d62dc6e425c0f150498b7e109b9f2b6800a`)
and `reflaxe.ruby-0.1.0.zip.sha256.json` (314 bytes, SHA-256
`f0fce041485b8de3be3ecb150283c7c35c9b0b6ee2fba5b13b07b20b3d6d3ea3`).
Each sidecar binds its artifact to version `0.1.0`, tag `v0.1.0`, and the
tested source SHA above.

## Tag and channel transition

Historical `v0.1.0-beta.2` is an annotated tag object
`a78bb96858e02210388be66c7b3ba4edfa94e813`, peeled to source commit
`a45eb02dd1dbaaa8bc8dec0da426613c3c3e0e98`. That commit is an ancestor of
`v0.1.0`; the beta release remains `prerelease=true`, while `v0.1.0` is
`prerelease=false`. The transition-only local `v0.0.0` alias is absent from the
remote tag set. This proves promotion into the normal `0.x` channel rather than
continued publication on a hidden beta channel.

The repository tag ruleset `18851281` protects every `refs/tags/v*` ref from
deletion and non-fast-forward updates with no bypass actor. Native immutable
releases are now enabled. GitHub applies that setting only to subsequently
published releases, so historical `v0.1.0` honestly remains
`immutable=false`; its tag and four verified assets must not be recreated just
to change that flag.

## Immutable publication and repair proofs

Two follow-up releases exercised both hosted paths after native immutability
was enabled:

| Release | Source SHA | Proof | Result |
| --- | --- | --- | --- |
| `v0.1.1` | `bc05a4ffe2f81d5c900e80b1aba1cf084e3ab45b` | Repair workflow [`29221904625`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29221904625), job [`86728591676`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29221904625/job/86728591676) | Existing tag repaired without deriving or moving a version; completed release `immutable=true` |
| `v0.1.2` | `7289d449766e17de47578df40d213a333be92111` | Normal CI workflow [`29221893930`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29221893930), release job [`86732732022`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29221893930/job/86732732022) | Exact same-run tested SHA published; completed release `immutable=true` |

`v0.1.2` also re-verified the current artifact contract: the gem is 239104
bytes with SHA-256
`6a431dd781fbf2f18ec35696bb70f6f8fbe018bfcabf2a549ca688b7b4420ef0`,
and the ZIP is 1077874 bytes with SHA-256
`9766346230560a2dae148cc5ba2e7590add4f68fe2c5b5d386c2836ef3c66675`.

## No-release continuity proof

The first commit after `v0.1.2` was
[`e485d098056cc3b1377a8b52928a302963570538`](https://github.com/fullofcaffeine/reflaxe.ruby/commit/e485d098056cc3b1377a8b52928a302963570538),
`docs: record live release protocol`. It changed documentation and release
contract assertions only.

| Evidence | Recorded value |
| --- | --- |
| Same-run CI workflow | [`29225406658`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29225406658), `success` |
| Privileged release job | [`86742889294`](https://github.com/fullofcaffeine/reflaxe.ruby/actions/runs/29225406658/job/86742889294), `success` |
| Required gate graph | Security/Gitleaks, formatter, release contracts, browser, production, and the historical Ruby compiler/package plus Rails runtime 3.2/3.3/4.0 matrix all `success`. The current matrix is defined separately in `lib/hxruby/support_matrix.json`. |
| Analyzer result | Found `v0.1.2`, analyzed exactly one commit, reported `no release`, and logged `There are no relevant changes, so no new version is released.` |
| Hosted result | No tag, GitHub Release, draft, asset, or release notes were created |

After completion, the complete remote version-tag set was still
`v0.1.0-beta.2`, `v0.1.0`, `v0.1.1`, and `v0.1.2`. Neither the local-only
transition alias `v0.0.0` nor a spurious `v0.1.3` existed. The GitHub Release
set remained the same four completed releases with zero drafts, `v0.1.2`
remained the newest release, and native immutable releases remained enabled.
This is a hosted same-run no-op proof, not merely a local analyzer simulation.

## Evidence reproduction

The durable values above came from the public Git tag, Release, asset, and
Actions APIs plus downloaded sidecars. Recheck them with read-only commands:

```bash
git ls-remote --tags origin
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.9.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.8.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.7.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.6.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.5.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.4.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.3.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.2.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.1.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.0.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v0.1.2
gh run view 29685310179 --json headSha,conclusion,jobs,url
gh run view 29682199568 --json headSha,conclusion,jobs,url
gh run view 29681012077 --json headSha,conclusion,jobs,url
gh run view 29653863727 --json headSha,conclusion,jobs,url
gh run view 29630132266 --json headSha,conclusion,jobs,url
gh run view 29619029159 --json headSha,conclusion,jobs,url
gh run view 29564630637 --json headSha,conclusion,jobs,url
gh run view 29560749968 --json headSha,conclusion,jobs,url
gh run view 29542618466 --json headSha,conclusion,jobs,url
gh run view 29527916051 --json headSha,conclusion,jobs,url
gh run view 29452140844 --json headSha,conclusion,jobs,url
gh run view 29516435128 --json headSha,conclusion,jobs,url
gh run view 29485362922 --json headSha,conclusion,jobs,url
gh run view 29474882954 --json headSha,conclusion,jobs,url
gh run view 29221893930 --json headSha,conclusion,jobs,url
gh run view 29221904625 --json headSha,conclusion,jobs,url
gh run view 29225406658 --json headSha,conclusion,jobs,url
gh api repos/fullofcaffeine/reflaxe.ruby/immutable-releases
gh api repos/fullofcaffeine/reflaxe.ruby/rulesets/18851281
```

See [Release Version Policy](release-version-policy.md),
[Reproducible Release Artifacts](release-artifacts.md),
[Tested-Commit Publication Workflow](release-publication-workflow.md), and
[Hosted Release Identity And Repair](release-hosting-and-repair.md) for the
normative protocol.
