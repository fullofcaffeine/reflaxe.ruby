package unitstd_ruby;

/**
	Focused Ruby EReg checks for behavior not exhaustively named by upstream.

	The upstream fixture owns the broad Haxe contract. These assertions keep the
	Ruby bridge honest for matchSub offsets, case-insensitive flags, dot-all
	lowering, and callback-visible match state.
**/
class ERegSemantics {
	public static function run():Void {
		var caseInsensitive = ~/ruby/i;
		Assert.isTrue(caseInsensitive.match("RuBy"), "EReg i option should lower to Ruby ignorecase");

		var dotAll = new EReg("a.b", "s");
		Assert.isTrue(dotAll.match("a\nb"), "EReg s option should lower to Ruby dot-all mode");

		var sub = ~/b./;
		Assert.isTrue(sub.matchSub("abcbd", 2, 3), "EReg.matchSub should search inside the requested substring");
		var pos = sub.matchedPos();
		Assert.isTrue(pos.pos == 3, "EReg.matchSub matchedPos should be relative to the original string");
		Assert.isTrue(sub.matchedLeft() == "abc", "EReg.matchSub matchedLeft should preserve original prefix");
		Assert.isTrue(sub.matchedRight() == "", "EReg.matchSub matchedRight should preserve original suffix");

		var seen = "";
		var mapped = ~/(b)(c)/.map("abc", function(e) {
			seen = e.matched(1) + e.matched(2) + ":" + e.matchedLeft() + ":" + e.matchedRight();
			return "BC";
		});
		Assert.isTrue(mapped == "aBC", "EReg.map should replace through callback output");
		Assert.isTrue(seen == "bc:a:", "EReg.map callback should observe current match state");
	}
}
