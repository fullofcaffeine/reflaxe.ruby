package views.devise.users;

import app.auth.UserAuth;
import devisehx.hhx.AuthLinks;
import devisehx.hhx.DeviseErrors;
import devisehx.hhx.DeviseFormFields;
import models.User;
import rails.action_view.HtmlNode;

typedef UnlocksNewLocals = {
	var resource:User;
}

// Generated DeviseHx HHX unlock request view skeleton.
// Lockable account state stays in Devise/Rails; this checked HHX view
// emits the ordinary `user_unlock_path` request form with typed field refs.

@:railsTemplate("devise/unlocks/new")
@:railsTemplateAst("render")
class UnlocksNewView {
	public static function render(locals:UnlocksNewLocals):HtmlNode {
		return <main class="devisehx-auth-shell">
			<section class="devisehx-auth-card">
				<span class="eyebrow">DeviseHx unlock</span>
				<h1>Resend unlock instructions</h1>
				<p>Devise owns lock/unlock semantics; RailsHx keeps the route and errors typed.</p>
				<if ${DeviseErrors.hasAny(locals.resource)}>
					<section class="devisehx-errors" aria-label="Unlock errors">
						<ul>
							<for ${message in DeviseErrors.fullMessages(locals.resource)}>
								<li>${message}</li>
							</for>
						</ul>
					</section>
				</if>
				<form_with url=${AuthLinks.unlockPath(UserAuth.scope)} scope="user" local class="devisehx-auth-form">
					<div>
						<field_label name=${DeviseFormFields.email}>Email</field_label>
						<email_field name=${DeviseFormFields.email} autocomplete="email" required />
					</div>
					<submit type="submit">Resend unlock instructions</submit>
				</form_with>
				<link_to url=${AuthLinks.signInPath(UserAuth.scope)} class="devisehx-secondary-link">Back to sign in</link_to>
			</section>
		</main>;
	}
}
