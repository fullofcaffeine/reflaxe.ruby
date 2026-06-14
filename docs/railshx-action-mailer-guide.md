# RailsHx ActionMailer Guide

RailsHx mailers are Haxe-authored Rails mailers. The compiler emits ordinary
`ActionMailer::Base` subclasses and ordinary ERB templates under `app/views`;
HHX and macros are the typed authoring layer, not a replacement mail runtime.

## Mailer Classes

Annotate a Haxe class with `@:railsMailer` and extend
`rails.action_mailer.Base`:

```haxe
import rails.action_mailer.MailAddress;
import rails.action_mailer.MailLayout;

@:railsMailer
class UserMailer extends rails.action_mailer.Base {
	public function welcome(email:String, name:String, message:String):Void {
		var locals:WelcomeEmailLocals = {
			name: name,
			message: message,
			productName: "RailsHx"
		};

		attachments().add("welcome.txt", message);
		MailerMacro.mailMultipart(this, {
			to: email,
			from: "team@example.test",
			cc: ["ops@example.test"],
			replyTo: MailAddress.one("reply@example.test"),
			subject: "Welcome to typed RailsHx mail",
			layout: MailLayout.none()
		}, (Template.of(WelcomeEmailHtmlView) : Template<WelcomeEmailLocals>), locals,
			(Template.of(WelcomeEmailTextView) : Template<WelcomeEmailLocals>), locals);
	}
}
```

Generated Ruby stays Rails-shaped:

```ruby
class UserMailer < ActionMailer::Base
  def welcome(email, name, message)
    attachments["welcome.txt"] = message
    mail(to: email, from: "team@example.test", cc: ["ops@example.test"],
      reply_to: "reply@example.test", subject: "Welcome to typed RailsHx mail",
      layout: false) do |format|
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

## Typed Mail Options And Attachments

`MailOptions` keeps common Rails kwargs typed while still lowering to normal
ActionMailer keyword arguments:

- `to`, `from`, `cc`, `bcc`, and `replyTo` use `MailAddress`, which accepts a
  single `String` or `Array<String>`.
- `layout` uses `MailLayout`, with `MailLayout.none()` lowering to `layout:
  false`.
- arbitrary recipient/layout objects require `MailAddress.unchecked(...)` or
  `MailLayout.unchecked(...)` at a reviewed interop boundary.

Mailer attachments use `attachments().add(name, content)` for common string
attachments and emit Rails' standard `attachments["name"] = content`. More
complex Rails attachment hashes should use
`attachments().addUnchecked(name, value)` until a typed builder exists.

## Runtime Strategy

`npm run test:action-mailer` is the fast compiler/static lane. It checks:

- `@:railsMailer` emits an `ActionMailer::Base` subclass.
- `mail(...)` object literals lower to Ruby keyword args.
- recipient/layout options reject object-shaped raw values unless an explicit
  unchecked wrapper is used.
- attachments lower to Rails' attachment proxy and reject non-string content on
  the typed `add(...)` path.
- multipart format blocks render checked templates and locals.
- generated HTML and text ERB files exist.
- bad template locals fail during Haxe compilation.

Rails runtime delivery remains part of the Rails runtime lane. When Rails gems
are installed, `REQUIRE_RAILS=1 npm run test:rails-runtime` must make missing
Rails runtime dependencies fail instead of silently skipping.
