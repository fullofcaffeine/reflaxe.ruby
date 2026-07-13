# Release Version Policy

RubyHx uses normal `0.x` releases from `main`. Major zero already communicates
that the API is in initial development, so normal releases do not carry an
automatic `-beta` suffix. The existing `v0.1.0-beta.2` tag remains immutable
history and was the valid tag-derived baseline; the first qualifying main
release promoted that lineage to the ordinary `v0.1.0` version.

These are separate SemVer concepts. A `0.y.z` version communicates initial
development and may make breaking changes according to the major-zero bump
policy below. A suffix such as `-beta.2` is an explicit prerelease identifier
that sorts before its corresponding normal version and belongs to a deliberate
prerelease channel. RubyHx currently has no ongoing prerelease branch or
channel: normal `main` releases have no suffix and GitHub marks them
`prerelease=false`. Adding a future prerelease channel requires an explicit,
tested branch/channel policy; it cannot be inferred merely from major zero.

semantic-release intentionally excludes prerelease tags when it calculates the
last release for a stable branch. RubyHx handles that single historical
transition with `scripts/release/prepare-semver-transition.mjs`: when no stable
tag exists, it verifies that the configured `v0.1.0-beta.2` tag is the newest
canonical prerelease merged into the tested commit, then creates an ephemeral
local `v0.0.0` alias at exactly the same commit. The policy forces any
qualifying fix, feature, or major-zero breaking change to stable `0.1.0`, uses
the real beta tag in the generated compare link, and deletes the alias in the
first prepare hook before semantic-release can run `git push --tags`. The alias
is never pushed, released, or used after a stable tag exists. Missing,
persistent, mismatched, or non-newest transition tags fail closed.

This document owns version selection and the boundary into artifact staging.
Tracked version surfaces use the non-release `0.0.0` development sentinel.
Release preparation injects the selected version, matching tag, and tested
source SHA only into temporary Haxelib and gem trees and leaves the checkout
byte-identical. Normal publication is the final privileged job of the same
successful main-push workflow and checks out that run's exact SHA. Hosted
digest verification and existing-tag-only repair remain separate
release-protocol work. See `release-publication-workflow.md`.

## Conventional Commit mapping

`scripts/release/analyze-commits.mjs` delegates commit parsing to the installed
official `@semantic-release/commit-analyzer`, including both `type!:` headers
and `BREAKING CHANGE:` footers. It then applies only the major-zero and stable
major approval rules:

| Commit set | Current lineage | Result |
| --- | --- | --- |
| `fix:` or `perf:` | any supported major | patch |
| `feat:` | any supported major | minor |
| breaking change | `0.x`, major 1 not approved | minor `0.(y+1).0` |
| breaking change | `0.x`, major 1 approved | `1.0.0` |
| breaking change | stable N, N+1 approved | `(N+1).0.0` |
| docs/tests/chores only | any supported major | no release |

This is conventional SemVer behavior for initial development: a breaking
major-zero change advances the minor component. It cannot accidentally turn
into `1.0.0` merely because semantic-release normally maps a breaking commit to
`major`.

## Stable-major approval

Stable majors are approved explicitly in the semantic-release plugin entry:

```json
{
  "approvedStableMajors": []
}
```

The list must be the contiguous sequence `1..N`. Graduation to `1.0.0`
requires changing it to `[1]` in a reviewed commit with matching regression
evidence. A later breaking `1.x` release requires `[1, 2]`; approval for 1 never
implicitly approves 2. Stable lineage whose current major is absent, skipped,
duplicated, or otherwise unknown fails before a version can be selected.

## Tag-owned lineage

Version lineage comes only from semantic-release's `lastRelease`, which is
derived from Git tags. The policy requires an exact canonical pair:

```text
version: 0.2.3
gitTag:  v0.2.3
```

Missing tags, partial or non-canonical versions, mismatched tag/version pairs,
build metadata, and stable-major prerelease lineage on the normal main channel
fail closed. `package.json`, `haxelib.json`, the gemspec, and README prose cannot
seed or override the next version. That separation is intentional: later
release slices inject the selected version into temporary artifact staging
rather than rewriting tracked source metadata.

## Executable evidence

Run:

```bash
npm run test:release-version-policy
```

The gate exercises fix, feature, major-zero breaking, approved `1.0.0`, stable
breaking, historical prerelease promotion, and no-release commit sets through
the real analyzer. Negative cases cover absent/mismatched tags, invalid or
unsupported SemVer, unknown majors, missing next-major approval, and malformed
approval lists. It also runs the installed semantic-release engine against
temporary Git repositories. One fixture proves that `v0.2.3` plus a fix selects
`0.2.4` despite contradictory `99.99.99` package metadata. Another performs the
complete `v0.1.0-beta.2` to `v0.1.0` transition and asserts the public compare
link plus the exact remote tag set, including that `v0.0.0` is never pushed.

## Release notes

Canonical hosted notes are generated from the Conventional Commits between
the previous canonical tag and the exact new tag. Every public release body
starts with a `## v<SemVer>` heading and includes a compare link, categorized
change bullets, and commit links. `CHANGELOG.md` is reviewed source history and
may be edited in an ordinary commit, but release automation never rewrites or
commits it. Existing-tag repair regenerates the same notes from the existing
tag range; it never selects a new version. A docs/tests/chore-only commit that
the analyzer classifies as no release creates neither a tag nor release notes.

The first hosted transition, normal immutable publication, repair, and no-op
evidence are recorded in [Live Release Protocol Evidence](release-live-evidence.md).
