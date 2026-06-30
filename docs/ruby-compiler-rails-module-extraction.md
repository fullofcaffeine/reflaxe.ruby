# RubyCompiler Rails Module Extraction Plan

`RubyCompiler.hx` is still the Reflaxe compiler entrypoint, but it now carries
too many RailsHx responsibilities directly: ActionView/HHX lowering, controller
and model artifact emission, ActiveRecord query lowering, Turbo/Hotwire helpers,
routes, migrations, generated tests, jobs, mailers, ActionCable, DeviseHx
companion behavior, artifact paths, and ownership decisions. This document maps
those responsibilities into focused modules so extraction can happen in small,
snapshot-backed steps.

## Design Shape

- Keep `RubyCompiler` as the orchestration root that Reflaxe calls.
- Move Rails-only decisions into `reflaxe.ruby.rails.*` modules with narrow
  typed APIs.
- Keep target-neutral Ruby lowering helpers separate from RailsHx helpers.
- Preserve generated Ruby/ERB exactly unless a bead explicitly approves drift.
- Add or audit snapshot/negative coverage before moving a surface that owns
  emitted output or diagnostics.
- Avoid companion-package package-name checks in core compiler modules; companion
  layers should contribute generic metadata/contracts that Rails modules consume.

## Responsibility Map

| Current surface in `RubyCompiler` | Target module direction | Coverage before/with extraction |
| --- | --- | --- |
| Rails artifact paths and safe path validation | `rails.RailsArtifactPaths` | Existing template/test/mailer/generator snapshots; negative path diagnostics through template/test generator smokes |
| ActionView/HHX node and attr lowering | `rails.RailsTemplatesCompiler` or `rails.action_view.*` | `test:components`, `test:todoapp-rails`, `test:action-mailer`, `test:snapshots`, negative HHX diagnostic fixtures |
| Turbo/Turbo Streams/Hotwire lowering | `rails.RailsTurboCompiler` | `test:turbo`, `test:turbo-streams`, browser sentinel, snapshots |
| Controllers, lifecycle, params, flash/session/cookies | `rails.RailsControllersCompiler` | `test:action-controller-params`, todoapp request/browser tests, lifecycle diagnostic tests |
| ActiveRecord models, fields, associations, scopes, queries | `rails.RailsActiveRecordCompiler` | `test:active-record-model`, SQL string policy, snapshots, negative field/query diagnostics |
| Mailers and previews | `rails.RailsMailersCompiler` | `test:action-mailer`, mailer preview path diagnostics, snapshots |
| Jobs | `rails.RailsJobsCompiler` | `test:active-job`, snapshots |
| ActionCable channels/connections | `rails.RailsCableCompiler` | `test:action-cable`, browser/live smoke where relevant, snapshots |
| Routes DSL and route artifact emission | Existing `RailsRoutes*` modules plus a compiler adapter | `test:routes-dsl`, `test:routes-generator`, route parity dogfood |
| Migrations and generator-owned artifacts | `rails.RailsMigrationsCompiler` / generator modules | `test:migration-generator`, generator smoke tests, snapshots |
| Rails tests DSL lowering | `rails.RailsTestsCompiler` | `test:template-test-generator`, generated Rails test snapshots, negative DSL diagnostics |
| DeviseHx companion behavior | Generic companion/metadata registry consumed by Rails modules | DeviseHx core/controller tests, todoapp auth browser tests, strict current-required diagnostics |

## Extraction Order

1. Extract pure Rails artifact path logic. This is low risk because it is
   deterministic and already covered indirectly by generated artifact snapshots.
2. Extract Rails test/mailer preview artifact helpers next; they share path
   validation and have focused smoke tests.
3. Extract Turbo/Turbo Streams call lowering. It is narrower than HHX templates
   and already has dedicated smoke/snapshot gates.
4. Split ActionView/HHX lowering after adding targeted negative diagnostics for
   helper tags, locals, and unsafe view-local helper bodies.
5. Split controllers and ActiveRecord last among common app surfaces because
   they coordinate many typed APIs and runtime semantics.
6. Introduce a companion-layer registry before moving more DeviseHx-specific
   behavior, so core compiler code stops learning gem package names.

## First Slice

The first implemented slice extracts Rails artifact path normalization and
validation into `reflaxe.ruby.rails.RailsArtifactPaths`. `RubyCompiler` keeps
small delegating wrappers for now so call sites remain stable. This should
produce no generated-output drift; any drift means the extraction changed
behavior and must be fixed or explicitly documented under a separate bead.
