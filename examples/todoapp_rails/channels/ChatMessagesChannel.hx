package channels;

import rails.ActionCable;
import rails.action_cable.Channel;
import rails.action_cable.Stream;

typedef ChatSubscriptionParams = {}

typedef ChatBroadcast = {
	var id:Int;
	var body:String;
	var userId:Int;
}

class ChatCable {
	public static inline function roomStream():Stream<ChatBroadcast> {
		return Stream.named("todoapp:chat");
	}
}

// Typed ActionCable channel for the todoapp room.
//
// Demonstrates: RailsHx can own a real ActionCable channel while still emitting
// ordinary Rails channel code and using Rails' websocket runtime.
// Type safety: `ChatBroadcast` is shared with the Haxe JS client, and
// `ChatCable.roomStream()` carries that payload type for server broadcasts.
// IntelliSense: editors should complete `streamFrom`, `stopAllStreams`, and
// typed payload fields on the shared broadcast typedef.
// Rails output: a normal `ActionCable::Channel::Base` subclass under
// `app/haxe_gen/channels`.

@:railsChannel
class ChatMessagesChannel extends Channel<ChatSubscriptionParams, ChatBroadcast> {
	public function subscribed():Void {
		streamFrom(ChatCable.roomStream());
	}

	public function unsubscribed():Void {
		stopAllStreams();
	}

	public static function announce(id:Int, body:String, userId:Int):Void {
		ActionCable.broadcast(ChatCable.roomStream(), {
			id: id,
			body: body,
			userId: userId
		});
	}
}
