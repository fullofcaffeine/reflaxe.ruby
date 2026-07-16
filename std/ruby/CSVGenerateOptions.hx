package ruby;

/**
	Typed, string-preserving options for Ruby CSV row generation.

	The facade owns separator and quoting controls whose results remain ordinary
	CSV strings. Write converters, headers, encodings, and arbitrary replacement
	objects stay omitted rather than leaking an open Ruby value boundary.
**/
typedef CSVGenerateOptions = {
	@:optional
	@:native("col_sep")
	var columnSeparator:String;

	@:optional
	@:native("row_sep")
	var rowSeparator:String;

	@:optional
	@:native("quote_char")
	var quoteCharacter:Null<String>;

	@:optional
	@:native("force_quotes")
	var forceQuotes:Bool;

	@:optional
	@:native("quote_empty")
	var quoteEmptyFields:Bool;
}
