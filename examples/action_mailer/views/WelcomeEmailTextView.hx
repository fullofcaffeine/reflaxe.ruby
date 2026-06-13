package views;

import rails.action_view.HtmlNode;
import views.WelcomeEmailView.WelcomeEmailLocals;

// Text mailer template authored through the same typed HHX AST.
//
// Demonstrates: text-compatible mail body generation while still using the
// Haxe template/locals type-checking path. The compiler emits a `.text.erb`
// Rails view because the template metadata includes that extension.
@:railsTemplate("mailers/user_mailer/welcome.text.erb")
@:railsTemplateAst("render")
class WelcomeEmailTextView {
	public static function render(locals:WelcomeEmailLocals):HtmlNode {
		return <>
			Hello ${locals.name},

			${locals.productName} mailers are typed.
			${locals.message}
		</>;
	}
}
