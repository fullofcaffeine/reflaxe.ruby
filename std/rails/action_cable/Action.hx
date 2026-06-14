package rails.action_cable;

/*
	Typed client-side ActionCable action token.

	The abstract stores the Rails method name as a String and erases back to that
	string for generated JavaScript, but it does not allow implicit construction
	from String. That lets app code write Rails-native action names while Haxe
	keeps the payload type attached to the action at compile time.
*/
abstract Action<TData>(String) to String {
	inline function new(name:String) {
		this = name;
	}

	public static inline function named<TData>(name:String):Action<TData> {
		return new Action<TData>(name);
	}
}
