package devisehx;

/**
	Typed placeholder for Devise `sign_in` options.

	The first skeleton intentionally keeps this narrow. Future slices should add
	only options that can be proven from Devise docs/runtime behavior and should
	avoid an open-ended untyped bag.
**/
typedef SignInOptions = {
	?bypass:Bool,
	?force:Bool
}
