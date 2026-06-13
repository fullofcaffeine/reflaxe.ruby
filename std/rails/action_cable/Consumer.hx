package rails.action_cable;

class Consumer {
	public static function create(?url:String):Dynamic {
		return url == null
			? js.Syntax.code("ActionCable.createConsumer()")
			: js.Syntax.code("ActionCable.createConsumer({0})", url);
	}

	public static function subscribe<TParams, TPayload>(
		consumer:Dynamic,
		channel:String,
		params:TParams,
		callbacks:SubscriptionCallbacks<TPayload>
	):Subscription<TPayload> {
		var identifier:Dynamic = js.Syntax.code("Object.assign({ channel: {0} }, {1})", channel, params);
		return js.Syntax.code("{0}.subscriptions.create({1}, {2})", consumer, identifier, callbacks);
	}
}
