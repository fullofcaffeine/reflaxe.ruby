package views.devise.users;

import app.auth.UserAuth;
import devisehx.hhx.AuthLinks;
import models.User;
import rails.action_view.FlashMessages;
import rails.action_view.HtmlNode;

typedef SessionsNewLocals = {
	var resource:User;
}

// Generated DeviseHx HHX session view skeleton.
// Devise/Rails still owns authentication runtime behavior; this Haxe file
// owns the typed template source and compiles to app/views/devise/sessions/new.html.erb.
// Type safety: AuthLinks.sessionPath validates UserAuth.scope metadata and
// FlashMessages reads ordinary Rails flash without authoring raw ERB.
@:railsTemplate("devise/sessions/new")
@:railsTemplateAst("render")
class SessionsNewView {
	public static function render(locals:SessionsNewLocals):HtmlNode {
		return <main class="devisehx-auth-shell">
			<section class="devisehx-auth-card">
				<span class="eyebrow">DeviseHx session</span>
				<h1>Sign in</h1>
				<p>Devise owns Warden and password verification; RailsHx owns this typed HHX source.</p>
				<if ${FlashMessages.hasMessage()}>
					<div class=${"devisehx-flash is-" + FlashMessages.kind()} role="alert">
						${FlashMessages.message()}
					</div>
				</if>
				<form_with url=${AuthLinks.sessionPath(UserAuth.scope)} scope="user" local class="devisehx-auth-form">
					<div>
						<field_label name="email">Email</field_label>
						<text_field name="email" type="email" autocomplete="email" required />
					</div>
					<div>
						<field_label name="password">Password</field_label>
						<password_field name="password" autocomplete="current-password" required />
					</div>
					<submit type="submit">Sign in</submit>
				</form_with>
				<devise_sign_up_link scope=${UserAuth.scope} class="devisehx-secondary-link">Create an account</devise_sign_up_link>
			</section>
		</main>;
	}
}
