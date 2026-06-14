package rails.active_support;

/**
	Opaque handle returned by `ActiveSupport::Notifications.subscribe`.

	The handle erases back to Rails' runtime subscription object via `to Dynamic`
	so generated Ruby can call `ActiveSupport::Notifications.unsubscribe(...)`
	directly. There is intentionally no `from Dynamic`: app code should obtain
	handles from `Notifications.subscribe(...)` / `monotonicSubscribe(...)`, not
	manufacture fake subscription tokens.
**/
abstract Subscription(Dynamic) to Dynamic {}
