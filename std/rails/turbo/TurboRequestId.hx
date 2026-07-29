package rails.turbo;

/**
	Opaque correlation token for Turbo page-refresh streams.

	Turbo sends `X-Turbo-Request-Id` with browser-initiated requests and remembers
	recent IDs client-side. Echoing that ID on a refresh stream lets the
	originating browser ignore its own broadcast instead of refreshing twice.

	The value lowers to Rails' ordinary request-id string, but there is no
	implicit conversion from `String`: application code must cross the boundary
	explicitly with `TurboRequestId.named(...)`.
**/
abstract TurboRequestId(String) to String {
	public inline function new(value:String) {
		this = value;
	}

	public static function named(value:String):TurboRequestId {
		return new TurboRequestId(value);
	}
}
