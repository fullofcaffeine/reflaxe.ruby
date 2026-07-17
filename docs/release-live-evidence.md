# Live Release Protocol Evidence

This page records the hosted proof for the RubyHx tested-commit release
protocol. It is evidence, not mutable version configuration: canonical
`v<SemVer>` Git tags still own version lineage, and the release workflow still
derives every new version from Conventional Commits.

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
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.4.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.3.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.2.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.1.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.0.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v0.1.2
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
