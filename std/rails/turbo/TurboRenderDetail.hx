package rails.turbo;

import js.html.Element;

typedef TurboRenderDetail = {
	var ?newBody:Element;
	var ?renderMethod:String;
	var ?resume:Void->Void;
}
