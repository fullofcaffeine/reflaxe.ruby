package;

import rails.action_view.HtmlNode;

/**
	Positive HHX target-ownership fixture.

	The annotation proves the shared contract target is present as a static id;
	it does not emit a runtime registry or wrapper.
**/
@:railsTemplate("rooms/index")
@:railsTemplateAst("render")
@:railsDomTargets(RoomHooks.rowsId)
class RoomView {
	public static function render():HtmlNode {
		return <main><ul id=${RoomHooks.rowsId}></ul></main>;
	}
}
