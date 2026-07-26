import rails.action_view.HtmlNode;

class InvalidHhxDynamicMain {
	public static function dynamicTarget():String {
		return "room-rows";
	}

	static function main():Void {
		InvalidDynamicTargetView.render();
	}
}

@:railsTemplate("rooms/index")
@:railsTemplateAst("render")
@:railsDomTargets(InvalidHhxDynamicMain.dynamicTarget())
class InvalidDynamicTargetView {
	public static function render():HtmlNode {
		return <ul id="room-rows"></ul>;
	}
}
