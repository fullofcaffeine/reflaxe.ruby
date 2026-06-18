package rails.routing;

/**
	Typed HTTP verb token for Rails route declarations.

	The macro DSL lets authors write `match("search", target, [GET, POST])`,
	which is valid Haxe only because macros read the identifiers before normal
	value resolution. This enum abstract is the typed carrier for APIs that need
	a value-level verb representation.
**/
enum abstract HttpVerb(String) to String {
	var GET = "get";
	var POST = "post";
	var PATCH = "patch";
	var PUT = "put";
	var DELETE = "delete";
	var OPTIONS = "options";
	var HEAD = "head";
}
