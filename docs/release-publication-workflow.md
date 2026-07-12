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
- the full compiler/examples/snapshots/package suite on Ruby 3.2, 3.3, and 4.0;
- RailsHx browser Playwright;
- mandatory Rails runtime integration on Ruby 3.2, 3.3, and 4.0;
- RailsHx production dogfood;
- release policy, workflow, and reproducible-artifact contracts.

GitHub does not start a job with ordinary `needs` unless every dependency
succeeds. A failed, cancelled, skipped, or absent result therefore cannot
publish. Pull requests, feature pushes, fork repositories, and manual events
fail the job-level eligibility condition. Normal CI intentionally has no
`workflow_dispatch` or cross-workflow `workflow_run` publication path.

Main workflow runs are not auto-cancelled because an older run may already be
inside its privileged publication job. Publication additionally uses the fixed
`release-${{ github.repository }}` concurrency group with cancellation disabled.
The existing-tag-only repair workflow introduced by the hosted-verification
slice must use this same group; it may repair an immutable tag but must never
derive or create a new version.

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

## Exact release toolchain

Release-affecting tools are reviewed inputs rather than moving aliases:

| Input | Exact release value |
| --- | --- |
| Runner | `ubuntu-24.04` |
| Node.js | `22.14.0` |
| npm | `10.9.2` |
| Ruby | `3.3.11` |
| RubyGems | `3.5.22` |
| Haxe | `4.3.7` |
| lix | `15.12.4` |
| semantic-release | `25.0.5` |

All npm release dependencies use exact versions in `package.json` and
`package-lock.json`. Workflow actions use full 40-character commit SHAs. The
release job verifies Node, npm, Ruby, RubyGems, and Haxe versions before running
the locked semantic-release binary directly. Changing any pin is an ordinary
reviewed code change and must keep `npm audit` clean.

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
