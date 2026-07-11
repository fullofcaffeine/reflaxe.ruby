package ruby;

/**
	Typed Haxe facade for Ruby's standard-library `Pathname` value.

	The facade keeps path operations nominal and chainable while mapping
	Haxe-idiomatic method names to ordinary Ruby receiver calls. It deliberately
	exposes a focused, precisely typed subset instead of Ruby's open variadic
	forwarders; repeated `join(...)` calls cover composition without leaking an
	untyped argument boundary.
**/
@:rubyRequire("pathname")
@:native("Pathname")
extern class Pathname {
	public function new(path:String);

	@:native("to_path")
	public function toPath():String;

	public function join(part:String):Pathname;

	@:native("join")
	public function joinPath(part:Pathname):Pathname;

	@:native("basename")
	public function baseName(?suffix:String):Pathname;

	@:native("dirname")
	public function directoryName():Pathname;

	@:native("extname")
	public function extension():String;

	@:native("cleanpath")
	public function clean(?considerSymlink:Bool):Pathname;

	@:native("expand_path")
	public function expand(?base:String):Pathname;

	@:native("realpath")
	public function real(?base:String):Pathname;

	@:native("relative_path_from")
	public function relativeTo(base:Pathname):Pathname;

	public function parent():Pathname;

	public function children(?withDirectory:Bool):Array<Pathname>;

	@:native("absolute?")
	public function isAbsolute():Bool;

	@:native("relative?")
	public function isRelative():Bool;

	@:native("root?")
	public function isRoot():Bool;

	@:native("exist?")
	public function exists():Bool;

	@:native("file?")
	public function isFile():Bool;

	@:native("directory?")
	public function isDirectory():Bool;

	@:native("readable?")
	public function isReadable():Bool;

	@:native("writable?")
	public function isWritable():Bool;

	@:native("executable?")
	public function isExecutable():Bool;

	@:native("symlink?")
	public function isSymlink():Bool;

	@:native("empty?")
	public function isEmpty():Bool;

	public function read(?length:Int, ?offset:Int):String;
}
