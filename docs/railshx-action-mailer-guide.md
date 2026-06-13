# RailsHx ActionMailer Guide

RailsHx mailers are Haxe-authored Rails mailers. The compiler emits ordinary
`ActionMailer::Base` subclasses and ordinary ERB templates under `app/views`;
HHX and macros are the typed authoring layer, not a replacement mail runtime.

## Mailer Classes

Annotate a Haxe class with `@:railsMailer` and extend
`rails.action_mailer.Base`:

```haxe
@:railsMailer
class UserMailer extends rails.action_mailer.Base {
	public function welcome(email:String, name:String, message:String):Void {
		var locals:WelcomeEmailLocals = {
			name: name,
			message: message,
			productName: "RailsHx"
		};

		MailerMacro.mailMultipart(this, {
			to: email,
			from: "team@example.test",
			subject: "Welcome to typed RailsHx mail"
		}, (Template.of(WelcomeEmailHtmlView) : Template<WelcomeEmailLocals>), locals,
			(Template.of(WelcomeEmailTextView) : Template<WelcomeEmailLocals>), locals);
	}
}
```

Generated Ruby stays Rails-shaped:

```ruby
class UserMailer < ActionMailer::Base
  def welcome(email, name, message)
    mail(to: email, from: "team@example.test", subject: "Welcome to typed RailsHx mail") do |format|
      format.html { render(template: "mailers/user_mailer/welcome", locals: {...}) }
      format.text { render(template: "mailers/user_mailer/welcome.text", locals: {...}) }
    end
  end
end
```

## Typed Templates

Mailer templates use the same Rails HHX path as ActionView:

```haxe
typedef WelcomeEmailLocals = {
	var name:String;
	var message:String;
	var productName:String;
}

@:railsTemplate("mailers/user_mailer/welcome")
@:railsTemplateAst("render")
class WelcomeEmailHtmlView {
	public static function render(locals:WelcomeEmailLocals):HtmlNode {
		return <section>
			<p>Hello ${locals.name},</p>
			<h1>${locals.productName} mailers are typed.</h1>
			<p>${locals.message}</p>
		</section>;
	}
}
```

`Template.of(ViewClass) : Template<Locals>` checks that the view class exists
and is annotated with `@:railsTemplate`. `MailerMacro.mailHtml`,
`MailerMacro.mailText`, and `MailerMacro.mailMultipart` check the locals value
against `Template<TLocals>` before Ruby is emitted, then lower Haxe camelCase
locals such as `productName` to Rails locals such as `product_name`.

## Runtime Strategy

`npm run test:action-mailer` is the fast compiler/static lane. It checks:

- `@:railsMailer` emits an `ActionMailer::Base` subclass.
- `mail(...)` object literals lower to Ruby keyword args.
- multipart format blocks render checked templates and locals.
- generated HTML and text ERB files exist.
- bad template locals fail during Haxe compilation.

Rails runtime delivery remains part of the Rails runtime lane. When Rails gems
are installed, `REQUIRE_RAILS=1 npm run test:rails-runtime` must make missing
Rails runtime dependencies fail instead of silently skipping.
