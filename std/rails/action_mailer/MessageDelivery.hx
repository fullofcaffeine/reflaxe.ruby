package rails.action_mailer;

/*
	Facade for Rails' ActionMailer::MessageDelivery.

	Parameterized mailer calls such as `UserMailer.with(...).welcome` return this
	Rails object. The methods below keep Haxe call sites typed while lowering to
	ordinary Rails delivery methods.
 */
class MessageDelivery {
	@:native("deliver_now")
	public function deliverNow():Dynamic {
		return null;
	}

	@:native("deliver_later")
	public function deliverLater():Dynamic {
		return null;
	}
}
