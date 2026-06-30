# RailsHx DSL Ergonomics Audit

RailsHx DSLs should be legal Haxe first, then macro-lowered to ordinary
Ruby/Rails. This audit tracks where the public API already follows that rule,
where metadata remains useful as compatibility, and where future work should
reduce stringly or repetitive authoring.

| Surface | Current canonical shape | Desired direction | Migration risk |
| --- | --- | --- | --- |
| Controller lifecycle | `static final lifecycle = { beforeAction(authenticateUser); rescueFrom(RecordNotFound, notFound); }` | Keep contextual lifecycle as canonical. Legacy method metadata remains compatibility-only. | Low; new code should use `lifecycle`, old metadata still lowers. |
| ActiveJob lifecycle | `static final lifecycle = { queueAs("mailers"); retryOn(StandardError, {attempts: 3}); discardOn(DeserializationError); }` | Keep contextual lifecycle as canonical. Add more typed queue tokens later if queue names become centralized. | Low; `@:queueAs`, `@:retryOn`, and `@:discardOn` still compile as compatibility. |
| ActiveRecord queries | `Todo.where({isCompleted: false}).order(Todo.f.title.asc()).limit(10)` | Keep relation chains Rails-shaped, typed, and field-ref driven. Prefer macro-generated field/association refs over strings. | Medium; query APIs are broad and should avoid raw SQL creep. |
| ActiveRecord scopes | `@:railsScope public static function incomplete()` | Keep metadata for compiler-owned class declaration because the method body is the typed API. Explore contextual scope registries only if metadata becomes repetitive. | Low; metadata maps closely to Rails class macros. |
| Model metadata | `@:railsModel`, `@:column`, `@:belongsTo`, `@:validates` | Keep metadata where it describes declarations on fields/classes. Generate refs, params keys, associations, and validations from it. | Medium; schemas/generators should reduce hand-written metadata over time. |
| Migrations | `@:railsMigration(...)` plus `MigrationOperation` values | Prefer generator-created operation snapshots for production migrations. Model metadata may seed the first file, but migration history must not live-derive from mutable current models. | Medium; DB behavior needs strong fail-closed checks. |
| HHX templates/components | `@:railsTemplateAst` methods returning inline HHX | Keep HHX as default. Template refs, slots, locals, model fields, route helpers, and view-local presentation helpers should be typed refs/functions instead of repeated strings. Follow `railshx-view-local-helpers-design.md`: static scalar helpers first, then markup helpers after diagnostics are proven. | Medium; parser/helper coverage is still expanding. |
| Mailers | `@:railsMailer` with typed `mail(...)` and `MailerMacro.mailHtml(...)` | Keep Rails-native ActionMailer output. Consider contextual lifecycle-style DSL only for repeated mailer callbacks/config that metadata cannot express well. | Low; current API is explicit and typed enough for the initial slice. |
| ActionCable channels | `@:railsChannel` plus generated typed subscription helpers | Review for contextual declarations if stream/subscription setup becomes metadata-heavy. Keep generated Ruby as normal ActionCable. | Medium; runtime behavior is less covered than compiler smoke. |
| Generators | Ruby/Rails-native `bin/rails generate hxruby:*` wrappers | Keep Rails-native generator UX. Generators create/adopt typed Haxe source and contracts; Rails runtime tasks such as `db:migrate` and `test` remain Rails-owned. Use Haxe or Haxe->Ruby dogfooding only after Ruby generator contracts are stable. | Low; app-facing Rails UX should not regress. |
| Ruby extension interop | `@:rubyInclude`, `@:rubyExtend`, `@:rubyPatch`, typed extern contracts | Keep typed contracts and generator-assisted adoption. Optional LLM suggestions must remain reviewable and compile-checked. | Medium; metaprogramming-heavy gems need conservative inference. |

## Compatibility Policy

Metadata is not banned. It is appropriate when it annotates a declaration that
already exists in Haxe, such as model fields, scopes, extern/native mapping, or
compatibility with older RailsHx code. For app-facing APIs that feel like Ruby
class-body macros, prefer a contextual field such as `lifecycle` because it is
valid Haxe, editor-friendly, and still compiler-erased.

When improving a DSL, preserve existing source compatibility unless the old API
is unsafe. If an old metadata form remains, document it as compatibility rather
than the canonical path and keep tests proving both the new typed path and the
legacy lowering contract.
