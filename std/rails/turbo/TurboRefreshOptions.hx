package rails.turbo;

private typedef TurboRefreshOptionFields = {
	var ?requestId:TurboRequestId;
	var ?method:TurboRefreshMethod;
	var ?scroll:TurboRefreshScroll;
}

/**
	Typed options for a direct or broadcast Turbo page-refresh stream.

	The abstract exists so object literals stay closed and editor-friendly while
	the compiler can erase the carrier into ordinary Rails keyword arguments.
	The `TurboRequestId` conversion preserves the original request-only call
	shape without accepting a plain `String` or exposing a raw attributes bag.
**/
abstract TurboRefreshOptions(TurboRefreshOptionFields) from TurboRefreshOptionFields {
	inline function new(options:TurboRefreshOptionFields) {
		this = options;
	}

	@:from
	public static function fromRequestId(requestId:TurboRequestId):TurboRefreshOptions {
		return new TurboRefreshOptions({requestId: requestId});
	}
}
