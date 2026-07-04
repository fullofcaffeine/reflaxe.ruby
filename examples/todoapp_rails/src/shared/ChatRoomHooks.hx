package shared;

import shared.TodoHooks.DomId;
import shared.TodoHooks.Selector;

/**
	Browser-safe Hotwire hooks for the todoapp chat room.

	These values are shared by HHX, generated Playwright hooks, and Haxe client
	code. Server-only contracts such as typed ActionView templates live in
	`ChatRoomContract` so the frontend build can keep depending on this small
	constant surface without pulling in Rails compiler macros.
**/
class ChatRoomHooks {
	public static inline var streamName:ChatRoomStream = "todoapp:chat";
	public static inline var panelId:DomId = TodoHooks.chatPanelId;
	public static inline var listTargetId:DomId = TodoHooks.chatListId;
	public static inline var streamSourceConnectedSelector:Selector = "turbo-cable-stream-source[connected]";
}

abstract ChatRoomStream(String) from String to String {}
