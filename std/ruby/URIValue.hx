package ruby;

/**
	Nominal common contract for values returned by Ruby's `URI` module.

	Ruby returns scheme-specific subclasses from `URI.parse`; `URI::Generic` is
	their shared base, so this facade exposes only common reads and value-returning
	composition. Nullable components stay explicit, and mutating or
	scheme-specific APIs remain on future narrower contracts.
**/
@:rubyRequire("uri")
@:native("URI::Generic")
extern class URIValue {
	public function scheme():Null<String>;

	public function userinfo():Null<String>;

	public function user():Null<String>;

	public function password():Null<String>;

	public function host():Null<String>;

	public function hostname():Null<String>;

	public function port():Null<Int>;

	public function path():Null<String>;

	public function query():Null<String>;

	public function opaque():Null<String>;

	public function fragment():Null<String>;

	@:native("hierarchical?")
	public function isHierarchical():Bool;

	@:native("absolute?")
	public function isAbsolute():Bool;

	@:native("relative?")
	public function isRelative():Bool;

	public function merge(reference:String):URIValue;

	@:native("route_to")
	public function routeTo(destination:String):URIValue;

	@:native("route_from")
	public function routeFrom(base:String):URIValue;

	public function normalize():URIValue;

	@:native("to_s")
	public function toString():String;
}
