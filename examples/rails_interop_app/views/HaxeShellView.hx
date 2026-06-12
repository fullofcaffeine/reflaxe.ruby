package views;

import rails.action_view.HtmlNode;
import rails.action_view.Template;
import views.TypedWidgetView.TypedSummaryLocals;

typedef LegacyBadgeLocals = {
	var label:String;
	var tone:String;
}

typedef HaxeShellLocals = {
	var title:String;
	var legacyBadgeLabel:String;
	var formattedPrice:String;
	var typedSummary:String;
}

@:railsTemplate("mixed/haxe_shell")
@:railsTemplateAst("render")
class HaxeShellView {
	public static function render(locals:HaxeShellLocals):HtmlNode {
		return <main class="interop-page haxe-shell">
			<content_for name="head">
				<meta name="railshx-template" content="haxe-shell-with-legacy-rails" />
			</content_for>
			<section class="interop-hero">
				<span class="eyebrow">RailsHx gradual adoption</span>
				<h1>${locals.title}</h1>
				<p class="lede">Start with a quick Rails PoC, wrap the useful Ruby and ERB with typed Haxe contracts, then convert pieces to HHX when the shape settles.</p>
				<div class="interop-grid">
					<article class="panel">
						<span class="eyebrow">Haxe calls existing Ruby</span>
						<h2>${locals.formattedPrice}</h2>
						<p>LegacyPriceFormatter is plain Ruby. Haxe sees a typed extern and emits a normal Ruby constant call.</p>
					</article>
					<article class="panel">
						<span class="eyebrow">Haxe renders existing ERB</span>
						<partial template=${(Template.external("legacy/badge") : Template<LegacyBadgeLocals>)} locals=${{
							label: locals.legacyBadgeLabel,
							tone: "warm"
						}} />
						<p>The ERB partial is external Rails source; RailsHx type-checks the locals object before emitting the render call.</p>
					</article>
				</div>
				<partial template=${(Template.named("typed_widgets/summary") : Template<TypedSummaryLocals>)} locals=${{
					title: "HHX island rendered from Haxe",
					count: 3,
					note: locals.typedSummary
				}} />
				<a class="cta-link" href="/legacy-shell">Open the legacy ERB shell consuming Haxe</a>
			</section>
		</main>;
	}
}
