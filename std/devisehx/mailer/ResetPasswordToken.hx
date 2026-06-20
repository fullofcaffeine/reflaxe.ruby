package devisehx.mailer;

/**
	Opaque Devise reset-password token.

	The value is runtime-owned by Devise. Haxe code should pass it through typed
	mailer hooks and templates without logging or constructing token strings.
**/
abstract ResetPasswordToken(String) to String {}
