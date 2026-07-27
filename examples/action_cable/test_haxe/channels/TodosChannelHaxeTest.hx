package test_haxe.channels;

import channels.TodosChannel;
import channels.TodosChannel.TodoBroadcast;
import channels.TodosChannel.TodoCable;
import channels.TodosChannel.TodoSubscriptionParams;
import rails.test.ChannelTestCase;

/**
	Haxe-authored channel test proving that subscription params and stream names
	stay tied to `TodosChannel`'s typed contract. RailsHx emits an ordinary
	`ActionCable::Channel::TestCase`; Rails itself performs the subscription and
	stream assertion.
**/
@:railsChannelTest(channels.TodosChannel)
@:railsTest("channels/todos_channel_haxe_test")
@:keep
class TodosChannelHaxeTest extends ChannelTestCase<TodoSubscriptionParams, TodoBroadcast> {
	@:test
	public function subscribesToTheTypedStream():Void {
		subscribe({listId: "open"});
		assertHasStream(TodoCable.listStream("open"));
	}

	@:test
	public function unsubscribeClearsTheTypedStream():Void {
		subscribe({listId: "open"});
		unsubscribe();
		assertNoStreams();
	}
}
