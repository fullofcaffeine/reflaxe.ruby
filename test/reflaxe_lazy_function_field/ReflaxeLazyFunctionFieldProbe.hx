#if macro
import haxe.macro.Context;
import haxe.macro.Type;
import reflaxe.BaseCompiler.BaseCompilerFileOutputType;
import reflaxe.DirectToStringCompiler;
import reflaxe.ReflectCompiler;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;
import reflaxe.data.EnumOptionData;

using reflaxe.helpers.ClassFieldHelper;

/**
	Minimal Reflaxe compiler used to exercise lazy function-field metadata through
	the same `filterTypes` lifecycle used by real targets. It emits no target code;
	the contract is that a type loaded only by `Context.getType` still produces
	precise `ClassFuncData` instead of being mistaken for a non-function field.
**/
class ReflaxeLazyFunctionFieldProbe extends DirectToStringCompiler {
	public static function Start():Void {
		Context.onAfterInitMacros(Begin);
	}

	static function Begin():Void {
		ReflectCompiler.AddCompiler(new ReflaxeLazyFunctionFieldProbe(), {
			fileOutputType: Manual,
			outputDirDefineName: "reflaxe_lazy_probe_output",
			expressionPreprocessors: [],
			ignoreBodilessFunctions: true,
			trackClassHierarchy: false
		});
	}

	override public function filterTypes(moduleTypes:Array<ModuleType>):Array<ModuleType> {
		final lazyType = Context.getType("LazyAddedType");
		switch lazyType {
			case TInst(classRef, _):
				final classType = classRef.get();
				final methods = classType.statics.get().filter(field -> field.name == "injectedMethod");
				if (methods.length != 1) {
					Context.error("Expected one lazily loaded injectedMethod field.", classType.pos);
				}
				final method = methods[0];
				if (method.findFuncData(classType, true) == null) {
					Context.error("Function information not found for lazily typed field.", method.pos);
				}
				moduleTypes.push(TClassDecl(classRef));
			case _:
				Context.error("Expected LazyAddedType to resolve to a class.", Context.currentPos());
		}
		return moduleTypes;
	}

	public function compileClassImpl(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>):Null<String> {
		return null;
	}

	public function compileEnumImpl(enumType:EnumType, options:Array<EnumOptionData>):Null<String> {
		return null;
	}

	public function compileExpressionImpl(expr:TypedExpr, topLevel:Bool):Null<String> {
		return null;
	}
}
#end
