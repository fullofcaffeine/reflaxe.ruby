package rails.test.playwright;

import js.lib.Promise;
import rails.test.playwright.Types.Expectation;
import rails.test.playwright.Types.Locator;
import rails.test.playwright.Types.Page;

typedef TestArgs = {
	final page:Page;
}

/**
	Minimal Playwright imports for Haxe-authored browser specs.

	`@:jsRequire` keeps the emitted JavaScript tied to the ordinary
	`@playwright/test` package. RailsHx does not wrap or replace Playwright;
	this extern only gives Haxe tests completion and type checking.
**/
@:jsRequire("@playwright/test")
extern class PlaywrightApi {
	@:native("test")
	public static function test(name:String, fn:TestArgs->Promise<Void>):Void;

	@:native("expect")
	public static function expect(locator:Locator):Expectation;
}
