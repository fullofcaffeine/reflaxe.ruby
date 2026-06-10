package reflaxe.ruby;

#if (macro || reflaxe_runtime)
import haxe.macro.Type.BaseType;
import reflaxe.output.DataAndFileInfo;
import reflaxe.output.StringOrBytes;
import reflaxe.ruby.ast.RubyAST.RubyFile;
import reflaxe.ruby.ast.RubyASTPrinter;

@:access(reflaxe.ruby.RubyCompiler)
class RubyOutputIterator {
	var compiler:RubyCompiler;
	var context:CompilationContext;
	var index:Int;
	var maxIndex:Int;

	public function new(compiler:RubyCompiler) {
		this.compiler = compiler;
		this.context = compiler.createCompilationContext();
		this.compiler.currentCompilationContext = context;
		this.index = 0;
		this.maxIndex = compiler.classes.length + compiler.enums.length + compiler.typedefs.length + compiler.abstracts.length;
	}

	public function hasNext():Bool {
		return index < maxIndex;
	}

	public function next():DataAndFileInfo<StringOrBytes> {
		var astData:DataAndFileInfo<RubyFile> = if (index < compiler.classes.length) {
			compiler.classes[index];
		} else if (index < compiler.classes.length + compiler.enums.length) {
			compiler.enums[index - compiler.classes.length];
		} else if (index < compiler.classes.length + compiler.enums.length + compiler.typedefs.length) {
			compiler.typedefs[index - compiler.classes.length - compiler.enums.length];
		} else {
			compiler.abstracts[index - compiler.classes.length - compiler.enums.length - compiler.typedefs.length];
		}
		index++;
		context.setCurrentModule(moduleLabel(astData.baseType), astData.baseType == null ? null : astData.baseType.pos);
		return astData.withOutput(StringOrBytes.fromString(RubyASTPrinter.printFile(astData.data)));
	}

	static function moduleLabel(base:Null<BaseType>):String {
		if (base == null) {
			return "<unknown>";
		}
		if (base.module != null && base.module.length > 0) {
			return base.module;
		}
		if (base.pack != null && base.pack.length > 0) {
			return base.pack.concat([base.name]).join(".");
		}
		return base.name;
	}
}
#end
