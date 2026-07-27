package rails.test;

import rails.action_cable.Stream;

/**
	Typed marker base for Haxe-authored ActionCable channel tests.

	`TParams` is the tested channel's subscription-parameter record and
	`TPayload` is its stream payload. `@:railsChannelTest(ChannelType)` binds this
	compile-time test declaration to the real `@:railsChannel` owner, and the
	compiler emits Rails' native `ActionCable::Channel::TestCase` plus
	`tests ChannelType`. These methods are authoring facades only: generated Ruby
	calls Rails' own helpers, so no RailsHx test runtime is introduced.
**/
class ChannelTestCase<TParams, TPayload> {
	public function new() {}

	@:railsActionCableTestSubscribe
	@:native("subscribe")
	public function subscribe(params:TParams):Void {}

	@:native("assert_has_stream")
	public function assertHasStream(stream:Stream<TPayload>):Void {}

	@:native("assert_no_streams")
	public function assertNoStreams():Void {}

	@:native("unsubscribe")
	public function unsubscribe():Void {}
}
