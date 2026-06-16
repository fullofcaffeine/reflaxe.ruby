// Ruby extension interop tour.
//
// Demonstrates: simple `include`, simple `extend`, wrapping an existing Ruby
// class gradually, creating Haxe-owned Ruby modules/classes, and using a narrow
// raw Ruby island for target-specific metaprogramming.
// Type safety: extension contracts inject typed instance/static members into
// Haxe classes/externs; duplicates are compile errors unless explicitly
// overridden; `@:native` keeps Ruby method names while preserving Haxe-friendly
// completion names.
// IntelliSense: editors should complete mixed-in methods such as `slug()`,
// static extension methods such as `findBySlug(...)`, Haxe-owned members, and
// typed public APIs even when implementation is Ruby-owned.
// Ruby output: externs remain type-only, Haxe-owned classes emit normal
// `include`/`extend`, and injected type stubs do not leak into generated Ruby.
using StringMonkeyPatch;

// Scenario 1: consume an existing Ruby module that adds instance methods.
//
// `Sluggable` is implemented in Ruby, not Haxe. This extern interface is the
// typed Haxe contract for the instance methods that Ruby's `include Sluggable`
// adds to a receiver. The compiler copies this method shape into any class that
// uses `@:rubyInclude(SluggableInstance)`, so Haxe can type-check `post.slug()`
// while generated Ruby still calls the normal Ruby method.

@:rubyRequireRelative("./support/extensions")
@:rubyMixin({module: "Sluggable"})
extern interface SluggableInstance {
	@:native("slug")
	public function slug():String;
}

// Scenario 2: consume an existing Ruby module that adds class methods.
//
// Ruby's `extend SlugSearch` adds methods to the class object. In Haxe, static
// methods on the contract model that class-method surface. `@:native` keeps the
// Haxe API Haxe-friendly (`findBySlug`) while emitting the Ruby method name
// (`find_by_slug`).

@:rubyRequireRelative("./support/extensions")
@:rubyMixin({module: "SlugSearch"})
extern class SlugSearchClassMethods {
	@:native("find_by_slug")
	public static function findBySlug(slug:String):LegacyPost;
}

// Scenario 3: wrap a fully existing Ruby class without taking ownership of it.
//
// `LegacyPost` already exists in `support/extensions.rb`, where Ruby includes
// `Sluggable` and extends `SlugSearch`. This extern adds typed knowledge of that
// Ruby behavior to Haxe. No `legacy_post.rb` is generated; Haxe only verifies
// constructor/method calls and lowers them to direct Ruby calls.

@:rubyRequireRelative("./support/extensions")
@:native("LegacyPost")
@:rubyInclude(SluggableInstance)
@:rubyExtend(SlugSearchClassMethods)
extern class LegacyPost {
	public function new(title:String):Void;
}

// Scenario 4: describe Ruby mixins that a Haxe-owned class wants to use.
//
// The Ruby modules are still implemented externally in this first slice, but
// the receiving class below is Haxe-owned. These contracts give Haxe typed
// access to the mixed-in members while telling the Ruby compiler which module
// constant to emit in `include Decorated` and `extend Decorated`.

@:rubyMixin({module: "Decorated"})
extern interface PureHaxeDecoratedInstance {
	public function decorated():String;
}

// Class-method contract for the same Ruby module. Ruby allows one module to be
// used for both instance and class methods; Haxe keeps those surfaces separate
// because instance and static typing are different.

@:rubyMixin({module: "Decorated"})
extern class PureHaxeDecoratedClassMethods {
	@:native("build_label")
	public static function buildLabel(value:String):String;
}

// Scenario 5: create a Haxe-owned class that emits normal Ruby extension calls.
//
// The generated file contains a regular Ruby class with `include Decorated` and
// `extend Decorated`. The injected `decorated()` and `buildLabel()` members are
// type stubs only; they are erased from the class body so Ruby dispatch uses the
// real module methods. Ruby callers can consume `HaxeOwnedPost` as if it had
// been hand-written.

@:rubyInclude(PureHaxeDecoratedInstance)
@:rubyExtend(PureHaxeDecoratedClassMethods)
class HaxeOwnedPost {
	public var title:String;

	public function new(title:String) {
		this.title = title;
	}

	public function displayTitle():String {
		return "title:" + title;
	}
}

// Scenario 6: author a Ruby module in Haxe and include it.
//
// `@:rubyModule("DecoratedFromHaxe")` emits that Ruby `module`, not a class.
// Instance methods in the Haxe module become Ruby module instance methods, so a
// receiver can use them through `include DecoratedFromHaxe`.
// Type safety/IntelliSense: `HaxeModulePost` receives a typed `haxeBadge(...)`
// instance method through `@:rubyInclude(HaxeAuthoredDecorated)`.

@:rubyModule("DecoratedFromHaxe")
class HaxeAuthoredDecorated {
	@:native("haxe_badge")
	public function haxeBadge(value:String):String {
		return "haxe-module:" + value;
	}
}

// Scenario 7: author a Ruby module in Haxe and extend it.
//
// Ruby `extend Mod` adds module instance methods as class methods on the
// receiver. The build macro understands `@:rubyModule` contracts, so
// `@:rubyExtend(HaxeAuthoredClassMethods)` exposes `haxeClassBadge(...)` as a
// typed static method on `HaxeModulePost` while the emitted Ruby remains
// `extend ClassMethodsFromHaxe`.

@:rubyModule("ClassMethodsFromHaxe")
class HaxeAuthoredClassMethods {
	@:native("haxe_class_badge")
	public function haxeClassBadge(value:String):String {
		return "haxe-class:" + value;
	}
}

@:rubyInclude(HaxeAuthoredDecorated)
@:rubyExtend(HaxeAuthoredClassMethods)
class HaxeModulePost {
	public function new() {}
}

// Scenario 8: consume a Ruby module from a small raw-backed Haxe island.
//
// `RawDecorated` is still typed as a normal mixin contract. The raw Ruby below
// is intentionally separate from the mixin: it demonstrates how to keep a small
// target-specific metaprogramming operation behind a typed public method.

@:rubyMixin({module: "RawDecorated"})
extern interface RawDecoratedInstance {
	public function rawDecorated():String;
}

// Scenario 9: use `@:rubyAllowRaw` only around the smallest necessary type.
//
// Strict examples reject `__ruby__` unless the module/type explicitly declares
// raw authority. This is the escape-hatch shape for Ruby-specific behavior that
// is not yet covered by typed std/compiler APIs. The public method remains
// typed, so callers do not need to know raw Ruby exists internally.

@:rubyAllowRaw
@:rubyInclude(RawDecoratedInstance)
class HaxeRawBackedPost {
	public var title:String;

	public function new(title:String) {
		this.title = title;
	}

	public function rubyClassName():String {
		return untyped __ruby__("{0}.class.name", this);
	}
}

// Scenario 10: consume monkey-patched Ruby receiver methods through `using`.
//
// `StringMonkeyPatch` is an extern `@:rubyPatch(String)` contract in
// `StringMonkeyPatch.hx`. It models methods that Ruby adds directly to `String`
// by reopening the class. Haxe gets completion/type-checking for
// `"value".headline()` and `"value".surround(...)`; generated Ruby calls those
// patched receiver methods directly, without a wrapper class or helper object.
// Scenario 11: create and consume a pure Haxe library with no Ruby support file.
//
// This class does not wrap Ruby and does not use `__ruby__`. It proves that the
// same project can mix pure Haxe-owned Ruby output with typed wrappers around
// existing Ruby code.
class HaxeOnlyLibrary {
	public static function headline(value:String):String {
		return "haxe:" + value;
	}
}

// The entrypoint exercises each scenario in increasing complexity:
// existing Ruby externs, Haxe-authored modules, Haxe-owned mixin receivers,
// raw-backed islands, and a pure Haxe library. The smoke test also inspects
// generated Ruby to ensure the output stays Ruby-native (`module`,
// `include`/`extend`) and injected stubs do not leak.
class Main {
	static function main() {
		// Existing Ruby adoption: Haxe gets typed calls, Ruby keeps ownership.
		var legacy = new LegacyPost("Ship Typed Mixins");
		Sys.println(legacy.slug());
		Sys.println(LegacyPost.findBySlug("ship-typed-mixins").slug());

		// Haxe-owned receiver: generated Ruby includes/extends real modules.
		var owned = new HaxeOwnedPost("Owned Type");
		Sys.println(owned.decorated());
		Sys.println(HaxeOwnedPost.buildLabel("abc"));
		Sys.println(owned.displayTitle());

		// Haxe-owned modules: generated Ruby defines modules and includes/extends
		// them exactly like hand-written Ruby.
		var modulePost = new HaxeModulePost();
		Sys.println(modulePost.haxeBadge("typed"));
		Sys.println(HaxeModulePost.haxeClassBadge("typed"));

		// Raw-backed island: public API is typed, implementation is explicitly
		// allowed to use Ruby-specific metaprogramming internally.
		var rawBacked = new HaxeRawBackedPost("Raw Island");
		Sys.println(rawBacked.rawDecorated());
		Sys.println(rawBacked.rubyClassName());

		// Monkey-patch contract: Haxe `using` makes Ruby receiver extensions
		// discoverable and checked, then the compiler lowers to direct calls.
		Sys.println("typed patch".headline());
		Sys.println("typed patch".surround("[", "]"));
		Sys.println(StringMonkeyPatch.headline("direct patch"));

		// Pure Haxe library: no Ruby source required.
		Sys.println(HaxeOnlyLibrary.headline("library"));
	}
}
