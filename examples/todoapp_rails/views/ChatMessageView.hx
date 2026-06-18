package views;

import models.ChatMessage;
import rails.action_view.HtmlNode;
import rails.turbo.StreamName;
import rails.turbo.StreamTarget;
import shared.TodoHooks;

typedef ChatMessageLocals = {
	var message:ChatMessage;
}

// Typed chat message partial.
//
// Demonstrates: the Rails-native Hotwire path for realtime rows. The same HHX
// partial renders initial page state and server-side Turbo Stream broadcasts,
// so no Haxe JS string template can drift from Rails-rendered HTML.
// Type safety: `ChatMessageLocals` carries a real `ChatMessage`, and stream
// broadcasts must provide that local before the compiler emits Rails code.
// IntelliSense: editors should complete `locals.message.body`,
// `locals.message.userId`, `ChatMessageView.roomStream`, and `roomTarget`.
// Ruby/Rails output: normal `_chat_message.html.erb` rendered by ActionView and
// `Turbo::StreamsChannel.broadcast_prepend_to`.
// `@:railsTemplate(...)` binds this Haxe view class to the Rails partial path
// the compiler will materialize under `app/views`. `@:railsTemplateAst("render")`
// tells RailsHx to parse the `render` method's HHX return value as a typed
// ActionView AST, then emit ERB from it instead of treating the method as normal
// Ruby code. Together they make the Haxe class the source of truth for a normal
// Rails partial.
@:railsTemplate("controllers/todos/_chat_message")
@:railsTemplateAst("render")
class ChatMessageView {
	public static inline function roomStream():StreamName<ChatMessageLocals> {
		return StreamName.named("todoapp:chat");
	}

	public static inline function roomTarget():StreamTarget {
		return StreamTarget.named(TodoHooks.chatListId);
	}

	public static function render(locals:ChatMessageLocals):HtmlNode {
		return <li class=${TodoHooks.chatMessageClass} data-railshx-chat-message-key=${locals.message.id}>
			<span class="avatar">#</span>
			<div>
				<strong>User ${locals.message.userId}</strong>
				<p>${locals.message.body}</p>
			</div>
		</li>;
	}
}
