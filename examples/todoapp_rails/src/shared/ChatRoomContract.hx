package shared;

import models.ChatMessage;
import rails.action_view.Template;
import rails.turbo.StreamTarget;
import shared.ChatRoomHooks;
import views.ChatMessageView;
import views.ChatMessageView.ChatMessageLocals;

/**
	Server-side typed Hotwire contract for the todoapp chat room.

	`@:hotwireContract` consumes the private stream/target/row declarations and
	generates `streamName()`, `streamTarget()`, and `rowTemplate()` with one shared
	`ChatMessageLocals` type. The browser-safe hook module still owns the literal
	values, while this server contract adds the Rails template and the explicit
	domain-model-to-locals mapping the macro cannot truthfully infer.
**/
@:hotwireContract
class ChatRoomContract {
	static final stream = ChatRoomHooks.streamName();
	static final target = ChatRoomHooks.targetId();
	static final row:Template<ChatMessageLocals> = Template.of(ChatMessageView);

	public static inline function panelTarget():StreamTarget {
		return StreamTarget.named(ChatRoomHooks.panelId);
	}

	public static inline function messageLocals(message:ChatMessage):ChatMessageLocals {
		return {message: message};
	}
}
