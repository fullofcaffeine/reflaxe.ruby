import controllers.MixedController;
import services.TypedStats;
import views.ApplicationLayoutView;
import views.HaxeShellView;
import views.TypedWidgetView;

class Main {
	static function main() {
		var controller:MixedController = null;
		var layoutView:Class<ApplicationLayoutView> = ApplicationLayoutView;
		var shellView:Class<HaxeShellView> = HaxeShellView;
		var widgetView:Class<TypedWidgetView> = TypedWidgetView;
		Sys.println(controller == null);
		Sys.println(layoutView != null);
		Sys.println(shellView != null);
		Sys.println(widgetView != null);
		Sys.println(TypedStats.summary(["legacy Ruby", "typed Haxe"]));
	}
}
