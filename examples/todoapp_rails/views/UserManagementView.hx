package views;

import controllers.UsersController.UserIndexLocals;
import rails.action_view.HtmlNode;
import routes.Routes;
import shared.TodoHooks;

// Typed user management page.
//
// Demonstrates: a second HHX page that can render both as a full Rails page and
// as the matching response body for the todo board's `<turbo_frame>`.
// Type safety: `UserIndexLocals` drives nullable current-user handling and the
// `users:Array<User>` loop; role/email/name are checked model fields; the frame
// id comes from the same `TodoHooks.userFrameId` contract used by the caller.
// IntelliSense: editors should complete user fields, `TodoHooks.userFrameId`,
// and `Routes.todosPath`.
// Helper ergonomics: this uses the simple HHX `<link_to text="...">` form,
// which lowers to Rails' non-block `link_to "Back to todo board", ...`.
// Ruby/Rails output: `controllers/users/index.html.erb` containing a normal
// `<turbo-frame id="railshx-user-frame">` that Turbo can extract.
@:railsTemplate("controllers/users/index")
@:railsTemplateAst("render")
class UserManagementView {
	public static function render(locals:UserIndexLocals):HtmlNode {
		return <main class="todo-shell users-shell">
			<turbo_frame id=${TodoHooks.userFrameId} class=${TodoHooks.userFrameClass}>
				<section class="card users-page-hero">
					<span class="eyebrow">RailsHx user management</span>
					<h1>Typed users, ordinary Rails output.</h1>
					<p>
						This page is intentionally small: it shows how RailsHx can add typed
						controllers/views around a user model while still generating plain Ruby
						and ERB that a Rails app can own or adopt later.
					</p>
					<link_to url=${Routes.todosPath()} text="Back to todo board" class="typed-route-link" data-turbo-frame="_top" />
				</section>
				<section class="user-grid">
					<for ${user in locals.users}>
						<article class=${locals.currentUser != null && locals.currentUser.id == user.id ? "user-management-card is-current" : "user-management-card"}>
							<span class="avatar">${user.initials()}</span>
							<div>
								<h2>${user.name}</h2>
								<p>${user.email}</p>
								<span class="role-pill">${user.roleLabel()}</span>
							</div>
						</article>
					</for>
				</section>
			</turbo_frame>
		</main>;
	}
}
