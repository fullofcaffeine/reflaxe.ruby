package rails.action_view;

/**
	Compile-time RailsHx HTML node AST.

	Embedded expressions are normal Haxe expressions, so field accesses and loop
	binders are type-checked before the compiler lowers the tree to ERB.
**/
enum HtmlNode {
	Text(value:String);
	ExprText<T>(value:T);

	DoctypeHtml;
	Fragment(children:Array<HtmlNode>);
	Element(name:String, attrs:Array<HtmlAttr>, children:Array<HtmlNode>);

	If(cond:Bool, thenBranch:HtmlNode, elseBranch:Null<HtmlNode>);
	For<T>(items:Iterable<T>, render:T->HtmlNode);
	Partial<TLocals>(template:Template<TLocals>, locals:TLocals);
	LinkTo<TLabel, TUrl>(label:TLabel, url:TUrl, attrs:Array<HtmlAttr>);
	LinkToBlock<TUrl>(url:TUrl, attrs:Array<HtmlAttr>, children:Array<HtmlNode>);
	ImageTag<TSource>(source:TSource, attrs:Array<HtmlAttr>);
	PictureTag(source:String, attrs:Array<HtmlAttr>);
	FaviconLinkTag(source:String, attrs:Array<HtmlAttr>);
	PreloadLinkTag(source:String, attrs:Array<HtmlAttr>);
	JavascriptIncludeTag(source:String, attrs:Array<HtmlAttr>);
	JavascriptTag(content:String, attrs:Array<HtmlAttr>);
	AutoDiscoveryLinkTag(feedType:String, url:String, attrs:Array<HtmlAttr>);
	AudioTag(source:String, attrs:Array<HtmlAttr>);
	VideoTag(source:String, attrs:Array<HtmlAttr>);
	MailTo<TEmail, TLabel>(email:TEmail, label:Null<TLabel>, attrs:Array<HtmlAttr>);
	PhoneTo<TLabel>(phone:String, label:Null<TLabel>, attrs:Array<HtmlAttr>);
	SmsTo<TLabel>(phone:String, label:Null<TLabel>, attrs:Array<HtmlAttr>);
	Pluralize(count:Int, singular:String, plural:Null<String>);
	SimpleFormat<TText>(text:TText, attrs:Array<HtmlAttr>);
	Truncate<TText>(text:TText, length:Null<Int>, omission:Null<String>);
	Excerpt(text:String, phrase:String, radius:Null<Int>, omission:Null<String>);
	Highlight(text:String, phrase:String, highlighter:Null<String>, sanitize:Null<Bool>);
	WordWrap(text:String, lineWidth:Null<Int>, breakSequence:Null<String>);
	Sanitize(html:String, tags:Null<Array<String>>, attributes:Null<Array<String>>);
	SanitizeCss(style:String);
	StripTags(html:String);
	StripLinks(html:String);
	ToSentence(items:Array<String>, wordsConnector:Null<String>, twoWordsConnector:Null<String>, lastWordConnector:Null<String>);
	EscapeOnce(html:String);
	CdataSection(content:String);
	SafeJoin(items:Array<String>, separator:Null<String>);
	TokenList(tokens:Array<String>);
	ClassNames(tokens:Array<String>);
	Cycle(values:Array<String>, name:Null<String>);
	CurrentCycle(name:Null<String>);
	ResetCycle(name:Null<String>);
	TimeAgoInWords(fromTime:Date, includeSeconds:Null<Bool>);
	DistanceOfTimeInWords(fromTime:Date, toTime:Date, includeSeconds:Null<Bool>);
	TimeTag<TLabel>(time:Date, label:Null<TLabel>, attrs:Array<HtmlAttr>);
	NumberToCurrency(number:Float, unit:Null<String>, precision:Null<Int>);
	NumberToPercentage(number:Float, precision:Null<Int>);
	NumberToHuman(number:Float, precision:Null<Int>);
	NumberToHumanSize(number:Float, precision:Null<Int>);
	NumberWithPrecision(number:Float, precision:Null<Int>, significant:Null<Bool>, delimiter:Null<String>, separator:Null<String>,
		stripInsignificantZeros:Null<Bool>);
	NumberWithDelimiter(number:Float, delimiter:Null<String>, separator:Null<String>);
	NumberToDelimited(number:Float, delimiter:Null<String>, separator:Null<String>);
	NumberToPhone(number:String, areaCode:Null<Bool>, delimiter:Null<String>, extension:Null<String>, countryCode:Null<Int>);
	ButtonTag(content:String, attrs:Array<HtmlAttr>);
	SubmitTag(value:String, attrs:Array<HtmlAttr>);
	// Rails `button_to` has both normal and block forms. Keeping separate AST
	// nodes lets HHX lower simple labels to `button_to "Label", path` and
	// nested markup to `button_to path do ... end` without runtime wrappers.
	ButtonTo<TLabel, TUrl>(label:TLabel, url:TUrl, attrs:Array<HtmlAttr>);
	ButtonToBlock<TUrl>(url:TUrl, attrs:Array<HtmlAttr>, children:Array<HtmlNode>);
	CsrfMetaTags;
	CspMetaTag;
	StylesheetLinkTag(name:String, attrs:Array<HtmlAttr>);
	JavascriptImportmapTags;
	TurboStreamFrom<TPayload>(stream:rails.turbo.StreamName<TPayload>);
	// HHX authors write `<turbo_frame id=...>` because Haxe identifiers cannot
	// naturally use Rails' dash tag spelling. The compiler erases this node to
	// a normal `<turbo-frame>` element, preserving standard Hotwire behavior.
	TurboFrame<TId>(id:TId, attrs:Array<HtmlAttr>, children:Array<HtmlNode>);
	Yield;
	FormWith<TUrl>(url:TUrl, scope:String, attrs:Array<HtmlAttr>, children:Array<HtmlNode>);
	FormHiddenField<TValue>(name:String, value:TValue);
	FormLabel<TText>(name:String, text:TText, attrs:Array<HtmlAttr>);
	FormTextField(name:String, attrs:Array<HtmlAttr>);
	FormPasswordField(name:String, attrs:Array<HtmlAttr>);
	FormFileField(name:String, attrs:Array<HtmlAttr>);
	FormTextArea(name:String, attrs:Array<HtmlAttr>);
	FormCheckBox(name:String, attrs:Array<HtmlAttr>);
	FormSubmit<TText>(text:TText, attrs:Array<HtmlAttr>);
	ContentFor(name:String, children:Array<HtmlNode>);
	YieldContent(name:String);
	Component<TLocals>(template:Template<TLocals>, locals:TLocals, slotName:String, children:Array<HtmlNode>);
	ComponentRef<TLocals>(component:Component<TLocals>, locals:TLocals, children:Array<HtmlNode>);
}
