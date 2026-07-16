package ruby;

/**
	Typed, bounded facade for Ruby's CSV library.

	The public contract deliberately stays in header-free, converter-free rows of
	`Null<String>` fields. Default methods keep the common path concise; `With`
	variants use typed `@:rubyKwargs` carriers, and `forEachRow*` uses
	`@:rubyBlockArg`, so generated Ruby remains direct `CSV.*` calls with native
	keywords and blocks instead of a wrapper runtime.
**/
@:rubyRequire("csv")
@:native("CSV")
extern class CSV {
	@:native("parse_line")
	public static function parseLine(input:String):Null<CSVRow>;

	@:native("parse_line")
	@:rubyKwargs
	public static function parseLineWith(input:String, options:CSVParseOptions):Null<CSVRow>;

	@:native("parse")
	public static function parseRows(input:String):Array<CSVRow>;

	@:native("parse")
	@:rubyKwargs
	public static function parseRowsWith(input:String, options:CSVParseOptions):Array<CSVRow>;

	@:native("read")
	public static function readRows(path:String):Array<CSVRow>;

	@:native("read")
	@:rubyKwargs
	public static function readRowsWith(path:String, options:CSVParseOptions):Array<CSVRow>;

	@:native("foreach")
	@:rubyBlockArg
	public static function forEachRow(path:String, block:CSVRow->Void):Void;

	@:native("foreach")
	@:rubyKwargs
	@:rubyBlockArg
	public static function forEachRowWith(path:String, options:CSVParseOptions, block:CSVRow->Void):Void;

	@:native("generate_line")
	public static function generateLine(row:CSVRow):String;

	@:native("generate_line")
	@:rubyKwargs
	public static function generateLineWith(row:CSVRow, options:CSVGenerateOptions):String;

	@:native("generate_lines")
	public static function generateRows(rows:Array<CSVRow>):String;

	@:native("generate_lines")
	@:rubyKwargs
	public static function generateRowsWith(rows:Array<CSVRow>, options:CSVGenerateOptions):String;
}
