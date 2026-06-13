import rails.active_support.EventName;
import rails.active_support.NotificationEvent;
import rails.active_support.Notifications;
import rails.active_support.Subscription;

typedef TodoShipPayload = {
	var listId:String;
	var count:Int;
}

class TodoEvents {
	public static inline var shipped:EventName<TodoShipPayload> = "todo.shipped";
}

// Demonstrates: typed Rails instrumentation around app code while generated
// Ruby stays ActiveSupport::Notifications-native.
// Type safety: `TodoEvents.shipped` carries the `TodoShipPayload` shape, so
// instrument payloads and subscriber payload reads are checked by Haxe.
// IntelliSense: editors should complete `Notifications.instrument`,
// `Notifications.subscribe`, `event.payload.listId`, and `event.duration`.
// Rails output: calls lower to `ActiveSupport::Notifications.instrument` and
// `ActiveSupport::Notifications.subscribe` with normal Rails payload hashes.
class Main {
	public static function main():Void {
		var subscription:Subscription = Notifications.subscribe(TodoEvents.shipped, function(event:NotificationEvent<TodoShipPayload>):Void {
			Sys.println(event.payload.listId + ":" + Std.string(event.payload.count));
		});

		var label = Notifications.instrument(TodoEvents.shipped, {listId: "open", count: 2}, function():String {
			return "instrumented";
		});
		Sys.println(label);
		Notifications.unsubscribe(subscription);
	}
}
