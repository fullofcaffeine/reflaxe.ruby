package e2e_haxe;

import js.lib.Promise;
import js.lib.RegExp;
import rails.test.playwright.Playwright.PW;
import rails.test.playwright.Types.Page;
import reflaxe.js.Async;
import reflaxe.js.Async.await;
import shared.TodoHooks;

// Haxe-authored Playwright browser spec.
//
// Demonstrates: browser tests can reuse typed RailsHx constants such as
// `TodoHooks` while lowering to an ordinary Playwright-compatible JavaScript
// spec. Vanilla TypeScript Playwright specs remain first-class; this layer is
// useful when tests benefit from Haxe completion/types or shared app contracts.
// JS output: a Genes module tree under e2e/generated/haxe_todoapp plus a tiny
// Playwright-discoverable e2e/generated/haxe_todoapp.spec.js wrapper.
class TodoappBrowserSpec {
	static function main():Void {
		PW.testPage("haxe-authored browser spec reuses typed RailsHx hooks", Async.async(function(page:Page):Promise<Void> {
			await(page.goto("/todos", {waitUntil: "domcontentloaded", timeout: 15000}));
			await(PW.see(page.locator(".login-shell")).toBeVisible());

			await(page.getByRole("button", {name: "Continue as guest"}).click());
			await(PW.see(page.locator(TodoHooks.classSelector(TodoHooks.shellClass))).toBeVisible());
			await(PW.see(page.locator(TodoHooks.idSelector(TodoHooks.chatPanelId))).toBeVisible());
			await(PW.see(page.locator(TodoHooks.attrSelector(TodoHooks.flashAttr))).toHaveAttribute("hidden", ""));
			await(PW.see(page.locator(".session-chip")).toContainText("Guest Workspace"));
			if (!new RegExp("/todos$").test(page.url())) {
				throw 'Expected /todos URL, got ${page.url()}';
			}
			return Promise.resolve(null);
		}));
	}
}
