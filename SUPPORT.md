# Support And Maintenance

RubyHx and RailsHx are community-supported and currently maintained by one
person. The maintainer of record is Marcelo Serpa
([`@fullofcaffeine`](https://github.com/fullofcaffeine)). Support, issue triage,
compatibility decisions, releases, security handling, and the bundled companion
layers are provided on a best-effort basis with no response-time SLA or LTS
promise.

There is no secondary privileged maintainer today. If the maintainer is
unavailable, responses and releases may be delayed. This document will be
updated before the project claims backup coverage or a stronger service level.

## Where To Report

- Report suspected vulnerabilities through the private channel in
  [Security](SECURITY.md). Never put sensitive reproduction details in a public
  issue.
- Report reproducible bugs, compatibility problems, and documentation gaps in
  [GitHub Issues](https://github.com/fullofcaffeine/reflaxe.ruby/issues/new).
  Include the RubyHx release, Haxe version, Ruby and Rails versions when
  relevant, a minimal reproduction, and the generated diagnostic or output.
- Propose APIs and features through GitHub Issues with a concrete use case.
- Use [Repository Development](docs/development.md) for local gates and the
  contribution workflow. The tracked `bd` export is maintainer work tracking,
  not a separate public support queue.

## Supported Scope

[`lib/hxruby/support_matrix.json`](lib/hxruby/support_matrix.json) and the
[Compatibility Matrix](docs/compatibility-matrix.md) define the tested support
promise. Tested versions are evidence and maintenance commitments, not an
artificial compatibility ceiling: newer or otherwise unverified Ruby and Rails
versions may work and are warned about rather than rejected unless they violate
a real minimum requirement.

Stable `1.x` compatibility changes follow the public SemVer and deprecation
contract and must appear in release notes and the support matrix. A future
stable major requires its own evidence-gated approval; approval for major 1
does not authorize major 2. See [Public Contract](docs/public-contract.md) and
[Release Version Policy](docs/release-version-policy.md).

## Maintenance Rhythm

- Every canonical push runs compiler, package, Rails runtime, browser,
  production, security, and release-contract gates before publication.
- Dependabot checks GitHub Actions, npm, and the committed Rails Bundler lock
  weekly. Mandatory npm, Ruby advisory, and secret scans run in CI. Updates are
  reviewed and merged on a best-effort schedule rather than a promised SLA.
- Support end dates in the machine matrix are checked on every canonical CI
  run. An expired branch or runtime lane must be updated, narrowed, or removed
  before another release can publish.
- Releases are generated only from the exact tested `main` SHA with categorized
  change notes and immutable checksum-bound assets.

## Ownership And Routing

| Surface | Responsibility and issue routing |
| --- | --- |
| `reflaxe.ruby`, RubyHx, `hxruby`, and RailsHx core | The maintainer of record owns releases and compatibility decisions. Report compiler, runtime, package, generator, and core RailsHx issues in this repository. |
| Bundled companion layers such as DeviseHx | Report typed facade, macro, generator, or integration issues here. Report Devise, Warden, Rails, or other upstream runtime defects to their upstream project. |
| Independently released companions | Their own repository owns releases, support matrix, and gem-specific behavior. Cross-boundary defects should link issues in both repositories. |
| Generated applications | Application teams own their code, data, dependencies, deployment, and incident response. This project owns documented compiler/runtime/generator behavior. |

## Release And Security Authority

Normal publication is the final job of the successful canonical `main`
workflow. Its repository-scoped `GITHUB_TOKEN`, not a maintainer-built local
artifact or broad personal token, creates the tag and immutable release. The
maintainer may manually dispatch only the existing-tag repair workflow described
in [Hosted Release Identity And Repair](docs/release-hosting-and-repair.md).

The same maintainer currently receives private vulnerability reports and owns
coordinated disclosure decisions. [Security](SECURITY.md) describes supported
security versions and emergency publication. If ownership becomes multi-writer,
the release identity, review rules, backup authority, and companion routing must
be documented and tested before the stronger model is advertised.
