package shared;

import models.ChatMessage;
import rails.action_view.Template;
import rails.turbo.StreamName;
import rails.turbo.StreamTarget;
import shared.ChatRoomHooks;
import views.ChatMessageView;
import views.ChatMessageView.ChatMessageLocals;

/**
	Server-side typed Hotwire contract for the todoapp chat room.

	The stream name and DOM targets come from the browser-safe hook module, while
	this class adds Rails-only template and locals types. Controllers and HHX use
	this contract instead of repeating Turbo stream strings, target IDs, or
	`Template.of(...)` casts at each call site.
**/
class ChatRoomContract {
	public static inline function messageStream():StreamName<ChatMessageLocals> {
		return StreamName.named(ChatRoomHooks.streamName);
	}

	public static inline function messageTarget():StreamTarget {
		return StreamTarget.named(ChatRoomHooks.listTargetId);
	}

	public static inline function panelTarget():StreamTarget {
		return StreamTarget.named(ChatRoomHooks.panelId);
	}

	public static inline function messageTemplate():Template<ChatMessageLocals> {
		return (Template.of(ChatMessageView) : Template<ChatMessageLocals>);
	}

	public static inline function messageLocals(message:ChatMessage):ChatMessageLocals {
		return {message: message};
	}
}
