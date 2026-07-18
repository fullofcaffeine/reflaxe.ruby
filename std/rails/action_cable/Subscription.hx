package rails.action_cable;

/**
	Opaque facade over the JavaScript ActionCable subscription handle.

	The underlying Rails object is still the normal value returned by
	`consumer.subscriptions.create(...)`; the abstract exists so we can expose
	typed helpers instead of a structural `{ perform(action:String, data:Dynamic) }`
	shape. `from Dynamic` is intentional here because Rails owns the runtime
	handle. App code receives it from a generated `MyChannel.client` reference or
	the explicit `Consumer.subscribeExternal(...)` interop seam, then calls typed
	methods on this abstract.
**/
abstract Subscription<TPayload>(Dynamic) from Dynamic to Dynamic {
	public inline function perform<TData>(action:Action<TData>, data:TData):Void {
		js.Syntax.code("{0}.perform({1}, {2})", this, action, data);
	}

	public inline function performUnchecked(action:String, ?data:Dynamic):Void {
		if (data == null) {
			js.Syntax.code("{0}.perform({1})", this, action);
		} else {
			js.Syntax.code("{0}.perform({1}, {2})", this, action, data);
		}
	}

	public inline function unsubscribe():Void {
		js.Syntax.code("{0}.unsubscribe()", this);
	}
}
