package ruby;

/**
	Typed Ruby-semantic facade for the native core `Time` class.

	This contract deliberately keeps Ruby's one-based month, epoch-seconds,
	timezone, and daylight-saving behavior instead of imitating Haxe `Date`.
	Factories and receiver methods dispatch directly to core Ruby without a
	require or runtime wrapper. Open Numeric inputs, subsecond units, named
	timezone objects, mutation, permissive parsing, and heterogeneous arrays are
	omitted from this bounded surface.
**/
@:native("Time")
extern class Time {
	public static function now():Time;

	/** Creates a local time from Unix seconds, including a fractional part. **/
	public static function at(seconds:Float):Time;

	/** Creates a local time; `month` is Ruby's one-based month number. **/
	public static function local(year:Int, ?month:Int, ?day:Int, ?hour:Int, ?minute:Int, ?second:Float):Time;

	/** Creates a UTC time; `month` is Ruby's one-based month number. **/
	public static function utc(year:Int, ?month:Int, ?day:Int, ?hour:Int, ?minute:Int, ?second:Float):Time;

	public function year():Int;

	public function month():Int;

	public function day():Int;

	public function hour():Int;

	@:native("min")
	public function minute():Int;

	@:native("sec")
	public function second():Int;

	@:native("wday")
	public function weekday():Int;

	@:native("yday")
	public function yearDay():Int;

	@:native("dst?")
	public function isDaylightSavingTime():Bool;

	@:native("utc?")
	public function isUtc():Bool;

	@:native("utc_offset")
	public function utcOffsetSeconds():Int;

	/** Ruby may return `null` when the timezone has no textual abbreviation. **/
	public function zone():Null<String>;

	/** Returns a non-mutating UTC copy of this instant. **/
	@:native("getutc")
	public function toUtc():Time;

	/** Returns a non-mutating copy in the process-local timezone. **/
	@:native("getlocal")
	public function toLocal():Time;

	/** Returns a non-mutating copy at a fixed UTC offset measured in seconds. **/
	@:native("getlocal")
	public function toOffset(offsetSeconds:Int):Time;

	@:native("to_i")
	public function toEpochSecond():Int;

	@:native("to_f")
	public function toEpochSeconds():Float;

	public function strftime(format:String):String;

	/** Returns a new instant `seconds` after this one. **/
	@:native("+")
	public function addSeconds(seconds:Float):Time;

	/** Returns a new instant `seconds` before this one. **/
	@:native("-")
	public function subtractSeconds(seconds:Float):Time;

	/** Returns this instant minus `other`, measured in seconds. **/
	@:native("-")
	public function secondsSince(other:Time):Float;
}
