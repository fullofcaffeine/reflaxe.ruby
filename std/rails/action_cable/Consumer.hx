package rails.action_cable;

/**
	Nominal handle for Rails' browser-side ActionCable consumer.

	Canonical Haxe-owned channel code subscribes through the generated
	`MyChannel.client` reference. The string-based methods remain explicit
	compatibility and Rails-owned-channel interop seams.
**/
class Consumer {
	public static function create(?url:String):Consumer {
		return url == null ? js.Syntax.code("ActionCable.createConsumer()") : js.Syntax.code("ActionCable.createConsumer({0})", url);
	}

	@:deprecated("Use MyChannel.client.subscribe(...) for @:railsChannel classes or subscribeExternal(...) for Rails-owned channels.")
	public static function subscribe<TParams, TPayload>(consumer:Consumer, channel:String, params:TParams,
			callbacks:SubscriptionCallbacks<TPayload>):Subscription<TPayload> {
		return subscribeExternal(consumer, channel, params, callbacks);
	}

	/**
		Subscribe to a Rails-owned or otherwise external channel whose class is not
		available as an `@:railsChannel` Haxe contract. The caller owns the checked
		channel name and the two generic shapes at this deliberate interop boundary.
	**/
	public static function subscribeExternal<TParams, TPayload>(consumer:Consumer, channel:String, params:TParams,
			callbacks:SubscriptionCallbacks<TPayload>):Subscription<TPayload> {
		return js.Syntax.code("{0}.subscriptions.create(Object.assign({ channel: {1} }, {2}), {3})", consumer, channel, params, callbacks);
	}
}
