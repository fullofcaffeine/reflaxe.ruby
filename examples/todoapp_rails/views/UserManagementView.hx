package views;

import controllers.UsersController.UserIndexLocals;
import devisehx.hhx.DeviseFormFields;
import models.User;
import rails.action_view.HtmlNode;
import routes.Routes;
import shared.TodoHooks;

// Typed user management page.
//
// Demonstrates: a second HHX page that can render both as a full Rails page and
// as the matching response body for the todo board's `<turbo_frame>`.
// Type safety: `UserIndexLocals` carries an admin `currentUser` and the
// `users:Array<User>` loop; CRUD forms use `User.railsParamKey`, `User.f.*`,
// DeviseFormFields for transient password params, and `Routes.userPath(user.id)`
// instead of hand-written Rails names.
// IntelliSense: editors should complete user fields, `TodoHooks.userFrameId`,
// `Routes.userPath`, and Rails HHX form tags.
// Ruby/Rails output: `controllers/users/index.html.erb` containing a normal
// `<turbo-frame id="railshx-user-frame">` and resourceful `form_with` output
// that Turbo can extract into the todo board.
@:railsTemplate("controllers/users/index")
@:railsTemplateAst("render")
class UserManagementView {
	public static function render(locals:UserIndexLocals):HtmlNode {
		return <main class="users-shell">
			<turbo_frame id=${TodoHooks.userFrameId} class=${TodoHooks.userFrameClass}>
				<div class="users-admin-board">
					<section class="users-page-hero">
						<div>
							<span class="eyebrow">Admin-only RailsHx user management</span>
							<h1>Typed users, ordinary Rails CRUD.</h1>
							<p>
								Only admins can reach this panel. The forms are HHX-authored, params
								are derived from typed model fields, and Rails receives normal
								resourceful controller actions.
							</p>
						</div>
						<link_to url=${Routes.todosPath()} text="Back to todo board" class="typed-route-link" data-turbo-frame="_top" />
					</section>

					<section class="user-create-card" aria-label="Create a user">
						<div>
							<span class="eyebrow">Create user</span>
							<h2>Invite a typed teammate.</h2>
							<p>Use a real Devise password here; the generated Rails controller permits those extra auth keys explicitly.</p>
						</div>
						<form_with url=${Routes.usersPath()} scope=${User.railsParamKey} local class="user-create-form">
							<div>
								<field_label name=${User.f.name}>Name</field_label>
								<text_field name=${User.f.name} placeholder="Ada Lovelace" required />
							</div>
							<div>
								<field_label name=${User.f.email}>Email</field_label>
								<text_field name=${User.f.email} placeholder="ada@example.test" required />
							</div>
							<div>
								<field_label name=${User.f.role}>Role</field_label>
								<text_field name=${User.f.role} placeholder="member" value="member" required />
							</div>
							<div>
								<field_label name=${DeviseFormFields.password}>Password</field_label>
								<password_field name=${DeviseFormFields.password} placeholder="password123" required />
							</div>
							<div>
								<field_label name=${DeviseFormFields.passwordConfirmation}>Confirm password</field_label>
								<password_field name=${DeviseFormFields.passwordConfirmation} placeholder="password123" required />
							</div>
							<submit type="submit">Create user</submit>
						</form_with>
					</section>

					<section class="user-grid" aria-label="Manage users">
						<for ${user in locals.users}>
							<article class=${locals.currentUser.id == user.id ? "user-management-card is-current" : "user-management-card"}>
								<header class="user-card-heading">
									<span class="avatar">${user.initials()}</span>
									<div>
										<h2>${user.name}</h2>
										<p>${user.email}</p>
									</div>
									<span class="role-pill">${user.roleLabel()}</span>
								</header>
								<form_with url=${Routes.userPath(user.id)} scope=${User.railsParamKey} method="patch" local class="user-card-form">
									<div>
										<field_label name=${User.f.name} for=${"user_" + Std.string(user.id) + "_name"}>Name</field_label>
										<text_field name=${User.f.name} id=${"user_" + Std.string(user.id) + "_name"} value=${user.name} required />
									</div>
									<div>
										<field_label name=${User.f.email} for=${"user_" + Std.string(user.id) + "_email"}>Email</field_label>
										<text_field name=${User.f.email} id=${"user_" + Std.string(user.id) + "_email"} value=${user.email} required />
									</div>
									<div>
										<field_label name=${User.f.role} for=${"user_" + Std.string(user.id) + "_role"}>Role</field_label>
										<text_field name=${User.f.role} id=${"user_" + Std.string(user.id) + "_role"} value=${user.role} required />
									</div>
									<submit type="submit">Save user</submit>
								</form_with>
								<if ${locals.currentUser.id != user.id}>
									<form_with url=${Routes.userPath(user.id)} scope=${User.railsParamKey} method="delete" local class="user-delete-form">
										<submit type="submit">Remove user</submit>
									</form_with>
								</if>
							</article>
						</for>
					</section>
				</div>
			</turbo_frame>
		</main>;
	}
}
