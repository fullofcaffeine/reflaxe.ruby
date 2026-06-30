package client;

import rails.action_cable.Consumer;
import channels.TodosChannel.TodoBroadcast;
import channels.TodosChannel.TodoSubscriptionParams;
import channels.TodosChannel.TodoCable;

// Demonstrates: typed Haxe JS can subscribe to an existing Rails ActionCable
// consumer without replacing Rails' generated `channels/consumer` module.
// Type safety: subscription params and received payloads share the same typedefs
// as the server channel. Client-side `perform(...)` actions use typed action
// tokens, so raw action strings and wrong payload shapes fail during Haxe
// compilation.
// IntelliSense: editors should complete `Consumer.subscribe`, `received`, and
// fields on `TodoBroadcast`.
// JS output: this lowers to `consumer.subscriptions.create(...)`, which is the
// Rails ActionCable client API.
class TodosCableClient {
	public static function subscribe(consumer:Consumer, listId:String, onTitle:String->Void):Void {
		var params:TodoSubscriptionParams = {listId: listId};
		var subscription = Consumer.subscribe(consumer, "TodosChannel", params, {
			connected: function():Void {},
			disconnected: function():Void {},
			received: function(payload:TodoBroadcast):Void {
				onTitle(payload.title);
			}
		});
		subscription.perform(TodoCable.pingAction(), {title: "client ping"});
	}
}
