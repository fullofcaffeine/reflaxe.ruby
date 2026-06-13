package rails.action_cable;

@:autoBuild(rails.macros.ChannelMacro.build())
class Channel<TParams, TPayload> {
	public function new() {}

	@:native("stream_from")
	public function streamFrom(stream:Stream<TPayload>):Void {}

	@:native("stream_for")
	public function streamFor(target:Dynamic):Void {}

	@:native("stop_stream_from")
	public function stopStreamFrom(stream:Stream<TPayload>):Void {}

	@:native("stop_all_streams")
	public function stopAllStreams():Void {}

	@:railsActionCableParam
	public function param<TValue>(param:SubscriptionParam<TValue>):TValue {
		return cast null;
	}

	public function transmit(payload:TPayload):Void {}

	public function reject():Void {}
}
