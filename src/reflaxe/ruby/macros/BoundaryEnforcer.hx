package reflaxe.ruby.macros;

#if macro
import haxe.macro.Context;
import reflaxe.ruby.BuildDetection;
import reflaxe.ruby.compiler.RubyBuildContextResolver;
import reflaxe.ruby.macros.RawInjectionPolicy;

class BoundaryEnforcer {
	static var initialized = false;

	public static function init():Void {
		if (initialized) {
			return;
		}
		initialized = true;

		if (!BuildDetection.isRubyBuild() || !Context.defined(RubyBuildContextResolver.STRICT_EXAMPLES_DEFINE)) {
			return;
		}

		var findings = RawInjectionPolicy.preflightFindings(path -> RawInjectionPolicy.isExampleOrTestSource(path));
		if (findings.length > 0) {
			Context.fatalError("BoundaryEnforcer: __ruby__ is not allowed in strict examples (" + findings[0] + ")", Context.currentPos());
		}

		Context.onAfterTyping(types -> RawInjectionPolicy.enforce(types, RawInjectionPolicy.isClassUnderExampleOrTest,
			"BoundaryEnforcer: __ruby__ is not allowed in strict examples. Use typed Ruby externs or std/runtime wrappers."));
	}
}
#else
class BoundaryEnforcer {
	public static function init():Void {}
}
#end
