package interop.gems.demo_auth;

// Rails-owned Ruby constant adopted through a typed Haxe extern.
// Generated from Bundler gem demo_auth.
// Generated from deterministic YARD @param/@return tags without executing Ruby.
// Unsupported or incomplete signatures are omitted with review markers; no broad fallback type is synthesized.
@:native("DemoAuth::SessionManager")
extern class SessionManager {
	// Inferred from deterministic YARD @param/@return tags; verify the documented contract matches runtime behavior.
	public function new(?scope:String):Void;
	// Inferred from deterministic YARD @param/@return tags; verify the documented contract matches runtime behavior.
	@:native("current_user")
	public function currentUser(controller:String):Null<String>;
	// Review required: skipped undocumented_status: no immediately preceding YARD @param/@return tags were found.
	// Review required: skipped unsupported_payload: unsupported YARD @param payload type [Hash]; use a precise scalar, nilable scalar, or Array<T> contract.
	// Review required: skipped duplicate_marker: multiple YARD-documented definitions were found across gem sources; Ruby load order is not inferred.
	// Review required: skipped same_file_token: no deterministic YARD signature was found for this method in the reopened gem source.
	// Review required: skipped audit_token: no deterministic YARD signature was found for this method in the reopened gem source.
	// Inferred from deterministic YARD @param/@return tags; verify the documented contract matches runtime behavior.
	@:native("enabled?")
	public static function enabled(scope:String):Bool;
}
