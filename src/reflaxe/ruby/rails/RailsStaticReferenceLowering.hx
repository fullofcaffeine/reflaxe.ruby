package reflaxe.ruby.rails;

import reflaxe.ruby.ast.RubyAST.RubyExpr;

/**
	Owns structural Ruby expressions for Rails static token facades.

	These mappings are Rails API policy rather than general Ruby reference
	syntax, so they stay in the Rails layer. The compiler supplies only the
	resolved Haxe type and field names; this service returns ordinary RubyAST and
	never depends back on the orchestration root or printer.
**/
class RailsStaticReferenceLowering {
	public static function token(typeName:String, fieldName:String):Null<RubyExpr> {
		return switch (typeName) {
			case "rails.action_controller.Mime":
				switch (fieldName) {
					case "html" | "get_html": RubyIndex(RubyConstantPath("Mime"), RubySymbol("html"));
					case "json" | "get_json": RubyIndex(RubyConstantPath("Mime"), RubySymbol("json"));
					case "turboStream" | "get_turboStream": RubyIndex(RubyConstantPath("Mime"), RubySymbol("turbo_stream"));
					case "xml" | "get_xml": RubyIndex(RubyConstantPath("Mime"), RubySymbol("xml"));
					case "all" | "get_all": RubyConstantPath("Mime::ALL");
					case _: null;
				}
			case "rails.action_controller.RequestVariantToken":
				switch (fieldName) {
					case "phone" | "get_phone": RubySymbol("phone");
					case "tablet" | "get_tablet": RubySymbol("tablet");
					case "desktop" | "get_desktop": RubySymbol("desktop");
					case "nativeApp" | "get_nativeApp": RubySymbol("native_app");
					case _: null;
				}
			case _: null;
		}
	}
}
