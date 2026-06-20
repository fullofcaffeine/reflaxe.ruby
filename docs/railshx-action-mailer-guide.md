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

`npm run test:action-mailer` is both the fast compiler/static lane and, when a
Rails bundle is available, a generated Rails runtime lane. The static pass
checks:

- `@:railsMailer` emits an `ActionMailer::Base` subclass.
- `mail(...)` object literals lower to Ruby keyword args.
- recipient/layout options reject object-shaped raw values unless an explicit
  unchecked wrapper is used.
- attachments lower to Rails' attachment proxy and reject non-string content on
  the typed `add(...)` path.
- multipart format blocks render checked templates and locals.
- generated HTML and text ERB files exist.
- bad template locals fail during Haxe compilation.

The runtime pass materializes a tiny Rails app, requires the generated mailer,
and runs Rails tests against the real `ActionMailer::Base` behavior:

- `Mailers::UserMailer.welcome(...)` builds a multipart message.
- `to`, `from`, `cc`, `reply_to`, and `subject` are asserted through the Rails
  mail object.
- HTML and text bodies render the HHX-authored ERB templates with checked
  locals.
- `attachments().add(...)` produces a real ActionMailer attachment.
- `deliver_now` writes to the Rails test delivery collection.

If the generated app bundle is unavailable, the local fast lane prints a staged
skip so compiler work stays lightweight. `REQUIRE_RAILS=1 npm run
test:rails-runtime` includes `test:action-mailer` and makes missing Rails
runtime dependencies fail instead of silently skipping.

## Parameterized Mailers And Previews

Rails parameterized mailers are supported through a typed Rails-shaped seam:
declare a typed params object, expose a checked `withParams(...)` extern stub
for Rails' `.with(...)` class API, and read values inside the mailer through
`param(MailParam<T>)`. This gives Haxe call sites completion/type-checking while
the compiler emits ordinary Rails `params[:key]` access.

```haxe
import rails.action_mailer.MailParam;
import rails.action_mailer.MessageDelivery;

typedef WelcomeMailerParams = {
	var email:String;
	var name:String;
	var message:String;
}

final class WelcomeMailerParam {
	public static final email:MailParam<String> = "email";
	public static final name:MailParam<String> = "name";
	public static final message:MailParam<String> = "message";
}

@:railsMailer
class UserMailer extends rails.action_mailer.Base {
	// Compiler-only Haxe declaration for Rails' native `.with(...)` API.
	// It emits no Ruby method; calls lower to `UserMailer.with(email: ..., ...)`.
	@:native("with")
	@:rubyKwargs
	@:rubyExternStub
	public static function withParams(params:WelcomeMailerParams):UserMailer {
		return cast null;
	}

	public function welcomeFromParams():MessageDelivery {
		var email = param(WelcomeMailerParam.email);
		var name = param(WelcomeMailerParam.name);
		var message = param(WelcomeMailerParam.message);
		var locals:WelcomeEmailLocals = {
			name: name,
			message: message,
			productName: "RailsHx"
		};

		return MailerMacro.mailMultipart(this, {
			to: email,
			subject: "Welcome to typed RailsHx mail"
		}, (Template.of(WelcomeEmailHtmlView) : Template<WelcomeEmailLocals>), locals,
			(Template.of(WelcomeEmailTextView) : Template<WelcomeEmailLocals>), locals);
	}
}
```

The intended generated Ruby is ordinary Rails:

```ruby
class UserMailer < ActionMailer::Base
  def welcome_from_params
    email = params[:email]
    name = params[:name]
    message = params[:message]
    mail(to: email, subject: "Welcome to typed RailsHx mail") do |format|
      # Rails-native format render calls emitted by MailerMacro.
    end
  end
end
```

App code can call the Rails parameterized API without writing raw hashes:

```haxe
UserMailer.withParams({
	email: user.email,
	name: user.name,
	message: "Typed params stay checked."
}).welcomeFromParams().deliverLater();
```

That call lowers to Rails' `UserMailer.with(email: ..., name: ..., message:
"...").welcome_from_params.deliver_later`, while Haxe checks that every
required param is present and has the expected type.

Generated `withParams(...)` wrappers from `@:railsMailerParams(...)` remain
future work. Today, author the small `@:rubyExternStub` yourself or let a future
generator create it. The unchecked Rails escape hatch, if needed, must be named
explicitly, for example `withUnchecked(...)`.

Preview classes can also be Haxe-authored and compiler-erased into normal
Rails preview artifacts:

```haxe
@:railsMailerPreview(UserMailer)
class UserMailerPreview extends rails.action_mailer.Preview {
	public function welcome():rails.action_mailer.MessageDelivery {
		var user = User.previewFixture();
		return UserMailer.withParams({
			email: user.email,
			name: user.name,
			message: "Previewed through typed RailsHx params."
		}).welcomeFromParams();
	}
}
```

The compiler should emit `ActionMailer::Preview` subclasses under
`test/mailers/previews`, and the runtime lane loads the generated preview and
exercises the preview action in a tiny Rails app. Unsupported preview shapes,
dynamic parameter hashes, or Rails-owned preview files should remain explicit
adoption/interop boundaries until they have typed contracts.

## Current Production Boundary

The supported production path today is ordinary Rails mailer delivery from a
Haxe-authored `@:railsMailer`, typed mail kwargs, typed HHX HTML/text templates,
and string attachments through `attachments().add(...)`.

Parameterized mailers are supported for typed `.with(...)` call sites and typed
`params[:key]` reads inside Haxe-authored mailers. Haxe-authored preview classes
are supported as generated `ActionMailer::Preview` artifacts. Generated
`withParams(...)` wrappers, richer attachment hashes, mailer/job integration,
and preview/test-helper generators remain deferred. Do not represent those as
supported just because the lower-level Rails API can be reached with unchecked
interop.
