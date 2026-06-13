package rails.active_support;

@:rubyRequire("active_support/notifications")
class Notifications {
	public static function instrument<TPayload, TResult>(event:EventName<TPayload>, payload:TPayload, block:Void->TResult):TResult {
		return block();
	}

	public static function subscribe<TPayload>(event:EventName<TPayload>, handler:NotificationEvent<TPayload>->Void):Subscription {
		return cast null;
	}

	public static function monotonicSubscribe<TPayload>(event:EventName<TPayload>, handler:NotificationEvent<TPayload>->Void):Subscription {
		return cast null;
	}

	public static function unsubscribe(subscription:Subscription):Void {}
}
