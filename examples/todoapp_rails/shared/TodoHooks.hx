package shared;

/**
	Typed behavior hooks shared by Rails HHX, Haxe-authored browser JS, and
	Playwright.

	Keep styling-only classes local to CSS/templates. Put names here when a value
	is a cross-layer contract: a slot name, selector, data attribute, storage key,
	or class/id used by browser behavior or tests.
**/
class TodoHooks {
	public static inline var headSlot:ContentSlot = "head";
	public static inline var componentBodySlot:ComponentSlot = "body";

	public static inline var templateMetaName:MetaName = "railshx-template";
	public static inline var templateMetaContent:MetaContent = "todo-index";

	public static inline var shellClass:CssClass = "todo-shell";
	public static inline var formClass:CssClass = "todo-form";
	public static inline var sessionFormClass:CssClass = "session-form";
	public static inline var sessionFooterClass:CssClass = "session-footer";
	public static inline var itemClass:CssClass = "todo-item";
	public static inline var listClass:CssClass = "todo-list";
	public static inline var dotClass:CssClass = "todo-dot";
	public static inline var flashClass:CssClass = "railshx-flash";

	public static inline var openWorkId:DomId = "open-work";
	public static inline var openWorkHref:Href = "#open-work";
	public static inline var todoListId:DomId = "railshx-todo-list";
	public static inline var sessionPanelId:DomId = "railshx-session-panel";

	public static inline var boundAttr:DataAttr = "data-railshx-bound";
	public static inline var scrollAttr:DataAttr = "data-railshx-scroll";
	public static inline var flashAttr:DataAttr = "data-railshx-flash";
	public static inline var sessionAttr:DataAttr = "data-railshx-session";
	public static inline var sessionZoneAttr:DataAttr = "data-railshx-session-zone";

	public static inline var submitStorageKey:StorageKey = "railshx.todo.just_added";
	public static inline var submitScrollStorageKey:StorageKey = "railshx.todo.submit_scroll_y";
	public static inline var sessionStorageKey:StorageKey = "railshx.todo.session_changed";

	public static inline function classSelector(value:CssClass):Selector {
		return "." + value;
	}

	public static inline function idSelector(value:DomId):Selector {
		return "#" + value;
	}

	public static inline function attrSelector(value:DataAttr):Selector {
		return "[" + value + "]";
	}

	public static inline function anchorHref(value:DomId):Href {
		return "#" + value;
	}
}

abstract CssClass(String) from String to String {}
abstract DomId(String) from String to String {}
abstract DataAttr(String) from String to String {}
abstract Selector(String) from String to String {}
abstract Href(String) from String to String {}
abstract StorageKey(String) from String to String {}
abstract ContentSlot(String) from String to String {}
abstract ComponentSlot(String) from String to String {}
abstract MetaName(String) from String to String {}
abstract MetaContent(String) from String to String {}
