package controllers;

import interop.LegacyPriceFormatter;
import rails.action_view.Template;
import rails.macros.ViewMacro;
import services.TypedStats;
import views.ApplicationLayoutView;
import views.HaxeShellView;
import views.HaxeShellView.HaxeShellLocals;

@:railsController
class MixedController extends rails.action_controller.Base {
	public function haxeShell() {
		var surfaces = ["legacy ERB partial", "typed Haxe service", "RailsHx HHX partial"];
		ViewMacro.renderTemplateWithLayout(this, (Template.of(HaxeShellView) : Template<HaxeShellLocals>), {
			title: "Haxe shell, legacy Rails parts.",
			legacyBadgeLabel: LegacyPriceFormatter.badgeLabel("poc", 1299),
			formattedPrice: LegacyPriceFormatter.call(1299),
			typedSummary: TypedStats.summary(surfaces)
		}, Template.layout(ApplicationLayoutView));
	}
}
