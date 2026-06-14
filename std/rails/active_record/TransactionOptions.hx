package rails.active_record;

/**
	Typed options for Rails `transaction(...)`.
**/
typedef TransactionOptions = {
	@:optional var requiresNew:Bool;
	@:optional var joinable:Bool;
	@:optional var isolation:TransactionIsolation;
}
