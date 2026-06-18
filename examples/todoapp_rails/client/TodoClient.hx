package client;

import channels.ChatMessagesChannel.ChatBroadcast;
import js.Browser;
import js.html.Element;
import js.html.Event;
import js.html.EventTarget;
import rails.action_cable.Consumer;
import rails.turbo.Turbo;
import rails.turbo.TurboStreamAction;
import reflaxe.js.Async;
import reflaxe.js.Async.await;
import shared.TodoHooks;

// Haxe-authored Rails/Turbo client behavior.
//
// Demonstrates: RailsHx can use Haxe for browser JavaScript while staying
// Turbo-idiomatic through typed `rails.turbo.Turbo` event and stream helpers.
// Type safety: DOM values are typed as `Element`/`Event` where possible;
// storage keys and behavior hooks are centralized constants instead of repeated
// magic strings; Turbo submit/fetch details and ActionCable room payloads use
// typed structural contracts.
// IntelliSense: editors should complete `Turbo.onLoad`, `Turbo.onSubmitStart`,
// `Turbo.onBeforeFetchRequest`, `Browser.document`, `Element` methods, and the
// helper functions below.
// JS/Rails output: compiled JavaScript pinned through Rails importmap and run
// alongside Turbo.
class TodoClient {
	static var chatSubscribed:Bool = false;

	public static function main():Void {
		boot();
		Turbo.onLoad(function(_:Event):Void {
			boot();
		});
		Turbo.onSubmitStart(function(event):Void {
			var form = event.detail.formSubmission == null ? null : event.detail.formSubmission.formElement;
			captureTodoSubmit(form == null ? event.target : form);
		});
		Turbo.onSubmitEnd(function(event):Void {
			var form = event.detail.formSubmission == null ? null : event.detail.formSubmission.formElement;
			announceTodoSubmit(form == null ? event.target : form, event.detail.success);
			announceSessionSubmit(form == null ? event.target : form, event.detail.success);
			announceChatSubmit(form == null ? event.target : form, event.detail.success);
		});
		Turbo.onBeforeFetchRequest(function(event):Void {
			Turbo.addFetchRequestHeader(event, "X-RailsHx-Client", "todoapp");
		});
	}

	static function boot():Void {
		bindTodoForm();
		bindSessionForms();
		bindChatForms();
		subscribeToChat();
		bindScrollLinks();
		announceCompletedCreate();
		announceSessionChange();
		announceChatChange();
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

	static function captureTodoSubmit(target:Null<EventTarget>):Void {
		var form = elementTarget(target);
		if (form == null || !form.classList.contains(TodoHooks.formClass)) {
			return;
		}
		try {
			Browser.window.sessionStorage.setItem(TodoHooks.submitStorageKey, "1");
			Browser.window.sessionStorage.setItem(TodoHooks.submitScrollStorageKey, Std.string(currentScrollY()));
		} catch (_:js.lib.Error) {}
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

	static function bindSessionForms():Void {
		var forms = Browser.document.querySelectorAll(TodoHooks.classSelector(TodoHooks.sessionFormClass));
		for (i in 0...forms.length) {
			var form:Element = cast forms.item(i);
			if (form == null || form.getAttribute(TodoHooks.boundAttr) == "true") {
				continue;
			}
			form.setAttribute(TodoHooks.boundAttr, "true");
			form.addEventListener("submit", function(_:Event):Void {
				try {
					Browser.window.sessionStorage.setItem(TodoHooks.sessionStorageKey, "1");
				} catch (_:js.lib.Error) {}
			});
		}
	}

	static function bindChatForms():Void {
		var forms = Browser.document.querySelectorAll(TodoHooks.classSelector(TodoHooks.chatFormClass));
		for (i in 0...forms.length) {
			var form:Element = cast forms.item(i);
			if (form == null || form.getAttribute(TodoHooks.boundAttr) == "true") {
				continue;
			}
			form.setAttribute(TodoHooks.boundAttr, "true");
			form.addEventListener("submit", function(_:Event):Void {
				try {
					Browser.window.sessionStorage.setItem(TodoHooks.chatStorageKey, "1");
				} catch (_:js.lib.Error) {}
			});
		}
	}

	static function subscribeToChat():Void {
		var panel = Browser.document.querySelector(TodoHooks.idSelector(TodoHooks.chatPanelId));
		if (chatSubscribed || panel == null) {
			return;
		}
		chatSubscribed = true;
		var consumer = Consumer.create();
		Consumer.subscribe(consumer, "Channels::ChatMessagesChannel", {}, {
			connected: function():Void {
				panel.setAttribute(TodoHooks.chatCableReadyAttr, "true");
			},
			disconnected: function():Void {
				panel.removeAttribute(TodoHooks.chatCableReadyAttr);
			},
			received: function(payload:ChatBroadcast):Void {
				appendBroadcastMessage(payload);
			}
		});
	}

	static function announceSessionSubmit(target:Null<EventTarget>, success:Null<Bool>):Void {
		var form = elementTarget(target);
		if (form == null || !form.classList.contains(TodoHooks.sessionFormClass) || success == false) {
			return;
		}
		announceSessionChangeNow();
	}

	static function announceTodoSubmit(target:Null<EventTarget>, success:Null<Bool>):Void {
		var form = elementTarget(target);
		if (form == null || !form.classList.contains(TodoHooks.formClass) || success == false) {
			return;
		}
		announceCompletedCreateNow();
	}

	static function announceChatSubmit(target:Null<EventTarget>, success:Null<Bool>):Void {
		var form = elementTarget(target);
		if (form == null || !form.classList.contains(TodoHooks.chatFormClass) || success == false) {
			return;
		}
		announceChatChangeNow();
	}

	static function announceCompletedCreate():Void {
		var shouldAnnounce = false;
		var savedScrollY:Null<Float> = null;
		try {
			shouldAnnounce = Browser.window.sessionStorage.getItem(TodoHooks.submitStorageKey) == "1";
			savedScrollY = Std.parseFloat(Browser.window.sessionStorage.getItem(TodoHooks.submitScrollStorageKey));
			Browser.window.sessionStorage.removeItem(TodoHooks.submitStorageKey);
			Browser.window.sessionStorage.removeItem(TodoHooks.submitScrollStorageKey);
		} catch (_:js.lib.Error) {}
		if (!shouldAnnounce) {
			return;
		}

		if (savedScrollY != null && !Math.isNaN(savedScrollY)) {
			restoreScroll(savedScrollY);
		}
		announceCompletedCreateNow();
	}

	static function announceCompletedCreateNow():Void {
		var flash = Browser.document.querySelector(TodoHooks.attrSelector(TodoHooks.flashAttr));
		if (flash != null) {
			flash.textContent = "Task added to open work";
			flash.removeAttribute("hidden");
			hideAfterDelay(flash, 2200);
		}
	}

	static function announceSessionChange():Void {
		var shouldAnnounce = false;
		try {
			shouldAnnounce = Browser.window.sessionStorage.getItem(TodoHooks.sessionStorageKey) == "1";
			Browser.window.sessionStorage.removeItem(TodoHooks.sessionStorageKey);
		} catch (_:js.lib.Error) {}
		if (!shouldAnnounce) {
			return;
		}
		announceSessionChangeNow();
	}

	static function announceSessionChangeNow():Void {
		var flash = Browser.document.querySelector(TodoHooks.attrSelector(TodoHooks.flashAttr));
		if (flash != null) {
			flash.textContent = "Session updated";
			flash.removeAttribute("hidden");
			hideAfterDelay(flash, 2200);
		}
		var zone = Browser.document.querySelector(TodoHooks.attrSelector(TodoHooks.sessionZoneAttr));
		if (zone != null) {
			zone.classList.add("is-warm");
			removeClassAfterDelay(zone, "is-warm", 900);
		}
	}

	static function announceChatChange():Void {
		var shouldAnnounce = false;
		try {
			shouldAnnounce = Browser.window.sessionStorage.getItem(TodoHooks.chatStorageKey) == "1";
			Browser.window.sessionStorage.removeItem(TodoHooks.chatStorageKey);
		} catch (_:js.lib.Error) {}
		if (!shouldAnnounce) {
			return;
		}
		announceChatChangeNow();
	}

	static function announceChatChangeNow():Void {
		var flash = Browser.document.querySelector(TodoHooks.attrSelector(TodoHooks.flashAttr));
		if (flash != null) {
			flash.textContent = "Room note posted";
			flash.removeAttribute("hidden");
			hideAfterDelay(flash, 2200);
		}
		var panel = Browser.document.querySelector(TodoHooks.idSelector(TodoHooks.chatPanelId));
		if (panel != null) {
			panel.classList.add("is-warm");
			removeClassAfterDelay(panel, "is-warm", 900);
		}
	}

	static function appendBroadcastMessage(payload:ChatBroadcast):Void {
		var list = Browser.document.querySelector(TodoHooks.idSelector(TodoHooks.chatListId));
		if (list == null) {
			return;
		}
		var messageKey = Std.string(payload.id);
		if (Browser.document.querySelector(TodoHooks.attrEqualsSelector(TodoHooks.chatMessageKeyAttr, messageKey)) != null) {
			return;
		}

		Turbo.renderStreamMessage(Turbo.stream(TurboStreamAction.Prepend, TodoHooks.chatListId, chatMessageTemplate(payload, messageKey)));
	}

	static function chatMessageTemplate(payload:ChatBroadcast, messageKey:String):String {
		return '<li class="${TodoHooks.chatMessageClass}" ${TodoHooks.chatMessageKeyAttr}="${escapeHtml(messageKey)}">'
			+ '<span class="avatar">#</span>'
			+ '<div><strong>User ${payload.userId}</strong><p>${escapeHtml(payload.body)}</p></div>'
			+ '</li>';
	}

	static function escapeHtml(value:String):String {
		return value.split("&")
			.join("&amp;")
			.split("<")
			.join("&lt;")
			.split(">")
			.join("&gt;")
			.split("\"")
			.join("&quot;")
			.split("'")
			.join("&#39;");
	}

	@:async
	static function hideAfterDelay(element:Element, milliseconds:Int):Void {
		await(Async.delay(milliseconds));
		element.setAttribute("hidden", "hidden");
	}

	@:async
	static function removeClassAfterDelay(element:Element, className:String, milliseconds:Int):Void {
		await(Async.delay(milliseconds));
		element.classList.remove(className);
	}

	static function focusAndScroll(target:Element):Void {
		try {
			target.focus();
		} catch (_:js.lib.Error) {}
		js.Syntax.code("{0}.scrollIntoView({ behavior: 'smooth', block: 'start' })", target);
	}

	static function elementTarget(target:Null<EventTarget>):Null<Element> {
		return target == null ? null : (Std.isOfType(target, Element) ? cast target : null);
	}

	static function currentScrollY():Float {
		return js.Syntax.code("window.scrollY || window.pageYOffset || 0");
	}

	static function restoreScroll(scrollY:Float):Void {
		js.Syntax.code("window.scrollTo(0, {0})", scrollY);
	}
}
