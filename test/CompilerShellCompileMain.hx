import reflaxe.ruby.CompilationContext;
import reflaxe.ruby.RubyCompiler;
import reflaxe.ruby.ast.RubyAST;
import reflaxe.ruby.ast.RubyASTPrinter;
import reflaxe.ruby.compiler.RubyBuildContext;

class CompilerShellCompileMain {
	static function main():Void {
		var context = CompilationContext.fromBuildContext(RubyBuildContext.legacyDefaults());
		context.setCurrentModule("Smoke", null);
		var compiler = new RubyCompiler();
		var printed = RubyASTPrinter.printFile({
			modulePath: [],
			statements: [RubyComment("compiler shell smoke")]
		});
		if (printed.indexOf("compiler shell smoke") < 0 || compiler == null || context.currentModuleLabel != "Smoke") {
			throw "compiler shell smoke failed";
		}
	}
}
