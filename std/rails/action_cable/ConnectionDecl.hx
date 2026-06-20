package rails.action_cable;

/**
	Compiler-owned marker calls for ActionCable connection declarations.

	`rails.macros.CableConnectionDsl.identifiedBy(...)` expands user-friendly
	identifier declarations into this marker. The Ruby compiler only recognizes
	it inside `@:railsCableConnection`'s `identifiers` field and erases the field
	into Rails' normal `identified_by` class macro.
**/
extern class ConnectionDecl {
	public static function identifiedBy<TValue>(identifier:ConnectionIdentifier<TValue>):ConnectionDecl;
}
