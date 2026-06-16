package reflaxe.ruby;

#if macro
import haxe.macro.Context;
#end

class ProfileResolver {
	public static inline final DEFINE_NAME = "reflaxe_ruby_profile";
	public static inline final RUBY_FIRST_DEFINE = "ruby_first";
	public static inline final IDIOMATIC_DEFINE = "ruby_idiomatic";
	public static inline final PORTABLE_DEFINE = "ruby_portable";

	#if macro
	public static function resolve():RubyProfile {
		var raw = Context.definedValue(DEFINE_NAME);
		var selected = new Array<{source:String, profile:RubyProfile}>();

		if (raw != null && raw == "") {
			Context.fatalError('`-D ' + DEFINE_NAME + '` requires a value: ruby_first|portable (legacy alias: idiomatic)', Context.currentPos());
		}

		if (raw != null && raw != "") {
			selected.push({
				source: "-D " + DEFINE_NAME + "=" + raw,
				profile: parseProfile(raw)
			});
		}

		if (Context.defined(RUBY_FIRST_DEFINE)) {
			selected.push({source: "-D " + RUBY_FIRST_DEFINE, profile: RubyProfile.Idiomatic});
		}
		if (Context.defined(IDIOMATIC_DEFINE)) {
			selected.push({source: "-D " + IDIOMATIC_DEFINE, profile: RubyProfile.Idiomatic});
		}
		if (Context.defined(PORTABLE_DEFINE)) {
			selected.push({source: "-D " + PORTABLE_DEFINE, profile: RubyProfile.Portable});
		}

		if (selected.length == 0) {
			return RubyProfile.Idiomatic;
		}

		var winner = selected[0];
		for (index in 1...selected.length) {
			var current = selected[index];
			if (current.profile != winner.profile) {
				var sources = [for (entry in selected) entry.source].join(", ");
				Context.fatalError("Conflicting Ruby profile defines: " + sources, Context.currentPos());
			}
		}

		return winner.profile;
	}

	static function parseProfile(raw:String):RubyProfile {
		var normalized = StringTools.trim(raw).toLowerCase();
		return switch (normalized) {
			case "ruby_first", "idiomatic": RubyProfile.Idiomatic;
			case "portable": RubyProfile.Portable;
			case _:
				Context.fatalError('Invalid profile "' + raw + '" for -D ' + DEFINE_NAME + ' (expected ruby_first|portable; legacy alias: idiomatic)',
					Context.currentPos());
				RubyProfile.Idiomatic;
		}
	}
	#else
	public static function resolve():RubyProfile {
		return RubyProfile.Idiomatic;
	}
	#end
}
