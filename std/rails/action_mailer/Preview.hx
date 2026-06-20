package rails.action_mailer;

/*
	Marker base for Haxe-authored Rails mailer previews.

	Classes annotated with `@:railsMailerPreview` are compiler inputs: RailsHx
	emits a normal `ActionMailer::Preview` class under `test/mailers/previews`
	and does not generate an app runtime wrapper class.
 */
class Preview {}
