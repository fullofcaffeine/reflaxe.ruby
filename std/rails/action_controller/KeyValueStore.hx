package rails.action_controller;

/**
	Typed facade over Rails controller stores such as flash, session, and cookies.

	The compiler lowers `get`, `set`, and `delete` to Rails-native bracket/delete
	calls on the receiver. String literal keys are emitted as snake_case symbols.
**/
extern class KeyValueStore<TValue> {
	public function get(key:String):Null<TValue>;
	public function set(key:String, value:TValue):TValue;
	public function delete(key:String):Null<TValue>;
}
