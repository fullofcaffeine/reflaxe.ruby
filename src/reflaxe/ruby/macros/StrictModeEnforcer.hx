package reflaxe.ruby.macros;

#if macro
import haxe.macro.Context;
import reflaxe.ruby.BuildDetection;
import reflaxe.ruby.compiler.RubyBuildContextResolver;
import reflaxe.ruby.macros.RawInjectionPolicy;

class StrictModeEnforcer {
	static var initialized = false;

	public static function init():Void {
		if (initialized) {
			return;
		}
		initialized = true;

		if (!BuildDetection.isRubyBuild() || !Context.defined(RubyBuildContextResolver.STRICT_DEFINE)) {
			return;
		}

		var projectRoot = RawInjectionPolicy.normalizePath(Sys.getCwd());
		var findings = RawInjectionPolicy.preflightFindings(path -> RawInjectionPolicy.isProjectSource(path, projectRoot));
		if (findings.length > 0) {
			Context.fatalError("StrictModeEnforcer: __ruby__ is not allowed in strict mode (" + findings[0] + ")", Context.currentPos());
		}

		Context.onAfterTyping(types -> RawInjectionPolicy.enforce(types, classType -> RawInjectionPolicy.isClassUnderProject(classType, projectRoot),
			"StrictModeEnforcer: __ruby__ is not allowed in strict mode. Prefer typed Ruby externs or move target-specific interop into std/runtime."));
	}
}
#else
class StrictModeEnforcer {
	public static function init():Void {}
}
#end
