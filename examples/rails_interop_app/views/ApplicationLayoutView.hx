package views;

import rails.action_view.HtmlNode;

@:railsTemplate("layouts/application")
@:railsTemplateAst("render")
class ApplicationLayoutView {
	public static function render():HtmlNode {
		return <>
			<doctype_html />
			<html>
				<head>
					<title>RailsHx Interop</title>
					<meta name="viewport" content="width=device-width,initial-scale=1" />
					<csrf_meta_tags />
					<csp_meta_tag />
					<yield_content name="head" />
					<stylesheet_link_tag name="application" />
				</head>
				<body>
					<rails_yield />
				</body>
			</html>
		</>;
	}
}
