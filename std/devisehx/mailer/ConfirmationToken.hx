package devisehx.mailer;

/**
	Opaque Devise confirmation token.

	Devise creates and validates the token at runtime. RailsHx exposes it as a
	distinct Haxe type so custom mailer hook signatures cannot accidentally swap
	confirmation, reset-password, and unlock tokens. There is intentionally no
	public `from String` conversion.
**/
abstract ConfirmationToken(String) to String {}
