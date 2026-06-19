package controllers;

import app.auth.UserAuth;
import models.User;
import rails.action_controller.Status;
import rails.action_view.Template;
import rails.macros.ControllerDsl.beforeAction;
import rails.macros.ParamsMacro;
import rails.macros.ViewMacro;
import routes.Routes;
import views.ApplicationLayoutView;
import views.UserManagementView;

typedef UserIndexLocals = {
	var users:Array<User>;
	var currentUser:User;
}

// Typed user management controller.
//
// Demonstrates: a second RailsHx controller/view route in the todoapp, still
// rendered through typed locals and HHX.
// Type safety: `User.f.name.asc()` keeps ordering tied to the typed model field,
// and `Template.of(UserManagementView) : Template<UserIndexLocals>` checks the
// rendered locals object.
// IntelliSense: editors should complete `User.f.*`, relation chains, and
// `UserIndexLocals` fields.
// Ruby/Rails output: a normal Rails controller rendering a generated ERB view.

@:railsController
class UsersController extends rails.action_controller.Base {
	static final lifecycle = {
		beforeAction(UserAuth.authenticate, {});
	};

	public function index() {
		var currentUser = requireAdmin();
		if (currentUser == null) {
			return;
		}
		var users = User.order(User.f.name.asc()).toArray();
		ViewMacro.renderTemplateWithLayout(this, (Template.of(UserManagementView) : Template<UserIndexLocals>), {
			users: users,
			currentUser: currentUser
		}, Template.layout(ApplicationLayoutView));
	}

	public function create() {
		var currentUser = requireAdmin();
		if (currentUser == null) {
			return;
		}
		var attrs = ParamsMacro.requirePermit(this.params(), User.railsParamKey, [User.f.name, User.f.email, User.f.role, "password", "passwordConfirmation"]);
		User.create(attrs);
		this.flash.notice("User created");
		redirectToLocation(Routes.usersPath(), {status: Status.seeOther});
	}

	public function update() {
		var currentUser = requireAdmin();
		if (currentUser == null) {
			return;
		}
		var attrs = ParamsMacro.requirePermit(this.params(), User.railsParamKey, [User.f.name, User.f.email, User.f.role]);
		var user = User.find(paramId());
		user.update(attrs);
		this.flash.notice("User updated");
		redirectToLocation(Routes.usersPath(), {status: Status.seeOther});
	}

	public function destroy() {
		var currentUser = requireAdmin();
		if (currentUser == null) {
			return;
		}
		var user = User.find(paramId());
		if (user.id == currentUser.id) {
			this.flash.alert("Admins cannot delete their own active session");
		} else {
			user.destroy();
			this.flash.notice("User removed");
		}
		redirectToLocation(Routes.usersPath(), {status: Status.seeOther});
	}

	function requireAdmin():Null<User> {
		var currentUser = UserAuth.currentRequired(this);
		if (currentUser.canManageUsers()) {
			return currentUser;
		}
		this.flash.alert("Admin access is required for user management");
		redirectToLocation(Routes.todosPath(), {status: Status.seeOther});
		return null;
	}

	function paramId():Int {
		var raw = this.params().get("id");
		var parsed = raw == null ? null : Std.parseInt(raw);
		return parsed == null ? 0 : parsed;
	}
}
