package;

import ruby.MatchData as RubyMatchData;
import ruby.Regexp as RubyRegexp;

/**
	Ruby `Regexp` backed implementation of Haxe `EReg`.

	Ruby and Haxe differ most visibly in replacement syntax: Ruby expands
	`\1`, while Haxe expands `$1` and treats `$$` as a literal dollar. The
	replacement path is kept here so constructor-created and `~/.../` regexes
	share the same Haxe-facing contract.

	This remains a semantic adapter rather than an alias for `ruby.Regexp`:
	EReg owns stateful match accessors, `matchSub`, and `g` behavior. Only native
	escaping and the internal `MatchData` value use the public typed facades,
	because those contracts match exactly without changing portable behavior.
**/
class EReg {
	final pattern:String;
	final options:String;
	final global:Bool;

	public function new(pattern:String, options:String) {
		this.pattern = pattern;
		this.options = options;
		this.global = options.indexOf("g") != -1;
		untyped __ruby__("(flags = 0; flags |= Regexp::IGNORECASE if {1}.include?('i'); flags |= Regexp::MULTILINE if {1}.include?('s'); @native_regex = Regexp.new({0}, flags); @match = nil; @last_string = nil; @last_offset = 0; nil)",
			pattern, options);
	}

	public function match(s:String):Bool {
		return untyped __ruby__("(@last_string = {0}; @last_offset = 0; @match = @native_regex.match({0}); !@match.nil?)", s);
	}

	public function matched(n:Int):String {
		return untyped __ruby__("@match[{0}]", n);
	}

	public function matchedLeft():String {
		return untyped __ruby__("{0}[0...(@last_offset + @match.begin(0))].to_s", untyped __ruby__("@last_string"));
	}

	public function matchedRight():String {
		return untyped __ruby__("{0}[(@last_offset + @match.end(0))..].to_s", untyped __ruby__("@last_string"));
	}

	public function matchedPos():{pos:Int, len:Int} {
		return {
			pos: untyped __ruby__("@last_offset + @match.begin(0)"),
			len: untyped __ruby__("@match.end(0) - @match.begin(0)")
		};
	}

	public function matchSub(s:String, pos:Int, len:Int = -1):Bool {
		return
			untyped __ruby__("(subject = ({2}.nil? || {2} < 0 ? {0}[{1}..] : {0}[{1}, {2}]); @last_string = {0}; @last_offset = {1}; @match = subject.nil? ? nil : @native_regex.match(subject); !@match.nil?)",
			s, pos, len);
	}

	public function split(s:String):Array<String> {
		if (!global) {
			if (!match(s)) {
				return [s];
			}
			return [matchedLeft(), matchedRight()];
		}
		return
			cast untyped __ruby__("(begin parts = []; offset = 0; string = {0}; while offset <= string.length; match = @native_regex.match(string, offset); break if match.nil?; parts << string[offset...match.begin(0)].to_s; next_offset = match.end(0); if next_offset == offset; offset += 1; else offset = next_offset; end; end; parts << string[offset..].to_s; parts end)",
			s);
	}

	public function replace(s:String, by:String):String {
		var limit = global ? null : 1;
		return
			untyped __ruby__("(begin count = 0; {0}.gsub(@native_regex) do |match_text| match = Regexp.last_match; if !{2}.nil? && count >= {2}; match_text; else count += 1; EReg.expand_replacement({1}, match); end end end)",
			s, by, limit);
	}

	public function map(s:String, f:EReg->String):String {
		return
			untyped __ruby__("(begin out = +''; offset = 0; string = {0}; while offset <= string.length; match = @native_regex.match(string, offset); break if match.nil?; @last_string = string; @last_offset = 0; @match = match; out << string[offset...match.begin(0)].to_s; out << {1}.call(self).to_s; if !@global; out << string[match.end(0)..].to_s; return out; end; if match.end(0) == offset; out << string[match.end(0), 1].to_s; offset = match.end(0) + 1; else offset = match.end(0); end; end; out << string[offset..].to_s; out end)",
			s, f);
	}

	public static function escape(s:String):String {
		return RubyRegexp.escape(s);
	}

	/** Keeps the unsafe raw seam local while proving the native carrier's shape. **/
	static function expandReplacement(by:String, match:RubyMatchData):String {
		return
			untyped __ruby__("(begin out = +''; index = 0; replacement = {0}.to_s; while index < replacement.length; char = replacement[index]; if char == '$' && index + 1 < replacement.length; next_char = replacement[index + 1]; if next_char == '$'; out << '$'; index += 2; next; elsif next_char >= '1' && next_char <= '9'; value = {1}[next_char.to_i]; out << value.to_s unless value.nil?; index += 2; next; end; end; out << char; index += 1; end; out end)",
			by, match);
	}
}
