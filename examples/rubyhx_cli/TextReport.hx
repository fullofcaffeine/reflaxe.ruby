/**
	Typed value returned by the text-report library and serialized by the CLI.

	Ruby callers receive the same generated hash-shaped value that Haxe callers
	use, so the field names and value types remain one shared contract.
**/
typedef TextReport = {
	var path:String;
	var lines:Int;
	var words:Int;
	var characters:Int;
}
