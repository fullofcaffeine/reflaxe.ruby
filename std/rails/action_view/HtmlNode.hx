package rails.action_view;

/**
	Compile-time RailsHx HTML node AST.

	Embedded expressions are normal Haxe expressions, so field accesses and loop
	binders are type-checked before the compiler lowers the tree to ERB.
**/
enum HtmlNode {
	Text(value:String);
	ExprText<T>(value:T);

	Fragment(children:Array<HtmlNode>);
	Element(name:String, attrs:Array<HtmlAttr>, children:Array<HtmlNode>);

	If(cond:Bool, thenBranch:HtmlNode, elseBranch:Null<HtmlNode>);
	For<T>(items:Iterable<T>, render:T->HtmlNode);
}
