package channels;

import rails.ActionCable;
import rails.action_cable.Channel;
import rails.action_cable.Stream;
import rails.action_cable.SubscriptionParam;

typedef TodoSubscriptionParams = {
	var listId:String;
}

typedef TodoBroadcast = {
	var title:String;
	var completed:Bool;
}

class TodoCable {
	public static inline var listId:SubscriptionParam<String> = "listId";

	public static inline function listStream(listId:String):Stream<TodoBroadcast> {
		return Stream.named("todos:" + listId);
	}
}

// Demonstrates: a Haxe-authored ActionCable channel that emits a normal
// ActionCable::Channel::Base subclass.
// Type safety: subscription params use `SubscriptionParam<T>`, stream names carry
// their broadcast payload type, and `ActionCable.broadcast(...)` rejects payloads
// that do not match `TodoBroadcast`.
// IntelliSense: editors should complete `param`, `streamFrom`, `transmit`,
// `stopAllStreams`, and the typed `TodoCable` refs.
// Rails output: generated Ruby calls `stream_from`, `transmit`,
// `stop_all_streams`, and `ActionCable.server.broadcast`.
@:railsChannel
class TodosChannel extends Channel<TodoSubscriptionParams, TodoBroadcast> {
	public function subscribed():Void {
		var listId = param(TodoCable.listId);
		streamFrom(TodoCable.listStream(listId));
	}

	public function unsubscribed():Void {
		stopAllStreams();
	}

	public function ping():Void {
		transmit({title: "pong", completed: false});
	}

	public static function announce(listId:String, title:String):Void {
		ActionCable.broadcast(TodoCable.listStream(listId), {
			title: title,
			completed: false
		});
	}
}
