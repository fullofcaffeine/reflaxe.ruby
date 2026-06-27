package rails.action_controller;

/**
	Typed Rails MIME token access for ordered request negotiation.

	Rails owns `Mime[:html]`/`Mime[:json]` objects at runtime. These inline
	helpers keep app code on typed `RequestFormat` values while preserving the
	ordinary Rails constants in generated Ruby.
	`@:rubyAllowRaw` is scoped to this std facade so strict app examples can use
	typed tokens without carrying raw Ruby injection in application code.
**/
@:rubyAllowRaw
class Mime {
	public static var html(get, never):RequestFormat;
	public static var json(get, never):RequestFormat;
	public static var turboStream(get, never):RequestFormat;
	public static var xml(get, never):RequestFormat;
	public static var all(get, never):RequestFormat;

	static function get_html():RequestFormat {
		return cast untyped __ruby__("Mime[:html]");
	}

	static function get_json():RequestFormat {
		return cast untyped __ruby__("Mime[:json]");
	}

	static function get_turboStream():RequestFormat {
		return cast untyped __ruby__("Mime[:turbo_stream]");
	}

	static function get_xml():RequestFormat {
		return cast untyped __ruby__("Mime[:xml]");
	}

	static function get_all():RequestFormat {
		return cast untyped __ruby__("Mime::ALL");
	}
}
