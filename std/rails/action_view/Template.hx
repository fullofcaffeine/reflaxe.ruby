package rails.action_view;

class Template<TLocals> {
	public final templatePath:String;
	public final isExternal:Bool;

	public function new(path:String, ?isExternal:Bool = false) {
		this.templatePath = path;
		this.isExternal = isExternal;
	}

	public static function named<TLocals>(path:String):Template<TLocals> {
		return new Template(path);
	}

	public static function external<TLocals>(path:String):Template<TLocals> {
		return new Template(path, true);
	}
}
