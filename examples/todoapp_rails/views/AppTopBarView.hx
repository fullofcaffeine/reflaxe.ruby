package views;

import models.User;
import app.auth.UserAuth;
import devisehx.hhx.AuthLinks;
import rails.action_view.HtmlNode;
import routes.Routes;
import shared.TodoHooks;

typedef AppTopBarLocals = {
	var currentUser:User;
}

// Authenticated app top bar authored as Rails HHX.
//
// Demonstrates: the board no longer carries a login/demo panel. Devise owns the
// session; Haxe owns a typed `currentUser` local, typed route helpers, and a
// standard Rails `button_to` logout form.
// Type safety: `currentUser` is non-null because `TodosController` is protected
// by `UserAuth.authenticate`; `Routes.*` helpers are generated from Rails route
// output; `AuthLinks.signOutPath(UserAuth.scope)` validates the generated
// Devise scope before emitting Rails' ordinary `destroy_user_session_path`;
// `TodoHooks.userFrameId` keeps the users frame target centralized.
// IntelliSense: editors should complete `currentUser.initials`,
// `currentUser.roleLabel`, `UserAuth.scope`, `AuthLinks.signOutPath`, and
// `TodoHooks.userFrameId`.
// Ruby/Rails output: normal `link_to`, `button_to`, and HTML header markup.
@:railsTemplate("controllers/todos/_app_top_bar")
@:railsTemplateAst("render")
class AppTopBarView {
	public static function render(locals:AppTopBarLocals):HtmlNode {
		return <header class="app-topbar" aria-label="Todoapp session">
			<div class="brand-mark">
				<span class="brand-glyph">Hx</span>
				<span>
					<strong>RailsHx Todo</strong>
					<em>Devise session active</em>
				</span>
			</div>
			<nav class="topbar-actions" aria-label="Primary">
				<if ${locals.currentUser.canManageUsers()}>
					<link_to url=${Routes.usersPath()} class="typed-route-link topbar-link" data-turbo-frame=${TodoHooks.userFrameId}>
						<span>Users</span>
					</link_to>
				</if>
				<link_to url=${TodoHooks.openWorkHref} class="typed-route-link topbar-link" data-railshx-scroll>
					<span>Open work</span>
				</link_to>
			</nav>
			<div class="session-chip">
				<span class="avatar">${locals.currentUser.initials()}</span>
				<span class="session-copy">
					<strong>${locals.currentUser.name}</strong>
					<em>${locals.currentUser.roleLabel()} · ${locals.currentUser.email}</em>
				</span>
				<button_to url=${AuthLinks.signOutPath(UserAuth.scope)} method="delete" class="session-clear-form topbar-logout" data-railshx-session>
					Log out
				</button_to>
			</div>
		</header>;
	}
}
