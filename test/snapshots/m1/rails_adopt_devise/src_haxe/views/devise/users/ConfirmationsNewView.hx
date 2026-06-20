package views.devise.users;

import app.auth.UserAuth;
import devisehx.hhx.AuthLinks;
import devisehx.hhx.DeviseErrors;
import models.User;
import rails.action_view.HtmlNode;

typedef ConfirmationsNewLocals = {
	var resource:User;
}

// Generated DeviseHx HHX confirmation request view skeleton.
// Confirmable remains Devise-owned at runtime; RailsHx owns the checked
// HHX source, typed Devise route helper, and typed resource error block.
@:railsTemplate("devise/confirmations/new")
@:railsTemplateAst("render")
class ConfirmationsNewView {
	public static function render(locals:ConfirmationsNewLocals):HtmlNode {
		return <main class="devisehx-auth-shell">
			<section class="devisehx-auth-card">
				<span class="eyebrow">DeviseHx confirmation</span>
				<h1>Resend confirmation instructions</h1>
				<p>Devise owns confirmation tokens; RailsHx keeps this request form typed.</p>
				<if ${DeviseErrors.hasAny(locals.resource)}>
					<section class="devisehx-errors" aria-label="Confirmation errors">
						<ul>
							<for ${message in DeviseErrors.fullMessages(locals.resource)}>
								<li>${message}</li>
							</for>
						</ul>
					</section>
				</if>
				<form_with url=${AuthLinks.confirmationPath(UserAuth.scope)} scope="user" local class="devisehx-auth-form">
					<div>
						<field_label name="email">Email</field_label>
						<text_field name="email" type="email" autocomplete="email" required />
					</div>
					<submit type="submit">Resend confirmation</submit>
				</form_with>
				<devise_sign_in_link scope=${UserAuth.scope} class="devisehx-secondary-link">Back to sign in</devise_sign_in_link>
			</section>
		</main>;
	}
}
