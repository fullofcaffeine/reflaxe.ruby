import rails.action_view.HtmlNode;

class InvalidHhxMissingMain {
	static function main():Void {
		InvalidTargetView.render();
	}
}

@:railsTemplate("rooms/index")
@:railsTemplateAst("render")
@:railsDomTargets("missing-room-rows")
class InvalidTargetView {
	public static function render():HtmlNode {
		return <ul id="other-room-rows"></ul>;
	}

	// An unrelated field must not satisfy the selected `render` template proof.
	public static function unusedMarkup():HtmlNode {
		return <div id="missing-room-rows"></div>;
	}
}
