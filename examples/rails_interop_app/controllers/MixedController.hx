package controllers;

import interop.LegacyPriceFormatter;
import rails.action_view.Template;
import rails.macros.ViewMacro;
import services.TypedStats;
import views.ApplicationLayoutView;
import views.HaxeShellView;
import views.HaxeShellView.HaxeShellLocals;

// Gradual-adoption controller.
//
// Demonstrates: a RailsHx controller rendering an HHX view while consuming an
// existing Ruby service and an existing ERB partial through typed contracts.
// Type safety: `Template.of(HaxeShellView) : Template<HaxeShellLocals>` ties the
// locals object to the view typedef; missing/wrong locals fail in Haxe.
// IntelliSense: editors should complete `LegacyPriceFormatter`, `TypedStats`,
// `ViewMacro.renderTemplateWithLayout`, and the required locals fields.
// Ruby output: a normal Rails controller action that calls Ruby constants and
// renders a Rails template/layout.
@:railsController
class MixedController extends rails.action_controller.Base {
	static final lifecycle = [];

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
