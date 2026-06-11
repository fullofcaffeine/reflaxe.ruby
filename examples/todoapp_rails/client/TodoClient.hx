package client;

import client.railshx.Turbo;
import js.Browser;
import js.html.Element;
import js.html.Event;

class TodoClient {
	static inline var submitStorageKey = "railshx.todo.just_added";
	static inline var submitScrollStorageKey = "railshx.todo.submit_scroll_y";
	static inline var boundAttr = "data-railshx-bound";

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
		var form = Browser.document.querySelector(".todo-form");
		if (form == null || form.getAttribute(boundAttr) == "true") {
			return;
		}
		form.setAttribute(boundAttr, "true");
		form.addEventListener("submit", function(event:Event):Void {
			captureTodoSubmit(event.target);
		});
	}

	static function captureTodoSubmit(target:Dynamic):Void {
		var form:Element = cast target;
		if (form == null || !form.classList.contains("todo-form")) {
			return;
		}
		try {
			Browser.window.sessionStorage.setItem(submitStorageKey, "1");
			Browser.window.sessionStorage.setItem(submitScrollStorageKey, Std.string(currentScrollY()));
		} catch (_:Dynamic) {}
	}

	static function bindScrollLinks():Void {
		var links = Browser.document.querySelectorAll("[data-railshx-scroll]");
		for (i in 0...links.length) {
			var link:Element = cast links.item(i);
			if (link == null || link.getAttribute(boundAttr) == "true") {
				continue;
			}
			link.setAttribute(boundAttr, "true");
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
			shouldAnnounce = Browser.window.sessionStorage.getItem(submitStorageKey) == "1";
			savedScrollY = Std.parseFloat(Browser.window.sessionStorage.getItem(submitScrollStorageKey));
			Browser.window.sessionStorage.removeItem(submitStorageKey);
			Browser.window.sessionStorage.removeItem(submitScrollStorageKey);
		} catch (_:Dynamic) {}
		if (!shouldAnnounce) {
			return;
		}

		if (savedScrollY != null && !Math.isNaN(savedScrollY)) {
			restoreScroll(savedScrollY);
		}

		var flash = Browser.document.querySelector("[data-railshx-flash]");
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
