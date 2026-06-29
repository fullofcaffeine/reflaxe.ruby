import {Async} from "railshx/reflaxe/js/Async"
import {Turbo} from "railshx/rails/turbo/Turbo"
import {TextAreaComposer} from "railshx/rails/hotwire/TextAreaComposer"
import {Exception} from "railshx/haxe/Exception"
import {Register} from "railshx/genes/Register"
import {Std} from "railshx/Std"

export const TodoClient = Register.global("$hxClasses")["client.TodoClient"] = 
class TodoClient {
	static main() {
		TodoClient.boot();
		Turbo.onLoad(function (_) {
			TodoClient.boot();
		});
		Turbo.onSubmitStart(function (event) {
			let form = (event.detail.formSubmission == null) ? null : event.detail.formSubmission.formElement;
			TodoClient.captureTodoSubmit((form == null) ? event.target : form);
		});
		Turbo.onSubmitEnd(function (event) {
			let form = (event.detail.formSubmission == null) ? null : event.detail.formSubmission.formElement;
			TodoClient.announceTodoSubmit((form == null) ? event.target : form, event.detail.success);
			TodoClient.announceSessionSubmit((form == null) ? event.target : form, event.detail.success);
			TodoClient.announceChatSubmit((form == null) ? event.target : form, event.detail.success);
		});
		Turbo.onBeforeFetchRequest(function (event) {
			Turbo.addFetchRequestHeader(event, "X-RailsHx-Client", "todoapp");
		});
	}
	static boot() {
		TodoClient.bindTodoForm();
		TodoClient.bindSessionForms();
		TodoClient.bindChatForms();
		TodoClient.bindScrollLinks();
		TodoClient.announceCompletedCreate();
		TodoClient.announceSessionChange();
		TodoClient.announceChatChange();
	}
	static bindTodoForm() {
		let form = window.document.querySelector("." + "todo-form");
		if (form == null || form.getAttribute("data-railshx-bound") == "true") {
			return;
		};
		form.setAttribute("data-railshx-bound", "true");
		form.addEventListener("submit", function (event) {
			TodoClient.captureTodoSubmit(event.target);
		});
	}
	static captureTodoSubmit(target) {
		let form = TodoClient.elementTarget(target);
		if (form == null || !form.classList.contains("todo-form")) {
			return;
		};
		try {
			window.sessionStorage.setItem("railshx.todo.just_added", "1");
			window.sessionStorage.setItem("railshx.todo.submit_scroll_y", Std.string(TodoClient.currentScrollY()));
		}catch (_g) {
			if (!((Exception.caught(_g).unwrap()) instanceof Error)) {
				throw _g;
			};
		};
	}
	static bindScrollLinks() {
		let links = window.document.querySelectorAll("[" + "data-railshx-scroll" + "]");
		let _g = 0;
		let _g1 = links.length;
		while (_g < _g1) {
			let i = _g++;
			let link = links.item(i);
			if (link == null || link.getAttribute("data-railshx-bound") == "true") {
				continue;
			};
			link.setAttribute("data-railshx-bound", "true");
			link.addEventListener("click", function (event) {
				let href = link.getAttribute("href");
				if (href == null || href.charAt(0) != "#") {
					return;
				};
				let target = window.document.querySelector(href);
				if (target == null) {
					return;
				};
				event.preventDefault();
				TodoClient.focusAndScroll(target);
			});
		};
	}
	static bindSessionForms() {
		let forms = window.document.querySelectorAll("[" + "data-railshx-session" + "]");
		let _g = 0;
		let _g1 = forms.length;
		while (_g < _g1) {
			let i = _g++;
			let form = forms.item(i);
			if (form == null || form.getAttribute("data-railshx-bound") == "true") {
				continue;
			};
			form.setAttribute("data-railshx-bound", "true");
			form.addEventListener("submit", function (_) {
				try {
					window.sessionStorage.setItem("railshx.todo.session_changed", "1");
				}catch (_g) {
					if (!((Exception.caught(_g).unwrap()) instanceof Error)) {
						throw _g;
					};
				};
			});
		};
	}
	static bindChatForms() {
		let forms = window.document.querySelectorAll("." + "chat-form");
		let _g = 0;
		let _g1 = forms.length;
		while (_g < _g1) {
			let i = _g++;
			let form = forms.item(i);
			if (form == null || form.getAttribute("data-railshx-bound") == "true") {
				continue;
			};
			form.setAttribute("data-railshx-bound", "true");
			form.addEventListener("submit", function (_) {
				try {
					window.sessionStorage.setItem("railshx.todo.chat_posted", "1");
				}catch (_g) {
					if (!((Exception.caught(_g).unwrap()) instanceof Error)) {
						throw _g;
					};
				};
			});
			TextAreaComposer.bindEnterSubmit(form);
		};
	}
	static announceSessionSubmit(target, success) {
		let form = TodoClient.elementTarget(target);
		if (form == null || form.getAttribute("data-railshx-session") != "true" || success == false) {
			return;
		};
		TodoClient.announceSessionChangeNow();
	}
	static announceTodoSubmit(target, success) {
		let form = TodoClient.elementTarget(target);
		if (form == null || !form.classList.contains("todo-form") || success == false) {
			return;
		};
		TodoClient.announceCompletedCreateNow();
	}
	static announceChatSubmit(target, success) {
		let form = TodoClient.elementTarget(target);
		if (form == null || !form.classList.contains("chat-form") || success == false) {
			return;
		};
		TextAreaComposer.clear(form);
		TodoClient.announceChatChangeNow();
	}
	static announceCompletedCreate() {
		let shouldAnnounce = false;
		let savedScrollY = null;
		try {
			shouldAnnounce = window.sessionStorage.getItem("railshx.todo.just_added") == "1";
			savedScrollY = parseFloat(window.sessionStorage.getItem("railshx.todo.submit_scroll_y"));
			window.sessionStorage.removeItem("railshx.todo.just_added");
			window.sessionStorage.removeItem("railshx.todo.submit_scroll_y");
		}catch (_g) {
			if (!((Exception.caught(_g).unwrap()) instanceof Error)) {
				throw _g;
			};
		};
		if (!shouldAnnounce) {
			return;
		};
		if (savedScrollY != null && !(isNaN)(savedScrollY)) {
			TodoClient.restoreScroll(savedScrollY);
		};
		TodoClient.announceCompletedCreateNow();
	}
	static announceCompletedCreateNow() {
		let flash = window.document.querySelector("[" + "data-railshx-flash" + "]");
		if (flash != null) {
			flash.textContent = "Task added to open work";
			flash.removeAttribute("hidden");
			TodoClient.hideAfterDelay(flash, 2200);
		};
	}
	static announceSessionChange() {
		let shouldAnnounce = false;
		try {
			shouldAnnounce = window.sessionStorage.getItem("railshx.todo.session_changed") == "1";
			window.sessionStorage.removeItem("railshx.todo.session_changed");
		}catch (_g) {
			if (!((Exception.caught(_g).unwrap()) instanceof Error)) {
				throw _g;
			};
		};
		if (!shouldAnnounce) {
			return;
		};
		TodoClient.announceSessionChangeNow();
	}
	static announceSessionChangeNow() {
		let flash = window.document.querySelector("[" + "data-railshx-flash" + "]");
		if (flash != null) {
			flash.textContent = "Session updated";
			flash.removeAttribute("hidden");
			TodoClient.hideAfterDelay(flash, 2200);
		};
		let zone = window.document.querySelector("[" + "data-railshx-session-zone" + "]");
		if (zone != null) {
			zone.classList.add("is-warm");
			TodoClient.removeClassAfterDelay(zone, "is-warm", 900);
		};
	}
	static announceChatChange() {
		let shouldAnnounce = false;
		try {
			shouldAnnounce = window.sessionStorage.getItem("railshx.todo.chat_posted") == "1";
			window.sessionStorage.removeItem("railshx.todo.chat_posted");
		}catch (_g) {
			if (!((Exception.caught(_g).unwrap()) instanceof Error)) {
				throw _g;
			};
		};
		if (!shouldAnnounce) {
			return;
		};
		TodoClient.announceChatChangeNow();
	}
	static announceChatChangeNow() {
		let flash = window.document.querySelector("[" + "data-railshx-flash" + "]");
		if (flash != null) {
			flash.textContent = "Room note posted";
			flash.removeAttribute("hidden");
			TodoClient.hideAfterDelay(flash, 2200);
		};
		let panel = window.document.querySelector("#" + "railshx-chat-panel");
		if (panel != null) {
			panel.classList.add("is-warm");
			TodoClient.removeClassAfterDelay(panel, "is-warm", 900);
		};
	}
	static async hideAfterDelay(element, milliseconds) {
		await Async.delay(milliseconds);
		element.setAttribute("hidden", "hidden");
	}
	static async removeClassAfterDelay(element, className, milliseconds) {
		await Async.delay(milliseconds);
		element.classList.remove(className);
	}
	static focusAndScroll(target) {
		try {
			target.focus();
		}catch (_g) {
			if (!((Exception.caught(_g).unwrap()) instanceof Error)) {
				throw _g;
			};
		};
		target.scrollIntoView({ behavior: 'smooth', block: 'start' });
	}
	static elementTarget(target) {
		if (target == null) {
			return null;
		} else if (((target) instanceof HTMLElement)) {
			return target;
		} else {
			return null;
		};
	}
	static currentScrollY() {
		return window.scrollY || window.pageYOffset || 0;
	}
	static restoreScroll(scrollY) {
		window.scrollTo(0, scrollY);
	}
	static get __name__() {
		return "client.TodoClient"
	}
	get __class__() {
		return TodoClient
	}
}

