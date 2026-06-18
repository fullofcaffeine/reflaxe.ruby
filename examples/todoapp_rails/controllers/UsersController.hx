package controllers;

import models.User;
import rails.action_view.Template;
import rails.macros.ViewMacro;
import views.ApplicationLayoutView;
import views.UserManagementView;

typedef UserIndexLocals = {
	var users:Array<User>;
	var currentUser:Null<User>;
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
	static final lifecycle = [];

	public function index() {
		var users = User.order(User.f.name.asc()).toArray();
		ViewMacro.renderTemplateWithLayout(this, (Template.of(UserManagementView) : Template<UserIndexLocals>), {
			users: users,
			currentUser: UserSession.currentUser(this)
		}, Template.layout(ApplicationLayoutView));
	}
}
