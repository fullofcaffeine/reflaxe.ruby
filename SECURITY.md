# Security

Report security issues privately to the repository owner instead of opening a public issue.

## Secret Scanning

This repo enforces secret scanning in two places:

- Local hooks: `npm run hooks:install` installs a pre-commit hook that runs staged `gitleaks`.
- CI: `.github/workflows/security-gitleaks.yml` runs gitleaks on pull requests and pushes to `main`.

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
