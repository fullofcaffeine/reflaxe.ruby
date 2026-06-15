package rails.test;

/**
	Typed carrier for Rails/Minitest test descriptions.

	The abstract intentionally erases to `String` for Ruby output, while giving
	RailsHx a distinct type to document intent and tighten validation in the
	compiler. The compiler currently requires literal strings for deterministic
	generated test names and diagnostics.
**/
abstract TestDescription(String) from String to String {
	inline function new(value:String) {
		this = value;
	}
}
