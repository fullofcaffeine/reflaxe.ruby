package reflaxe.ruby.compiler;

import reflaxe.ruby.ProfileResolver;
import reflaxe.ruby.RubyProfile;
#if macro
import haxe.macro.Context;
#end

class RubyBuildContextResolver {
	public static inline final STRICT_EXAMPLES_DEFINE = "reflaxe_ruby_strict_examples";
	public static inline final STRICT_DEFINE = "reflaxe_ruby_strict";
	public static inline final STRICT_POLICY_DEFINE = "reflaxe_ruby_strict_policy";
	public static inline final RUNTIME_PLAN_REPORT_DEFINE = "reflaxe_ruby_runtime_plan_report";
	public static inline final GAP_REPORT_DEFINE = "reflaxe_ruby_gap_report";
	public static inline final RAILS_DEFINE = "reflaxe_ruby_rails";
	public static inline final RAILS_OUTPUT_ROOT_DEFINE = "reflaxe_ruby_rails_output_root";

	#if macro
	public static function resolve():RubyBuildContext {
		var profile = ProfileResolver.resolve();
		var strictPolicy = parseStrictUserBoundaryPolicy(Context.definedValue(STRICT_POLICY_DEFINE));
		var strictUserBoundaries = resolveStrictUserBoundaries(strictPolicy, Context.defined(STRICT_DEFINE));
		var railsOutputRoot = parseRailsOutputRoot(Context.definedValue(RAILS_OUTPUT_ROOT_DEFINE));
		return new RubyBuildContext(profile, "ruby_output", "__ruby__", Context.defined(STRICT_EXAMPLES_DEFINE), strictPolicy, strictUserBoundaries,
			Context.defined(RUNTIME_PLAN_REPORT_DEFINE), Context.defined(GAP_REPORT_DEFINE), Context.defined(RAILS_DEFINE), railsOutputRoot);
	}

	static function parseStrictUserBoundaryPolicy(raw:Null<String>):String {
		if (raw == null) {
			return "auto";
		}
		var normalized = StringTools.trim(raw).toLowerCase();
		if (normalized == "") {
			return "auto";
		}
		return switch (normalized) {
			case "auto", "on", "off":
				normalized;
			case _:
				Context.fatalError('Unknown `' + STRICT_POLICY_DEFINE + '` value "' + raw + '" (expected: auto, on, off)', Context.currentPos());
				"auto";
		}
	}

	static function resolveStrictUserBoundaries(strictPolicy:String, strictDefineEnabled:Bool):Bool {
		if (strictDefineEnabled) {
			return true;
		}
		return switch (strictPolicy) {
			case "on": true;
			case "off": false;
			case _: false;
		}
	}

	static function parseRailsOutputRoot(raw:Null<String>):Null<String> {
		if (raw == null) {
			return null;
		}
		var normalized = StringTools.trim(raw).split("\\").join("/");
		while (StringTools.endsWith(normalized, "/")) {
			normalized = normalized.substr(0, normalized.length - 1);
		}
		if (normalized == "") {
			return null;
		}
		if (StringTools.startsWith(normalized, "/") || normalized.indexOf("//") != -1 || normalized.indexOf("..") != -1) {
			Context.fatalError('Unsafe `'
				+ RAILS_OUTPUT_ROOT_DEFINE
				+ '` value "'
				+ raw
				+ '" (expected a safe relative Rails path such as app/haxe_gen or engines/blog/app/haxe_gen)',
				Context.currentPos());
		}
		for (segment in normalized.split("/")) {
			if (segment == "" || segment == "." || segment == "..") {
				Context.fatalError('Unsafe `' + RAILS_OUTPUT_ROOT_DEFINE + '` value "' + raw + '" (path segments must not be empty, ".", or "..")',
					Context.currentPos());
			}
		}
		return normalized;
	}
	#else
	public static function resolve():RubyBuildContext {
		return RubyBuildContext.legacyDefaults(RubyProfile.Idiomatic);
	}
	#end
}
