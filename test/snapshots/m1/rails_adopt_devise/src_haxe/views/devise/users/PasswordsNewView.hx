package views.devise.users;

import app.auth.UserAuth;
import devisehx.hhx.AuthLinks;
import devisehx.hhx.DeviseErrors;
import devisehx.hhx.DeviseFormFields;
import models.User;
import rails.action_view.HtmlNode;

typedef PasswordsNewLocals = {
	var resource:User;
}

// Generated DeviseHx HHX password reset request view skeleton.
// Recoverable remains Devise-owned at runtime; this view only gives Haxe
// authors typed route helpers, typed field refs, typed resource errors, and HHX source.

@:railsTemplate("devise/passwords/new")
@:railsTemplateAst("render")
class PasswordsNewView {
	public static function render(locals:PasswordsNewLocals):HtmlNode {
		return <main class="devisehx-auth-shell">
			<section class="devisehx-auth-card">
				<span class="eyebrow">DeviseHx password reset</span>
				<h1>Reset your password</h1>
				<p>Devise sends reset instructions; RailsHx keeps the form action and errors typed.</p>
				<if ${DeviseErrors.hasAny(locals.resource)}>
					<section class="devisehx-errors" aria-label="Password reset errors">
						<ul>
							<for ${message in DeviseErrors.fullMessages(locals.resource)}>
								<li>${message}</li>
							</for>
						</ul>
					</section>
				</if>
				<form_with url=${AuthLinks.passwordPath(UserAuth.scope)} scope="user" local class="devisehx-auth-form">
					<div>
						<field_label name=${DeviseFormFields.email}>Email</field_label>
						<email_field name=${DeviseFormFields.email} autocomplete="email" required />
					</div>
					<submit type="submit">Send reset instructions</submit>
				</form_with>
				<link_to url=${AuthLinks.signInPath(UserAuth.scope)} class="devisehx-secondary-link">Back to sign in</link_to>
			</section>
		</main>;
	}
}
