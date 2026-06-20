package rails.test;

/**
	Marker base class for Haxe-authored Rails request/integration tests.

	`@:railsTest` classes extending this type are compile-time inputs: the Ruby
	compiler emits an ordinary `ActionDispatch::IntegrationTest` file under
	`test/generated`, while keeping the Haxe class out of app autoload output.
**/
class RequestTestCase {
	public function new() {}
}
