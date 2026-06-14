package rails.turbo;

/**
	Typed DOM target token for Rails Turbo stream helpers.

	The abstract still lowers to the plain Rails target string via `to String`,
	but it deliberately has no `from String`: app code must opt into
	`StreamTarget.named(...)` or shared constants so behavior-bearing DOM targets
	are searchable and cannot be replaced by casual string literals.
**/
abstract StreamTarget(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static function named(name:String):StreamTarget {
		return new StreamTarget(name);
	}
}
