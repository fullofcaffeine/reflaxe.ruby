package rails.test.playwright;

import js.Syntax;
import js.lib.Promise;
import rails.test.playwright.PlaywrightApi.TestArgs;
import rails.test.playwright.Types.Expectation;
import rails.test.playwright.Types.Locator;
import rails.test.playwright.Types.Page;

/**
	Small typed facade for Haxe-authored Playwright specs.

	Playwright detects fixtures from JavaScript destructuring (`async ({ page })`
	=> ...). Haxe cannot express destructuring in function arguments, so this
	facade owns the one required JS interop boundary and app tests call
	`PW.testPage(name, page -> ...)` instead of raw `js.Syntax.code`.
**/
class PW {
	public static function testPage(name:String, fn:Page->Promise<Void>):Void {
		final cb:TestArgs->Promise<Void> = cast Syntax.code("({ page }) => fn(page)");
		PlaywrightApi.test(name, cb);
	}

	public static inline function see(locator:Locator):Expectation {
		return PlaywrightApi.expect(locator);
	}
}
