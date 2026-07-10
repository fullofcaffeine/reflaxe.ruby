package reflaxe.ruby;

#if macro
import haxe.macro.Compiler as MacroCompiler;
import reflaxe.BaseCompiler.BaseCompilerFileOutputType;
import reflaxe.ReflectCompiler;
import reflaxe.ruby.compiler.RubyBuildContextResolver;
import reflaxe.ruby.macros.BoundaryEnforcer;
import reflaxe.ruby.macros.RailsInlineMarkup;
import reflaxe.ruby.macros.RubyExtensionMacro;
import reflaxe.ruby.macros.StrictModeEnforcer;
#end

class CompilerInit {
	#if macro
	static var initialized = false;

	public static function Start():Void {
		if (!BuildDetection.isRubyBuild()) {
			return;
		}

		if (initialized) {
			return;
		}
		initialized = true;

		CompilerBootstrap.Start();
		// Custom-target builds still need a stable target define so libraries and
		// application code can use the conventional `#if ruby` branch.
		MacroCompiler.define("ruby");
		RailsInlineMarkup.enable();
		MacroCompiler.addGlobalMetadata("", "@:build(reflaxe.ruby.macros.RubyExtensionMacro.build())", true, true, false);

		var buildContext = RubyBuildContextResolver.resolve();
		BoundaryEnforcer.init();
		if (buildContext.isPortable()) {
			MacroCompiler.define("ruby_portable");
		} else {
			MacroCompiler.define("ruby_first");
			MacroCompiler.define("ruby_idiomatic");
		}
		if (buildContext.strictUserBoundaries) {
			MacroCompiler.define(RubyBuildContextResolver.STRICT_DEFINE);
		}
		StrictModeEnforcer.init();

		ReflectCompiler.Start();
		ReflectCompiler.AddCompiler(new RubyCompiler(), {
			fileOutputExtension: ".rb",
			outputDirDefineName: buildContext.outputDirDefineName,
			fileOutputType: FilePerModule,
			targetCodeInjectionName: buildContext.targetCodeInjectionName,
			expressionPreprocessors: [],
			ignoreBodilessFunctions: false,
			ignoreExterns: true,
			trackUsedTypes: true
		});
	}
	#else
	public static function Start():Void {}
	#end
}
