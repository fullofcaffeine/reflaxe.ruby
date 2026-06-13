package rails.action_cable;

typedef Subscription<TPayload> = {
	function perform(action:String, ?data:Dynamic):Void;
	function unsubscribe():Void;
}
