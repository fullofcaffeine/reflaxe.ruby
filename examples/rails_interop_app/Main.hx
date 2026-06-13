import controllers.MixedController;
import services.TypedStats;
import views.ApplicationLayoutView;
import views.HaxeShellView;
import views.TypedWidgetView;

// Mixed Rails/RailsHx adoption smoke entrypoint.
//
// Demonstrates: one app combining existing Ruby/ERB, typed Haxe services, HHX
// views, and RailsHx controllers.
// Type safety: imports resolve each generated Haxe/RailsHx surface before the
// Rails app is materialized; `TypedStats.summary` is checked as a typed service.
// IntelliSense: editors should complete controller/view/service classes and
// service method signatures.
// Ruby output: generated constants under the Rails output root that legacy Ruby
// can call/render like normal Rails code.
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
