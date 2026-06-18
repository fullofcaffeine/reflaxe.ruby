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
// Demonstrates: a Rails session form authored as HHX, with typed model field
// refs for the submitted user id and centralized behavior hooks for Haxe JS.
// Type safety: `User.f.id` powers the hidden field, `currentUser` is nullable,
// and `Routes.signInPath/signOutPath/usersPath` are generated route externs.
// IntelliSense: editors should complete `users`, `currentUser`, `user.roleLabel`,
// `User.f.id`, and the route helpers.
// Ruby/Rails output: normal Rails `form_with`, `link_to`, and ERB loops.
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
				<link_to url=${Routes.usersPath()} class="typed-route-link team-route-link">
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
				<form_with url=${Routes.signOutPath()} scope="session" method="delete" local class="session-clear-form" data-railshx-session>
					<submit type="submit">Clear session</submit>
				</form_with>
			</div>
		</section>;
	}
}
