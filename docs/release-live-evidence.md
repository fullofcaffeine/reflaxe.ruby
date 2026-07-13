# Live Release Protocol Evidence

This page records the hosted proof for the RubyHx tested-commit release
protocol. It is evidence, not mutable version configuration: canonical
`v<SemVer>` Git tags still own version lineage, and the release workflow still
derives every new version from Conventional Commits.

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

The next commit after `v0.1.2` deliberately changes documentation and release
contract assertions only. Its Conventional Commit type is `docs`, so the
locked analyzer must return no release while the complete same-run gate graph
remains green. After that hosted run completes, this section records its exact
commit, workflow, release-job identity, conclusion, and the unchanged remote
version-tag set. That two-step record distinguishes a real hosted no-op from a
local analyzer simulation.

## Evidence reproduction

The durable values above came from the public Git tag, Release, asset, and
Actions APIs plus downloaded sidecars. Recheck them with read-only commands:

```bash
git ls-remote --tags origin
gh api repos/fullofcaffeine/reflaxe.ruby/releases/tags/v0.1.2
gh run view 29221893930 --json headSha,conclusion,jobs,url
gh run view 29221904625 --json headSha,conclusion,jobs,url
gh api repos/fullofcaffeine/reflaxe.ruby/immutable-releases
gh api repos/fullofcaffeine/reflaxe.ruby/rulesets/18851281
```

See [Release Version Policy](release-version-policy.md),
[Reproducible Release Artifacts](release-artifacts.md),
[Tested-Commit Publication Workflow](release-publication-workflow.md), and
[Hosted Release Identity And Repair](release-hosting-and-repair.md) for the
normative protocol.
