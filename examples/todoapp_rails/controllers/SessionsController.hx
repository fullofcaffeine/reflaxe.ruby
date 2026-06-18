package controllers;

import models.User;
import rails.action_controller.Status;
import rails.action_view.Template;
import rails.macros.ParamsMacro;
import rails.turbo.StreamTarget;
import rails.turbo.TurboStreams;
import routes.Routes;
import shared.TodoHooks;
import views.UserSwitcherView;
import views.UserSwitcherView.UserSwitcherLocals;

// Demo session controller.
//
// Demonstrates: first-party Rails session usage from typed Haxe. This is not a
// Devise replacement; it is a small dogfood seam for controller stores,
// params, redirects, and Turbo-friendly form submissions.
// Type safety: `User.f.id` drives strong params, `Params.get("id")` lowers to
// Rails `params[:id]`, and `Routes.todosPath()` is a typed route extern.
// IntelliSense: editors should complete `User.f.id`, `session/flash` helpers,
// and route helpers.
// Ruby/Rails output: ordinary Rails controller actions using `session`,
// `flash`, `find`, and `redirect_to`.
@:railsController
class SessionsController extends rails.action_controller.Base {
	static final lifecycle = [];

	public function create() {
		var userParams = this.params().requireParam(User.railsParamKey);
		ParamsMacro.requirePermit(this.params(), User.railsParamKey, [User.f.id]);
		var user = User.find(cast userParams.get("id"));
		this.session().set(UserSession.currentUserIdKey, user.id);
		this.flash().set("notice", "Signed in as " + user.name);
		respondTo(function(format) {
			format.turboStream(function() {
				render({
					turboStream: TurboStreams.replace(StreamTarget.named(TodoHooks.sessionPanelId),
						(Template.of(UserSwitcherView) : Template<UserSwitcherLocals>), {
							users: User.order(User.f.name.asc()).toArray(),
							currentUser: user
						})
				});
			});
			format.html(function() {
				redirectToLocation(Routes.todosPath(), {status: Status.seeOther});
			});
		});
	}

	public function destroy() {
		this.session().delete(UserSession.currentUserIdKey);
		this.flash().set("notice", "Session cleared");
		respondTo(function(format) {
			format.turboStream(function() {
				render({
					turboStream: TurboStreams.replace(StreamTarget.named(TodoHooks.sessionPanelId),
						(Template.of(UserSwitcherView) : Template<UserSwitcherLocals>), {
							users: User.order(User.f.name.asc()).toArray(),
							currentUser: null
						})
				});
			});
			format.html(function() {
				redirectToLocation(Routes.todosPath(), {status: Status.seeOther});
			});
		});
	}
}
