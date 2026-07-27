package shared;

import shared.TodoHooks.DomId;
import shared.TodoHooks.Selector;

/**
	Browser-safe Hotwire hooks for the todoapp chat room.

	`@:hotwireHooks` consumes the private stream, target, and explicit readiness
	declarations and generates browser-safe typed accessors. Server-only
	contracts such as typed ActionView templates live in `ChatRoomContract`, so
	frontend and Playwright builds never need to import models or views merely to
	reuse test selectors.
**/
@:hotwireHooks
class ChatRoomHooks {
	static final stream:ChatRoomStream = "todoapp:chat";
	static final target:DomId = TodoHooks.chatListId;
	static final ready:Selector = "turbo-cable-stream-source[connected]";

	public static inline var panelId:DomId = TodoHooks.chatPanelId;
}

abstract ChatRoomStream(String) from String to String {}
