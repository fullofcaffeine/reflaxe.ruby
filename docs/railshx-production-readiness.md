# RailsHx Production Readiness

RailsHx is intended to become production-ready for real Rails applications, not
only a compiler demo. The current state is an alpha with strong typed compiler
coverage and a credible production path, but production readiness is not declared
until the gates in this document are met.

Tracking epic: `haxe.ruby-bjv` RailsHx production readiness.

## Current Status

RailsHx already proves the main shape:

- Haxe-authored Rails models, relations, controllers, params, migrations, routes,
  HHX templates, generators, and Rails interop can emit Rails-native artifacts.
- The canonical todo app and mixed adoption fixtures cover compile-time output,
  Ruby syntax, browser smoke, and optional Rails runtime lanes.
- Strict examples reject raw `__ruby__`; raw ERB and external templates are
  explicit migration/interop paths rather than the default authoring style.

The remaining gap is production confidence: mandatory runtime coverage, deploy
evidence, API completeness, safe escape-hatch policy, and polished app/generator
workflow.

## Supported Baseline And Adoption Guidance

Until `haxe.ruby-bjv` is closed, RailsHx should be described as alpha for
production Rails adoption. Teams may pilot it in controlled apps, but should
pin compiler/runtime versions, keep generated artifacts in CI, run the runtime
gates below, and expect API gaps to become explicit beads before broad rollout.

The current supported toolchain baseline is documented in
[Compatibility Matrix](compatibility-matrix.md): Haxe `4.3.7`, Node `20`, and
Ruby `3.2`, `3.3`, and `4.0` in CI. Rails output targets Rails 7+/8-style app
shape unless a future compatibility row narrows or expands that contract.

Support expectation before production readiness:

- No silent production blockers: file or link a bead under `haxe.ruby-bjv`.
- No untracked unsafe shortcuts: raw Ruby/ERB/SQL/Dynamic paths must be explicit
  and documented.
- No unsupported-version promises: users should stay on the documented matrix.
- No production-ready claim until every P0/P1 gate in this doc is closed.

## Production-Ready Definition

RailsHx can be called production-ready when all of these are true:

- `npm test`, `npm run test:rails-runtime`, `npm run test:todoapp-playwright`,
  packaging checks, release-contract checks, and snapshot checks are mandatory
  and green in CI for the supported toolchain matrix.
- A deployable RailsHx dogfood app proves compile, migrations, Rails tests,
  Zeitwerk, assets, and release artifact shape.
- Typed Rails APIs cover the common production path for models, migrations,
  controllers, params, routes, templates, jobs, mailers, storage, Turbo,
  ActionCable, instrumentation, and gradual adoption.
- Unsafe boundaries are explicit: raw Ruby, raw ERB, raw SQL/string clauses,
  unchecked file paths, `Dynamic`, and generated adoption contracts are either
  typed, fail-closed, or clearly opt-in with tests. SQL/string-bearing APIs
  follow [RailsHx SQL And String-Bearing API Policy](railshx-sql-string-policy.md).
- Rails-facing generators and dev/prod workflows feel Rails-native and better
  than hand-written boilerplate, with actionable diagnostics.
- Existing Ruby/ERB/Rails apps can adopt RailsHx incrementally without losing
  type safety at every boundary.
- Docs tell users what is supported, what is still alpha, what commands prove
  readiness, and which versions are supported.

## Tracked Work

| Bead | Gate | Required outcome |
| --- | --- | --- |
| `haxe.ruby-bjv.1` | Mandatory Rails runtime CI | `npm run test:rails-runtime` is a required CI gate on supported Ruby/Rails lanes, with clear failure staging. |
| `haxe.ruby-bjv.2` | Deployable dogfood app | A RailsHx app proves production compile, migrations, Rails tests, `zeitwerk:check`, `assets:precompile`, and release artifact shape. |
| `haxe.ruby-bjv.3` | Typed API completeness audit | Production Rails API blockers are inventoried in [RailsHx Typed API Production Gap Audit](railshx-typed-api-production-gap-audit.md) and converted into implementation beads. SQL/string-bearing APIs get a typed or explicit escape-hatch policy before implementation. |
| `haxe.ruby-bjv.4` | Escape-hatch/security audit | Raw Ruby, raw ERB, raw SQL, dynamic boundaries, file-backed macros, and generator inference are named in [RailsHx Escape Hatch And Security Audit](railshx-escape-hatch-security-audit.md) and are fail-closed or explicit opt-ins with tests. |
| `haxe.ruby-bjv.5` | Generator and workflow hardening | Install/scaffold/adopt/route generators, watch loops, client compilation, test flow, and production build flow are Rails-native and documented. |
| `haxe.ruby-bjv.6` | Gradual adoption hardening | Existing Ruby/ERB/Rails code can consume Haxe output and Haxe can consume existing app code through typed, checked contracts. |
| `haxe.ruby-bjv.7` | Public readiness checklist | User-facing docs state maturity, commands, versions, support expectations, known blockers, and release criteria. |

## Graduation Gates

Before declaring production readiness, run and record:

```bash
npm test
npm run test:rails-runtime
npm run test:todoapp-playwright
npm run test:todoapp-production
npm run test:snapshots
npm run test:strict-boundaries
npm run test:sql-string-policy
npm run test:haxelib-package
npm run test:gem-package
npm run ci:release-contracts
```

The dedicated CI Rails runtime job runs `npm run test:rails-runtime` across the
supported Ruby matrix (`3.2`, `3.3`, `4.0`). The local `npm test` path may skip
Rails runtime execution when generated-app bundles are absent, but the dedicated
runtime command and CI lane install those bundles and fail closed when Rails
cannot boot. Runtime smoke logs must identify the failing boundary with staged
labels such as `compiler`, `materialization`, `migration`, `request tests`, and
browser stages.

Snapshot tests are the primary RailsHx compiler-output contract. A production
surface should have committed snapshots for the generated Ruby/Rails artifacts
that define its public shape; smoke tests should only add targeted invariants,
negative compile failures, syntax checks, and thin Rails consumption seams that
snapshots cannot prove. Runtime Rails tests must stay focused on generated app
integration points such as autoloading, rendering, migrations, mail delivery,
storage services, ActionCable channels, assets, and production boot. Broad Rails
behavior belongs to Rails unless RailsHx introduces custom runtime logic.

The dedicated CI production dogfood job runs `npm run test:todoapp-production`
on the pinned Ruby lane. That command compiles server Haxe/HHX and Haxe-authored
client JS, materializes the Rails app, runs migrations/tests, runs
`zeitwerk:check`, precompiles production assets, creates
`test/.generated/rails_integration_release.tgz`, and verifies the archive
contains generated RailsHx Ruby, ERB, JS, migrations, and initializer files.

For a generated or adopted Rails app, also run:

```bash
bundle exec rake hxruby:compile
bundle exec rake hxruby:compile:client
bundle exec rails db:migrate
bundle exec rails test
bundle exec rails zeitwerk:check
RAILS_ENV=production bundle exec rake hxruby:production
```

Generated apps expose the same production lane as `bin/railshx-prod`. The rake task is the CI/buildpack entrypoint; the bin script is the app-author convenience wrapper. Both must compile RailsHx server output and Haxe-authored client JS before Rails production checks run.

## Design Rules While Closing The Gap

- Prefer typed RailsHx APIs over raw strings or `Dynamic`.
- Generated Ruby should remain recognizable Rails code.
- Rails-owned code can stay Rails-owned; use typed externs, `Template.existing`,
  route sync, RBS/source-backed adoption, and explicit interop contracts.
- Haxe-owned Rails templates should default to HHX; raw ERB remains an explicit
  migration escape hatch only.
- Any filesystem-backed macro or generator must fail closed when referenced
  files/directories are missing.
- LLM assistance may propose adoption contracts, but generated code must still
  pass validation, Haxe compilation, Ruby syntax checks, and Rails runtime gates.
- Before adding a new unsafe RailsHx boundary, update
  [RailsHx Escape Hatch And Security Audit](railshx-escape-hatch-security-audit.md)
  and file or link the follow-up bead.
