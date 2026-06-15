package channels;

import rails.ActionCable;
import rails.action_cable.Action;
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

typedef TodoPingPayload = {
	var title:String;
}

class TodoCable {
	// Demonstrates: subscription params are explicit typed tokens. The value
	// still lowers to Rails' normal `params["list_id"]`, but raw strings cannot
	// satisfy `param(...)` elsewhere.
	public static inline function listId():SubscriptionParam<String> {
		return SubscriptionParam.named("listId");
	}

	public static inline function listStream(listId:String):Stream<TodoBroadcast> {
		return Stream.named("todos:" + listId);
	}

	public static inline function pingAction():Action<TodoPingPayload> {
		return Action.named("ping");
	}
}

// Demonstrates: a Haxe-authored ActionCable channel that emits a normal
// ActionCable::Channel::Base subclass.
// Type safety: subscription params use `SubscriptionParam<T>`, stream names carry
// their broadcast payload type, and `ActionCable.broadcast(...)` rejects payloads
// that do not match `TodoBroadcast`. Client action tokens such as
// `TodoCable.pingAction()` keep `subscription.perform(...)` payloads typed too.
// Runtime seam: the `"reject"` list id demonstrates Rails-native subscription
// rejection via the typed `reject()` helper; `unsubscribed()` demonstrates
// stream cleanup through `stop_all_streams`.
// IntelliSense: editors should complete `param`, `streamFrom`, `transmit`,
// `stopAllStreams`, and the typed `TodoCable` refs.
// Rails output: generated Ruby calls `stream_from`, `transmit`,
// `reject`, `stop_all_streams`, and `ActionCable.server.broadcast`.
@:railsChannel
class TodosChannel extends Channel<TodoSubscriptionParams, TodoBroadcast> {
	public function subscribed():Void {
		var listId = param(TodoCable.listId());
		if (listId == "reject") {
			reject();
			return;
		}
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
