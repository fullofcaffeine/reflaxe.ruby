package client;

import js.Browser;
import js.html.Element;
import js.html.Event;
import rails.turbo.Turbo;
import shared.TodoHooks;

// Haxe-authored Rails/Turbo client behavior.
//
// Demonstrates: RailsHx can use Haxe for browser JavaScript while staying
// Turbo-idiomatic through typed `rails.turbo.Turbo` event helpers.
// Type safety: DOM values are typed as `Element`/`Event` where possible;
// storage keys and behavior hooks are centralized constants instead of repeated
// magic strings.
// IntelliSense: editors should complete `Turbo.onLoad`, `Turbo.onSubmitStart`,
// `Browser.document`, `Element` methods, and the helper functions below.
// JS/Rails output: compiled JavaScript pinned through Rails importmap and run
// alongside Turbo.
class TodoClient {
	public static function main():Void {
		boot();
		Turbo.onLoad(function(_:Event):Void {
			boot();
		});
		Turbo.onSubmitStart(function(event):Void {
			captureTodoSubmit(event.target);
		});
	}

	static function boot():Void {
		bindTodoForm();
		bindScrollLinks();
		announceCompletedCreate();
	}

	static function bindTodoForm():Void {
		var form = Browser.document.querySelector(TodoHooks.classSelector(TodoHooks.formClass));
		if (form == null || form.getAttribute(TodoHooks.boundAttr) == "true") {
			return;
		}
		form.setAttribute(TodoHooks.boundAttr, "true");
		form.addEventListener("submit", function(event:Event):Void {
			captureTodoSubmit(event.target);
		});
	}

	static function captureTodoSubmit(target:Dynamic):Void {
		var form:Element = cast target;
		if (form == null || !form.classList.contains(TodoHooks.formClass)) {
			return;
		}
		try {
			Browser.window.sessionStorage.setItem(TodoHooks.submitStorageKey, "1");
			Browser.window.sessionStorage.setItem(TodoHooks.submitScrollStorageKey, Std.string(currentScrollY()));
		} catch (_:Dynamic) {}
	}

	static function bindScrollLinks():Void {
		var links = Browser.document.querySelectorAll(TodoHooks.attrSelector(TodoHooks.scrollAttr));
		for (i in 0...links.length) {
			var link:Element = cast links.item(i);
			if (link == null || link.getAttribute(TodoHooks.boundAttr) == "true") {
				continue;
			}
			link.setAttribute(TodoHooks.boundAttr, "true");
			link.addEventListener("click", function(event:Event):Void {
				var href = link.getAttribute("href");
				if (href == null || href.charAt(0) != "#") {
					return;
				}
				var target = Browser.document.querySelector(href);
				if (target == null) {
					return;
				}
				event.preventDefault();
				focusAndScroll(target);
			});
		}
	}

	static function announceCompletedCreate():Void {
		var shouldAnnounce = false;
		var savedScrollY:Null<Float> = null;
		try {
			shouldAnnounce = Browser.window.sessionStorage.getItem(TodoHooks.submitStorageKey) == "1";
			savedScrollY = Std.parseFloat(Browser.window.sessionStorage.getItem(TodoHooks.submitScrollStorageKey));
			Browser.window.sessionStorage.removeItem(TodoHooks.submitStorageKey);
			Browser.window.sessionStorage.removeItem(TodoHooks.submitScrollStorageKey);
		} catch (_:Dynamic) {}
		if (!shouldAnnounce) {
			return;
		}

		if (savedScrollY != null && !Math.isNaN(savedScrollY)) {
			restoreScroll(savedScrollY);
		}

		var flash = Browser.document.querySelector(TodoHooks.attrSelector(TodoHooks.flashAttr));
		if (flash != null) {
			flash.textContent = "Task added to open work";
			flash.removeAttribute("hidden");
			Browser.window.setTimeout(function():Void {
				flash.setAttribute("hidden", "hidden");
			}, 2200);
		}
	}

	static function focusAndScroll(target:Element):Void {
		try {
			target.focus();
		} catch (_:Dynamic) {}
		js.Syntax.code("{0}.scrollIntoView({ behavior: 'smooth', block: 'start' })", target);
	}

	static function currentScrollY():Float {
		return js.Syntax.code("window.scrollY || window.pageYOffset || 0");
	}

	static function restoreScroll(scrollY:Float):Void {
		js.Syntax.code("window.scrollTo(0, {0})", scrollY);
	}
}
