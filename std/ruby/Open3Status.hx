package ruby;

/**
	Typed read-only view of the completed child `Process::Status` from Open3.

	`capture3` waits for completion, so `succeeded()` is a concrete Bool. Exit and
	signal codes retain Ruby's nullability because only one termination mode owns
	each value.
**/
@:native("Process::Status")
extern class Open3Status {
	@:native("success?")
	public function succeeded():Bool;

	@:native("exitstatus")
	public function exitCode():Null<Int>;

	@:native("pid")
	public function processId():Int;

	@:native("exited?")
	public function exited():Bool;

	@:native("signaled?")
	public function signaled():Bool;

	@:native("termsig")
	public function terminationSignal():Null<Int>;
}
