typedef KeywordOptions = {
	var requiredLabel:String;

	@:native("retry_count")
	var retries:Int;

	@:optional
	@:native("note_text")
	var note:Null<String>;

	@:optional
	var active:Bool;
}

/**
	Executable contract for symmetric typed Ruby keyword methods.

	Required fields become normal required Ruby keywords. Optional fields remain
	in a checked `**optional_keywords` bucket so `Reflect.hasField` can distinguish
	omission from explicit null. Direct field reads do not allocate a carrier;
	`passthrough` deliberately returns the object and therefore exercises the
	documented, string-key materialization path.
**/
class KeywordShapes {
	static var assignedValue:Int = 0;

	public function new() {}

	@:rubyKwargs
	public static function describe(prefix:String, options:KeywordOptions):String {
		var note = Reflect.hasField(options, "note") ? Std.string(options.note) : "missing";
		var active = Reflect.hasField(options, "active") ? Std.string(options.active) : "missing";
		return prefix + ":" + options.requiredLabel + ":" + options.retries + ":" + note + ":" + active;
	}

	@:rubyKwargs
	public function describeInstance(options:KeywordOptions):String {
		return describe("instance", options);
	}

	@:rubyKwargs
	public static function passthrough(options:KeywordOptions):KeywordOptions {
		return options;
	}

	@:rubyKwargs
	public static function mutate(options:KeywordOptions):String {
		options.requiredLabel += "!";
		return options.requiredLabel;
	}

	@:rubyKwargs
	@:rubyBlockArg
	public static function transform<T>(options:KeywordOptions, block:String->T):T {
		return block(options.requiredLabel);
	}

	@:native("ready?")
	public static function ready():Bool {
		return true;
	}

	@:native("save!")
	public static function saveBang(value:String):String {
		return "saved:" + value;
	}

	@:native("value=")
	public static function assignValue(value:Int):Void {
		assignedValue = value;
	}

	public static function assigned():Int {
		return assignedValue;
	}
}
