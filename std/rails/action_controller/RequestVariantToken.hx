package rails.action_controller;

/**
	Typed Rails request variant tokens for assigning `request.variant`.

	Rails expects symbols such as `:phone` or `:tablet`. These inline helpers
	keep Haxe app code typed while generated Ruby remains ordinary Rails variant
	assignment.
	`@:rubyAllowRaw` is scoped to this std facade so strict app examples can use
	typed tokens without carrying raw Ruby injection in application code.
**/
@:rubyAllowRaw
class RequestVariantToken {
	public static var phone(get, never):RequestVariantToken;
	public static var tablet(get, never):RequestVariantToken;
	public static var desktop(get, never):RequestVariantToken;
	public static var nativeApp(get, never):RequestVariantToken;

	static function get_phone():RequestVariantToken {
		return cast untyped __ruby__(":phone");
	}

	static function get_tablet():RequestVariantToken {
		return cast untyped __ruby__(":tablet");
	}

	static function get_desktop():RequestVariantToken {
		return cast untyped __ruby__(":desktop");
	}

	static function get_nativeApp():RequestVariantToken {
		return cast untyped __ruby__(":native_app");
	}
}
