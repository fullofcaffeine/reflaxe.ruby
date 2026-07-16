package ruby;

/**
	Typed, bounded facade for Ruby's standard-library `URI` module.

	The contract accepts concrete Haxe strings and returns nominal URI values so
	common parsing and component encoding stay type-checked while generated Ruby
	uses the native module directly. Enumerable form data, open conversion
	protocols, optional encodings, and variadic joins remain outside this facade.
**/
@:rubyRequire("uri")
@:native("URI")
extern class URI {
	public static function parse(value:String):URIValue;

	/** Joins exactly two URI references; chain through `URIValue.merge` for more parts. **/
	public static function join(base:String, reference:String):URIValue;

	@:native("encode_www_form_component")
	public static function encodeFormComponent(value:String):String;

	@:native("decode_www_form_component")
	public static function decodeFormComponent(value:String):String;

	@:native("encode_uri_component")
	public static function encodeComponent(value:String):String;

	@:native("decode_uri_component")
	public static function decodeComponent(value:String):String;
}
