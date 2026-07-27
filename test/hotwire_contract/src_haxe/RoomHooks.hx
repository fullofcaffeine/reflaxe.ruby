package;

/**
	Browser-safe declaration fixture. The public `rowsId` remains the HHX
	ownership token; `@:hotwireHooks` derives the stream and Playwright accessors
	without importing the server-side row template.
**/
@:hotwireHooks
class RoomHooks {
	static final stream:RoomStream = "rooms:updates";
	static final target:RoomDomId = RoomTokens.rowsId;
	static final ready:RoomSelector = "turbo-cable-stream-source[connected]";
}

class RoomTokens {
	public static inline final rowsId = "room-rows";
}

abstract RoomStream(String) from String to String {}
abstract RoomDomId(String) from String to String {}
abstract RoomSelector(String) from String to String {}
