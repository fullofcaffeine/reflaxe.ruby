package rails.action_controller;

/**
	Typed kwargs for Rails conditional GET helpers.

	Rails accepts keyword hashes for `fresh_when` and `stale?`. This typedef
	keeps the common ETag/template keys checked by Haxe and lets the compiler
	lower camelCase Haxe fields such as `weakEtag` to Rails-native
	`weak_etag:` kwargs.
**/
typedef FreshnessOptions = {
	@:optional var etag:String;
	@:optional var weakEtag:String;
	@:optional var strongEtag:String;
	@:optional var lastModified:String;
	@:optional var template:String;
}
