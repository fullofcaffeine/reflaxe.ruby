package rails.turbo;

enum abstract TurboEvent(String) to String {
	var BeforeCache = "turbo:before-cache";
	var BeforeFetchRequest = "turbo:before-fetch-request";
	var BeforeFetchResponse = "turbo:before-fetch-response";
	var BeforeFrameRender = "turbo:before-frame-render";
	var BeforeRender = "turbo:before-render";
	var BeforeStreamRender = "turbo:before-stream-render";
	var BeforeVisit = "turbo:before-visit";
	var Click = "turbo:click";
	var FrameLoad = "turbo:frame-load";
	var FrameRender = "turbo:frame-render";
	var Load = "turbo:load";
	var Render = "turbo:render";
	var SubmitEnd = "turbo:submit-end";
	var SubmitStart = "turbo:submit-start";
	var Visit = "turbo:visit";
}
