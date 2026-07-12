/** Proves that constructor kwargs use the same call and definition contract. **/

import KeywordShapes.KeywordOptions;

class KeywordConstructed {
	public final rendered:String;

	@:rubyKwargs
	public function new(options:KeywordOptions) {
		rendered = options.requiredLabel + ":" + options.retries;
	}
}
