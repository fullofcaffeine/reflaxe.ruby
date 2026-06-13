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

For a pure Haxe-owned library, author the class in Haxe and attach contracts for the Ruby module shape you want to expose:

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

If the module implementation is also Haxe-owned, prefer future compiler-owned `@:rubyModule`/`@:rubyConcern` style APIs over hand-written Ruby. Until that lands, keep module implementation in a small Ruby support file or a narrow raw-backed island.

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
bin/rails generate hxruby:adopt --service LegacySearch --signature-source rbs
```

The generator should produce Haxe externs and extension contracts, never unchecked dynamic calls by default. LLM assistance is acceptable as a suggest-only layer: it can draft contracts from Ruby source/docs, but the generated Haxe should compile, and risky guesses should be marked for review.

Filesystem-backed macros/generators must fail closed. If an API references `app/models`, `app/views`, `sig`, `rbs_collection`, a gem path, or any other file/directory source, missing paths must be compile/generator errors by default. Provide an explicit unchecked escape hatch only when there is a real synthetic/test/adoption reason, and name it accordingly (`external`, `unchecked`, or similar).

## Current Example

`examples/ruby_extensions` demonstrates:

- consuming an existing Ruby class that already includes and extends modules;
- adding typed extension contracts to an extern;
- generating a Haxe-owned class that emits normal `include` and `extend`;
- keeping injected Haxe type stubs out of generated Ruby;
- using a small `@:rubyAllowRaw` type for a deliberately raw-backed method.

Run:

```bash
npm run test:ruby-extensions
```

## Follow-Up Work

The current slice supports typed mixin consumption and Haxe-owned `include`/`extend`/`prepend` emission. Remaining work:

- author Haxe-owned Ruby modules/concerns directly;
- support typed `using`/monkey-patch extension contracts;
- add generator-assisted contract discovery from Ruby source, RBS, YARD, Rails schema/routes, and optional LLM suggestions;
- add richer validation for dynamic DSLs such as `ActiveSupport::Concern`, Rails scopes, callbacks, and gem-specific metaprogramming.
