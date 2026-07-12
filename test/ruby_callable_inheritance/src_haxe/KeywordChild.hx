/** Keyword override and `super` forwarding both inherit the base ABI. **/
class KeywordChild extends KeywordBase {
	public function new() {
		super();
	}

	override public function configure(options:CallableOptions):String {
		return "child:" + super.configure(options);
	}
}
