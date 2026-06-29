import {Register} from "railshx/genes/Register"

export const Forms = Register.global("$hxClasses")["rails.dom.Forms"] = 
class Forms {
	static requestSubmit(form) {
		let nativeForm = form;
		nativeForm.requestSubmit();
	}
	static get __name__() {
		return "rails.dom.Forms"
	}
	get __class__() {
		return Forms
	}
}

