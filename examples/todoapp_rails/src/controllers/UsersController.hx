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
	var formUser:User;
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
class UsersController extends ApplicationController {
	static final lifecycle = {
		beforeAction(UserAuth.authenticate, {});
	};

	public function index() {
		var currentUser = requireAdmin();
		if (currentUser == null) {
			return;
		}
		renderIndex(currentUser, User.build({role: "member"}));
	}

	public function create() {
		var currentUser = requireAdmin();
		if (currentUser == null) {
			return;
		}
		var attrs = ParamsMacro.requirePermit(this.params(), User.railsParamKey, [User.f.name, User.f.email, User.f.role, "password", "password_confirmation"]);
		var user = User.create(attrs);
		if (!user.persisted()) {
			this.flash.alertNow("Could not save user. Review the highlighted details and try again.");
			renderIndexUnprocessable(currentUser, user);
			return;
		}
		this.flash.notice("User saved");
		redirectToLocation(Routes.usersPath(), {status: Status.seeOther});
	}

	public function update() {
		var currentUser = requireAdmin();
		if (currentUser == null) {
			return;
		}
		var attrs = ParamsMacro.requirePermit(this.params(), User.railsParamKey, [User.f.name, User.f.email, User.f.role]);
		var user = User.find(paramId());
		if (!user.update(attrs)) {
			this.flash.alertNow("Could not update user. Review the details and try again.");
			renderIndexUnprocessable(currentUser, User.build({role: "member"}));
			return;
		}
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

	function renderIndex(currentUser:User, formUser:User):Void {
		var users = User.order(User.f.name.asc()).toArray();
		ViewMacro.renderTemplateWithLayout(this, (Template.of(UserManagementView) : Template<UserIndexLocals>), {
			users: users,
			currentUser: currentUser,
			formUser: formUser
		}, Template.layout(ApplicationLayoutView));
	}

	function renderIndexUnprocessable(currentUser:User, formUser:User):Void {
		var users = User.order(User.f.name.asc()).toArray();
		ViewMacro.renderTemplateWithLayoutStatus(this, (Template.of(UserManagementView) : Template<UserIndexLocals>), {
			users: users,
			currentUser: currentUser,
			formUser: formUser
		}, Template.layout(ApplicationLayoutView), Status.unprocessableEntity);
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
