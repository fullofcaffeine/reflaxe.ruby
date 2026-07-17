package ruby;

/**
	Require-backed strict parsing extensions for Ruby's native `Time` class.

	Core `ruby.Time` intentionally stays available without loading Ruby's `time`
	default gem. This separate native view exists so parsing opts into
	`require "time"` only when used, while still emitting direct `Time.iso8601`
	and `Time.strptime` calls. Heuristic `Time.parse`, DateTime conversion, open
	`Numeric` inputs, and parser blocks remain outside this bounded contract.
**/
@:rubyRequire("time")
@:native("Time")
extern class TimeParsing {
	/** Parses the restricted ISO 8601/XML Schema form accepted by Ruby Time. **/
	@:native("iso8601")
	public static function parseIso8601(value:String):Time;

	/** Parses `value` using an explicit `strptime`-style format. **/
	@:native("strptime")
	public static function parseWithFormat(value:String, format:String):Time;
}
