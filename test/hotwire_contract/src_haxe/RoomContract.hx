package;

import rails.action_view.Template;

typedef RoomRowLocals = {
	final title:String;
}

/**
	Positive fixture for the declaration-only Hotwire contract.

	The explicit row type is the single source of `RoomRowLocals`; the macro
	generates all three accessors without emitting a RoomContract runtime class.
**/
@:hotwireContract
class RoomContract {
	static final stream = "rooms:updates";
	static final target = "room-rows";
	static final row:Template<RoomRowLocals> = Template.named("rooms/row");

	public static inline function locals(title:String):RoomRowLocals {
		return {title: title};
	}
}
