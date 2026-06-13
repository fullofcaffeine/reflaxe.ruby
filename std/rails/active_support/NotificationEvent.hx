package rails.active_support;

class NotificationEvent<TPayload> {
	public var name(default, null):String;
	public var payload(default, null):TPayload;
	public var duration(default, null):Float;
	public var allocations(default, null):Int;
}
