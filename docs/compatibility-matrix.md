# Compatibility Matrix

This document records the supported tool/runtime contract for `reflaxe.ruby`.
The source of truth is the packaged
[`lib/hxruby/support_matrix.json`](../lib/hxruby/support_matrix.json) manifest;
CI rejects drift between that manifest, workflows, package metadata, and this
guide.

## CI Baseline

| Surface | Versions | Status | Notes |
| --- | --- | --- | --- |
| Haxe | `4.3.7` | Supported | Pinned by `.haxerc` and `.github/workflows/ci.yml`. |
| Node.js | `>= 22.14.0`, `< 23` | Supported build-tool line | CI exercises the minimum `22.14.0` patch and current tested `22.23.1` patch. Release and repair jobs pin `22.23.1` with npm `10.9.8`. Node 22 reaches upstream EOL on 2027-04-30. |
| npm | `>= 10.9.2`, `< 11` | Supported with Node 22 | The release package-manager pin is `10.9.8`; the minimum Node lane retains its bundled npm `10.9.2`. |
| MRI Ruby | `3.4`, `4.0` | Primary | The full compiler/package suite and mandatory Rails runtime lane execute on both branches. |
| MRI Ruby | `3.3` | Transitional | The same full gates execute on 3.3 through its project sunset on 2027-03-31. New local development uses Ruby `3.4.10`. |
| Ruby 3.2 | EOL | Unsupported | Upstream support ended on 2026-04-01. The gem requires Ruby `>= 3.3`, and `hxruby:doctor` rejects this branch explicitly. |
| Rails fixture dependency range | `>= 7.0`, `< 8.0` | Accepted by current fixtures | This Bundler range is not evidence that every Rails 7 minor is independently supported. |
| Rails runtime evidence | `7.2.3.1` | Verified beta lane | The committed reference lock and canonical runtime lanes use Rails `7.2.3.1` with Ruby 3.3/3.4/4.0 and SQLite. Upstream security support ends on 2026-08-09, and CI expires this evidence rather than silently carrying it forward. |
| Rails 8.1 | Planned | Not currently supported | Rails 8.1 is the proposed runtime target for a combined RubyHx/RailsHx stable `1.0`. It must pass the reference/runtime matrix tracked by `haxe_ruby-nho0`; otherwise RailsHx remains beta. |
| Canonical platform | Ubuntu 24.04, Linux `x86_64` | Verified | macOS, Windows, ARM, Alpine/musl, JRuby, and TruffleRuby are unverified rather than implied support. Doctor reports that distinction. |
| Database runtime | SQLite | Verified | PostgreSQL and MySQL options have compile/snapshot evidence only. |
| Browser/client | Chromium via Playwright; importmap-rails, Propshaft, Turbo, Genes | Verified beta lane | Other browsers and asset/bundler stacks are unverified. |
| Distribution | GitHub Releases | Supported channel | The checksum-verified Haxelib ZIP and `hxruby` gem asset are not published to the Haxelib or RubyGems.org registries. |

Rails-shaped APIs that resemble Rails 8 do not establish Rails 8 runtime
compatibility. The generated fixtures accept `>= 7.0` and `< 8.0`, but the
current evidence supports only the locked Rails `7.2.3.1` lane. Other Rails 7
minors require their own runtime evidence before they become support claims.
The Rails 7.2 evidence deadline intentionally forces a new decision before its
upstream security window closes. Passing Ruby compilation on an EOL Rails line
will not extend the public RailsHx support claim.

Ruby lifecycle dates are checked against the official
[Ruby branch table](https://www.ruby-lang.org/en/downloads/branches/), Node
against the [Node release table](https://nodejs.org/en/about/previous-releases),
and Rails against the
[Rails support announcement](https://rubyonrails.org/2025/10/29/new-rails-releases-and-end-of-support-announcement).

## Diagnostics And Evidence Shape

`bundle exec rake hxruby:doctor` rejects unsupported MRI, Haxe, Node, and loaded
Rails versions with the verified alternatives. It warns when the host platform
is outside the canonical Ubuntu/Linux x86_64 lane. A warning means the
environment may work but is not covered by the stable support evidence; it is
not silently upgraded into a guarantee.

The full compiler, snapshot, package-consumer, and Rails runtime matrices run on
Ruby 3.3, 3.4, and 4.0. Browser and production sentinels remain representative
lanes on the oldest supported Ruby 3.3 branch, while the full and runtime gates
cover both primary branches. Node compatibility gates exercise both the declared
minimum and the current tested patch.

## Local Development Notes

The repo pins local Ruby `3.4.10` with `.ruby-version`; `rbenv install` from the
repo root installs the primary local lane. Ruby 3.3 remains useful for checking
the oldest supported branch but is no longer the day-to-day default.

Some lightweight Ruby smoke tests can pass on older system Rubies, including Ruby `2.6`, but that is a convenience only. Rails-first output assumes modern Ruby and Rails baselines from the PRD.

The runtime file `runtime/hxruby/data_define.rb` includes compatibility behavior for older Rubies that do not provide `Data.define`; this is why Ruby `2.6` may emit `Data` deprecation warnings in local minitest output. Those warnings are expected locally and are not part of the supported Rails baseline.

Run `rake test:rails:runtime` from the pinned Ruby to install generated app
bundles and execute the mandatory Rails runtime integration and mixed-interop
tests locally. CI runs the underlying npm command across Ruby `3.3`, `3.4`, and
`4.0`. The plain `rake test`/`npm test` command remains friendly for fast
compiler work: it syntax-checks generated Rails artifacts and runs Rails runtime
tests only when the local bundles are already available.

## Profiles

| Profile | Define | Status | Purpose |
| --- | --- | --- | --- |
| Ruby-first | `-D reflaxe_ruby_profile=ruby_first` | Default | Ruby/Rails conventions win when they conflict with cross-target portability. |
| Portable | `-D reflaxe_ruby_profile=portable` | Available | Haxe-semantics-first contract. Still emit idiomatic Ruby where behavior is preserved. |

See [Ruby Profiles](profiles.md) for the full profile contract. `-D reflaxe_ruby_profile=idiomatic` and `-D ruby_idiomatic` remain compatibility aliases for `ruby_first`. Profiles are semantic guardrails in one compiler pipeline, not separate backends. `metal` is intentionally not a public Ruby profile; performance policy should use explicit optimizer/runtime defines instead.

## Ruby Callable ABI

| Feature | Haxe surface | Status |
| --- | --- | --- |
| Typed native Ruby block calls | `@:rubyBlockArg` plus a final precise function parameter | Implemented for inline, stored, nullable, zero-/multi-argument, generic, patch, module/concern, and constructor call shapes |
| Haxe-owned Ruby block methods | The same `@:rubyBlockArg` declaration on static, instance, constructor, module, or concern methods | Implemented with direct `yield` versus captured `&block` chosen by conservative escape analysis |
| Callback-local return safety | Ordinary Haxe `return` inside an inline callback | Implemented: non-tail returns use a strict lambda passed with `&`; tail-safe callbacks remain native blocks |
| Ruby-origin calls into Haxe-owned block methods | Normal Ruby `{ ... }` / `do ... end` syntax | Executable coverage, including optional/captured/forwarded blocks and required captured-block diagnostics |
| Typed Ruby keyword calls and Haxe-owned definitions | `@:rubyKwargs` plus a required anonymous-object/typedef carrier with required/`@:optional` fields | Implemented for inline, stored, arbitrary single-evaluation, structurally narrowed, native-named, static, instance, constructor, combined-block, and Ruby-origin shapes; optional presence and unknown-key rejection are preserved |
| Ruby rest parameters and splat calls | Final `haxe.Rest<T>` and Haxe `...values` | Implemented for static, instance, constructor, forwarding, inline/stored spread, and Ruby-origin calls; unsupported rest-plus-keyword/block declarations fail closed |
| Method values, override/interface inheritance, and `super` forwarding | Ordinary Haxe method values/inheritance | Implemented for static/instance/effectful-receiver captures, optional/combined block+keyword adapters, Rest/splat method values, unannotated overrides, base/interface static types, recursion, modules/concerns, native `super`, and fail-closed conflicts |
| Pure RubyHx executable/Ruby-origin contract | `examples/ruby_callable_abi` plus handwritten `ruby_origin.rb` | Implemented with exact snapshots, Ruby syntax/runtime coverage, direct/captured/forwarded/optional/keyword-plus-block methods, typed stdlib extern blocks, and no `HXRuby.*` semantic helper calls |
| Array transform callable lowering | Haxe `Array.map` / `Array.filter` | Behavior-preserving backend calls emit native Ruby `map` / `select`; stored and non-tail-return callbacks retain strict lambda semantics; upstream parity and helper-removal policy are executable |

See [Ruby Callable And Method ABI](ruby-callable-abi.md) for the authoring,
lowering, diagnostics, and verification contract.

Typed-expression lowering is exhaustive and fail-closed. Unsupported compiler
intrinsics or statement-only shapes reaching value lowering are compile errors,
not generated `nil` placeholders; see [Ruby Compiler Correctness](compiler-correctness.md).

## Rails Mode

RailsHx satisfies the production-readiness gate for the documented `0.x` beta
contract. The supported surfaces below are tested and documented; see
[RailsHx Production Readiness](railshx-production-readiness.md) for the
mandatory runtime, deploy, security, API-completeness, generator, and support
gates that maintain that status. The typed API production audit is tracked in
[RailsHx Typed API Production Gap Audit](railshx-typed-api-production-gap-audit.md).
Unsafe boundary policy is tracked in
[RailsHx Escape Hatch And Security Audit](railshx-escape-hatch-security-audit.md).

| Feature | Define/tool | Status |
| --- | --- | --- |
| Rails output root | `-D reflaxe_ruby_rails` | Implemented |
| Custom Rails output root | `-D reflaxe_ruby_rails_output_root=<path>` | Implemented with safe relative path validation |
| ActiveRecord model surface | `rails.active_record.Base<T>` | Implemented |
| ActiveRecord compile-time model metadata | `@:railsColumn`, `Todo.f.title`, `Todo.typedColumnCount()` | Implemented without emitting runtime schema methods into Rails models |
| Typed ActiveRecord field refs | `Todo.fields.title` / `Todo.f.title : Field<Todo, String>`, `Todo.f.notes : NullableField<Todo, String>`, `Todo.railsParamKey : ModelKey<Todo>` | Initial form/params slice; string-to-field coercion is intentionally rejected |
| Typed ActiveRecord association refs | `Todo.associations.user` / `Todo.a.user : Association<Todo, User>` | Initial association query slice |
| Typed ActiveRecord relation chain | `Todo.none().reverseOrder().readOnly().select(Todo.f.title).distinct().where({completed: false}).whereNot({status: "done"}).whereIn(Todo.f.status, ["open"]).whereBetween(Todo.f.id, 1, 10).whereGt(Todo.f.id, 1).where(Todo.f.title.lower().eq("ship")).whereNotLte(Todo.f.id, 10).whereNull(Todo.f.notes).rewhere({status: "done"}).or(Todo.where({completed: true})).merge(Todo.where({status: "open"})).order(Todo.f.title.asc()).order(Todo.f.title.lower().asc()).reorder(Order.many([Todo.f.id.desc(), Todo.f.title.asc()])).offset(20).limit(10) : Relation<Todo, criteria>`, `Todo.pluck(Todo.f.title) : Array<String>`, `Todo.maximum(Todo.f.id) : Null<Int>`, `Todo.sum(Todo.f.userId) : Int`, `Todo.average(Todo.f.userId) : Null<Float>` inferred | Initial query slice |
| Typed ActiveRecord projections/grouped counts | `Projection.pluck(Todo.where({...}), {id: Todo.f.id, title: Todo.f.title}) : Array<{id:Int, title:String}>`, `Projection.group(Todo, Todo.f.status, {status: Todo.f.status, todoCount: Todo.f.id.count()}) : Array<{status:String, todoCount:Int}>`, `Group.count(Todo, Todo.f.userId) : haxe.ds.IntMap<Int>`, `Group.countHaving(Todo, Todo.f.status, Todo.f.id.count().gt(1)) : haxe.ds.StringMap<Int>` | Initial projection/grouping/having slice |
| Typed ActiveRecord association queries | `Todo.includes(Todo.associations.user).joins(Todo.a.user)` | Initial association query slice |
| Typed ActiveRecord scopes | `@:railsScope public static function incomplete()`, `@:railsDefaultScope public static function orderedByTitle()` | Emits Rails `scope` / `default_scope` macros while preserving typed Haxe calls |
| Typed ActiveRecord find helpers | `Todo.find(1)`, `Todo.findBy({externalId: "x"})`, `relation.findBy({...})` | Initial query slice |
| Typed ActiveRecord existence/count/loading helpers | `Todo.exists({externalId: "x"})`, `relation.exists({...})`, `Todo.count()`, `relation.count()`, `Todo.first()`, `relation.last()` | Initial query slice |
| Model associations/validations/enums/callbacks metadata | `@:belongsTo`, `@:hasMany`, `@:hasOne`, `@:validates`, `@:railsEnum`, `@:beforeValidation`, `@:railsCallback("after_commit")` | Implemented initial typed metadata validation |
| Typed Rails migrations | `@:railsMigration({models: [...], knownModels: [...], externalTables: [...]})` + snapshot `MigrationOperation` values | Model-derived create-table compatibility plus production-preferred snapshot operations: `CreateTable` with typed id/id-type/primary-key/comment/temporary options, `ChangeTable` with typed column/default/null change, column/index rename, column/reference/index add/remove bulk blocks, guarded table-block foreign-key, unique-constraint, and exclusion-constraint add/remove including guarded constraint forms, check-constraint add/remove, guarded add-index, guarded remove-index with DDL options, and timestamp add/remove, `Column`, `Reference` with typed id-type/comment/index columns, typed foreign-key hashes including deferred validation, and polymorphic foreign-key diagnostics, `Index`, typed string/text/numeric/date/time/binary/json columns, typed column comments, typed index comments, using methods, index types, guarded concurrent index algorithms through `disableDdlTransaction`, MySQL index lock modes, operation-level MySQL DDL algorithms/locks for add/change/remove/rename column and remove-index operations, prefix lengths, opclasses, ordered columns, include columns, and nulls-not-distinct options, reversible comment changes, typed timestamp add/remove, typed join table create/drop with typed column options, checked extension enable/disable, checked schema create/drop/rename, checked enum create/drop/add/type/value rename, checked column bounds, idempotent create/drop tables, idempotent add/remove columns/references, typed reversible column removal, typed reversible bulk column removal, named/idempotent/deferrable foreign keys and named/idempotent foreign-key removal, named/idempotent indexes, named/idempotent index removal, reversible index renames, checked index enable/disable, typed default/null backfill changes, deferred FK/check validation including table-block validation commands, `AddReference`, `AddCompositeIndex`, `RemoveCompositeIndex`, safe named/idempotent check constraints, generic named constraint validation/removal, checked unique constraints including idempotent creation/removal and using-index conversion, checked exclusion constraints including idempotent creation/removal, rename/change-null, reversible destructive ops, migration version metadata, and explicit SQL/data rollback |
| ActionController surface | `rails.action_controller.Base` | Implemented |
| Strong params macro | `ParamsMacro.requirePermit(this.params(), Todo.railsParamKey, [Todo.f.title], {metadata: ["source"], tags: []})` | Typed field-ref validation and nested permit specs implemented; returns nominal `PermittedParams<Todo>` so Rails-owned parameter objects remain positional and model-scoped without `Dynamic` |
| Controller request/response facades | `request.requestMethod()`, `request.format().json()`, `request.formats()`, `request.contentMimeType()`, `request.variant().phone()`, `response.status()` | Initial typed extern facade slice, including MIME format, negotiated formats, content/media type, and variant inquirers |
| Controller lifecycle | `static final lifecycle = { beforeAction(authenticateUser, {only: [create]}); skipBeforeAction(loadTenant, {only: [runtimeOk]}); rescueFrom(RecordNotFound, notFound); }` | Contextual lifecycle DSL for filters, skip filters, and `rescue_from`; legacy method metadata remains compatibility-only |
| ActiveJob lifecycle/runtime | `static final lifecycle = { queueAs("mailers"); retryOn(StandardError, {attempts: 3}); discardOn(DeserializationError); }`, `performLater(...)`, `performNow(...)` | Initial contextual lifecycle DSL plus typed enqueue helpers; runtime Rails lane covers queue/enqueue/perform, typed argument serialization/deserialization, retry re-enqueue behavior, and discard tracking through Rails' test adapter |
| Controller stores | `flash.notice("...")`, `flash.alert("...")`, `session().get("key")`, `cookies().delete("key")` | Initial typed flash/session/cookies store slice |
| Controller response statuses | `head(Status.noContent)`, `render({json: data, status: Status.created})` | Initial typed status-token slice lowering to Rails symbols |
| Controller download responses | `sendFile(path, {filename: "todos.csv", disposition: SendDisposition.attachment, status: Status.ok})`, `sendData(csv, {...})` | Initial typed `send_file`/`send_data` kwargs slice |
| Controller HTTP freshness | `freshWhen({etag: "todos"})`, `stale({weakEtag: "todos", template: "controllers/todos/index"})` | Initial typed `fresh_when`/`stale?` kwargs slice |
| Controller CSRF policy | `protectFromForgery({with: ForgeryProtectionStrategy.exception, except: [index]})` | Initial typed `protect_from_forgery` lifecycle slice with strategy tokens and action refs |
| Controller respond_to | `respondTo(function(format) { format.html(...); format.json(...); })` | Initial typed format collector slice |
| Typed ActionView render locals | `ViewMacro.renderTemplate(...)` + `Template<TLocals>` | Implemented |
| RailsHx-owned template refs | `Template.of(ViewClass) : Template<TLocals>`, `Template.layout(LayoutViewClass)` | Initial checked-template slice |
| External Rails template locals | `Template.existing("path") : Template<TLocals>`; `Template.external("path")` as lower-level escape | Initial interop slice |
| Rails template artifact generation | `@:railsTemplate(...)` | Implemented |
| Rails HHX inline templates | `@:railsTemplateAst(...)` + `return <div>...</div>` | Initial page/partial helper slice |
| Typed Rails partial locals object | `render(locals:TLocals)` + `locals.foo` projection | Initial locals slice |
| Typed ActionView template AST | `@:railsTemplateAst(...)` + `H`/`HtmlNode`/`HtmlAttr` | Initial lower-level AST slice |
| Typed ActionView partial composition | `H.partial(...)` + `Template<TLocals>` | Initial partial/component slice |
| Typed ActionView route/helper calls | `H.linkTo(...)`, `H.buttonTo(...)` + route externs | Initial helper slice |
| Typed ActionView form helpers | `<form_with scope=${Todo.railsParamKey}>`, `<text_field name=${Todo.f.title}>`, `<search_field name=${Todo.f.title}>`, `<email_field name=${DeviseFormFields.email}>`, `<select name=${User.f.role} options=${[{label: "Member", value: "member"}]}>`, `<field_errors name=${Todo.f.title}>`, `<text_area>`, `<check_box>`, `<submit>` | Initial typed field-ref form slice |
| Typed HHX control/helper tags | `<if>`, `<for>`, `<link_to>`, `<button_to>`, `<partial>` | Initial template/helper slice |
| Typed HHX helper label children | static text or `${...}` expression children | Initial helper slice |
| Typed HHX nested helper slots | `<link_to>...</link_to>`, `<button_to>...</button_to>` block-form content | Initial slot slice |
| HHX view-local helper methods | Static same-class helpers called from `@:railsTemplateAst` views | R&D design drafted; scalar helpers recommended as first implementation slice |
| Typed RailsHx components | `Component<TLocals>`, `<component component=${...}>`, `Slot.content()` | Initial ActionView capture/render partial slice |
| Typed Turbo client helpers | `rails.turbo.Turbo`, `TurboVisitAction`, `TurboStreamAction` | Initial Haxe JS/importmap-friendly slice |
| Typed server-side Turbo streams | `TurboStreams.append/prepend/before/after/replace/update/remove`, `broadcast*To`, `StreamTarget`, `StreamName<TPayload>`, `Template<TLocals>` | Rails-native `turbo_stream.*`/`Turbo::StreamsChannel` slice |
| Typed ActionMailer mailers | `@:railsMailer`, `@:railsMailerParams`, `@:railsMailerPreview`, `MailerMacro.mailHtml/mailText/mailMultipart`, `Template<TLocals>`, `MailParam<T>`, `AttachmentValue`, `MessageDelivery` | Initial typed mailer/template/preview slice plus generated Rails runtime lane for multipart bodies, headers, typed string/hash/inline attachments, `deliver_now`, typed ActiveJob `deliver_later`, typed parameterized `.with(...)` params, and preview loading |
| Typed ActiveStorage attachments | `@:hasOneAttached`, `@:hasManyAttached`, `Model.attachments.*`, `Attachable`, `Attachables`, `Blob`, `SignedId`, `<file_field direct_upload>` | Initial typed refs plus generated Rails runtime lane for signed-ID attach, typed hash attachables, blob metadata/direct-upload helpers, direct-upload file field rendering, download/read, and purge on one/many attachments |
| Typed ActionCable channels/subscriptions | `@:railsChannel`, `Channel<TParams, TPayload>`, `Stream<TPayload>`, `SubscriptionParam<T>` | Channel/client static smoke plus generated Rails `ActionCable::Channel::TestCase` runtime lane |
| Typed ActiveSupport instrumentation | `EventName<TPayload>`, `Notifications.instrument/subscribe`, `NotificationEvent<TPayload>` | Initial ActiveSupport::Notifications static/runtime-if-available slice |
| Raw ERB template escape hatch | `@:railsAllowRawErb` | Implemented for migration/interop only |
| Mixed Rails/RailsHx adoption sample | `examples/rails_interop_app` + `npm run test:rails-interop` | Initial compile/static smoke |
| Existing Rails boundary adoption generator | `bin/rails generate hxruby:adopt` / `rake hxruby:gen:adopt` | Explicit service/template wrappers, source-backed service signature inference, source-backed extension contracts, Bundler gem inventory, and automatic strict YARD selection for gem constants |
| Rails app install generator | `bin/rails generate hxruby:install` / `rake hxruby:gen:app` | Implemented with typed starter controller, HHX layout/page, Haxe-owned root route, client JS, CSS/importmap, `hxruby:start`, and `hxruby:start:watch` |
| Route helper generator | `bin/rails generate hxruby:routes` / `rake hxruby:gen:routes` | Hardened for named Rails routes, nested/resource params, namespaces, member/collection routes, optional segments, globs, and mount-like rows |
| Haxe-owned route DSL | `@:railsRoutes` + `static final routes = { root(...); get(...); resources(...); }` | Initial slice: root, verb routes including `options`/`head`, typed `match(..., [GET, POST])`, typed controller/action refs, checked route aliases/path literals including optional and glob segments, resources/resource `only`/`except`/`param`, checked legacy `resourceName(...)`, nested `member`/`collection`, `namespace`, `scope`, `controller`, `defaults`, `constraints`, and generated `config/routes.rb` |
| ActionMailer generator | `bin/rails generate hxruby:mailer` / `rake hxruby:gen:mailer` | Generates Haxe-owned `@:railsMailer`, `@:railsMailerParams`, typed HHX html/text templates, `@:railsMailerPreview`, and Haxe-authored Rails test source |
| Template generator | `bin/rails generate hxruby:template` / `rake hxruby:gen:template` | Generates typed HHX view/partial source with checked Rails template paths and typed locals; raw ERB remains compiler output |
| Haxe-authored test generator | `bin/rails generate hxruby:test` / `rake hxruby:gen:test` | Generates `@:railsTest` sources using `@:railsTests static function define():Void`; Minitest is default, with explicit/auto RSpec adapter output under `spec/generated/**` |
| Scaffold generator | `bin/rails generate hxruby:scaffold` / `rake hxruby:gen:model` | Implemented |
| Rails engine/plugin affordances | `--rails-output-root`, engine-local `reflaxe_ruby_rails_output_root`, generated autoload initializer | Initial engine-local output and host-consumption slice |

The rows above describe the current Rails MVP. The deeper typed Rails compiler layer is tracked as RailsHx; see `docs/railshx-roadmap.md`, [RailsHx Typed ActiveRecord Query Guide](railshx-query-guide.md), and the `haxe.ruby-wpi` bead epic.

## Strict Boundary Policy

| Define | Status | Behavior |
| --- | --- | --- |
| `reflaxe_ruby_strict_examples` | Implemented | Rejects raw `__ruby__` injection in examples and tests/snapshots. |
| `reflaxe_ruby_strict` | Implemented | Rejects raw `__ruby__` injection in project sources. |
| `@:rubyAllowRaw` | Implemented | Narrow module/type escape hatch for policy-specific tests or framework-owned islands. |

See [RailsHx Escape Hatch And Security Audit](railshx-escape-hatch-security-audit.md)
for the full raw Ruby, raw ERB, SQL/string, `Dynamic`, file-backed macro, and
generator-inference policy.

## Ruby Extension Interop

| Feature | Surface | Status |
| --- | --- | --- |
| Typed instance mixin contracts | `@:rubyMixin` + `@:rubyInclude(Contract)` | Initial implementation |
| Typed prepend contracts | `@:rubyMixin` + `@:rubyPrepend(Contract)` | Initial implementation |
| Typed class-method mixin contracts | `@:rubyMixin` + `@:rubyExtend(Contract)` | Initial implementation |
| Extern extension consumption | `@:native("RubyConstant") extern class ...` plus extension contracts | Initial implementation |
| Haxe-owned mixin emission | generated Ruby `include`/`prepend`/`extend` | Initial implementation |
| Haxe-owned Ruby module authoring | `@:rubyModule("RubyModuleName")` | Initial implementation |
| Haxe-owned ActiveSupport::Concern authoring | `@:rubyConcern("RubyModuleName")` | Initial static output implementation |
| Typed monkey-patch/`using` contracts | `@:rubyPatch(ReceiverType)` plus Haxe `using` | Initial implementation |
| Typed ActiveSupport receiver facades | `rails.active_support.ObjectPresence`, `rails.active_support.StringFilters` | Initial facade slice |
| Generator-assisted contracts from Ruby source metadata | `hxruby:adopt --extension-source ... --extension-module ...` | Initial Ripper-backed implementation |
| Generator-assisted contracts from RBS | `hxruby:adopt --service Foo --rbs sig/foo.rbs` | Strict non-executing precise-or-omitted subset with scalar/nilable/Symbol/Array typing, canonical path checks, malformed-file failures, and no broad fallback types |
| Generator-assisted service contracts from YARD | `hxruby:adopt --service Foo --yard app/services/foo.rb` | Initial deterministic, no-execution, precise-or-omitted subset implemented |
| Automatic gem contracts from YARD | `hxruby:adopt --gem some_gem --discover` / `--write contracts` | Bundler-resolved `lib` discovery implemented with canonical path checks, reopened-constant aggregation, strict precise-or-omitted YARD contracts, and review-marked source fallback only for constants without YARD signatures |
| Generator-assisted contracts from broader Rails metadata/LLM suggestions | planned | Not implemented; LLM suggestions must remain advisory and pass compile/tests |
