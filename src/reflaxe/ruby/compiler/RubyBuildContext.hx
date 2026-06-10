package reflaxe.ruby.compiler;

import reflaxe.ruby.RubyProfile;

class RubyBuildContext {
	public final profile:RubyProfile;
	public final outputDirDefineName:String;
	public final targetCodeInjectionName:String;
	public final strictExamples:Bool;
	public final strictUserBoundaryPolicy:String;
	public final strictUserBoundaries:Bool;
	public final runtimePlanReportEnabled:Bool;
	public final gapReportEnabled:Bool;
	public final railsMode:Bool;
	public final railsOutputRoot:String;

	public function new(profile:RubyProfile, outputDirDefineName:String, targetCodeInjectionName:String, strictExamples:Bool,
			strictUserBoundaryPolicy:String, strictUserBoundaries:Bool, runtimePlanReportEnabled:Bool, gapReportEnabled:Bool, railsMode:Bool,
			railsOutputRoot:String) {
		this.profile = profile == null ? RubyProfile.Idiomatic : profile;
		this.outputDirDefineName = normalizeDefineName(outputDirDefineName, "ruby_output");
		this.targetCodeInjectionName = normalizeDefineName(targetCodeInjectionName, "__ruby__");
		this.strictExamples = strictExamples == true;
		this.strictUserBoundaryPolicy = normalizeStrictUserBoundaryPolicy(strictUserBoundaryPolicy);
		this.strictUserBoundaries = strictUserBoundaries == true;
		this.runtimePlanReportEnabled = runtimePlanReportEnabled == true;
		this.gapReportEnabled = gapReportEnabled == true;
		this.railsMode = railsMode == true;
		this.railsOutputRoot = normalizePath(railsOutputRoot, "app/haxe_gen");
	}

	public inline function isPortable():Bool {
		return profile == RubyProfile.Portable;
	}

	public static function legacyDefaults(?profile:RubyProfile):RubyBuildContext {
		return new RubyBuildContext(profile == null ? RubyProfile.Idiomatic : profile, "ruby_output", "__ruby__", false, "auto", false, false, false, false,
			"app/haxe_gen");
	}

	static function normalizeDefineName(raw:Null<String>, fallback:String):String {
		if (raw == null) {
			return fallback;
		}
		var trimmed = StringTools.trim(raw);
		return trimmed == "" ? fallback : trimmed;
	}

	static function normalizeStrictUserBoundaryPolicy(raw:Null<String>):String {
		if (raw == null) {
			return "auto";
		}
		var trimmed = StringTools.trim(raw).toLowerCase();
		return trimmed == "" ? "auto" : trimmed;
	}

	static function normalizePath(raw:Null<String>, fallback:String):String {
		if (raw == null) {
			return fallback;
		}
		var trimmed = StringTools.trim(raw).split("\\").join("/");
		while (StringTools.startsWith(trimmed, "/")) {
			trimmed = trimmed.substr(1);
		}
		while (StringTools.endsWith(trimmed, "/")) {
			trimmed = trimmed.substr(0, trimmed.length - 1);
		}
		return trimmed == "" ? fallback : trimmed;
	}
}
