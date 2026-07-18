import ruby.Regexp;
import ruby.RegexpOptions;

/** Executes from the isolated installed Haxelib to prove the Regexp slice ships. **/
class RegexpPackageContract {
	public static function verify():Void {
		var expression = new Regexp("(?<word>ruby)", RegexpOptions.ignoreCase);
		var match = expression.match("Ruby");
		if (match == null || match.capture(1) != "Ruby" || match.offset(0).finish() != 4) {
			throw "packaged ruby.Regexp/MatchData contract failed";
		}
	}
}
