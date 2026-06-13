package views;

import rails.action_view.HtmlNode;

// Todoapp layout authored as typed HHX.
//
// Demonstrates: Rails layout helpers as HHX tags (`csrf_meta_tags`,
// `stylesheet_link_tag`, `javascript_importmap_tags`, `rails_yield`) instead of
// hand-written ERB strings.
// Type safety: `render()` must return `HtmlNode`, helper tags are recognized by
// the Rails HHX macro, and this class is checked by `Template.layout(...)`.
// IntelliSense: editors should complete `ApplicationLayoutView` as a layout
// class and expose Haxe symbols used inside embedded expressions.
// Ruby/Rails output: `app/views/layouts/application.html.erb`.
@:railsTemplate("layouts/application")
@:railsTemplateAst("render")
class ApplicationLayoutView {
	public static function render():HtmlNode {
		return <>
			<doctype_html />
			<html>
				<head>
					<title>RailsHx Todoapp</title>
					<meta name="viewport" content="width=device-width,initial-scale=1" />
					<csrf_meta_tags />
					<csp_meta_tag />
					<yield_content name="head" />
					<stylesheet_link_tag name="application" data-turbo-track="reload" />
					<javascript_importmap_tags />
				</head>
				<body>
					<rails_yield />
				</body>
			</html>
		</>;
	}
}
