import reflaxe.ruby.BuildDetection;
import reflaxe.ruby.ProfileResolver;
import reflaxe.ruby.compiler.RubyBuildContextResolver;

class BuildContextCompileMain {
	static function main():Void {
		BuildDetection.isRubyBuild();
		ProfileResolver.resolve();
		RubyBuildContextResolver.resolve();
	}
}
