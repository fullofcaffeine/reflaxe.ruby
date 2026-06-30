package controllers;

import app.auth.UserAuth;
import models.ChatMessage;
import models.User;
import rails.action_controller.Status;
import rails.action_view.Template;
import rails.macros.ControllerDsl.beforeAction;
import rails.macros.ParamsMacro;
import rails.turbo.StreamTarget;
import rails.turbo.TurboStreams;
import routes.Routes;
import shared.TodoHooks;
import views.ChatPanelView;
import views.ChatPanelView.ChatPanelLocals;
import views.ChatMessageView;
import views.ChatMessageView.ChatMessageLocals;

// Typed chat controller.
//
// Demonstrates: classic Hotwire mutation with typed RailsHx authoring. Typed
// strong params create an ActiveRecord row; Rails broadcasts a server-rendered
// HHX row partial through Turbo Streams; Turbo submitters receive `204 No
// Content` so the broadcast is the only DOM mutation; HTML fallback redirects
// normally.
// Type safety: `ChatMessage.railsParamKey` scopes params, `ChatMessage.f.*`
// permits only real model fields, and `Template.of(ChatPanelView)` checks locals.
// IntelliSense: editors should complete chat field refs, route helpers, and
// Turbo stream helper types.
// Ruby/Rails output: an ordinary Rails controller with `respond_to`,
// `Turbo::StreamsChannel.broadcast_prepend_to`, `head :no_content`, and
// `redirect_to`.
@:railsController
class ChatMessagesController extends ApplicationController {
	static final lifecycle = {
		beforeAction(UserAuth.authenticate, {});
	};

	public function index() {
		respondTo(function(format) {
			format.turboStream(function() {
				render({
					turboStream: TurboStreams.replace(StreamTarget.named(TodoHooks.chatPanelId), (Template.of(ChatPanelView) : Template<ChatPanelLocals>), {
						messages: ChatMessage.latest().toArray(),
						currentUser: UserAuth.currentRequired(this),
						users: User.order(User.f.name.asc()).toArray()
					})
				});
			});
			format.html(function() {
				redirectToLocation(Routes.todosPath(), {status: Status.seeOther});
			});
		});
	}

	public function create() {
		var currentUser = UserAuth.currentRequired(this);
		var attrs = ParamsMacro.requirePermit(this.params(), ChatMessage.railsParamKey, [ChatMessage.f.body]);
		attrs = ParamsMacro.mergeField(attrs, ChatMessage.f.userId, currentUser.id);
		var message = ChatMessage.create(attrs);
		TurboStreams.broadcastPrependTo(ChatMessageView.roomStream(), ChatMessageView.roomTarget(),
			(Template.of(ChatMessageView) : Template<ChatMessageLocals>), {
				message: message
			});
		respondTo(function(format) {
			format.turboStream(function() {
				head(Status.noContent);
			});
			format.html(function() {
				redirectToLocation(Routes.todosPath(), {status: Status.seeOther});
			});
		});
	}
}
