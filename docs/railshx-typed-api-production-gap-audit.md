# RailsHx Typed API Production Gap Audit

This audit tracks typed Rails API gaps that block production readiness. It is not
a wish list: P0/P1 rows below must either be implemented, explicitly deferred
with a safe escape hatch, or linked to a bead before RailsHx can be called
production-ready.

Tracking gate: `haxe.ruby-bjv.3`.

## Audit Rules

- Rails remains the output contract. Typed Haxe APIs should lower to normal
  Rails Ruby, ERB, migrations, importmap assets, tests, and runtime behavior.
- Prefer typed refs/builders/macros for behavior-bearing Rails names: fields,
  associations, params keys, template refs, route helpers, Turbo targets,
  stream names, and ActionCable params/payloads.
- Strings are acceptable only when they are the Rails-native representation and
  are checked at compile/generator time, or when they are an explicit named
  escape hatch.
- SQL-bearing APIs must not be added as casual strings. Each API needs a typed
  builder/default, checked literal subset, or explicit audited escape hatch.
- Missing filesystem-backed inputs must fail closed: templates, RBS files,
  Ruby source files, route dumps, and generator-discovered contracts.
- Runtime confidence matters: production surfaces need static compiler tests
  plus Rails runtime, request, browser, or production dogfood coverage where the
  behavior depends on Rails.

## Production Blocker Beads

| Bead | Priority | Surface | Required outcome |
| --- | --- | --- | --- |
| `haxe.ruby-bjv.3.1` | P1 | ActiveRecord queries, scopes, transactions | Typed production query surface: scopes, transactions, locking, association-aware criteria, nested joins/includes, and SQL-bearing policy integration. |
| `haxe.ruby-bjv.3.2` | P1 | Models, associations, validations, migrations | Broader typed Rails model metadata and migration/schema evolution coverage, including constraints, indexes, reversible operations, and destructive-operation policy. |
| `haxe.ruby-bjv.3.3` | P1 | Controllers, routing, request lifecycle | Production ActionController coverage for filters, redirects, respond_to-style flows, request variants, rescue/auth seams, and route/controller validation. |
| `haxe.ruby-bjv.3.4` | P1 | HHX, ActionView, forms, components | Broader HHX helper/form/component/layout coverage with typed collection locals, slots, content_for/yield, and Rails-owned ERB interop. |
| `haxe.ruby-bjv.3.5` | P1 | ActionMailer, ActiveJob, ActiveStorage | Runtime-backed production slices for mailers, jobs, attachments, previews/tests, adapter/test-helper behavior, and storage helpers. |
| `haxe.ruby-bjv.3.6` | P1 | Turbo, Turbo Streams, ActionCable | Typed Hotwire/realtime APIs plus browser/runtime/channel coverage for stream names, targets, payloads, params, and subscriptions. |
| `haxe.ruby-bjv.3.7` | P1 | SQL and string-bearing APIs | Shared policy for typed defaults, checked literals, and explicit escape hatches across queries, migrations, templates, routes, Turbo, and external Rails paths. |

## Surface Audit

| Surface | Current state | Production gap | Bead |
| --- | --- | --- | --- |
| ActiveRecord flat criteria | `where`, `rewhere`, `findBy`, `exists` check flat model columns and value types. | Nested association criteria, richer predicates, relation-aware named criteria, and Rails-style scope builders are incomplete. | `haxe.ruby-bjv.3.1` |
| ActiveRecord relation chains | Common chains exist: `all`, `none`, `distinct`, `select`, `or`, `merge`, `order`, `reorder`, `limit`, `offset`, `first`, `last`, `toArray`. | Transactions, pessimistic/optimistic locking helpers, richer joins/includes/preload/eager_load, `where.not`, `unscope`, `only`, `except`, `references`, and `strict_loading` need typed decisions. | `haxe.ruby-bjv.3.1` |
| Projections/grouping/aggregates | Single-field `pluck`, named `Projection.pluck`, `Group.count`, min/max/sum/average initial slices exist. | Multi-model projections, richer grouped keys, select aliases, SQL functions, having/group expressions, and typed aggregate result objects need design/implementation. | `haxe.ruby-bjv.3.1`, `haxe.ruby-bjv.3.7` |
| Scopes | Model-owned static methods can return typed relations. | Rails-like typed scope declarations, lambda scopes, default scopes, merging rules, and generated Ruby shape need production guidance. | `haxe.ruby-bjv.3.1` |
| Model metadata | Initial columns, associations, validations, enums, callbacks, and schema metadata exist. | Common validation options, custom validators, dependent/inverse/through variants, polymorphic/STI decisions, nested attributes, scopes from associations, and callback coverage need audit-driven expansion. | `haxe.ruby-bjv.3.2` |
| Migrations | Create-table and follow-up operation validation exist for known tables/columns/indexes/FKs and reversible destructive operations. | Constraints/checks, composite indexes, rename/change-table helpers, schema history, external table contracts, data migrations, and raw SQL policy need production treatment. | `haxe.ruby-bjv.3.2`, `haxe.ruby-bjv.3.7` |
| Controllers/params | Typed strong params, request/response facades, filters, status tokens, flash/session/cookies, and template rendering exist. | `respond_to`, content negotiation, variants, rescue_from, around/after filters, auth hooks, streaming/send_file, CSRF policy, route/controller validation, and richer request specs need coverage. | `haxe.ruby-bjv.3.3` |
| Routes | Route helper generation supports named routes, nested/resource params, namespaces, member/collection routes, optional segments, globs, and mount-like rows. | Full route/controller/action verification, engines/mounts, constraints, defaults, and route-driven adoption workflows need production hardening. | `haxe.ruby-bjv.3.3`, `haxe.ruby-bjv.5` |
| HHX/ActionView | HHX templates, typed locals, partials, components, route/helper calls, forms, layout helpers, slots, and raw ERB escape are implemented as initial slices. | Collection rendering, Rails helper breadth, form builder depth, field errors, accessibility helpers, `content_for`/layout edge cases, component ergonomics, and richer external-template validation need production coverage. | `haxe.ruby-bjv.3.4` |
| ActionMailer | Initial typed mailer class/template slice exists. | Parameterized mailers, previews, attachments, multipart defaults, delivery/test helpers, runtime delivery assertions, and integration with jobs need production coverage. | `haxe.ruby-bjv.3.5` |
| ActiveJob | Initial typed job/enqueue slice exists. | Adapter-specific behavior, test helpers, serialization contracts, retry/discard edge cases, queue naming policy, and runtime perform/enqueue tests need hardening. | `haxe.ruby-bjv.3.5` |
| ActiveStorage | Initial typed attachment refs exist. | Attachment validations, variants/previews, blobs, direct uploads, purge/analyze helpers, service config assumptions, and runtime storage tests need production coverage. | `haxe.ruby-bjv.3.5` |
| Turbo/Hotwire | Typed Haxe client helpers and initial server-side Turbo stream helpers exist. | Broader frame/stream helper coverage, target/name typing, morph/refresh semantics, Turbo form failure paths, and browser assertions need production hardening. | `haxe.ruby-bjv.3.6` |
| ActionCable | Initial typed channel/subscription slice exists. | Runtime channel tests, connection identifiers, stream lifecycle, reject/confirm behavior, typed client subscription callbacks, and payload validation need production coverage. | `haxe.ruby-bjv.3.6` |
| ActiveSupport instrumentation | Typed event names/payloads exist as an initial slice. | Subscriber lifecycle, error handling, namespace conventions, and production observability integration should remain tracked, but it is not a P1 production blocker unless dogfood needs it. | follow-up as needed |
| Gradual adoption | Mixed Ruby/ERB/Haxe examples and generator-assisted service/template/extension contracts exist. | Production interop hardening is tracked separately: RBS/YARD/source inference breadth, Ruby consuming generated Haxe, and fail-closed adoption workflows. | `haxe.ruby-bjv.6` |

## SQL And String-Bearing Policy

Until `haxe.ruby-bjv.3.7` lands, new API work must classify string-bearing
surfaces before implementation:

| Class | Meaning | Examples |
| --- | --- | --- |
| Typed default | Normal RailsHx app code should use generated refs/builders/macros. | `Todo.f.title`, `Todo.a.user`, `Template.of(TodoView)`, `Todo.railsParamKey`, `StreamTarget.of(...)`. |
| Checked literal | Literal strings are accepted because Rails owns the value, but macros/generators validate path/shape/existence where possible. | `Template.existing("legacy/badge")`, route dump paths, RBS/source files, explicit external tables. |
| Explicit escape hatch | Unsafe or intentionally dynamic strings are allowed only through named APIs/metadata that are searchable and testable. | Raw ERB via `@:railsAllowRawErb`, future raw SQL fragments, external Rails-owned paths that cannot be verified. |

Any P1 implementation bead that adds string/SQL-bearing APIs must mention which
class it uses and include negative tests for accidental drift.

## Current Readiness Summary

RailsHx has a credible typed CRUD spine and production dogfood lane. The
remaining API gap is breadth and hardening: making common Rails surfaces typed
enough that production app authors do not have to fall back to `Dynamic`,
unchecked strings, raw SQL, or `__ruby__` for ordinary work.

Production-ready status remains blocked until the P1 beads above are closed or
explicitly reclassified with documented rationale.
