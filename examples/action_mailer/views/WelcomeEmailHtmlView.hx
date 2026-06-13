package views;

import rails.action_view.HtmlNode;
import views.WelcomeEmailView.WelcomeEmailLocals;

// HTML mailer template authored as Rails HHX.
//
// Demonstrates: email HTML authored in Haxe inline markup and lowered to
// Rails ERB. Embedded `${locals.*}` expressions are normal typed Haxe field
// reads, so renaming or omitting a local fails before Rails renders mail.
@:railsTemplate("mailers/user_mailer/welcome")
@:railsTemplateAst("render")
class WelcomeEmailHtmlView {
	public static function render(locals:WelcomeEmailLocals):HtmlNode {
		return <section class="email-shell">
			<p>Hello ${locals.name},</p>
			<h1>${locals.productName} mailers are typed.</h1>
			<p>${locals.message}</p>
		</section>;
	}
}
