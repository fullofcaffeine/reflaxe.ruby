package rails.action_view;

/**
	Compile-time RailsHx HTML attribute AST.

	These constructors are consumed by the Ruby compiler when a
	`@:railsTemplateAst(...)` method is used. They are not intended to be
	allocated by generated Ruby at runtime.
**/
enum HtmlAttr {
	Static(name:String, value:String);
	Bool(name:String);
	Expr<T>(name:String, value:T);
}
