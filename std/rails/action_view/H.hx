package rails.action_view;

#if macro
import haxe.macro.Context;
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

	public static macro function imageTag(source:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.ImageTag($source, $attrs);
	}

	public static macro function mailTo(email:Expr, label:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.MailTo($email, $label, $attrs);
	}

	public static macro function pluralize(count:Expr, singular:Expr, plural:Expr):Expr {
		return macro rails.action_view.HtmlNode.Pluralize($count, $singular, $plural);
	}

	public static macro function simpleFormat(text:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.SimpleFormat($text, $attrs);
	}

	public static macro function truncate(text:Expr, length:Expr, omission:Expr):Expr {
		return macro rails.action_view.HtmlNode.Truncate($text, $length, $omission);
	}

	public static macro function excerpt(text:Expr, phrase:Expr, radius:Expr, omission:Expr):Expr {
		return macro rails.action_view.HtmlNode.Excerpt($text, $phrase, $radius, $omission);
	}

	public static macro function highlight(text:Expr, phrase:Expr, highlighter:Expr, sanitize:Expr):Expr {
		return macro rails.action_view.HtmlNode.Highlight($text, $phrase, $highlighter, $sanitize);
	}

	public static macro function wordWrap(text:Expr, lineWidth:Expr, breakSequence:Expr):Expr {
		return macro rails.action_view.HtmlNode.WordWrap($text, $lineWidth, $breakSequence);
	}

	public static macro function stripTags(html:Expr):Expr {
		return macro rails.action_view.HtmlNode.StripTags($html);
	}

	public static macro function stripLinks(html:Expr):Expr {
		return macro rails.action_view.HtmlNode.StripLinks($html);
	}

	public static macro function toSentence(items:Expr, wordsConnector:Expr, twoWordsConnector:Expr, lastWordConnector:Expr):Expr {
		return macro rails.action_view.HtmlNode.ToSentence($items, $wordsConnector, $twoWordsConnector, $lastWordConnector);
	}

	public static macro function escapeOnce(html:Expr):Expr {
		return macro rails.action_view.HtmlNode.EscapeOnce($html);
	}

	public static macro function cdataSection(content:Expr):Expr {
		return macro rails.action_view.HtmlNode.CdataSection($content);
	}

	public static macro function safeJoin(items:Expr, separator:Expr):Expr {
		return macro rails.action_view.HtmlNode.SafeJoin($items, $separator);
	}

	public static macro function timeAgoInWords(fromTime:Expr, includeSeconds:Expr):Expr {
		return macro rails.action_view.HtmlNode.TimeAgoInWords($fromTime, $includeSeconds);
	}

	public static macro function distanceOfTimeInWords(fromTime:Expr, toTime:Expr, includeSeconds:Expr):Expr {
		return macro rails.action_view.HtmlNode.DistanceOfTimeInWords($fromTime, $toTime, $includeSeconds);
	}

	public static macro function timeTag(time:Expr, label:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.TimeTag($time, $label, $attrs);
	}

	public static macro function numberToCurrency(number:Expr, unit:Expr, precision:Expr):Expr {
		return macro rails.action_view.HtmlNode.NumberToCurrency($number, $unit, $precision);
	}

	public static macro function numberToPercentage(number:Expr, precision:Expr):Expr {
		return macro rails.action_view.HtmlNode.NumberToPercentage($number, $precision);
	}

	public static macro function numberToHuman(number:Expr, precision:Expr):Expr {
		return macro rails.action_view.HtmlNode.NumberToHuman($number, $precision);
	}

	public static macro function numberToHumanSize(number:Expr, precision:Expr):Expr {
		return macro rails.action_view.HtmlNode.NumberToHumanSize($number, $precision);
	}

	public static macro function numberWithPrecision(number:Expr, precision:Expr, significant:Expr, delimiter:Expr, separator:Expr,
			stripInsignificantZeros:Expr):Expr {
		return macro rails.action_view.HtmlNode.NumberWithPrecision($number, $precision, $significant, $delimiter, $separator, $stripInsignificantZeros);
	}

	public static macro function numberWithDelimiter(number:Expr, delimiter:Expr, separator:Expr):Expr {
		return macro rails.action_view.HtmlNode.NumberWithDelimiter($number, $delimiter, $separator);
	}

	public static macro function numberToDelimited(number:Expr, delimiter:Expr, separator:Expr):Expr {
		return macro rails.action_view.HtmlNode.NumberToDelimited($number, $delimiter, $separator);
	}

	public static macro function numberToPhone(number:Expr, areaCode:Expr, delimiter:Expr, extension:Expr, countryCode:Expr):Expr {
		return macro rails.action_view.HtmlNode.NumberToPhone($number, $areaCode, $delimiter, $extension, $countryCode);
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

	public static macro function fileField(name:Expr, attrs:Expr):Expr {
		return macro rails.action_view.HtmlNode.FormFileField($name, $attrs);
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

	/**
		Checked `data-*` attribute helper for lower-level `H.*` template code.

		HHX markup can write `data-turbo-frame="..."` directly. This macro gives
		manual `HtmlNode` authors the same Rails-facing output without repeating the
		`data-` prefix or leaking unchecked hook strings. The suffix must be a
		literal so Haxe can validate it before the Ruby compiler lowers helper attrs.
	**/
	public static macro function data(name:Expr, value:Expr):Expr {
		return prefixedAttr("data", name, value, StaticAttr);
	}

	public static macro function dataBool(name:Expr):Expr {
		return prefixedAttr("data", name, null, BoolAttr);
	}

	public static macro function dataExpr(name:Expr, value:Expr):Expr {
		return prefixedAttr("data", name, value, ExprAttr);
	}

	/**
		Checked `aria-*` attribute helper for lower-level `H.*` template code.

		Use this when a template is authored with explicit `HtmlNode` values instead
		of inline HHX. Keeping the suffix literal catches malformed accessibility
		attributes during Haxe compilation while emitting normal HTML/Rails output.
	**/
	public static macro function aria(name:Expr, value:Expr):Expr {
		return prefixedAttr("aria", name, value, StaticAttr);
	}

	public static macro function ariaBool(name:Expr):Expr {
		return prefixedAttr("aria", name, null, BoolAttr);
	}

	public static macro function ariaExpr(name:Expr, value:Expr):Expr {
		return prefixedAttr("aria", name, value, ExprAttr);
	}

	public static macro function role(value:Expr):Expr {
		return macro rails.action_view.HtmlAttr.Static("role", $value);
	}

	#if macro
	static function prefixedAttr(prefix:String, name:Expr, value:Null<Expr>, kind:CheckedAttrKind):Expr {
		var fullName = prefix + "-" + checkedAttrSuffix(prefix, name);
		return switch (kind) {
			case StaticAttr:
				macro rails.action_view.HtmlAttr.Static($v{fullName}, $value);
			case BoolAttr:
				macro rails.action_view.HtmlAttr.Bool($v{fullName});
			case ExprAttr:
				macro rails.action_view.HtmlAttr.Expr($v{fullName}, $value);
		}
	}

	static function checkedAttrSuffix(prefix:String, name:Expr):String {
		var suffix = switch (name.expr) {
			case EConst(CString(value, _)):
				value;
			default:
				Context.error('H.$prefix(...) expects a literal suffix such as "$prefix(\"live\", ...)"; dynamic attribute names must use H.attr(...) explicitly.',
					name.pos);
				return "";
		}
		if (StringTools.startsWith(suffix, prefix + "-")) {
			Context.error('H.$prefix(...) expects the suffix only. Use H.$prefix("${suffix.substr(prefix.length + 1)}", ...) instead of "$suffix".', name.pos);
		}
		var normalized = StringTools.replace(suffix, "_", "-");
		if (!isSafeAttrSuffix(normalized)) {
			Context.error('Invalid $prefix-* attribute suffix "$suffix". Use lowercase letters, digits, and dashes, starting with a letter.', name.pos);
		}
		return normalized;
	}

	static function isSafeAttrSuffix(value:String):Bool {
		if (value == null || value.length == 0) {
			return false;
		}
		for (i in 0...value.length) {
			var code = value.charCodeAt(i);
			var lower = code >= "a".code && code <= "z".code;
			var digit = code >= "0".code && code <= "9".code;
			var dash = code == "-".code;
			if (i == 0) {
				if (!lower) {
					return false;
				}
			} else if (!lower && !digit && !dash) {
				return false;
			}
		}
		return true;
	}
	#end
}

#if macro
private enum CheckedAttrKind {
	StaticAttr;
	BoolAttr;
	ExprAttr;
}
#end
