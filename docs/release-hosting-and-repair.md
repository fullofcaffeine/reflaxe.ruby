# Hosted Release Identity And Repair

RubyHx treats a release as one identity, not a tag plus loosely related files.
For version `V` and tested commit `S`, all of these values must agree:

| Surface | Required identity |
| --- | --- |
| Checked-out source | `HEAD == S` |
| Local Git tag | `vV^{commit} == S` |
| Origin Git tag | lightweight or peeled `vV == S` |
| GitHub Release | `tag_name == name == vV` |
| Haxelib ZIP | staged `haxelib.json`, `HXRuby::VERSION`, and provenance use `V`, `vV`, `S` |
| `hxruby` gem | gemspec version plus staged `haxelib.json`, `HXRuby::VERSION`, and provenance use `V`, `vV`, `S` |
| Hosted assets | exact reviewed names, labels, sizes, SHA-256 digests, and downloaded bytes match local candidates |

`scripts/release/release-hosting.mjs` owns this contract. The same verifier is
used before tag creation, after GitHub upload, and in manual repair. There is no
second artifact or version algorithm in the repair lane.

## Normal publication: draft, verify, publish

The final job of the tested main-push workflow still selects the version and
creates the tag through locked semantic-release. Its publication sequence is:

1. Rebuild the ZIP, gem, and two SHA-256/provenance sidecars from the exact
   tested Git tree.
2. Before tag creation, inspect the exact four local files plus the embedded
   ZIP/gem version, tag, source SHA, and full content manifests.
3. Create a GitHub draft release and upload all four assets through the pinned
   GitHub plugin.
4. Resolve `HEAD`, the local tag, and the origin tag to one SHA. Reject missing,
   duplicate, extra, partial, mislabeled, wrong-size, wrong-digest, or
   byte-different hosted assets.
5. Publish the draft only after every check succeeds, then require GitHub to
   report the completed release as immutable and download/verify all assets
   again.

This ordering follows GitHub's recommended immutable-release workflow: attach
everything to a draft, then publish. A failure before step 5 leaves a mutable
draft that repair can safely resume. A completed release is never edited by
RubyHx tooling.

GitHub's release-by-tag endpoint omits drafts. The shared adapter therefore
tries that narrow endpoint first for completed releases, then uses the
authenticated, bounded release-list pagination required to rediscover the
matching draft. GitHub may expose a draft through an internal `untagged-<hex>`
identifier; that shape is accepted only when the draft name is the exact `vV`.
The verifier checks the complete hosted asset set before rebinding the draft's
tag, target SHA, and name to the release identity, then validates them again
before publication. Completed releases never accept an internal tag. Duplicate
matches and pagination beyond the safety limit fail closed.

## Exact hosted asset set

Only these custom assets are accepted:

```text
hxruby-V.gem
hxruby-V.gem.sha256.json
reflaxe.ruby-V.zip
reflaxe.ruby-V.zip.sha256.json
```

The sidecars are approved provenance assets, not optional checksum hints. Each
binds its artifact's local filename, hosted filename, bytes, SHA-256, `V`,
`vV`, and `S`. GitHub's asset `digest` and a fresh download must both match.
Any additional custom asset fails verification and is not deleted
automatically.

## Existing-tag-only repair

`.github/workflows/release-repair.yml` is a manual recovery lane. Its only
input is an existing safe `v<SemVer>` tag. It validates the remote ref before
checkout, checks out `refs/tags/<input>` with full history and
`persist-credentials: false`, parses `V` from that exact input identity, and
rebuilds from the clean tag commit. Only after the four artifacts exist, the
workflow overlays `scripts/release/**` from `github.workflow_sha`: the exact
reviewed commit that supplied the dispatched workflow. This separates immutable
artifact source from repair-tool provenance, allowing a repair bug to be fixed
without checking out `main` or letting newer source enter the packages. The
workflow rechecks `HEAD` and the tag after that tooling-only overlay. It never
runs semantic-release, selects a next version, or creates, moves, force-pushes,
or deletes a tag. Repair and normal publication share the fixed
`release-${{ github.repository }}` concurrency group.

Repair behavior is deliberately state-dependent:

| Existing state | Repair action |
| --- | --- |
| Tag, no GitHub Release | Regenerate semantic-release-style notes from the previous canonical tag, create a draft, upload, verify, publish |
| Draft, no assets | Upload the four exact rebuilt assets, verify, publish |
| Draft, partial assets | Keep matching expected bytes; add missing expected bytes; replace mismatched expected bytes; verify, publish |
| Draft, unexpected asset | Fail without deleting the unexpected asset |
| Completed immutable release | Verification only; no mutation |
| Completed missing/mismatched/mutable release | Fail; publish a new corrective version instead of rewriting history |

Release-note regeneration reads the input tag and previous canonical tag; it
does not derive a new release version. It uses the official locked release-note
generator and requires version heading, compare link, and commit links.

## Repository protections and creation identity

The repository enables native immutable releases for future publications.
Once a draft is published, GitHub locks the associated tag and custom assets
and emits its release attestation. A repository tag ruleset separately applies
deletion and non-fast-forward protection to `refs/tags/v*`, including tags that
predate native release immutability. There is no bypass actor in the current
single-writer repository ruleset.

The current creation identity is the final CI job's repository-scoped
`GITHUB_TOKEN`; only that same-run job selects and creates a new version tag.
Repair receives the same narrow contents permission but no persisted Git
credential and cannot create a tag. If RubyHx becomes multi-writer, replace tag
creation with a dedicated GitHub App identity, add a `creation` rule for
`refs/tags/v*`, and grant bypass only to that App. Do not grant a general admin,
team, or personal-token bypass.

Native release immutability applies only to releases published after it is
enabled. Historical `v0.1.0` was verified against its four hosted assets and
sidecars before this repository setting existed; its tag is covered by the
version-tag ruleset. It must not be deleted/recreated merely to change that
historical GitHub flag.

## Executable checks

```bash
npm run test:release-hosting
npm run test:release-workflow
npm run ci:release-contracts
```

The state-machine gate covers tag/no-release, complete draft, partial draft,
mismatched expected draft asset, unexpected asset, immutable verification,
mutable final release, incomplete final release, and tag mismatch. The
workflow gate proves repair is manual, tag-only, non-cancelling, non-versioning,
credential-free for Git pushes, and pinned to the exact release toolchain.

GitHub references:

- [Immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)
- [Preventing changes to releases](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/establish-provenance-and-integrity/prevent-release-changes)
- [Repository rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository)
