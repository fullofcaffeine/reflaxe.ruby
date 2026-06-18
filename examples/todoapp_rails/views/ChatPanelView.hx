package views;

import models.ChatMessage;
import models.User;
import rails.action_view.HtmlNode;
import routes.Routes;
import shared.TodoHooks;

typedef ChatPanelLocals = {
	var messages:Array<ChatMessage>;
	var currentUser:Null<User>;
	var users:Array<User>;
}

// Typed chat panel partial.
//
// Demonstrates: realtime-style Rails UX without a parallel runtime. The panel is
// authored as HHX, replaced through Turbo Streams, and still works with plain
// HTML redirects when JavaScript is unavailable.
// Type safety: chat form fields use `ChatMessage.f.*`; the submit user comes
// from a nullable typed `currentUser`; the loop body sees each message as a
// `ChatMessage` with typed fields.
// IntelliSense: editors should complete `locals.messages`, `message.body`,
// `message.userId`, `ChatMessage.f.body`, and `Routes.chatMessagesPath`.
// Ruby/Rails output: normal ERB with `form_with`, loops, conditionals, and Rails
// route helpers.
@:railsTemplate("controllers/todos/_chat_panel")
@:railsTemplateAst("render")
class ChatPanelView {
	public static function render(locals:ChatPanelLocals):HtmlNode {
		return <section id=${TodoHooks.chatPanelId} class="card chat-panel" data-railshx-chat aria-label="RailsHx typed chatroom">
			<div class="chat-panel-header">
				<span class="eyebrow">Typed Turbo room</span>
				<h2>Ship room</h2>
				<p>
					This is a Rails-native chat slice: Haxe owns the model, migration,
					controller, params, route, HHX, and client hooks; Rails receives
					ordinary ActiveRecord, ActionView, and Turbo Stream artifacts.
				</p>
			</div>

			<ul id=${TodoHooks.chatListId} class=${TodoHooks.chatListClass}>
				<for ${message in locals.messages}>
					<li class=${TodoHooks.chatMessageClass} data-railshx-chat-message-key=${message.id}>
						<span class="avatar">#</span>
						<div>
							<strong>User ${message.userId}</strong>
							<p>${message.body}</p>
						</div>
					</li>
				</for>
			</ul>

			<if ${locals.messages.length == 0}>
				<div class="empty-state">No room notes yet. The standup is suspiciously quiet.</div>
			</if>

			<if ${locals.currentUser != null}>
				<form_with url=${Routes.chatMessagesPath()} scope=${ChatMessage.railsParamKey} local class=${TodoHooks.chatFormClass} data-railshx-chat-form>
					<hidden_field name=${ChatMessage.f.userId} value=${locals.currentUser.id} />
					<div>
						<field_label name=${ChatMessage.f.body}>Add a typed room note</field_label>
						<text_area name=${ChatMessage.f.body} placeholder="Share what changed, what blocked, or what shipped" rows=${3} required />
					</div>
					<submit type="submit">Post note</submit>
				</form_with>
			<else>
				<div class="empty-state">Choose a user before posting a room note.</div>
			</if>
		</section>;
	}
}
