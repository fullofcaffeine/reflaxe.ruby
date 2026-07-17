package ruby;

/**
	Typed Ruby-semantic facade for the default-gem `Date` class.

	Ruby owns one-based months, civil-calendar behavior, parsing, and day
	arithmetic. This is not the portable Haxe `Date` surface. The facade requires
	`date` and dispatches directly to `Date`; permissive parsing, calendar-reform
	starts, Rational values, DateTime, enumerators, and unchecked numeric inputs
	remain outside the bounded contract.
**/
@:rubyRequire("date")
@:native("Date")
extern class Date {
	/** Creates a civil date; `month` is Ruby's one-based month number. **/
	public function new(year:Int, ?month:Int, ?day:Int);

	public static function today():Date;

	/** Parses Ruby's strict ISO 8601 date forms. **/
	@:native("iso8601")
	public static function parseIso8601(value:String):Date;

	/** Parses `value` using the explicit `strftime`-style format. **/
	@:native("strptime")
	public static function parseWithFormat(value:String, format:String):Date;

	public function year():Int;

	public function month():Int;

	public function day():Int;

	@:native("wday")
	public function weekday():Int;

	@:native("yday")
	public function yearDay():Int;

	@:native("cwyear")
	public function isoWeekYear():Int;

	@:native("cweek")
	public function isoWeek():Int;

	@:native("cwday")
	public function isoWeekday():Int;

	@:native("leap?")
	public function isLeapYear():Bool;

	@:native("next_day")
	public function nextDay(?days:Int):Date;

	@:native("prev_day")
	public function previousDay(?days:Int):Date;

	@:native("next_month")
	public function nextMonth(?months:Int):Date;

	@:native("prev_month")
	public function previousMonth(?months:Int):Date;

	@:native("next_year")
	public function nextYear(?years:Int):Date;

	@:native("prev_year")
	public function previousYear(?years:Int):Date;

	@:native("iso8601")
	public function toIso8601():String;

	public function strftime(format:String):String;

	@:native("to_s")
	public function toString():String;
}
