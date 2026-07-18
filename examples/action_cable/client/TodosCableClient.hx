package client;

import rails.action_cable.Consumer;
import channels.TodosChannel;
import channels.TodosChannel.TodoCable;

// Demonstrates: typed Haxe JS can subscribe to an existing Rails ActionCable
// consumer without replacing Rails' generated `channels/consumer` module.
// Type safety: `TodosChannel.client` derives subscription params and received
// payloads from the server channel, so the client cannot repeat or drift its
// constant name. Client-side `perform(...)` actions use typed action
// tokens, so raw action strings and wrong payload shapes fail during Haxe
// compilation.
// IntelliSense: editors should complete `TodosChannel.client.subscribe`,
// `received`, and fields on `TodoBroadcast`.
// JS output: this lowers to `consumer.subscriptions.create(...)`, which is the
// Rails ActionCable client API.
class TodosCableClient {
	public static function subscribe(consumer:Consumer, listId:String, onTitle:String->Void):Void {
		var subscription = TodosChannel.client.subscribe(consumer, {listId: listId}, {
			connected: function():Void {},
			disconnected: function():Void {},
			received: function(payload):Void {
				onTitle(payload.title);
			}
		});
		subscription.perform(TodoCable.pingAction(), {title: "client ping"});
	}
}
