package rails.test;

/**
	Marker base class for Haxe-authored Rails model tests.

	`@:railsTest` classes extending this type are compile-time inputs: the Ruby
	compiler emits an ordinary `ActiveSupport::TestCase` file under
	`test/generated`, while keeping the Haxe class out of app autoload output.
**/
class ModelTestCase {
	public function new() {}
}
