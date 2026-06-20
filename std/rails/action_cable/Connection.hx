package rails.action_cable;

@:autoBuild(rails.macros.ConnectionMacro.build())
class Connection {
	public function new() {}

	@:railsActionCableConnectionAssign
	public function assign<TValue>(identifier:ConnectionIdentifier<TValue>, value:TValue):Void {}

	@:railsActionCableConnectionParam
	public function requestParam<TValue>(param:ConnectionParam<TValue>):Null<TValue> {
		return cast null;
	}

	@:native("reject_unauthorized_connection")
	public function rejectUnauthorizedConnection():Void {}
}
