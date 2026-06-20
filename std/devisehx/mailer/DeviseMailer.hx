package devisehx.mailer;

import rails.action_mailer.MailOptions;

/**
	Typed extern contract for Devise mailer hooks.

	This is a companion-layer type contract, not a Devise mailer runtime. Devise
	still owns `Devise::Mailer`; RailsHx uses the extern so Haxe-authored custom
	mailers and generated contracts can type-check hook signatures and opaque
	token usage while emitted Ruby stays Devise/Rails-native.
**/
@:native("Devise::Mailer")
extern class DeviseMailer<TModel> extends rails.action_mailer.Base {
	public function confirmationInstructions(record:TModel, token:ConfirmationToken, opts:MailOptions):Void;
	public function resetPasswordInstructions(record:TModel, token:ResetPasswordToken, opts:MailOptions):Void;
	public function unlockInstructions(record:TModel, token:UnlockToken, opts:MailOptions):Void;
}
