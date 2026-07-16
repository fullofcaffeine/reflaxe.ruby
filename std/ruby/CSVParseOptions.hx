package ruby;

/**
	Typed, string-preserving options for header-free Ruby CSV parsing.

	Every field is optional because `@:rubyKwargs` preserves omission separately
	from an explicit value. Headers, converters, encodings, open modes, and custom
	nil/empty replacements are intentionally absent because they change the input
	or result type beyond `CSVRow`.
**/
typedef CSVParseOptions = {
	@:optional
	@:native("col_sep")
	var columnSeparator:String;

	@:optional
	@:native("row_sep")
	var rowSeparator:String;

	@:optional
	@:native("quote_char")
	var quoteCharacter:Null<String>;

	/** Bounds parser look-ahead for an unterminated quoted field. **/
	@:optional
	@:native("max_field_size")
	var maxFieldSize:Int;

	@:optional
	@:native("skip_blanks")
	var skipBlankRows:Bool;

	@:optional
	@:native("strip")
	var stripFields:Bool;

	@:optional
	@:native("liberal_parsing")
	var liberalParsing:Bool;
}
