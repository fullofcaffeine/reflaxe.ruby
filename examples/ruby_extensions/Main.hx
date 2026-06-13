@:rubyRequireRelative("./support/extensions")
@:rubyMixin({module: "Sluggable"})
extern interface SluggableInstance {
	@:native("slug")
	public function slug():String;
}

@:rubyRequireRelative("./support/extensions")
@:rubyMixin({module: "SlugSearch"})
extern class SlugSearchClassMethods {
	@:native("find_by_slug")
	public static function findBySlug(slug:String):LegacyPost;
}

@:rubyRequireRelative("./support/extensions")
@:native("LegacyPost")
@:rubyInclude(SluggableInstance)
@:rubyExtend(SlugSearchClassMethods)
extern class LegacyPost {
	public function new(title:String):Void;
}

@:rubyMixin({module: "Decorated"})
extern interface PureHaxeDecoratedInstance {
	public function decorated():String;
}

@:rubyMixin({module: "Decorated"})
extern class PureHaxeDecoratedClassMethods {
	@:native("build_label")
	public static function buildLabel(value:String):String;
}

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

@:rubyMixin({module: "RawDecorated"})
extern interface RawDecoratedInstance {
	public function rawDecorated():String;
}

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

class HaxeOnlyLibrary {
	public static function headline(value:String):String {
		return "haxe:" + value;
	}
}

class Main {
	static function main() {
		var legacy = new LegacyPost("Ship Typed Mixins");
		Sys.println(legacy.slug());
		Sys.println(LegacyPost.findBySlug("ship-typed-mixins").slug());

		var owned = new HaxeOwnedPost("Owned Type");
		Sys.println(owned.decorated());
		Sys.println(HaxeOwnedPost.buildLabel("abc"));
		Sys.println(owned.displayTitle());

		var rawBacked = new HaxeRawBackedPost("Raw Island");
		Sys.println(rawBacked.rawDecorated());
		Sys.println(rawBacked.rubyClassName());

		Sys.println(HaxeOnlyLibrary.headline("library"));
	}
}
