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
  builder/default, checked literal subset, or explicit audited escape hatch as
  defined in [RailsHx SQL And String-Bearing API Policy](railshx-sql-string-policy.md).
- Missing filesystem-backed inputs must fail closed: templates, RBS files,
  Ruby source files, route dumps, and generator-discovered contracts.
- Runtime confidence matters: production surfaces need static compiler tests
  plus Rails runtime, request, browser, or production dogfood coverage where the
  behavior depends on Rails.

## Production Blocker Beads

| Bead | Priority | Surface | Required outcome |
| --- | --- | --- | --- |
| `haxe.ruby-bjv.3.1` | P1 | ActiveRecord queries, scopes, transactions | Covered: typed production query spine, scopes, transactions, locking, association-aware criteria, nested joins/includes, and SQL-bearing policy integration. |
| `haxe.ruby-bjv.3.2` | P1 | Models, associations, validations, migrations | Broader typed Rails model metadata and migration/schema evolution coverage, including constraints, indexes, reversible operations, and destructive-operation policy. |
| `haxe.ruby-bjv.3.3` | P1 | Controllers, routing, request lifecycle | Production ActionController coverage for filters, redirects, respond_to-style flows, request variants, rescue/auth seams, and route/controller validation. |
| `haxe.ruby-bjv.3.4` | P1 | HHX, ActionView, forms, components | Broader HHX helper/form/component/layout coverage with typed collection locals, slots, content_for/yield, and Rails-owned ERB interop. |
| `haxe.ruby-bjv.3.5` | P1 | ActionMailer, ActiveJob, ActiveStorage | Runtime-backed production slices for mailers, jobs, attachments, previews/tests, adapter/test-helper behavior, and storage helpers. |
| `haxe.ruby-bjv.3.6` | P1 | Turbo, Turbo Streams, ActionCable | Typed Hotwire/realtime APIs plus browser/runtime/channel coverage for stream names, targets, payloads, params, and subscriptions. |
| `haxe.ruby-bjv.3.7` | P1 | SQL and string-bearing APIs | Shared policy for typed defaults, checked literals, and explicit escape hatches across queries, migrations, templates, routes, Turbo, and external Rails paths. |

## Surface Audit

| Surface | Current state | Production gap | Bead |
| --- | --- | --- | --- |
| ActiveRecord flat criteria | `where`, `rewhere`, `findBy`, and `exists` check flat and nested association model columns and value types; `where(predicate)` / `whereNot(predicate)` cover typed Arel-backed field predicates. | Production blocker closed. Future relation-aware named criteria can be designed as an ergonomic follow-up if dogfood needs them. | `haxe.ruby-bjv.3.1` |
| ActiveRecord relation chains | Common chains exist: `all`, `none`, `distinct`, `select`, `or`, `merge`, `order`, `reorder`, `limit`, `offset`, `first`, `last`, `toArray`, `where.not`, `preload`, `eager_load`, transactions, and pessimistic locking. | Production blocker closed. Future breadth such as `unscope`, `only`, `except`, `references`, `strict_loading`, and optimistic-locking affordances should be separate non-blocking API expansion beads. | `haxe.ruby-bjv.3.1` |
| Projections/grouping/aggregates | Single-field `pluck`, named `Projection.pluck`, grouped aggregate `Projection.group`, `Group.count`, `Group.countHaving`, typed aggregate predicates, min/max/sum/average slices, and fluent field expressions exist. | Production blocker closed for the common path. Multi-model projections, richer grouped keys, joined aggregate projections, and broader SQL function builders remain future design/implementation breadth. | follow-up as needed |
| Scopes | `@:railsScope` and `@:railsDefaultScope` keep typed Haxe static methods while emitting Rails `scope` / `default_scope` macros; ordinary static methods remain available for class helpers. | Production blocker closed. Richer merging/default-scope policy and broader runtime coverage can be follow-up breadth. | `haxe.ruby-bjv.3.1` |
| Model metadata | Initial columns, associations, validations, enums, callbacks, and schema metadata exist. | Common validation options, custom validators, dependent/inverse/through variants, polymorphic/STI decisions, nested attributes, scopes from associations, and callback coverage need audit-driven expansion. | `haxe.ruby-bjv.3.2` |
| Migrations | Create-table, production snapshot operations, known table/column/index/FK validation, composite indexes, references, check constraints, rename/change-null, reversible destructive operations, external tables, migration version metadata, and explicit SQL/data rollback exist. | Fuller change-table helpers, schema history reports, richer data-migration helpers, and generator integration need production treatment. | `haxe.ruby-bjv.3.2`, `haxe.ruby-bjv.5.2`, `haxe.ruby-bjv.6.2` |
| Controllers/params | Typed strong params, request/response facades including `RequestFormat`, negotiated `formats`, content/media type helpers, and `RequestVariant`, contextual `lifecycle` declarations for filters, `rescue_from`, and `protect_from_forgery`, status tokens, `respond_to` format collector, typed `send_file`/`send_data` and `fresh_when`/`stale?` options, flash/session/cookies, template rendering, and a focused Rails request runtime lane exist. | Advanced accept/variant negotiation, auth hooks, streaming responses beyond file/data sends, advanced CSRF/custom strategies, and route/controller validation need coverage. | `haxe.ruby-bjv.3.3` |
| Routes | Route helper generation supports named routes, nested/resource params, namespaces, member/collection routes, optional segments, globs, and mount-like rows. | Full route/controller/action verification, engines/mounts, constraints, defaults, and route-driven adoption workflows need production hardening. | `haxe.ruby-bjv.3.3`, `haxe.ruby-bjv.5` |
| HHX/ActionView | HHX templates, typed locals, partials, components, route/helper calls, forms, layout helpers, slots, and raw ERB escape are implemented as initial slices. | Collection rendering, Rails helper breadth, form builder depth, field errors, accessibility helpers, `content_for`/layout edge cases, component ergonomics, and richer external-template validation need production coverage. | `haxe.ruby-bjv.3.4` |
| ActionMailer | Initial typed mailer class/template/preview slice exists, including generated Rails runtime coverage for multipart HTML/text body rendering, headers, typed string/hash/inline attachments, `deliver_now`, typed `deliverLater()` ActiveJob enqueue handles, `@:railsMailerParams` parameterized `.with(...)` wrappers, `params[:key]` reads, and loading a generated `ActionMailer::Preview`. | Unusual attachment shapes and richer mailer/job scheduling/options need implementation and runtime coverage. | `haxe.ruby-bjv.3.5`, `haxe.ruby-if3`, `haxe.ruby-4tx` |
| ActiveJob | Typed job/enqueue slice exists, including contextual lifecycle lowering and a generated Rails `ActiveJob::TestHelper` runtime lane for queue/enqueue/perform, serialization/deserialization, retry re-enqueue behavior, and discard tracking through Rails' test adapter. | Adapter-specific behavior beyond the test adapter, richer queue naming policy, and third-party adapter failure diagnostics remain app-owned unless a future typed adapter API is justified. | `haxe.ruby-bjv.3.5`, `haxe.ruby-71o`, `haxe.ruby-ox5` |
| ActiveStorage | Initial typed attachment refs exist, including generated Rails runtime coverage for ActiveStorage tables, test disk service, blob signed-ID attach, typed `io`/`filename`/`content_type` hash attachables, typed blob metadata/direct-upload facades, direct-upload file field rendering, download/read, and purge for one and many attachments. | Attachment validations, variants/previews, analyzer hooks, and richer attachable builders need production design and coverage. | `haxe.ruby-bjv.3.5`, `haxe.ruby-cfj`, `haxe.ruby-9sl`, `haxe.ruby-33p` |
| Turbo/Hotwire | Typed Haxe client helpers, initial server-side Turbo stream helpers, and todoapp browser coverage exist. | Broader frame/stream helper coverage, morph/refresh semantics, Turbo form failure paths, and browser assertions need production hardening. | `haxe.ruby-bjv.3.6`, `haxe.ruby-7bx` |
| ActionCable | Typed channel/subscription slice exists, including params, streams, broadcast payloads, typed JS consumers/actions, committed generated Ruby snapshots, and generated Rails `ActionCable::Channel::TestCase` runtime coverage for subscribe/stream/reject/unsubscribe/perform/broadcast. | Connection identifiers, richer auth seams, and broader client callback/runtime behavior need hardening. | `haxe.ruby-bjv.3.6`, `haxe.ruby-tke` |
| ActiveSupport instrumentation | Typed event names/payloads exist as an initial slice. | Subscriber lifecycle, error handling, namespace conventions, and production observability integration should remain tracked, but it is not a P1 production blocker unless dogfood needs it. | follow-up as needed |
| Gradual adoption | Mixed Ruby/ERB/Haxe examples and generator-assisted service/template/extension contracts exist. | Production interop hardening is tracked separately: RBS/YARD/source inference breadth, Ruby consuming generated Haxe, and fail-closed adoption workflows. | `haxe.ruby-bjv.6` |

## SQL And String-Bearing Policy

The detailed policy lives in
[RailsHx SQL And String-Bearing API Policy](railshx-sql-string-policy.md).
Every new string/SQL-bearing RailsHx API must classify itself as a typed
default, checked literal, or explicit escape hatch before implementation.

`npm run test:sql-string-policy` guards canonical RailsHx examples against
casual raw query strings such as `.where("...")` or `.order("...")`.

## Current Readiness Summary

RailsHx has a credible typed CRUD spine and production dogfood lane. The
remaining API gap is breadth and hardening: making common Rails surfaces typed
enough that production app authors do not have to fall back to `Dynamic`,
unchecked strings, raw SQL, or `__ruby__` for ordinary work.

Production-ready status remains blocked until the remaining P1 beads above are closed or
explicitly reclassified with documented rationale.
