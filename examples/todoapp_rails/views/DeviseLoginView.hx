package views;

import rails.action_view.FlashMessages;
import app.auth.UserAuth;
import devisehx.hhx.AuthLinks;
import devisehx.hhx.DeviseFormFields;
import rails.action_view.HtmlNode;
import routes.Routes;
import shared.TodoHooks;

// Devise session page authored as typed Rails HHX.
//
// Demonstrates: Devise still owns the sessions controller and Warden runtime,
// while RailsHx owns the generated login template. The form posts to Devise's
// real `user_session_path`; the guest CTA posts to the Haxe-owned guest action
// that calls typed `UserAuth.signIn`.
// Type safety: `AuthLinks.sessionPath(UserAuth.scope)` validates the generated
// Devise scope before emitting Rails' ordinary `user_session_path`;
// `Routes.guestSignInPath` is generated from Rails route output;
// `DeviseFormFields.email/password` lower to Rails' expected Devise form keys;
// `FlashMessages` reads Devise's normal Rails flash without authoring raw ERB;
// `TodoHooks.sessionAttr` lets the Haxe client bind the same Turbo form
// feedback as the board logout.
// IntelliSense: editors should complete route helpers, HHX form tags such as
// `email_field`, and shared hook constants.
// Ruby/Rails output: `app/views/devise/sessions/new.html.erb`, consumed by
// Devise's ordinary SessionsController.
@:railsTemplate("devise/sessions/new")
@:railsTemplateAst("render")
class DeviseLoginView {
	public static function render():HtmlNode {
		return <main class="login-shell">
			<section class="login-hero card">
				<div class="login-copy">
					<span class="eyebrow">DeviseHx session</span>
					<h1>Sign in to the typed Rails board.</h1>
					<p>
						Devise owns Warden, password verification, sessions, and redirects.
						RailsHx owns the typed route helpers, HHX template, and guest flow
						that make the happy path pleasant to author.
					</p>
				</div>
				<div class="credential-card">
					<span>Seeded demo</span>
					<strong>owner@example.test</strong>
					<em>password123</em>
				</div>
			</section>

			<section class="login-panel card" aria-label="Login">
				<div>
					<span class="eyebrow">Rails-native login</span>
					<h2>Welcome back.</h2>
					<p>Use seeded credentials or enter through the guest workspace.</p>
				</div>
				<if ${FlashMessages.hasMessage()}>
					<div class=${"login-flash is-" + FlashMessages.kind()} role="alert" aria-live="assertive">
						<span>Session message</span>
						<p>${FlashMessages.message()}</p>
					</div>
				</if>
				<form_with url=${AuthLinks.sessionPath(UserAuth.scope)} scope="user" local class="login-form" data-railshx-session>
					<div>
						<field_label name=${DeviseFormFields.email}>Email</field_label>
						<email_field name=${DeviseFormFields.email} autocomplete="email" placeholder="owner@example.test" autofocus required />
					</div>
					<div>
						<field_label name=${DeviseFormFields.password}>Password</field_label>
						<password_field name=${DeviseFormFields.password} autocomplete="current-password" placeholder="password123" required />
					</div>
					<submit type="submit">Log in</submit>
				</form_with>
				<div class="guest-entry">
					<span>Just touring?</span>
					<button_to url=${Routes.guestSignInPath()} method="post" class="auth-guest-form" data-railshx-session>
						Continue as guest
					</button_to>
				</div>
			</section>
		</main>;
	}
}
