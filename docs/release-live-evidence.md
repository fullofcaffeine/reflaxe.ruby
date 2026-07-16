# Live Release Protocol Evidence

This page records the hosted proof for the RubyHx tested-commit release
protocol. It is evidence, not mutable version configuration: canonical
`v<SemVer>` Git tags still own version lineage, and the release workflow still
derives every new version from Conventional Commits.

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
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.1.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v1.0.0
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v0.1.2
gh run view 29452140844 --json headSha,conclusion,jobs,url
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
