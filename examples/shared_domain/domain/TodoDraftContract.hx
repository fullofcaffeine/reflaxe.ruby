package domain;

/** A normalized todo draft that is safe to pass to a target-specific edge. */
typedef TodoDraft = {
	var title:String;
	var priority:Int;
}

/**
	Closed validation failures shared by server-side Ruby and browser JavaScript.

	The constructors carry stable machine-readable data instead of localized
	messages. Rails and the browser remain free to present those errors in the
	framework-native way that fits each target.
**/
enum TodoDraftError {
	TitleRequired;
	TitleTooLong(actual:Int, maximum:Int);
	PriorityOutOfRange(actual:Int, minimum:Int, maximum:Int);
}

/** A draft is either normalized and accepted or rejected with ordered errors. */
enum TodoDraftResult {
	Accepted(draft:TodoDraft);
	Rejected(errors:Array<TodoDraftError>);
}

/**
	Pure todo-draft behavior compiled unchanged to Ruby and JavaScript.

	This contract deliberately owns only deterministic normalization, validation,
	and wire serialization. Rails params/database work and browser DOM/network
	work stay in target-specific modules at the edges.
**/
class TodoDraftContract {
	public static inline var minimumPriority:Int = 1;
	public static inline var maximumPriority:Int = 3;
	public static inline var maximumTitleUnits:Int = 80;

	static final leadingFormWhitespace:EReg = ~/^[ \t\r\n]+/;
	// `(?![\s\S])` means true end-of-input on both targets. Ruby's `$` also
	// matches before an embedded newline, which would trim the wrong run here.
	static final trailingFormWhitespace:EReg = ~/[ \t\r\n]+(?![\s\S])/;
	static final repeatedFormWhitespace:EReg = ~/[ \t\r\n]+/g;

	/** Normalizes and validates one draft while preserving stable error order. */
	public static function evaluate(rawTitle:String, priority:Int):TodoDraftResult {
		var title = normalizeTitle(rawTitle);
		var errors:Array<TodoDraftError> = [];
		var titleUnits = utf16Length(title);

		if (titleUnits == 0) {
			errors.push(TitleRequired);
		} else if (titleUnits > maximumTitleUnits) {
			errors.push(TitleTooLong(titleUnits, maximumTitleUnits));
		}

		if (priority < minimumPriority || priority > maximumPriority) {
			errors.push(PriorityOutOfRange(priority, minimumPriority, maximumPriority));
		}

		return errors.length == 0 ? Accepted({title: title, priority: priority}) : Rejected(errors);
	}

	/**
		Encodes the closed result model with deterministic field and error ordering.

		`haxe.Json` is confined to quoting already-typed strings; it never becomes
		an open object boundary. Parsing transport input remains target-owned.
	**/
	public static function encode(result:TodoDraftResult):String {
		return switch (result) {
			case Accepted(draft):
				'{"status":"accepted","draft":{"title":${quote(draft.title)},"priority":${draft.priority}}}';
			case Rejected(errors):
				'{"status":"rejected","errors":[${[for (error in errors) encodeError(error)].join(",")}]}';
		};
	}

	/**
		Collapses ASCII form whitespace and trims it without changing other text.

		The regex owns only four explicit ASCII characters, avoiding differences in
		target-native definitions of broad classes such as `\\s`.
	**/
	public static function normalizeTitle(value:String):String {
		var withoutLeading = leadingFormWhitespace.replace(value, "");
		var trimmed = trailingFormWhitespace.replace(withoutLeading, "");
		return repeatedFormWhitespace.replace(trimmed, " ");
	}

	static function utf16Length(value:String):Int {
		var iterator = StringTools.iterator(value);
		var length = 0;
		while (iterator.hasNext()) {
			iterator.next();
			length++;
		}
		return length;
	}

	static function encodeError(error:TodoDraftError):String {
		return switch (error) {
			case TitleRequired:
				'{"field":"title","code":"required"}';
			case TitleTooLong(actual, maximum):
				'{"field":"title","code":"too_long","actual":${actual},"maximum":${maximum}}';
			case PriorityOutOfRange(actual, minimum, maximum):
				'{"field":"priority","code":"out_of_range","actual":${actual},"minimum":${minimum},"maximum":${maximum}}';
		};
	}

	static function quote(value:String):String {
		return haxe.Json.stringify(value);
	}
}
