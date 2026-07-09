package;

@:rubyRequire("cgi")
@:rubyRequire("uri")
class StringTools {
	public static function htmlEscape(s:String, ?quotes:Bool = false):String {
		return quotes ? untyped __ruby__("{0}.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub(34.chr, '&quot;').gsub(39.chr, '&#039;')",
			s) : untyped __ruby__("{0}.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')", s);
	}

	public static function htmlUnescape(s:String):String {
		return untyped __ruby__("{0}.to_s.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&quot;', 34.chr).gsub('&#039;', 39.chr).gsub('&amp;', '&')", s);
	}

	public static function contains(s:String, value:String):Bool {
		return s.indexOf(value) != -1;
	}

	public static function startsWith(s:String, start:String):Bool {
		return s.length >= start.length && s.substr(0, start.length) == start;
	}

	public static function endsWith(s:String, end:String):Bool {
		var start = s.length - end.length;
		return start >= 0 && s.substr(start, end.length) == end;
	}

	public static function isSpace(s:String, pos:Int):Bool {
		var c = s.charCodeAt(pos);
		return (c > 8 && c < 14) || c == 32;
	}

	public static function ltrim(s:String):String {
		var i = 0;
		while (i < s.length && isSpace(s, i)) {
			i++;
		}
		return i == 0 ? s : s.substr(i);
	}

	public static function rtrim(s:String):String {
		var i = s.length - 1;
		while (i >= 0 && isSpace(s, i)) {
			i--;
		}
		return i == s.length - 1 ? s : s.substr(0, i + 1);
	}

	public static function trim(s:String):String {
		return ltrim(rtrim(s));
	}

	public static function lpad(s:String, c:String, length:Int):String {
		var out = s;
		if (c == "") {
			return out;
		}
		while (out.length < length) {
			out = c + out;
		}
		return out;
	}

	public static function rpad(s:String, c:String, length:Int):String {
		var out = s;
		if (c == "") {
			return out;
		}
		while (out.length < length) {
			out += c;
		}
		return out;
	}

	public static function replace(s:String, sub:String, by:String):String {
		return
			untyped __ruby__("(begin string = {0}.to_s; needle = {1}.to_s; by = {2}.to_s; if needle.empty?; by.empty? ? string : string.each_char.to_a.join(by); else string.gsub(needle) { by }; end end)",
			s, sub, by);
	}

	public static function hex(n:Int, ?digits:Int):String {
		return
			untyped __ruby__("(->(value, digits) { out = (value.to_i & 0xffffffff).to_s(16).upcase; digits.nil? ? out : out.rjust(digits.to_i, '0') }).call({0}, {1})",
				n,
			digits);
	}

	public static function urlEncode(s:String):String {
		return untyped __ruby__("URI.encode_www_form_component({0}.to_s)", s);
	}

	public static function urlDecode(s:String):String {
		return untyped __ruby__("CGI.unescape({0}.to_s)", s);
	}

	public static function fastCodeAt(s:String, index:Int):Int {
		return s.charCodeAt(index);
	}

	public static inline function unsafeCodeAt(s:String, index:Int):Int {
		return fastCodeAt(s, index);
	}

	public static function isEof(c:Null<Int>):Bool {
		return c == null || c == 0;
	}

	// The Ruby compiler lowers these Haxe iterator facades to HXRuby runtime
	// iterators so generated code can keep Haxe's has_next/next_ loop shape.
	public static function iterator(s:String):Iterator<Int> {
		return cast null;
	}

	public static function keyValueIterator(s:String):KeyValueIterator<Int, Int> {
		return cast null;
	}

	// Upstream Haxe string iterators use @:access(StringTools) to share this
	// private UTF-16 helper surface with target-specific StringTools overrides.
	static inline var MIN_SURROGATE_CODE_POINT = 65536;

	static inline function utf16CodePointAt(s:String, index:Int):Int {
		var c = fastCodeAt(s, index);
		if (c >= 0xD800 && c <= 0xDBFF) {
			c = ((c - 0xD7C0) << 10) | (fastCodeAt(s, index + 1) & 0x3FF);
		}
		return c;
	}
}
