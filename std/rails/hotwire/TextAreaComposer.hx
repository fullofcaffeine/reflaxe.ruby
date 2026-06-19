package rails.hotwire;

import js.html.Element;
import js.html.KeyboardEvent;
import js.html.TextAreaElement;
import rails.dom.Forms;

class TextAreaComposer {
	public static function bindEnterSubmit(form:Element, ?textareaSelector:String):Void {
		var textarea = findTextarea(form, textareaSelector);
		if (textarea == null) {
			return;
		}
		var submitOnKeyUp = false;
		textarea.addEventListener("keydown", function(event:KeyboardEvent):Void {
			if (event.key != "Enter" || event.shiftKey || event.isComposing) {
				return;
			}
			event.preventDefault();
			submitOnKeyUp = true;
		});
		textarea.addEventListener("keyup", function(event:KeyboardEvent):Void {
			if (!submitOnKeyUp || event.key != "Enter") {
				return;
			}
			submitOnKeyUp = false;
			// This preserves the normal Hotwire path: browser validation,
			// Rails CSRF, Turbo form submission, and turbo:submit-* events.
			Forms.requestSubmit(cast form);
		});
	}

	public static function clear(form:Element, ?textareaSelector:String):Void {
		var textarea = findTextarea(form, textareaSelector);
		if (textarea != null) {
			textarea.value = "";
		}
	}

	static function findTextarea(form:Element, ?textareaSelector:String):Null<TextAreaElement> {
		var textarea = form.querySelector(textareaSelector == null ? "textarea" : textareaSelector);
		return textarea == null ? null : cast textarea;
	}
}
