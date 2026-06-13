# RailsHx ActiveSupport Instrumentation Guide

RailsHx instrumentation is a typed Haxe layer over Rails-owned
`ActiveSupport::Notifications`. It is not a replacement event bus. Haxe gives
the app a shared event constant and payload shape; generated Ruby calls
`ActiveSupport::Notifications` directly.

## Event Contracts

Declare app-owned events centrally with a typed payload:

```haxe
import rails.active_support.EventName;

typedef TodoShipPayload = {
	var listId:String;
	var count:Int;
}

class TodoEvents {
	public static inline var shipped:EventName<TodoShipPayload> = "todo.shipped";
}
```

The event still lowers to the Rails string `"todo.shipped"`, but the Haxe type
parameter carries the payload contract through publishers and subscribers.

## Publishing

```haxe
import rails.active_support.Notifications;

var label = Notifications.instrument(TodoEvents.shipped, {listId: "open", count: 2}, function():String {
	return "instrumented";
});
```

Generated Ruby is Rails-native:

```ruby
label = ActiveSupport::Notifications.instrument("todo.shipped", {list_id: "open", count: 2}) { "instrumented" }
```

Type safety used here:

- The payload object must match `TodoShipPayload`.
- Missing fields such as `count` fail at Haxe compile time.
- Haxe camelCase payload fields lower to Rails/Ruby snake_case hash keys.
- The block return type is preserved at the Haxe call site.

## Subscribing

```haxe
import rails.active_support.NotificationEvent;
import rails.active_support.Notifications;
import rails.active_support.Subscription;

var subscription:Subscription = Notifications.subscribe(TodoEvents.shipped, function(event:NotificationEvent<TodoShipPayload>):Void {
	Sys.println(event.payload.listId + ":" + Std.string(event.payload.count));
});

Notifications.unsubscribe(subscription);
```

Generated Ruby uses the normal Rails event object and symbol payload keys:

```ruby
subscription = ActiveSupport::Notifications.subscribe("todo.shipped") { |event|
  puts("#{event.payload[:list_id]}:#{event.payload[:count]}")
}
ActiveSupport::Notifications.unsubscribe(subscription)
```

Type safety used here:

- Editors should complete `event.payload.listId`, `event.payload.count`,
  `event.name`, `event.duration`, and `event.allocations`.
- Reading a payload field with the wrong Haxe type fails before Ruby runs.
- `subscribe` and `instrument` share the same `EventName<TPayload>`, so the
  publisher/subscriber payload contract cannot drift silently.

## Monotonic Subscriptions

Use `monotonicSubscribe` when Rails monotonic timing is preferred:

```haxe
Notifications.monotonicSubscribe(TodoEvents.shipped, function(event:NotificationEvent<TodoShipPayload>):Void {
	trace(event.duration);
});
```

This lowers to:

```ruby
ActiveSupport::Notifications.monotonic_subscribe("todo.shipped") do |event|
  # ...
end
```

## Runtime Strategy

The CI smoke for this surface is static-first:

- Compile a Haxe instrumentation example.
- Assert the generated Ruby uses `ActiveSupport::Notifications` directly.
- Assert payload field reads lower to `event.payload[:snake_case_key]`.
- Compile negative fixtures that prove missing payload fields and wrong
  subscriber field types fail at Haxe compile time.
- Run Ruby syntax checks.
- If local Ruby has `active_support/notifications`, run the generated Ruby and
  verify publish/subscribe behavior. If ActiveSupport is not installed, the
  runtime pass is skipped with an explicit message.

Run it directly:

```bash
npm run test:instrumentation
```

