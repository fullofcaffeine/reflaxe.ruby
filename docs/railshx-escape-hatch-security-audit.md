# RailsHx Escape Hatch And Security Audit

This audit names every production-relevant unsafe boundary currently allowed by
RailsHx and records how it is controlled. The goal is not to ban all Ruby/Rails
escape hatches; the goal is to make them explicit, searchable, opt-in, and
replaceable with typed APIs over time.

Tracking gate: `haxe.ruby-bjv.4`.

## Policy

- Default app-facing RailsHx code should use typed APIs, generated refs, macros,
  HHX, typed externs, and Rails-native generated output.
- Escape hatches must be named like escape hatches: `raw`, `external`,
  `existing`, `unchecked`, or a similarly explicit term.
- Checked escapes are preferred over unchecked escapes. For example,
  `Template.existing("legacy/badge") : Template<TLocals>` checks filesystem
  presence, while `Template.external("legacy/badge")` is lower-level.
- File-backed macros and generators fail closed by default. Missing templates,
  RBS files, Ruby source files, route dumps, or extension sources are errors
  unless the API name explicitly says the source is external/unchecked.
- LLM assistance is advisory only. It may suggest typed contracts, but cannot
  bypass generator validation, Haxe compilation, Ruby syntax checks, Rails
  runtime gates, or human review.
- Canonical RailsHx examples, especially `examples/todoapp_rails`, must avoid
  raw Ruby, raw ERB, unchecked paths, and casual `Dynamic` when a typed RailsHx
  API exists.

## Follow-Up Beads

| Bead | Priority | Scope | Required outcome |
| --- | --- | --- | --- |
| `haxe.ruby-bjv.4.1` | P1 | SQL/string escapes | Enforce the SQL/string policy across ActiveRecord, migrations, templates, Turbo, and related Rails APIs. |
| `haxe.ruby-bjv.4.2` | P1 | `Dynamic` boundaries | Classify and replace app-facing `Dynamic` uses with typed facades, abstracts, or generated contracts where possible. |
| `haxe.ruby-bjv.4.3` | P1 | Template/path escapes | Harden `Template.named`, `Template.external`, `@:railsTemplate(...)` paths, and filesystem checks. |
| `haxe.ruby-bjv.4.4` | P1 | Generator/LLM inference | Keep adoption inference deterministic, fail-closed, reviewable, and non-executing. |

## Escape Hatch Inventory

| Boundary | Default | Escape hatch | Current enforcement | Tests/docs | Follow-up |
| --- | --- | --- | --- | --- | --- |
| Raw Ruby injection | Typed std/runtime wrappers, externs, macros, or generated RailsHx APIs. | `untyped __ruby__(...)` inside narrowly scoped `@:rubyAllowRaw` modules/types. | `reflaxe_ruby_strict_examples` rejects raw injection in examples/tests; `reflaxe_ruby_strict` rejects project-source raw injection; raw call first argument must be a constant string. | `npm run test:strict-boundaries`; README strict policy; AGENTS rule forbids app-level raw Ruby. | Keep as-is for std/runtime internals; use `haxe.ruby-bjv.4.2` for app-facing dynamic/raw replacements. |
| Raw ERB authoring | HHX through `@:railsTemplateAst(...)`, typed `HtmlNode`, typed locals, and compiler-emitted ERB. | `@:railsAllowRawErb` on `@:railsTemplate(...)` classes. | Compiler rejects raw ERB bodies unless the explicit metadata is present. Canonical todoapp smoke rejects `@:railsAllowRawErb` in todoapp source. | `npm run test:todoapp-rails`; AGENTS hard rule for HHX default. | `haxe.ruby-bjv.4.3`, `haxe.ruby-bjv.3.4` for broader HHX helper coverage. |
| Existing Rails ERB | Haxe-owned templates use `Template.of(...)`/`Template.layout(...)`; external Rails-owned ERB uses checked contracts. | `Template.existing("path") : Template<TLocals>` / `Component.existing("path", "slot")` for checked Rails-owned ERB; `Template.external("path")` when a synthetic/test fixture cannot be discovered. | `Template.existing` and `Component.existing` require string literals, reject absolute/traversal/empty/backslash paths, and check `app/views`/`rails/app/views`; component slots must be safe Haxe/Ruby local identifiers. `Template.external` remains typed for locals but does not check filesystem presence. | `npm run test:rails-interop`; `npm run test:components`; `npm run test:rails-adopt-generator`; gradual adoption docs. | `haxe.ruby-bjv.4.3` for more complete path/unchecked policy. |
| Rails template/layout path strings | Typed template refs: `Template.of(ViewClass)`, `Template.layout(LayoutViewClass)`, and checked `Layout.named("application")` for explicit lower-level layout literals. | `@:railsTemplate("...")`, `Template.named("...")`, and `Template.external("...")`. | Literal-only and path-shape checks exist for compiler-owned paths; absolute, traversal, empty, repeated-slash, and backslash paths fail; missing Haxe-owned view classes fail through typed refs; raw layout strings are rejected by `ViewMacro.renderTemplateWithLayout`. | `npm run test:todoapp-rails`; type-safety review. | `haxe.ruby-bjv.4.3`. |
| Controller rescue constants | Typed exception externs such as `rails.active_record.RecordNotFound` with `rescueFrom(RecordNotFound, handler)`. | `rescueFromNamed("Ruby::Constant", handler)` for Ruby exceptions that do not have a typed extern yet. | The named form requires a safe Ruby constant path and still validates the handler method through the controller lifecycle DSL. | `npm run test:action-controller-params`; controller guide. | `haxe.ruby-bjv.3.3`, `haxe.ruby-bjv.4.1` for broader controller/string policy coverage. |
| Haxe-owned Rails routes | Typed route declarations such as `to(Controller, action)`, `externalTo("legacy/posts#show")`, checked route names, checked path literals, and `mountExternal(rubyConst("Sidekiq::Web"), at("/sidekiq"))`. | `uncheckedRubyRoute("...")` for a raw Rails route line that RailsHx cannot model yet. | The raw form requires `-D railshx_allow_unchecked_routes`, requires a single-line literal, and is covered by route DSL negative/positive smoke tests. It must stay out of canonical examples; future route manifest/parity work must mark raw entries opaque and compare Rails output where possible. | `npm run test:routes-dsl`; routing design doc; AGENTS routing rule. | `haxe.ruby-2pd.5`, `haxe.ruby-bjv.4.1`. |
| SQL/string-bearing query APIs | Typed refs/builders such as `Todo.f.title`, criteria objects, `Expr`, `Aggregate`, `Order.many`, `Projection.pluck`, `Projection.group`, `Group.count`, and `Group.countHaving`. | `whereSql(Sql.unsafeWhere(...))`, `whereNotSql(...)`, `orderSql(Sql.unsafeOrder(...))`, and `reorderSql(...)` for raw fragments RailsHx cannot model yet. | The unsafe constructor names and relation method names are searchable; plain `.where("...")` / `.order("...")` / grouped aggregate strings remain rejected in canonical sources; SQL fragments stay model/kind typed through `Sql<TModel, TKind>`. | `docs/railshx-sql-string-policy.md`; `docs/railshx-query-guide.md`; `npm run test:sql-string-policy`; `npm run test:active-record-model`. | `haxe.ruby-bjv.4.1`, `haxe.ruby-bjv.10`. |
| ActiveRecord custom lock strings | Typed lock helpers such as `Lock.forUpdate()`, `Lock.share()`, and `Lock.noWait()`. | `Lock.custom("...")` for database-specific lock strengths that Rails accepts but RailsHx does not model yet. | The API name is explicit, and normal examples prefer typed lock helpers. Future custom-lock use in canonical samples should document why a typed helper is insufficient. | `docs/railshx-query-guide.md`; `examples/active_record_model/README.md`; `npm run test:active-record-model`. | `haxe.ruby-bjv.4.1`, `haxe.ruby-bjv.3.1`. |
| Migration unknown tables | `models`/`knownModels` registry validates tables, columns, indexes, and foreign keys. | `externalTables: ["legacy_events"]` for Rails-owned schema outside Haxe metadata. | Unknown known-model tables/columns fail closed; external table names must be safe Rails table identifiers and intentionally skip column validation. | `npm run test:todoapp-rails`; migration comments in todoapp README. | `haxe.ruby-bjv.4.1`, `haxe.ruby-bjv.3.2`. |
| Generator/adoption source files | Deterministic metadata from Rails source, RBS, routes, schemas, or typed Haxe metadata. | Suggest-only discovery and future LLM-assisted patches. | Missing source/RBS files fail closed; source-backed adoption uses `Ripper`/RBS parsing without executing app code; input files must stay inside the app/output root; packages, Ruby constants, locals, Haxe type strings, and template paths are validated before Haxe source is emitted; generators protect existing wrappers; discovery prints suggestions without writing guessed contracts. | `npm run test:rails-adopt-generator`; gradual adoption and Ruby extension docs. | `haxe.ruby-bjv.4.4`, `haxe.ruby-bjv.6`. |
| `Dynamic` in app-facing APIs | Typed facades, generated externs, abstracts, and typed payload/locals/contracts. Generated route helpers use `RouteParam` so required segments are no longer advertised as `Dynamic`; relation-level ActiveRecord `find` uses typed scalar ID overloads instead of `Dynamic`; controller direct render/redirect status kwargs use `Status` through `RenderOptions`/`RedirectOptions`; `request().format()` returns typed `RequestFormat`; Turbo app code uses `EventTarget` targets and helpers such as `Turbo.addFetchRequestHeader(...)` instead of touching runtime fetch options directly; ActionCable client subscriptions require a typed `Consumer` handle and typed `Action<TData>` perform tokens; ActionMailer mail options use typed recipient/layout wrappers and typed attachment helpers; ActiveJob `performNow(...)` preserves the `perform(...)` return type and `performLater(...)` returns a typed job handle; ActiveSupport subscriptions use opaque handles without implicit `Dynamic` construction; ActiveStorage default `attach(...)` uses typed signed-id and `Attachable`/`Attachables` values. | `Dynamic` only at real runtime interop boundaries, explicit Haxe escapes such as `attachUnchecked(...)`, `Attachable.unchecked(...)`, `Attachables.unchecked(...)`, `performUnchecked(...)`, `MailAddress.unchecked(...)`, `MailLayout.unchecked(...)`, `AttachmentValue.unchecked(...)`, or `attachments().addUnchecked(...)`, Rails model/object route params via `RouteParam.model(...)`, broad Rails-owned render payloads such as `json`/`locals`, or generated review placeholders. | Some lower-level surfaces still use runtime-owned shapes: JS/Turbo fetch/response internals, controller render payload objects, generator-inferred unknown types, and explicit unchecked interop calls. Haxe's explicit `Dynamic` can still bypass ordinary static checks, so canonical APIs must not expose it casually. | Compatibility matrix, controller/Turbo/generator docs, `npm run test:todoapp-rails`, `npm run test:turbo`, `npm run test:routes-generator`, `npm run test:active-record-model`, `npm run test:action-cable`, `npm run test:action-mailer`, `npm run test:active-job`, `npm run test:instrumentation`, `npm run test:active-storage`. | `haxe.ruby-bjv.4.2`. |
| Behavior-bearing DOM hooks and CSS strings | Typed constants/abstracts shared by HHX, Haxe JS, and Playwright. | Local styling-only class strings. | Todoapp centralizes IDs/selectors/data attrs/storage keys through `shared.TodoHooks` and exports them to Playwright. | `npm run test:todoapp-rails`; `npm run test:todoapp-playwright`. | `haxe.ruby-bjv.3.4`, `haxe.ruby-bjv.3.6` for broader component/Turbo coverage. |

## Required Gates

Run these when changing escape-hatch behavior:

```bash
npm run test:strict-boundaries
npm run test:sql-string-policy
npm run test:todoapp-rails
npm run test:rails-interop
npm run test:rails-adopt-generator
npm run test:rails-generators
npm run ci:release-contracts
```

Use `npm run test:rails-runtime` and `npm run test:todoapp-production` when the
escape touches Rails runtime behavior, generated Rails app shape, migrations,
autoloading, or production assets.

## Current Decision

RailsHx production readiness remains blocked on the follow-up beads above, but
the escape hatches are now named and auditable. New RailsHx work should not add
another unsafe boundary unless this document is updated, a bead is filed, and
the API name makes the risk obvious.
