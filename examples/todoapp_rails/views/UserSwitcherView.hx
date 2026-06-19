package views;

import models.User;
import rails.action_view.HtmlNode;
import routes.Routes;
import shared.TodoHooks;

typedef UserSwitcherLocals = {
	var users:Array<User>;
	var currentUser:Null<User>;
}

// Typed DeviseHx auth/user panel partial.
//
// Demonstrates: Devise-owned login/logout routes plus a Haxe-owned guest
// sign-in action. The "Manage users" link still loads `/users` into a Turbo
// Frame, proving DeviseHx can compose with ordinary Hotwire navigation.
// Type safety: `currentUser` is nullable, `TodoHooks.userFrameId` keeps the
// frame target shared with the users page, and `Routes.*` helpers are generated
// typed externs from actual Rails routes.
// IntelliSense: editors should complete `users`, `currentUser`, `user.roleLabel`,
// `TodoHooks.userFrameId`, and Devise route helpers such as
// `newUserSessionPath`/`destroyUserSessionPath`.
// Ruby/Rails output: normal Rails `link_to`, `button_to`, `turbo-frame`, and
// ERB loops; Devise owns session persistence.
@:railsTemplate("controllers/todos/_user_switcher")
@:railsTemplateAst("render")
class UserSwitcherView {
	public static function render(locals:UserSwitcherLocals):HtmlNode {
		return <section id=${TodoHooks.sessionPanelId} class="team-console card auth-console" aria-label="RailsHx DeviseHx auth demo">
			<div class="team-console-copy">
				<span class="eyebrow">DeviseHx auth layer</span>
				<h2>Typed auth, Rails-owned sessions.</h2>
				<p>
					Devise owns Warden, passwords, routes, and sessions. Haxe owns the
					typed scope contract, auth filter, current-user helper, guest flow,
					and HHX composition around it.
				</p>
				<link_to url=${Routes.usersPath()} class="typed-route-link team-route-link" data-turbo-frame=${TodoHooks.userFrameId}>
					<span>Manage users</span>
				</link_to>
			</div>
			<div class="team-members auth-members" data-railshx-session-zone>
				<if ${locals.currentUser == null}>
					<div class="person-card auth-card">
						<span class="avatar">?</span>
						<span class="person-copy">
							<strong>Guest gate</strong>
							<span>Use Devise login or enter as a seeded guest.</span>
						</span>
						<span class="role-pill">Public</span>
					</div>
				<else>
					<div class="person-card is-current auth-card">
						<span class="avatar">${locals.currentUser.initials()}</span>
						<span class="person-copy">
							<strong>${locals.currentUser.name}</strong>
							<span>${locals.currentUser.email}</span>
						</span>
						<span class="role-pill">${locals.currentUser.roleLabel()}</span>
					</div>
				</if>
			</div>
			<div class=${TodoHooks.sessionFooterClass}>
				<span>
					Auth state:
					<strong>${locals.currentUser == null ? "signed out" : "signed in as " + locals.currentUser.name}</strong>
				</span>
				<if ${locals.currentUser == null}>
					<link_to url=${Routes.newUserSessionPath()} class="typed-route-link auth-link">
						<span>Open Devise login</span>
					</link_to>
					<button_to url=${Routes.guestSignInPath()} method="post" class="session-clear-form auth-guest-form" data-railshx-session>
						Continue as guest
					</button_to>
				<else>
					<button_to url=${Routes.destroyUserSessionPath()} method="delete" class="session-clear-form" data-railshx-session>
						Sign out
					</button_to>
				</if>
			</div>
			<turbo_frame id=${TodoHooks.userFrameId} class=${TodoHooks.userFrameClass}>
				<div class="user-frame-placeholder">
					<strong>Turbo Frame ready.</strong>
					<span>Open typed user management without leaving the board.</span>
					<button_to url=${Routes.usersPath()} method="get" class="typed-route-link">
						<span>Open in frame</span>
					</button_to>
				</div>
			</turbo_frame>
		</section>;
	}
}
