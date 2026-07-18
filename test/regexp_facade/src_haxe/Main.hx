import ruby.MatchData;
import ruby.Regexp;
import ruby.RegexpOptions;

/**
	Executable contract for native Ruby `Regexp` and `MatchData` facades.

	The sample proves closed option composition, timeout keywords, match-global
	versus side-effect-free entrypoints, indexed nullable captures, character
	offsets, named-capture inventories, and direct native value access.
**/
class Main {
	static function main():Void {
		Sys.println(Regexp.escape("a+b?"));

		var options = RegexpOptions.ignoreCase | RegexpOptions.multiline | RegexpOptions.extended;
		var expression = new Regexp(" r . b y ", options);
		Sys.println(expression.source());
		Sys.println(expression.options());
		Sys.println(expression.isCaseInsensitive());
		Sys.println(expression.hasFixedEncoding());
		Sys.println(expression.matches("R\nby"));
		Sys.println(expression.matches("xxR\nby", 2));
		Sys.println(expression.match("missing") == null);

		var named = new Regexp("(?<word>r.)(?<optional>z)?");
		Sys.println(named.names().join(","));
		Sys.println(named.namedCaptureIndexes() != null);
		var match = requireMatch(named.match("ruby"));
		Sys.println(match.toString());
		Sys.println(match.size());
		Sys.println(match.capture(0));
		Sys.println(match.capture(1));
		Sys.println(match.capture(2) == null);
		Sys.println(match.captureLength(1));
		Sys.println(match.captureLength(2) == null);
		Sys.println(match.captures().map(value -> value == null ? "null" : value).join(","));
		Sys.println(match.names().join(","));
		Sys.println(match.namedCaptures() != null);
		Sys.println(match.before());
		Sys.println(match.after());
		Sys.println(match.string());
		Sys.println(match.regexp().source());
		Sys.println(match.toArray().map(value -> value == null ? "null" : value).join(","));

		var whole = match.offset(0);
		Sys.println(whole.start());
		Sys.println(whole.finish());
		Sys.println(whole.isMatched());
		var optional = match.offset(2);
		Sys.println(optional.start() == null);
		Sys.println(optional.finish() == null);
		Sys.println(optional.isMatched());

		var offsetMatch = requireMatch(new Regexp("r.").match("xxruby", 2));
		Sys.println(offsetMatch.offset(0).start());
		Sys.println(offsetMatch.before());
		Sys.println(offsetMatch.after());

		var bounded = Regexp.compileWith("r.by", RegexpOptions.none, {timeoutSeconds: 0.25});
		Sys.println(bounded.timeoutSeconds());
		Sys.println(new Regexp("ruby").timeoutSeconds() == null);
		Sys.println(bounded.toString());
	}

	static function requireMatch(value:Null<MatchData>):MatchData {
		if (value == null) {
			throw "expected native Regexp match";
		}
		return value;
	}
}
