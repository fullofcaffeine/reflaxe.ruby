import {Forms} from "railshx/rails/dom/Forms"
import {Register} from "railshx/genes/Register"

export const TextAreaComposer = Register.global("$hxClasses")["rails.hotwire.TextAreaComposer"] = 
class TextAreaComposer {
	static bindEnterSubmit(form, textareaSelector) {
		let textarea = TextAreaComposer.findTextarea(form, textareaSelector);
		if (textarea == null) {
			return;
		};
		textarea.addEventListener("keydown", function (event) {
			if (event.key != "Enter" || event.shiftKey || event.isComposing || event.repeat) {
				return;
			};
			event.preventDefault();
			Forms.requestSubmit(form);
		});
	}
	static clear(form, textareaSelector) {
		let textarea = TextAreaComposer.findTextarea(form, textareaSelector);
		if (textarea != null) {
			textarea.value = "";
		};
	}
	static findTextarea(form, textareaSelector) {
		let textarea = form.querySelector((textareaSelector == null) ? "textarea" : textareaSelector);
		if (textarea == null) {
			return null;
		} else {
			return textarea;
		};
	}
	static get __name__() {
		return "rails.hotwire.TextAreaComposer"
	}
	get __class__() {
		return TextAreaComposer
	}
}

