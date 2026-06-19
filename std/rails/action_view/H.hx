package rails.action_view;

#if macro
import haxe.macro.Expr;
#end

/**
	Ergonomic RailsHx template helpers.

	Each macro expands to `HtmlNode`/`HtmlAttr` constructors, so template bodies
	stay type-checked Haxe while the Ruby compiler still lowers a structured AST
	into Rails-native ERB.
**/
class H {
	public static macro function text(value:Expr):Expr {
		return macro rails.action_view.HtmlNode.Text($value);
	}

	public static macro function expr(value:Expr):Expr {
		return macro rails.action_view.HtmlNode.ExprText($value);
	}

	public static macro function doctypeHtml():Expr {
		return macro rails.action_view.HtmlNode.DoctypeHtml;
	}

	public static macro function fragment(children:Expr):Expr {
		return macro rails.action_view.HtmlNode.Fragment($children);
	}

	public static macro function el(name:Expr, attrs:Expr, children:Expr):Expr {
		return macro rails.action_view.HtmlNode.Element($name, $attrs, $children);
	}

	public static macro function when(cond:Expr, thenBranch:Expr, elseBranch:Expr):Expr {
		return macro rails.action_view.HtmlNode.If($cond, $thenBranch, $elseBranch);
	}

	public static macro function each(items:Expr, render:Expr):Expr {
		return macro rails.action_view.HtmlNode.For($items, $render);
	}

	public static macro function partial(template:Expr, locals:Expr):Expr {
		return macro rails.action_view.HtmlNode.Partial($template, $locals);
	}

	public static macro function component(template:Expr, locals:Expr, slotName:Expr, children:Expr):Expr {
		return macro rails.action_view.HtmlNode.Component($template, $locals, $slotName, $children);
	}

	public static macro function componentRef(component:Expr, locals:Expr, children:Expr):Expr {
		return macro rails.action_view.HtmlNode.ComponentRef($component, $locals, $children);
	}

	public static macro function linkTo(label:Expr, url:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.LinkTo($label, $url, $attrs);
	}

	public static macro function linkBlock(url:Expr, attrs:Expr, children:Expr):Expr {
		return macro rails.action_view.HtmlNode.LinkToBlock($url, $attrs, $children);
	}

	public static macro function buttonTo(label:Expr, url:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.ButtonTo($label, $url, $attrs);
	}

	public static macro function buttonBlock(url:Expr, attrs:Expr, children:Expr):Expr {
		return macro rails.action_view.HtmlNode.ButtonToBlock($url, $attrs, $children);
	}

	public static macro function csrfMetaTags():Expr {
		return macro rails.action_view.HtmlNode.CsrfMetaTags;
	}

	public static macro function cspMetaTag():Expr {
		return macro rails.action_view.HtmlNode.CspMetaTag;
	}

	public static macro function stylesheetLinkTag(name:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.StylesheetLinkTag($name, $attrs);
	}

	public static macro function javascriptImportmapTags():Expr {
		return macro rails.action_view.HtmlNode.JavascriptImportmapTags;
	}

	public static macro function yieldContent():Expr {
		return macro rails.action_view.HtmlNode.Yield;
	}

	public static macro function contentFor(name:Expr, children:Expr):Expr {
		return macro rails.action_view.HtmlNode.ContentFor($name, $children);
	}

	public static macro function yieldContentNamed(name:Expr):Expr {
		return macro rails.action_view.HtmlNode.YieldContent($name);
	}

	public static macro function formWith(url:Expr, scope:Expr, attrs:Expr, children:Expr):Expr {
		return macro rails.action_view.HtmlNode.FormWith($url, $scope, $attrs, $children);
	}

	public static macro function hiddenField(name:Expr, value:Expr):Expr {
		return macro rails.action_view.HtmlNode.FormHiddenField($name, $value);
	}

	public static macro function label(name:Expr, text:Expr):Expr {
		return macro rails.action_view.HtmlNode.FormLabel($name, $text, []);
	}

	public static macro function textField(name:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.FormTextField($name, $attrs);
	}

	public static macro function passwordField(name:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.FormPasswordField($name, $attrs);
	}

	public static macro function textArea(name:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.FormTextArea($name, $attrs);
	}

	public static macro function checkBox(name:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.FormCheckBox($name, $attrs);
	}

	public static macro function submit(text:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.FormSubmit($text, $attrs);
	}

	public static macro function attr(name:Expr, value:Expr):Expr {
		return macro rails.action_view.HtmlAttr.Static($name, $value);
	}

	public static macro function className(value:Expr):Expr {
		return macro rails.action_view.HtmlAttr.Static("class", $value);
	}

	public static macro function boolAttr(name:Expr):Expr {
		return macro rails.action_view.HtmlAttr.Bool($name);
	}

	public static macro function attrExpr(name:Expr, value:Expr):Expr {
		return macro rails.action_view.HtmlAttr.Expr($name, $value);
	}
}
