# Ruby Extension Interop

Ruby uses `include`, `extend`, `prepend`, monkey patches, `ActiveSupport::Concern`, and code-generating DSLs heavily. RubyHx should model those idioms without forcing Haxe authors back into stringly/dynamic code.

The rule is: infer and generate what can be known, type what remains as a boundary, and fail closed when a macro points at files or directories.

## API Shape

Use extension contracts to describe methods added by a Ruby module:

```haxe
@:rubyMixin({module: "Sluggable"})
extern interface SluggableInstance {
	public function slug():String;
}

@:rubyMixin({module: "SlugSearch"})
extern class SlugSearchClassMethods {
	@:native("find_by_slug")
	public static function findBySlug(slug:String):Post;
}
```

Attach those contracts to a class:

```haxe
@:rubyInclude(SluggableInstance)
@:rubyExtend(SlugSearchClassMethods)
class Post {
	public var title:String;

	public function new(title:String) {
		this.title = title;
	}
}
```

Haxe sees `post.slug()` and `Post.findBySlug(...)` as typed calls. Generated Ruby stays normal:

```ruby
class Post
  include Sluggable
  extend SlugSearch
end
```

`@:rubyInclude(Contract)` injects instance members into the Haxe target. `@:rubyPrepend(Contract)` does the same but emits `prepend`. `@:rubyExtend(Contract)` injects static members and emits `extend`.

For extern targets, the injected members are type-only and no Ruby file is emitted. For Haxe-owned targets, the compiler emits `include`/`prepend`/`extend` and erases the injected stubs from the generated Ruby body.

For monkey-patched receiver methods, use `@:rubyPatch(ReceiverType)` plus Haxe `using`:

```haxe
using ActiveSupportStringPatch;

@:rubyRequire("active_support/core_ext/object/blank")
@:rubyPatch(String)
extern class ActiveSupportStringPatch {
	@:native("blank?")
	public static function blank(receiver:String):Bool;
}

var isBlank = "".blank();
```

Haxe type-checks `blank()` as a normal static extension method on `String`. Generated Ruby is direct receiver dispatch:

```ruby
"".blank?()
```

Patch contracts are for consuming existing Ruby receiver extensions. They must be `extern` classes whose public members are static functions with the patched receiver as the first argument. Use `@:native` when Ruby method names contain punctuation or do not fit Haxe naming.

## Simplest Cases

Simple instance mixin:

```haxe
@:rubyMixin({module: "Auditable"})
extern interface AuditableInstance {
	public function auditLabel():String;
}

@:rubyInclude(AuditableInstance)
class Invoice {}

var label = new Invoice().auditLabel();
```

Simple class-method mixin:

```haxe
@:rubyMixin({module: "FindByToken"})
extern class FindByTokenClassMethods {
	@:native("find_by_token")
	public static function findByToken(token:String):Invoice;
}

@:rubyExtend(FindByTokenClassMethods)
class Invoice {}

var invoice = Invoice.findByToken("abc");
```

Prepend, for Ruby interception semantics:

```haxe
@:rubyMixin({module: "InstrumentedSave"})
extern interface InstrumentedSaveInstance {
	public function save():Bool;
}

@:rubyPrepend(InstrumentedSaveInstance)
class Invoice {}
```

Simple monkey-patch contract:

```haxe
using StringMonkeyPatch;

@:rubyPatch(String)
extern class StringMonkeyPatch {
	public static function headline(receiver:String):String;
	public static function surround(receiver:String, left:String, right:String):String;
}

var value = "ship".surround("[", "]");
```

The first argument is the receiver that Ruby will dispatch on. Editors should complete `headline()` and `surround(...)` on `String` values after the `using` import.

## Wrap An Existing Ruby Library

When the Ruby code already exists, keep it Ruby-owned and add typed Haxe contracts at the seam:

```haxe
@:rubyRequire("friendly_id")
@:rubyMixin({module: "FriendlyId"})
extern interface FriendlyIdInstance {
	public function slug():String;
}

@:rubyRequire("friendly_id")
@:rubyMixin({module: "FriendlyId::FinderMethods"})
extern class FriendlyIdClassMethods {
	@:native("friendly")
	public static function friendly():FriendlyIdRelation<Post>;
}

@:native("Post")
@:rubyInclude(FriendlyIdInstance)
@:rubyExtend(FriendlyIdClassMethods)
extern class Post {}
```

This is the best first step for gradual adoption: no generated Ruby replaces the gem or app code, but Haxe now type-checks calls into the extension.

## Gradual Adoption

A practical migration usually moves through these stages:

1. Wrap the existing Ruby constant with `@:native`, `@:rubyRequire`, and typed extension contracts.
2. Type only the stable methods first; leave unknown/dynamic areas outside the Haxe boundary.
3. Add generated or hand-written facades when the Ruby API is too dynamic for direct typing.
4. Convert stable modules/classes to Haxe-owned code once Ruby callers can keep consuming the generated Ruby normally.

This supports quick PoCs: build the Ruby version first, wrap it with Haxe once the shape stabilizes, then gradually replace pieces with Haxe-owned implementations.

## Create A New Library In Haxe

For a pure Haxe-owned class, author the class in Haxe and attach contracts for the Ruby module shape you want to expose:

```haxe
@:rubyMixin({module: "DisplayName"})
extern interface DisplayNameInstance {
	public function displayName():String;
}

@:rubyInclude(DisplayNameInstance)
class Account {
	public var name:String;

	public function new(name:String) {
		this.name = name;
	}
}
```

Ruby callers get a normal class. Haxe callers get typed members.

If the module implementation is also Haxe-owned, author it with `@:rubyModule`:

```haxe
@:rubyModule("DisplayName")
class DisplayNameModule {
	public function displayName(value:String):String {
		return "display:" + value;
	}
}

@:rubyInclude(DisplayNameModule)
class Account {
	public function new() {}
}

var label = new Account().displayName("Ada");
```

The Haxe module class emits a Ruby `module DisplayName`. Its instance methods become Ruby module instance methods, so they work with `include`.

Ruby `extend Mod` also uses module instance methods, but exposes them as class methods on the receiver. `@:rubyExtend` understands `@:rubyModule` contracts and injects those methods as typed static methods:

```haxe
@:rubyModule("FindByToken")
class FindByTokenModule {
	@:native("find_by_token")
	public function findByToken(token:String):Account {
		return new Account();
	}
}

@:rubyExtend(FindByTokenModule)
class Account {
	public function new() {}
}

var account = Account.findByToken("abc");
```

For Rails/ActiveSupport-style modules, use `@:rubyConcern`:

```haxe
@:rubyConcern("Trackable")
class TrackableConcern {
	public function trackingLabel():String {
		return "tracked";
	}

	public static function lookupLabel(value:String):String {
		return "lookup:" + value;
	}
}
```

This emits a Ruby module with `extend ActiveSupport::Concern`; static Haxe methods lower into a Rails `class_methods do ... end` block. Because this requires ActiveSupport at runtime, plain Ruby smoke examples should use `@:rubyModule` unless the fixture is intentionally Rails/ActiveSupport-backed.

## Haxe Plus Ruby Escape Hatch

Use raw Ruby only for small metaprogramming islands that cannot yet be represented through typed std/compiler APIs:

```haxe
@:rubyAllowRaw
class RawBackedModel {
	public function rubyClassName():String {
		return untyped __ruby__("{0}.class.name", this);
	}
}
```

Rules for this lane:

- Put `@:rubyAllowRaw` on the smallest possible type.
- Keep the public API typed.
- Prefer typed externs, std/runtime wrappers, or compiler lowering whenever possible.
- Add a bead for missing typed support if the raw call appears in canonical app code.

## Metaprogramming-Heavy Libraries

For gems that define methods from declarations, database schema, routes, Sorbet/RBS, YARD, or runtime reflection, the right end state is generator-assisted contracts:

```bash
bin/rails generate hxruby:adopt --discover
bin/rails generate hxruby:adopt --extension-source app/models/concerns/sluggable.rb --extension-module Sluggable
```

The initial source-backed generator uses Ruby's parser to inspect module declarations and method signatures without executing app code. It emits `@:rubyMixin` instance/class-method contracts with `Dynamic` placeholders and review comments when source files lack real type metadata. Simple required and optional arguments are emitted; splats, keyword-heavy methods, and block signatures are skipped with comments so the generated Haxe remains compileable.

The generator should produce Haxe externs and extension contracts, never unchecked dynamic calls by default. LLM assistance is acceptable as a suggest-only layer: it can draft contracts from Ruby source/docs, but the generated Haxe should compile, and risky guesses should be marked for review.

Filesystem-backed macros/generators must fail closed. If an API references `app/models`, `app/views`, `sig`, `rbs_collection`, a gem path, or any other file/directory source, missing paths must be compile/generator errors by default. Provide an explicit unchecked escape hatch only when there is a real synthetic/test/adoption reason, and name it accordingly (`external`, `unchecked`, or similar).

Rails and Ruby std facades should use the same rule. For example, ActiveSupport-style receiver extensions should usually start as generated or hand-written `@:rubyPatch` contracts; module/Concern APIs should use `@:rubyMixin`/`@:rubyInclude`/`@:rubyExtend`; file-backed Rails components should use checked template/model/route macros. Prefer local reference sources in `../haxe.compilerdev.reference/rails` and `../haxe.compilerdev.reference/ruby` when designing these wrappers so the Haxe API stays typed while the output remains recognizable Ruby/Rails.

The initial std facades live under `rails.active_support`:

```haxe
using rails.active_support.ObjectPresence;
using rails.active_support.StringFilters;

var normalized = "  typed   rails ".squish();
var maybeValue = normalized.presence();
var hasValue = maybeValue.present();
```

These facades are still Ruby/Rails-owned APIs. Haxe provides the typed contract and completion surface; ActiveSupport provides the runtime implementation.

## Current Example

`examples/ruby_extensions` demonstrates:

- consuming an existing Ruby class that already includes and extends modules;
- adding typed extension contracts to an extern;
- generating a Haxe-owned class that emits normal `include` and `extend`;
- authoring Haxe-owned Ruby modules with `@:rubyModule`;
- statically verifying `@:rubyConcern` output for ActiveSupport::Concern-style modules;
- consuming monkey-patched receiver methods through `@:rubyPatch` and Haxe `using`;
- keeping injected Haxe type stubs out of generated Ruby;
- using a small `@:rubyAllowRaw` type for a deliberately raw-backed method.

Run:

```bash
npm run test:ruby-extensions
```

## Follow-Up Work

The current slice supports typed mixin consumption, Haxe-owned `include`/`extend`/`prepend` emission, Haxe-authored Ruby modules, initial Haxe-authored ActiveSupport::Concern output, typed monkey-patch/`using` contracts, and source-backed generation of initial `@:rubyMixin` contracts. Remaining work:

- add richer generator-assisted contract discovery from RBS, YARD, Rails schema/routes, and optional LLM suggestions;
- add richer validation/runtime examples for dynamic DSLs such as Rails scopes, callbacks, and gem-specific metaprogramming.
