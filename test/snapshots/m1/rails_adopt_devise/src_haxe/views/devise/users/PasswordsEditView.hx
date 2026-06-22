package views.devise.users;

import app.auth.UserAuth;
import devisehx.hhx.AuthLinks;
import devisehx.hhx.DeviseErrors;
import devisehx.hhx.DeviseFormFields;
import models.User;
import rails.action_view.HtmlNode;

typedef PasswordsEditLocals = {
	var resource:User;
}

// Generated DeviseHx HHX password edit view skeleton.
// The typed `locals.resource.resetPasswordToken` value comes from the
// recoverable schema column and lowers to Devise's conventional
// `reset_password_token` hidden form key in the generated Rails ERB.
@:railsTemplate("devise/passwords/edit")
@:railsTemplateAst("render")
class PasswordsEditView {
	public static function render(locals:PasswordsEditLocals):HtmlNode {
		return <main class="devisehx-auth-shell">
			<section class="devisehx-auth-card">
				<span class="eyebrow">DeviseHx password reset</span>
				<h1>Choose a new password</h1>
				<if ${DeviseErrors.hasAny(locals.resource)}>
					<section class="devisehx-errors" aria-label="Password update errors">
						<strong>${DeviseErrors.count(locals.resource)}</strong>
						<ul>
							<for ${message in DeviseErrors.fullMessages(locals.resource)}>
								<li>${message}</li>
							</for>
						</ul>
					</section>
				</if>
				<form_with url=${AuthLinks.passwordPath(UserAuth.scope)} scope="user" method="patch" local class="devisehx-auth-form">
					<hidden_field name=${DeviseFormFields.resetPasswordToken} value=${locals.resource.resetPasswordToken} />
					<div>
						<field_label name=${DeviseFormFields.password}>New password</field_label>
						<password_field name=${DeviseFormFields.password} autocomplete="new-password" required />
					</div>
					<div>
						<field_label name=${DeviseFormFields.passwordConfirmation}>Confirm new password</field_label>
						<password_field name=${DeviseFormFields.passwordConfirmation} autocomplete="new-password" required />
					</div>
					<submit type="submit">Change password</submit>
				</form_with>
			</section>
		</main>;
	}
}
