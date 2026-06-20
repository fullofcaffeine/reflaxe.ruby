package devisehx.mailer;

/**
	Opaque Devise unlock token.

	Keeping unlock tokens distinct from other Devise token values lets Haxe catch
	wrong-hook/wrong-template wiring before generated Ruby is loaded by Rails.
**/
abstract UnlockToken(String) to String {}
