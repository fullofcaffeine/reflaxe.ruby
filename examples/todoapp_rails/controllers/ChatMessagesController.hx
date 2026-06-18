package controllers;

import channels.ChatMessagesChannel;
import models.ChatMessage;
import models.User;
import rails.action_controller.Status;
import rails.action_view.Template;
import rails.macros.ParamsMacro;
import rails.turbo.StreamTarget;
import rails.turbo.TurboStreams;
import routes.Routes;
import shared.TodoHooks;
import views.ChatPanelView;
import views.ChatPanelView.ChatPanelLocals;

// Typed chat controller.
//
// Demonstrates: a small Turbo-style mutation surface that stays Rails-native:
// typed strong params create an ActiveRecord row, Turbo requests replace a typed
// HHX partial, and HTML fallback redirects normally.
// Type safety: `ChatMessage.railsParamKey` scopes params, `ChatMessage.f.*`
// permits only real model fields, and `Template.of(ChatPanelView)` checks locals.
// IntelliSense: editors should complete chat field refs, route helpers, and
// Turbo stream helper types.
// Ruby/Rails output: an ordinary Rails controller with `respond_to`,
// `turbo_stream.replace`, and `redirect_to`.
@:railsController
class ChatMessagesController extends rails.action_controller.Base {
	static final lifecycle = [];

	public function create() {
		var attrs = ParamsMacro.requirePermit(this.params(), ChatMessage.railsParamKey, [ChatMessage.f.body, ChatMessage.f.userId]);
		var message = ChatMessage.create(attrs);
		ChatMessagesChannel.announce(message.id, message.body, message.userId);
		respondTo(function(format) {
			format.turboStream(function() {
				render({
					turboStream: TurboStreams.replace(StreamTarget.named(TodoHooks.chatPanelId), (Template.of(ChatPanelView) : Template<ChatPanelLocals>), {
						messages: ChatMessage.latest().toArray(),
						currentUser: UserSession.currentUser(this),
						users: User.order(User.f.name.asc()).toArray()
					})
				});
			});
			format.html(function() {
				redirectToLocation(Routes.todosPath(), {status: Status.seeOther});
			});
		});
	}
}
