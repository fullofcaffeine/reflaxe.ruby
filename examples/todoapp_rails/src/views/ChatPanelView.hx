package views;

import models.ChatMessage;
import models.User;
import rails.action_view.HtmlNode;
import rails.action_view.Template;
import routes.Routes;
import shared.TodoHooks;
import views.ChatMessageView;
import views.ChatMessageView.ChatMessageLocals;

typedef ChatPanelLocals = {
	var messages:Array<ChatMessage>;
	var currentUser:User;
	var users:Array<User>;
}

// Typed chat panel partial.
//
// Demonstrates: classic Hotwire realtime UI authored through typed HHX. The
// panel subscribes with `<turbo_stream_from>`, Rails broadcasts server-rendered
// `_chat_message` partials, and Haxe JS does not maintain a duplicate room DOM.
// Type safety: chat form fields use `ChatMessage.f.*`; authorship comes from
// the authenticated `currentUser` in the controller, not a spoofable hidden
// field; the loop body sees each message as a `ChatMessage` with typed fields.
// IntelliSense: editors should complete `locals.messages`, `message.body`,
// `message.userId`, `ChatMessage.f.body`, `Routes.chatMessagesPath`, and
// `ChatMessageView.roomStream`.
// Ruby/Rails output: normal ERB with `turbo_stream_from`, `form_with`, typed
// partial renders, loops, conditionals, and Rails route helpers.
@:railsTemplate("controllers/todos/_chat_panel")
@:railsTemplateAst("render")
class ChatPanelView {
	public static function render(locals:ChatPanelLocals):HtmlNode {
		return <section id=${TodoHooks.chatPanelId} class="card chat-panel" data-railshx-chat aria-label="RailsHx typed chatroom">
			<div class="chat-panel-header">
				<div class="chat-panel-kicker">
					<span class="eyebrow">Typed Turbo room</span>
					<turbo_stream_from stream=${ChatMessageView.roomStream()} />
				</div>
				<h2>Ship room</h2>
				<p>
					This is a Rails-native chat slice: Haxe owns the model, migration,
					controller, params, route, HHX, and client hooks; Rails receives
					ordinary ActiveRecord, ActionView, and Turbo Stream artifacts.
				</p>
			</div>

			<ul id=${TodoHooks.chatListId} class=${TodoHooks.chatListClass}>
				<for ${message in locals.messages}>
					<partial template=${(Template.of(ChatMessageView) : Template<ChatMessageLocals>)} locals=${{message: message}} />
				</for>
			</ul>

			<if ${locals.messages.length == 0}>
				<div class="empty-state">No room notes yet. The standup is suspiciously quiet.</div>
			</if>

			<form_with url=${Routes.chatMessagesPath()} scope=${ChatMessage.railsParamKey} local class=${TodoHooks.chatFormClass} data-railshx-chat-form>
				<div>
					<field_label name=${ChatMessage.f.body}>Add a typed room note</field_label>
					<text_area name=${ChatMessage.f.body} placeholder="Share what changed, what blocked, or what shipped" rows=${3} required />
				</div>
				<submit type="submit">Post note</submit>
			</form_with>
		</section>;
	}
}
