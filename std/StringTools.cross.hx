package;

class StringTools {
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
		while (out.length < length) {
			out = c + out;
		}
		return out;
	}

	public static function rpad(s:String, c:String, length:Int):String {
		var out = s;
		while (out.length < length) {
			out += c;
		}
		return out;
	}

	public static function replace(s:String, sub:String, by:String):String {
		return s.split(sub).join(by);
	}

	public static function hex(n:Int, ?digits:Int):String {
		var out = "";
		var chars = "0123456789ABCDEF";
		do {
			out = chars.charAt(n & 15) + out;
			n = n >>> 4;
		} while (n > 0);
		while (digits != null && out.length < digits) {
			out = "0" + out;
		}
		return out;
	}

	public static function urlEncode(s:String):String {
		return s;
	}

	public static function urlDecode(s:String):String {
		return s;
	}

	public static function fastCodeAt(s:String, index:Int):Int {
		return s.charCodeAt(index);
	}
}
