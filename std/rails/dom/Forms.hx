package rails.dom;

import js.html.FormElement;

class Forms {
	public static function requestSubmit(form:FormElement):Void {
		var nativeForm:RequestSubmitFormElement = cast form;
		nativeForm.requestSubmit();
	}
}

// Haxe 4.3.7's DOM externs do not expose HTMLFormElement.requestSubmit yet.
// Keep the missing browser API in one typed RailsHx DOM facade so app code can
// call normal Hotwire/browser behavior without raw `js.Syntax.code(...)`.

@:native("HTMLFormElement")
private extern class RequestSubmitFormElement extends FormElement {
	public function requestSubmit():Void;
}
