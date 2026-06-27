package rails.action_controller;

/**
	Typed Rails request variant tokens for assigning `request.variant`.

	Rails expects symbols such as `:phone` or `:tablet`. These inline helpers
	keep Haxe app code typed while generated Ruby remains ordinary Rails variant
	assignment.
**/
class RequestVariantToken {
	public static var phone(get, never):RequestVariantToken;
	public static var tablet(get, never):RequestVariantToken;
	public static var desktop(get, never):RequestVariantToken;
	public static var nativeApp(get, never):RequestVariantToken;

	static inline function get_phone():RequestVariantToken {
		return cast untyped __ruby__(":phone");
	}

	static inline function get_tablet():RequestVariantToken {
		return cast untyped __ruby__(":tablet");
	}

	static inline function get_desktop():RequestVariantToken {
		return cast untyped __ruby__(":desktop");
	}

	static inline function get_nativeApp():RequestVariantToken {
		return cast untyped __ruby__(":native_app");
	}
}
