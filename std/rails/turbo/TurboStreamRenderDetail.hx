package rails.turbo;

import js.html.Element;

typedef TurboStreamRenderDetail = {
	var ?newStream:Element;
	var ?render:Element->Void;
}
