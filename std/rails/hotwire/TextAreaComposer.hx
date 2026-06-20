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
		textarea.addEventListener("keydown", function(event:KeyboardEvent):Void {
			if (event.key != "Enter" || event.shiftKey || event.isComposing || event.repeat) {
				return;
			}
			event.preventDefault();
			// This is the same shape a small vanilla Hotwire enhancement would
			// use: intercept Enter before the textarea inserts a newline, then
			// ask the browser to submit the real form. Shift+Enter is untouched,
			// so the browser keeps owning multiline text editing.
			// requestSubmit preserves validation, Rails CSRF, Turbo form
			// submission, and turbo:submit-* events.
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
