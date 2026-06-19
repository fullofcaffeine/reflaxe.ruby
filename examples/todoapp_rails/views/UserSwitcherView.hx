package views;

import models.User;
import rails.action_view.HtmlNode;
import routes.Routes;
import shared.TodoHooks;

typedef UserSwitcherLocals = {
	var users:Array<User>;
	var currentUser:Null<User>;
}

// Typed session/user switcher partial.
//
// Demonstrates: Rails session forms plus standard Turbo Frame navigation
// targets authored as HHX. The "Manage users" link and placeholder button load
// `/users` into the frame through normal Turbo behavior; direct `/users` visits
// still render as a normal Rails page fallback. Sign-out uses the simple
// `button_to "Clear session", sign_out_path, method: :delete` Rails shape,
// while the frame placeholder uses Rails' block-form `button_to ... do` shape
// to prove nested HHX children lower to a normal ActionView helper block.
// Type safety: `User.f.id` powers the hidden field, `currentUser` is nullable,
// `TodoHooks.userFrameId` keeps the frame target shared with the users page, and
// `Routes.signInPath/signOutPath/usersPath` are generated route externs.
// IntelliSense: editors should complete `users`, `currentUser`, `user.roleLabel`,
// `User.f.id`, `TodoHooks.userFrameId`, and the route helpers.
// Ruby/Rails output: normal Rails `form_with`, `link_to`, simple/block
// `button_to`, `turbo-frame`, and ERB loops; no custom fetch or client-side
// user rendering is generated.
@:railsTemplate("controllers/todos/_user_switcher")
@:railsTemplateAst("render")
class UserSwitcherView {
	public static function render(locals:UserSwitcherLocals):HtmlNode {
		return <section id=${TodoHooks.sessionPanelId} class="team-console card" aria-label="RailsHx user session demo">
			<div class="team-console-copy">
				<span class="eyebrow">Typed session layer</span>
				<h2>Choose a demo user</h2>
				<p>
					This panel is first-party RailsHx: typed ActiveRecord users, checked
					session params, Rails flash/session stores, and Turbo-friendly forms.
				</p>
				<link_to url=${Routes.usersPath()} class="typed-route-link team-route-link" data-turbo-frame=${TodoHooks.userFrameId}>
					<span>Manage users</span>
				</link_to>
			</div>
			<div class="team-members" data-railshx-session-zone>
				<for ${user in locals.users}>
					<form_with url=${Routes.signInPath()} scope=${User.railsParamKey} local class=${TodoHooks.sessionFormClass} data-railshx-session>
						<hidden_field name=${User.f.id} value=${user.id} />
						<button type="submit" class=${locals.currentUser != null && locals.currentUser.id == user.id ? "person-card is-current" : "person-card"}>
							<span class="avatar">${user.initials()}</span>
							<span class="person-copy">
								<strong>${user.name}</strong>
								<span>${user.email}</span>
							</span>
							<span class="role-pill">${user.roleLabel()}</span>
						</button>
					</form_with>
				</for>
			</div>
			<div class=${TodoHooks.sessionFooterClass}>
				<span>
					Current user:
					<strong>${locals.currentUser == null ? "fallback owner" : locals.currentUser.name}</strong>
				</span>
				<button_to url=${Routes.signOutPath()} method="delete" class="session-clear-form" data-railshx-session>
					Clear session
				</button_to>
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
