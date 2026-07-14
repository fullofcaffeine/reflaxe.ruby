# Security

## Report A Vulnerability

Use [GitHub private vulnerability reporting](https://github.com/fullofcaffeine/reflaxe.ruby/security/advisories/new).
Do not open a public issue for a suspected vulnerability. Include affected
versions, impact, reproduction details, and any suggested mitigation you have.

This is a community-supported, currently single-maintainer project with no
response-time SLA. Reports and coordinated disclosure are handled on a
best-effort basis; the maintainer will keep the reporter informed as the issue
is reproduced, scoped, fixed, and prepared for disclosure.

General issue routing, maintenance ownership, and support expectations are in
[Support And Maintenance](SUPPORT.md).

## Supported Versions

Before stable `1.x`, security fixes target the latest published `0.x` release
and current `main`. Older `0.x` users may need to upgrade. Runtime and toolchain
coverage follows the [compatibility matrix](docs/compatibility-matrix.md); an
unverified environment is not automatically known vulnerable or incompatible.

Emergency fixes use the same exact-SHA release workflow and immutable artifact
checks as ordinary releases. Existing-tag repair can restore or verify expected
assets but cannot move a tag or alter a completed release. See
[publication](docs/release-publication-workflow.md) and
[repair](docs/release-hosting-and-repair.md).

## Dependency And Secret Scanning

The canonical CI security job in `.github/workflows/ci.yml` runs `npm audit`, a
pinned `bundler-audit` scan of every tracked `Gemfile.lock`, a known-vulnerable
scanner fixture, and full-history Gitleaks. Dependabot checks GitHub Actions,
npm, and the committed Rails reference bundle weekly.

## Secret Scanning

This repo enforces secret scanning in two places:

- Local hooks: `npm run hooks:install` installs a pre-commit hook that runs staged `gitleaks`.
- CI: `.github/workflows/ci.yml` runs gitleaks on pull requests and pushes.

Run a full local scan with:

```bash
npm run security:gitleaks
```

Run the staged-only scan with:

```bash
npm run security:gitleaks:staged
```

The scan is configured by `.gitleaks.toml`. Only deterministic fixtures and generated test output should be allowlisted; real secrets, Rails credentials, `.env` files, API tokens, private keys, and machine-local paths must not be committed.

## Escape Hatches

Ruby/Rails escape hatches such as raw `__ruby__`, raw ERB, raw SQL, unchecked template paths, and dynamic adoption output are treated as security-sensitive compiler surfaces. Prefer typed externs, checked filesystem contracts, HHX, typed field refs, and generator-owned artifacts. See `docs/railshx-escape-hatch-security-audit.md` and `docs/railshx-sql-string-policy.md`.
