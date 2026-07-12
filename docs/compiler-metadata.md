# RubyHx And RailsHx Compiler Metadata

This is the canonical index for target-specific metadata understood by the
RubyHx compiler and RailsHx macro/compiler layers. Metadata is part of the
public authoring contract: each public entry below states where it is valid,
what arguments it accepts, how it changes generated Ruby/Rails artifacts, and
which safety boundary it carries.

Haxe's built-in `@:native("RubyName")` remains the supported way to map a Haxe
type or field to an existing Ruby constant or method name. On methods, RubyHx
accepts normal identifiers, predicate/bang/writer suffixes, and supported Ruby
operators. On fields inside a `@:rubyKwargs` carrier, the value must be a plain
Ruby keyword identifier because it also becomes a local binding in Haxe-owned
definitions. RubyHx does not
define a separate `@:rubyName` alias. Other Haxe-owned metadata such as
`@:build`, `@:autoBuild`, `@:from`, and `@:to` keeps its normal Haxe meaning;
this reference covers the target-specific `@:ruby*` and `@:rails*` contracts.

The coverage gate scans the compiler and macro sources so a newly recognized
target metadata token cannot land without appearing in this reference:

```bash
npm run test:compiler-metadata-docs
```

## Ruby Call And Dependency Metadata

| Metadata | Valid on / arguments | Compiler contract | Boundary and diagnostics |
| --- | --- | --- | --- |
| `@:rubyRequire("feature")` | Any used type; exactly one non-empty string literal; repeatable. | Registers a deduplicated, sorted `require "feature"` in the generated module/run prelude when the annotated type is used. | Models Ruby/std/gem load ownership explicitly. Missing or non-string arguments are compile errors. It does not install the library. |
| `@:rubyRequireRelative("path")` | Any used type; exactly one non-empty string literal; repeatable. | Registers a deduplicated, sorted `require_relative "path"`. | Use only for a checked packaged/local companion artifact. The path is emitted as declared; this is not a filesystem-existence macro. |
| `@:rubyKwargs` | A non-dynamic method; no metadata arguments. Its required typed anonymous-object/typedef carrier is final, or immediately precedes a `@:rubyBlockArg` callback. Optionality belongs on carrier fields with `@:optional`, not on the carrier parameter. | Removes the positional carrier on calls and Haxe-owned definitions. Inline literals emit direct keywords; stored/arbitrary carriers are projected through the declared schema with single evaluation. Required fields become required Ruby keywords. Optional fields use a checked `**optional_keywords` bucket so omission remains distinct from explicit `nil`; the Haxe string-key carrier is rebuilt only when the body uses it as a value. Field names follow Ruby naming or field-level `@:native`. | Invalid placement/carrier types, malformed/duplicate keyword names, optional carrier parameters, and undeclared inline fields fail closed. Structurally wider stored values are narrowed to the declared schema. Required/optional fields and value types remain Haxe-checked. Do not replace the carrier with `Dynamic`. |
| `@:rubyBlockArg` | A non-dynamic method; no metadata arguments. The final Haxe parameter is a precise function type. The marker belongs on the called method, not the callback value. | Removes the function from positional arguments. Tail-safe inline functions emit native blocks; stored/nullable callbacks and inline callbacks with non-tail `return` use Ruby `&callback`/`&lambda`. Haxe-owned definitions emit `yield` for required direct-only use and `&block` plus `.call` for optional/escaping use. | Invalid placement or a non-function final parameter fails at the declaration. Required captured blocks reject missing Ruby-origin blocks. Ruby-owned APIs retain their own lifecycle/`ensure`; this marker preserves that behavior but does not manufacture cleanup. |

When `@:rubyKwargs` and `@:rubyBlockArg` appear together, declare positional
arguments first, then the typed keyword object, then the typed callback. The
compiler peels the block and keyword object into ordinary Ruby syntax:

```haxe
@:rubyKwargs
@:rubyBlockArg
public static function subscribe<T>(name:String, options:{once:Bool}, block:String->T):T;
```

```ruby
subscribe("events", once: true) do |value|
  # typed callback body
end
```

An inline Haxe `function` is therefore the authoring representation of an
inline Ruby block. A named/stored Haxe function is compiled as a Ruby lambda and
forwarded with `&` so its declared arity is preserved:

```haxe
var handler = function(value:String):Int return value.length;
NativeApi.subscribe("events", {once: true}, handler);
```

```ruby
handler = ->(value) { value.length }
NativeApi.subscribe("events", once: true, &handler)
```

See [Ruby callable and method ABI](ruby-callable-abi.md) for optional blocks,
callback-local return semantics, definition-side `yield`/capture policy,
method-value and inheritance rules, rest/splat boundaries, diagnostics, and the
required verification matrix.

No metadata is needed for rest arguments. A final `haxe.Rest<T>` parameter is
the typed Haxe contract for Ruby `*args`, and a Haxe spread call such as
`visit(...values)` emits `visit(*values)`. Because Haxe requires `Rest` to be
final while keyword/block carriers occupy their own trailing positions, RubyHx
rejects a declaration that combines `Rest` with `@:rubyKwargs` or
`@:rubyBlockArg`; use a narrow typed facade for such a native Ruby API instead
of weakening the signature.

## Ruby Extension And Module Metadata

| Metadata | Valid on / arguments | Compiler contract | Boundary and diagnostics |
| --- | --- | --- | --- |
| `@:rubyMixin({module: "Ruby::Module"})` | An extern contract class; object with a literal `module` constant path. A literal string is also accepted by the compiler. | Names the existing Ruby module represented by the typed contract. It is consumed by include/extend/prepend metadata and is not emitted as a Haxe class implementation. | Use typed fields for known module methods. Invalid/unresolvable contracts fail during the extension build macro. |
| `@:rubyInclude(ContractType)` | A target class; one class/interface type path. | Injects public contract instance members for Haxe completion/type checking and emits Ruby `include ModuleName`. | Colliding members are rejected unless the existing target member explicitly uses `@:rubyExtensionOverride`. |
| `@:rubyPrepend(ContractType)` | A target class; one class/interface type path. | Injects public contract instance members and emits Ruby `prepend ModuleName`. | Prepend changes Ruby method lookup order; choose it only when that override order is intentional. Collision rules match include. |
| `@:rubyExtend(ContractType)` | A target class; one class/interface type path. | Injects typed static members and emits Ruby `extend ModuleName`. For a Haxe-owned `@:rubyModule`, its instance methods become class methods on the receiver. | The contract must resolve to a class/interface; invalid paths or member collisions are compile errors. |
| `@:rubyExtensionOverride` | A target field that intentionally already owns a member injected by include/prepend/extend. | Acknowledges the collision and keeps the explicit target field instead of injecting the contract field. | This is narrow collision authority, not a general override switch. Put it only on the conflicting field and test the Ruby lookup behavior. |
| `@:rubyPatch(ReceiverType)` | An extern class; one receiver type. Public methods must be static and take that receiver as argument one. | Makes the class a typed Haxe `using` contract. Calls erase the helper receiver argument and emit direct patched-receiver dispatch. | Non-extern contracts, non-static fields, non-functions, and methods without the explicit receiver are compile errors. Use for already-installed monkey patches, not to apply patches. |
| `@:rubyModule("Ruby::Module")` | A Haxe-owned non-extern class; one literal Ruby constant path. | Emits a normal Ruby `module`; Haxe instance methods become module instance methods. It can be consumed by include/extend metadata. | Constructors are forbidden because Ruby modules are not instantiated. Generated output remains a real Ruby module, not a wrapper class. |
| `@:rubyConcern("Ruby::Concern")` | A Haxe-owned non-extern class; one literal Ruby constant path. | Emits a Ruby module with `extend ActiveSupport::Concern`; static Haxe methods are emitted inside `class_methods do`. Adds the ActiveSupport concern require. | Constructors are forbidden. Use only when the runtime really owns ActiveSupport::Concern semantics; plain Ruby modules should use `@:rubyModule`. |

The full extension workflow, examples, generated shapes, and adoption guidance
live in [Ruby extension interop](ruby-extension-interop.md).

## Ruby Erasure And Escape Metadata

| Metadata | Valid on / arguments | Compiler contract | Boundary and diagnostics |
| --- | --- | --- | --- |
| `@:rubyNoEmit` | A type with no arguments. | Keeps the Haxe type available to macros/type checking but emits no Ruby artifact for it. | It cannot also own Rails artifact metadata such as model/controller/template/migration. Calls must be erased or specially lowered; otherwise app code would reference a nonexistent Ruby constant. |
| `@:rubyAllowRaw` | The smallest class/module/abstract implementation that must contain `untyped __ruby__(...)`; no arguments. | Grants the strict-boundary scanner authority for raw Ruby only within that source module. | Raw calls still require constant source strings. This is an audited escape hatch, not permission for app-level dynamic code. Prefer typed externs/compiler lowerings. |

## Rails Artifact Metadata

These entries are public RailsHx authoring contracts. They are active only in a
Rails build and normally materialize standard Rails files/constructs rather
than Haxe runtime shells.

| Metadata | Placement / arguments | Generated or validation contract |
| --- | --- | --- |
| `@:railsApplicationController` | Application controller class; no arguments. | Emits the Rails application-controller artifact/superclass contract used by generated controllers. |
| `@:railsController` | Haxe-owned controller class; no arguments. | Emits an ActionController subclass at the Rails-native path and consumes the typed lifecycle/render/params DSL. |
| `@:railsExternalController("Ruby::Controller")` | Extern/adoption controller contract; literal existing Ruby constant. | Lets typed route declarations target a Rails-owned controller without regenerating it. |
| `@:railsModel` / `@:railsModel("table_name")` | ActiveRecord model class; optional literal table name. | Emits the model, registers schema/field refs, and supplies checked model metadata to queries, params, routes, migrations, tests, and attachments. |
| `@:railsTimestamps` | Model class; no arguments. | Adds typed/generated `created_at` and `updated_at` ownership to the model registry. |
| `@:railsColumn` / `@:railsColumn({...})` | Model field. Options are a checked literal object (`primaryKey`, `index`, `dbType`, `precision`, `scale`, `defaultValue`). | Registers a typed database column and generated field ref; invalid option names/types/defaults fail compilation. |
| `@:railsExternalAttribute` | Precisely typed instance field on a `@:railsModel`; no arguments. Use field-level `@:native` when the Ruby writer name differs. | Adds a gem/framework-owned virtual attribute to typed create/build/update carriers without emitting a column, accessor, schema entry, or migration. It cannot also be a column/association and cannot use `Dynamic`; the declared runtime owner must actually provide the Ruby reader/writer. |
| `@:railsEnum({...})` | A `@:railsColumn` model field; non-empty same-kind String or Int literal values. | Emits ActiveRecord enum metadata and validates the Haxe field/value kind. |
| `@:railsCallback("after_commit")` | Model method; one supported Rails callback name literal. | Emits the corresponding model callback registration with a typed method reference. Unknown callback names fail compilation. |
| `@:railsScope` | Static model method with a Relation-compatible body. | Emits an ActiveRecord `scope`; an optional compiler-derived name follows Ruby naming. Arguments remain typed. |
| `@:railsDefaultScope` | Zero-argument static model method. | Emits `default_scope` from the typed relation expression; methods with arguments are rejected. |
| `@:railsMigration({...})` | Migration declaration class; checked options such as typed `models` and `knownModels`. | Materializes a timestamped Rails migration and validates table/column/association operation ordering against known model state. |
| `@:railsRoutes` | Routes declaration class; no arguments. | Consumes the legal Haxe routes DSL and emits `config/routes.rb` plus the checked route manifest/helper contract. |
| `@:railsTemplate("path")` | View/template class; one safe literal Rails template path. | Owns the Rails template artifact path. Paths are literal-only and validated; external Rails-owned templates use typed `Template.existing/external` APIs instead. |
| `@:railsTemplateAst("method")` | A `@:railsTemplate` class; one literal method name such as `render`. | Runs typed Rails HHX rewriting on that method before Ruby/ERB lowering. The method must exist and satisfy the typed HTML-node contract. |
| `@:railsAllowRawErb` | Rails-owned migration/interop template only; no arguments. | Permits the otherwise-rejected raw ERB path. It requires an explicit gap rationale/follow-up and is forbidden in canonical RailsHx-owned authoring. |
| `@:railsMailer` | ActionMailer class; no arguments. | Emits an ActionMailer-native class and lowers typed mail actions/templates. |
| `@:railsMailerParams(ParamsType)` | `@:railsMailer` class; one non-empty typedef/anonymous object type. | Generates typed parameter accessors and validates params usage; duplicate or non-type arguments fail compilation. |
| `@:railsMailerPreview` | Preview class; no arguments. | Emits a Rails mailer preview artifact at the conventional test path. |
| `@:railsMailerSuperclass("Ruby::Mailer")` | Typed companion/extern mailer contract; one literal Ruby superclass. | Reuses an existing framework/gem-owned mailer superclass without core package-name special cases. |
| `@:railsJob` | ActiveJob class with an instance `perform(...)` method. | Emits an ActiveJob subclass and validates/lower typed retry/discard lifecycle declarations. Missing `perform` is rejected. |
| `@:railsChannel` | ActionCable channel class with `subscribed()`. | Emits an ActionCable channel and lowers typed params/stream contracts. Missing required lifecycle methods are rejected. |
| `@:railsCableConnection` | ActionCable connection class with `connect()` and typed identifier declaration. | Emits `ApplicationCable::Connection`; missing `connect` or identifier host is rejected. |
| `@:railsTest("path")` | Rails test/spec declaration class; safe literal output path. | Materializes a Rails-native test artifact instead of a runtime Haxe class. |
| `@:railsTestAdapter("rails.minitest" | "rails.rspec")` | `@:railsTest` class; one supported adapter literal. | Selects generated Minitest or RSpec shape; unsupported adapters fail closed. |
| `@:railsTests` | Static declaration-host method inside `@:railsTest`. | Marks the legal Haxe test DSL body that the compiler consumes and erases into Rails-native test cases. |

Detailed domain contracts remain in the corresponding RailsHx design/testing
documents and executable examples. This index owns metadata discoverability and
cross-cutting rules; domain guides own the larger API around each artifact.

## Compiler-Internal Metadata

The following tokens are generated by build macros or used as handoff markers
between typed std facades and compiler passes. Application code must not author
them directly. They are listed so generated sources are explainable and the
documentation coverage gate remains complete.

| Metadata | Owner and purpose |
| --- | --- |
| `@:rubyExternStub` | Extension/Rails build macros mark injected compile-time stubs so the Ruby compiler does not emit fake method bodies. |
| `@:rubyInjectedExtension` | The Ruby extension build macro marks members it injected, preventing duplicate collision diagnostics during repeated macro passes. |
| `@:railsAssociation` | Model macro handoff carrying the resolved association name for compiler lowering. |
| `@:railsAttachment` / `@:railsAttachmentKind` | Model macro handoff carrying generated ActiveStorage attachment name/kind. |
| `@:railsField` | HHX/model macro handoff carrying a checked Rails field name derived from typed schema metadata. |
| `@:railsFilter` | Controller lifecycle handoff for already-validated filter declarations. |
| `@:railsActionCableParam` | Channel macro handoff for a checked ActionCable param accessor. |
| `@:railsActionCableConnectionParam` | Connection macro handoff for a checked connection param accessor. |
| `@:railsActionCableConnectionAssign` | Connection macro handoff for a typed connection assignment. |
| `@:railsActionCableConnectionAccess` | Channel macro handoff for a typed identifier exposed by the connection. |
| `@:railsNoEmit` | Legacy/internal Rails erasure marker; new cross-layer compile-time-only types use `@:rubyNoEmit`. |
| `@:rails_hxx_inline_markup` / `@:rails_hxx_no_inline_markup` | Rails inline-markup parser sentinels that prevent duplicate HHX rewriting; never an app-facing API. |

## Metadata Review Checklist

Before adding a new compiler metadata contract:

1. Define a reusable compiler concept rather than a package-name special case.
2. Specify valid placement, literal/type arguments, generated artifact shape,
   interactions, and failure diagnostics in this reference.
3. Add positive generated snapshots and negative compile coverage.
4. Keep unsafe authority narrow and document how it is prevented from leaking
   into app APIs.
5. Add the metadata token to the appropriate public or internal section before
   `test:compiler-metadata-docs` can pass.
