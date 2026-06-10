package reflaxe.ruby;

import reflaxe.ruby.compiler.RubyBuildContext;

#if (macro || reflaxe_runtime)
import haxe.macro.Expr.Position;
#else
private typedef Position = Dynamic;
#end

class CompilationContext {
	public final build:RubyBuildContext;
	public var currentModuleLabel:Null<String>;
	var modulePosByLabel:Map<String, Position>;

	public var profile(get, never):RubyProfile;

	public function new(build:RubyBuildContext) {
		this.build = build == null ? RubyBuildContext.legacyDefaults(RubyProfile.Idiomatic) : build;
		this.currentModuleLabel = null;
		this.modulePosByLabel = [];
	}

	public static function fromBuildContext(build:RubyBuildContext):CompilationContext {
		return new CompilationContext(build);
	}

	public function setCurrentModule(label:String, pos:Null<Position>):Void {
		currentModuleLabel = label;
		if (label != null && pos != null) {
			modulePosByLabel.set(label, pos);
		}
	}

	public function modulePosition(label:String):Null<Position> {
		return modulePosByLabel.get(label);
	}

	inline function get_profile():RubyProfile {
		return build.profile;
	}
}
