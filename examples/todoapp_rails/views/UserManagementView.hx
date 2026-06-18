package views;

import controllers.UsersController.UserIndexLocals;
import rails.action_view.HtmlNode;
import routes.Routes;

// Typed user management page.
//
// Demonstrates: a second full HHX page that consumes the same typed `User`
// contracts as the todo dashboard and links back through typed route helpers.
// Type safety: `UserIndexLocals` drives nullable current-user handling and the
// `users:Array<User>` loop; role/email/name are checked model fields.
// IntelliSense: editors should complete user fields and `Routes.todosPath`.
// Ruby/Rails output: `controllers/users/index.html.erb` rendered by Rails.
@:railsTemplate("controllers/users/index")
@:railsTemplateAst("render")
class UserManagementView {
	public static function render(locals:UserIndexLocals):HtmlNode {
		return <main class="todo-shell users-shell">
			<section class="card users-page-hero">
				<span class="eyebrow">RailsHx user management</span>
				<h1>Typed users, ordinary Rails output.</h1>
				<p>
					This page is intentionally small: it shows how RailsHx can add typed
					controllers/views around a user model while still generating plain Ruby
					and ERB that a Rails app can own or adopt later.
				</p>
				<link_to url=${Routes.todosPath()} class="typed-route-link">
					<span>Back to todo board</span>
				</link_to>
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
		</main>;
	}
}
