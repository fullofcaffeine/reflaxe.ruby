package reflaxe.ruby.naming;

class RubyNaming {
	static final RESERVED_KEYWORDS = [
		"BEGIN",
		"END",
		"alias",
		"and",
		"begin",
		"break",
		"case",
		"class",
		"def",
		"defined?",
		"do",
		"else",
		"elsif",
		"end",
		"ensure",
		"false",
		"for",
		"if",
		"in",
		"module",
		"next",
		"nil",
		"not",
		"or",
		"redo",
		"rescue",
		"retry",
		"return",
		"self",
		"super",
		"then",
		"true",
		"undef",
		"unless",
		"until",
		"when",
		"while",
		"yield"
	];

	static final RESERVED_CONSTANTS = [
		"ARGF",
		"ARGV",
		"Array",
		"BasicObject",
		"Class",
		"Data",
		"Dir",
		"Encoding",
		"ENV",
		"Exception",
		"FalseClass",
		"File",
		"Float",
		"Hash",
		"Integer",
		"IO",
		"Kernel",
		"Module",
		"NilClass",
		"Numeric",
		"Object",
		"Proc",
		"Range",
		"Regexp",
		"String",
		"Struct",
		"Symbol",
		"Thread",
		"Time",
		"TrueClass"
	];

	public static function isKeyword(name:String):Bool {
		return RESERVED_KEYWORDS.indexOf(name) != -1;
	}

	public static function isReservedConstant(name:String):Bool {
		return RESERVED_CONSTANTS.indexOf(name) != -1;
	}

	public static function toLocalName(name:String):String {
		if (name == "this") {
			return "self";
		}
		return escapeKeyword(lowerIdent(name, "hx_tmp"));
	}

	public static function toMethodName(name:String):String {
		if (name == "new") {
			return "initialize";
		}
		return escapeKeyword(lowerIdent(name, "hx_method"));
	}

	public static function toIvarName(name:String):String {
		var local = toLocalName(name);
		if (local == "self") {
			local = "self_";
		}
		return "@" + local;
	}

	public static function toConstantName(name:String):String {
		var sanitized = sanitizeIdent(stripBackticks(name), "HxConst");
		var parts = sanitized.split("_");
		var out = new StringBuf();
		for (part in parts) {
			if (part == null || part.length == 0) {
				continue;
			}
			out.add(part.charAt(0).toUpperCase());
			if (part.length > 1) {
				out.add(part.substr(1));
			}
		}
		var constant = out.toString();
		if (constant == "") {
			constant = "HxConst";
		}
		if (isReservedConstant(constant)) {
			constant += "_";
		}
		return constant;
	}

	public static function modulePath(pack:Array<String>):Array<String> {
		return pack == null ? [] : [for (part in pack) toConstantName(part)];
	}

	public static function fileStem(pack:Array<String>, typeName:String):String {
		var parts = pack == null ? [] : [for (part in pack) lowerIdent(part, "pkg")];
		parts.push(lowerIdent(typeName, "type"));
		return parts.join("_");
	}

	public static function fileName(typeName:String):String {
		return lowerIdent(typeName, "type");
	}

	public static function fileDir(pack:Array<String>):Null<String> {
		if (pack == null || pack.length == 0) {
			return null;
		}
		return [for (part in pack) lowerIdent(part, "pkg")].join("/");
	}

	public static function escapeKeyword(name:String):String {
		return isKeyword(name) ? name + "_" : name;
	}

	public static function toSnakeCase(name:String):String {
		if (name == null || name == "") {
			return "";
		}

		var out = new StringBuf();
		for (i in 0...name.length) {
			var ch = name.charAt(i);
			var lower = ch.toLowerCase();
			var isUpper = ch != lower && ch >= "A" && ch <= "Z";
			if (isUpper && i > 0) {
				var prev = name.charAt(i - 1);
				var prevIsLowerOrDigit = (prev >= "a" && prev <= "z") || (prev >= "0" && prev <= "9");
				var nextIsLower = false;
				if (i + 1 < name.length) {
					var next = name.charAt(i + 1);
					nextIsLower = next >= "a" && next <= "z";
				}
				if (prevIsLowerOrDigit || nextIsLower) {
					out.add("_");
				}
			}
			out.add(lower);
		}
		return out.toString();
	}

	static function lowerIdent(name:String, fallback:String):String {
		var snake = toSnakeCase(stripBackticks(name));
		var ident = sanitizeIdent(snake, fallback);
		if (startsWithDigit(ident)) {
			ident = "hx_" + ident;
		}
		return ident;
	}

	static function sanitizeIdent(name:String, fallback:String):String {
		if (name == null || name == "") {
			return fallback;
		}

		var out = new StringBuf();
		var prevUnderscore = false;
		for (i in 0...name.length) {
			var ch = name.charAt(i);
			var valid = isIdentChar(ch);
			var next = valid ? ch : "_";
			if (next == "_") {
				if (!prevUnderscore) {
					out.add("_");
				}
				prevUnderscore = true;
			} else {
				out.add(next);
				prevUnderscore = false;
			}
		}

		var ident = trimEdgeUnderscores(out.toString());
		return ident == "" ? fallback : ident;
	}

	static function stripBackticks(name:String):String {
		return name == null ? "" : name.split("`").join("");
	}

	static function isIdentChar(ch:String):Bool {
		return (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z") || (ch >= "0" && ch <= "9") || ch == "_";
	}

	static function startsWithDigit(value:String):Bool {
		return value != null && value.length > 0 && value.charAt(0) >= "0" && value.charAt(0) <= "9";
	}

	static function trimEdgeUnderscores(value:String):String {
		var start = 0;
		var end = value.length;
		while (start < end && value.charAt(start) == "_") {
			start++;
		}
		while (end > start && value.charAt(end - 1) == "_") {
			end--;
		}
		return value.substring(start, end);
	}
}
