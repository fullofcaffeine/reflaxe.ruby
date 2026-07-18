package rails.action_cable;

/**
	Browser subscription contract generated for one `@:railsChannel` class.

	The channel build macro adds a static `client` value carrying the server
	class's `Channel<TParams, TPayload>` types and exact Rails constant name. The
	abstract stays a plain string in generated JavaScript, while the build macro
	does not add the field during Ruby compilation. App code therefore writes
	`TodosChannel.client.subscribe(...)` without repeating or independently
	asserting the channel name, params, or received payload shape.
**/
abstract ChannelRef<TParams, TPayload>(String) {
	private inline function new(channelName:String) {
		this = channelName;
	}

	/**
		Subscribe through Rails' native ActionCable client using the server-derived
		params and payload contract.

		`js.Syntax.code` is intentionally local to this browser interop seam: Haxe
		does not model ActionCable's runtime-owned `subscriptions` object, while the
		public inputs and returned handle remain nominal and fully typed.
	**/
	public inline function subscribe(consumer:Consumer, params:TParams, callbacks:SubscriptionCallbacks<TPayload>):Subscription<TPayload> {
		return js.Syntax.code("{0}.subscriptions.create(Object.assign({ channel: {1} }, {2}), {3})", consumer, this, params, callbacks);
	}
}
