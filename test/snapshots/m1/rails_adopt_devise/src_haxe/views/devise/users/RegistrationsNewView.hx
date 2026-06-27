package views.devise.users;

import app.auth.UserAuth;
import devisehx.hhx.AuthLinks;
import devisehx.hhx.DeviseErrors;
import devisehx.hhx.DeviseFormFields;
import models.User;
import rails.action_view.HtmlNode;

typedef RegistrationsNewLocals = {
	var resource:User;
}

// Generated DeviseHx HHX registration view skeleton.
// The compiler checks that DeviseErrors receives a DeviseResource<User>
// and DeviseFormFields emits Rails' expected snake_case form keys.
@:railsTemplate("devise/registrations/new")
@:railsTemplateAst("render")
class RegistrationsNewView {
	public static function render(locals:RegistrationsNewLocals):HtmlNode {
		return <main class="devisehx-auth-shell">
			<section class="devisehx-auth-card">
				<span class="eyebrow">DeviseHx registration</span>
				<h1>Create your account</h1>
				<if ${DeviseErrors.hasAny(locals.resource)}>
					<section class="devisehx-errors" aria-label="Registration errors">
						<strong>${DeviseErrors.count(locals.resource)}</strong>
						<ul>
							<for ${message in DeviseErrors.fullMessages(locals.resource)}>
								<li>${message}</li>
							</for>
						</ul>
					</section>
				</if>
				<form_with url=${AuthLinks.registrationPath(UserAuth.scope)} scope="user" local class="devisehx-auth-form">
					<div>
						<field_label name=${DeviseFormFields.email}>Email</field_label>
						<email_field name=${DeviseFormFields.email} autocomplete="email" required />
					</div>
					<div>
						<field_label name=${DeviseFormFields.password}>Password</field_label>
						<password_field name=${DeviseFormFields.password} autocomplete="new-password" required />
					</div>
					<div>
						<field_label name=${DeviseFormFields.passwordConfirmation}>Confirm password</field_label>
						<password_field name=${DeviseFormFields.passwordConfirmation} autocomplete="new-password" required />
					</div>
					<submit type="submit">Create account</submit>
				</form_with>
				<devise_sign_in_link scope=${UserAuth.scope} class="devisehx-secondary-link">Already have an account?</devise_sign_in_link>
			</section>
		</main>;
	}
}
