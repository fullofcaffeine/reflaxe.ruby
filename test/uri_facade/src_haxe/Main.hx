/**
	Executable contract for the typed `ruby.URI` and `ruby.URIValue` facades.

	The calls exercise completion over common nullable components, typed URI
	composition, predicates, and component codecs. Generated Ruby should contain
	only `require "uri"`, direct `URI` module calls, and native receiver dispatch.
**/
class Main {
	static function main():Void {
		var parsed = ruby.URI.parse("https://user:pass@example.com:8443/app/items?q=hello%20world#top");
		Sys.println(parsed.scheme());
		Sys.println(parsed.userinfo());
		Sys.println(parsed.user());
		Sys.println(parsed.password());
		Sys.println(parsed.host());
		Sys.println(parsed.hostname());
		Sys.println(parsed.port());
		Sys.println(parsed.path());
		Sys.println(parsed.query());
		Sys.println(parsed.opaque() == null);
		Sys.println(parsed.fragment());
		Sys.println(parsed.isHierarchical());
		Sys.println(parsed.isAbsolute());
		Sys.println(parsed.isRelative());
		Sys.println(parsed.toString());

		Sys.println(parsed.merge("../api?q=1").toString());
		Sys.println(ruby.URI.parse("https://example.com/app/views/index").routeTo("https://example.com/app/assets/logo.svg").toString());
		Sys.println(ruby.URI.parse("https://example.com/app/assets/logo.svg").routeFrom("https://example.com/app/views/index").toString());
		Sys.println(ruby.URI.parse("HTTP://EXAMPLE.COM/~user").normalize().toString());
		Sys.println(ruby.URI.join("https://example.com/app/", "../assets/logo.svg").toString());

		Sys.println(ruby.URI.encodeFormComponent("a b+c"));
		Sys.println(ruby.URI.decodeFormComponent("a+b%2Bc"));
		Sys.println(ruby.URI.encodeComponent("a b/c?d"));
		Sys.println(ruby.URI.decodeComponent("a%20b%2Fc%3Fd"));
		var mailto = ruby.URI.parse("mailto:dev@example.com");
		Sys.println(mailto.path() == null);
		Sys.println(mailto.opaque());
		Sys.println(mailto.isHierarchical());
	}
}
