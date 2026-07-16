package ruby;

/**
	Property-only view of Open3's fixed `[stdout, stderr, status]` result.

	Ruby represents this native result as a heterogeneous Array, which Haxe must
	not expose as `Dynamic` or an unchecked bag. The private extern below permits
	exactly the three RBS-proven positional reads; no array access or conversion is
	available to callers, and generated Ruby remains direct native Array access.
**/
abstract Open3Capture(Open3CaptureTuple) {
	public var standardOutput(get, never):String;
	public var standardError(get, never):String;
	public var status(get, never):Open3Status;

	private inline function get_standardOutput():String {
		return this.readOutput();
	}

	private inline function get_standardError():String {
		return this.readError(1);
	}

	private inline function get_status():Open3Status {
		return this.readStatus();
	}
}

private extern class Open3CaptureTuple {
	@:native("first")
	public function readOutput():String;

	@:native("fetch")
	public function readError(index:Int):String;

	@:native("last")
	public function readStatus():Open3Status;
}
