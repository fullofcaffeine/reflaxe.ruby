import {Register} from "railshx/genes/Register"

export const Turbo = Register.global("$hxClasses")["rails.turbo.Turbo"] = 
class Turbo {
	static on(event, handler, document) {
		((document == null) ? window.document : document).addEventListener(event, handler);
	}
	static onTyped(event, handler, document) {
		Turbo.on(event, function (event) {
			handler(event);
		}, document);
	}
	static onLoad(handler) {
		Turbo.on("turbo:load", handler);
	}
	static onBeforeFetchRequest(handler) {
		Turbo.onTyped("turbo:before-fetch-request", handler);
	}
	static addFetchRequestHeader(event, name, value) {
		if (event.detail.fetchOptions != null) {
			event.detail.fetchOptions.headers = Object.assign({}, event.detail.fetchOptions.headers || {}, Turbo.headerObject(name,value));
		};
	}
	static onSubmitStart(handler) {
		Turbo.on("turbo:submit-start", function (event) {
			handler(event);
		});
	}
	static onSubmitEnd(handler) {
		Turbo.on("turbo:submit-end", function (event) {
			handler(event);
		});
	}
	static headerObject(name, value) {
		return ({ [name]: value });
	}
	static get __name__() {
		return "rails.turbo.Turbo"
	}
	get __class__() {
		return Turbo
	}
}

