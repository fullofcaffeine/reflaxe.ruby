package rails.action_view;

class Template<TLocals> {
	public final templatePath:String;

	public function new(path:String) {
		this.templatePath = path;
	}

	public static function named<TLocals>(path:String):Template<TLocals> {
		return new Template(path);
	}
}
