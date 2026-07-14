# Tested-Commit Publication Workflow

Normal RubyHx publication is the final job of `.github/workflows/ci.yml`. This
follows the same tested-commit pattern as `haxe.rust`: version selection remains
ordinary Conventional Commit/SemVer policy, while workflow structure proves
that the commit being tagged and packaged is the commit whose gates succeeded.

## Authorization boundary

The release job is eligible only for a `push` to `refs/heads/main` in the
canonical `fullofcaffeine/reflaxe.ruby` repository. It declares all of these
same-run dependencies:

- locked dependency audit plus full-history Gitleaks scanning;
- Haxe formatting;
- the full compiler/examples/snapshots/package suite on Ruby 3.3, 3.4, and 4.0;
- RailsHx browser Playwright;
- mandatory Rails runtime integration on Ruby 3.3, 3.4, and 4.0;
- RailsHx production dogfood;
- release policy, workflow, and reproducible-artifact contracts.

The job condition includes `!cancelled()` to replace GitHub's implicit status
filter, then compares every named `needs.<job>.result` to `success`. A failed,
cancelled, skipped, or absent result therefore cannot publish, while an opaque
scheduler-level aggregate state cannot silently skip publication after every
declared dependency has independently reported success. Pull requests, feature
pushes, fork repositories, and manual events fail the same condition. Normal CI
intentionally has no `workflow_dispatch` or cross-workflow `workflow_run`
publication path.

Main workflow runs are not auto-cancelled because an older run may already be
inside its privileged publication job. Publication additionally uses the fixed
`release-${{ github.repository }}` concurrency group with cancellation disabled.
The existing-tag-only repair workflow uses this same group; it may resume a
draft associated with an existing immutable tag but never derives or creates a
new version.

## Privileged job

The workflow defaults to `contents: read`. Only the final release job receives
`contents: write`; issue and pull-request write permissions are not granted.
Semantic-release success/failure comments and released labels are disabled, so
publication does not need those broader permissions.

The privileged job checks out `${{ github.sha }}` with full history. That SHA
is also the source identity passed by semantic-release into temporary ZIP/gem
staging. It does not download artifacts, restore executable caches, or accept a
custom broad release token. setup-node's implicit package-manager cache is
explicitly disabled in this job. It runs `npm ci`, audits the lockfile again, and
rebuilds both upload candidates locally from the exact Git tree before tagging
and publishing through the scoped workflow token.

The GitHub plugin creates a draft and uploads all four reviewed assets. The
following locked exec hook resolves the local/origin tag, validates both
embedded package identities, compares GitHub asset metadata and freshly
downloaded bytes to the local candidates, and only then publishes the draft.
Publication must immediately report native immutability. Failures leave a draft
for the separate existing-tag-only repair workflow; completed releases are
verification-only. See `release-hosting-and-repair.md`.

## Exact release toolchain

Release-affecting tools are reviewed inputs rather than moving aliases:

| Input | Exact release value |
| --- | --- |
| Runner | `ubuntu-24.04` |
| Node.js | `22.23.1` |
| npm | `10.9.8` |
| Ruby | `3.4.10` |
| RubyGems | `3.5.22` |
| Haxe | `4.3.7` |
| lix | `15.12.4` |
| semantic-release | `25.0.5` |

All npm release dependencies use exact versions in `package.json` and
`package-lock.json`. Workflow actions use full 40-character commit SHAs. The
release job verifies Node, npm, Ruby, RubyGems, and Haxe versions before running
the locked semantic-release binary directly. Changing any pin is an ordinary
reviewed code change and must keep `npm audit` clean.

Immediately before the locked engine, the job runs the fail-closed historical
SemVer transition check documented in `release-version-policy.md`. It is a
one-time compatibility bridge for `v0.1.0-beta.2`: the derived local alias is
removed by the policy plugin before any tag push. Once `v0.1.0` exists, the
check is a no-op and all later releases use ordinary stable tag lineage.

The Haxe setup exports the locked local `node_modules/.bin` directory before
running lix. Haxe's installation hook invokes `lix` by name in a child process;
ordering the PATH setup first keeps clean hosted runners reproducible instead of
accidentally relying on a developer shell's existing PATH.

## Executable contract

Run:

```bash
npm run test:release-workflow
npm run ci:release-contracts
npm audit
```

The workflow gate simulates canonical main, PR, manual ref, feature branch,
fork, mismatched SHA, failed, cancelled, skipped, and missing-result cases. It
also checks the exact needs graph, permissions, concurrency, full-SHA action
pins, checkout ref/history, absence of cache/artifact imports, exact toolchains,
locked install command, and disabled release comments.
