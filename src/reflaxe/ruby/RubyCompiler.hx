package reflaxe.ruby;

#if (macro || reflaxe_runtime)
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Type.AbstractType;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.DefType;
import haxe.macro.Type.EnumType;
import haxe.macro.Type.FieldAccess;
import haxe.macro.Type.ModuleType;
import haxe.macro.Type.TypedExpr;
import haxe.macro.Type.TVar;
import haxe.macro.TypedExprTools;
import haxe.macro.TypeTools;
import reflaxe.GenericCompiler;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;
import reflaxe.data.EnumOptionData;
import reflaxe.output.DataAndFileInfo;
import reflaxe.output.OutputPath;
import reflaxe.output.StringOrBytes;
import reflaxe.ruby.ast.RubyAST.RubyExpr;
import reflaxe.ruby.ast.RubyAST.RubyFile;
import reflaxe.ruby.ast.RubyAST.RubyStatement;
import reflaxe.ruby.compiler.RubyBuildContext;
import reflaxe.ruby.compiler.RubyBuildContextResolver;
import reflaxe.ruby.naming.RubyNaming;
import reflaxe.ruby.rails.RailsRouteDecl;
import reflaxe.ruby.rails.RailsRouteTarget;
import reflaxe.ruby.rails.RailsRouteManifest;
import reflaxe.ruby.rails.RailsRoutesExtractor;
import reflaxe.ruby.rails.RailsRoutesEmitter;
import reflaxe.ruby.RequireRegistry;
import sys.FileSystem;
import sys.io.File;

using reflaxe.helpers.ClassFieldHelper;

typedef RailsColumnInfo = {
	haxeName:String,
	rubyName:String,
	haxeType:String,
	railsType:String,
	nullable:Bool,
	defaultValue:Null<String>,
	primaryKey:Bool,
	index:Bool,
	unique:Bool,
	dbType:Null<String>
}

typedef RailsBelongsToInfo = {
	rubyName:String,
	columnName:String,
	referencedTable:String
}

typedef RailsMigrationConfig = {
	timestamp:String,
	className:String,
	version:String,
	models:Array<ClassType>,
	knownModels:Array<ClassType>,
	externalTables:Array<String>,
	operations:Array<RailsMigrationOperationInfo>
}

typedef RailsMigrationOperationInfo = {
	lines:Array<String>,
	foreignKeys:Array<RailsMigrationForeignKeyRef>
}

typedef RailsMigrationForeignKeyRef = {
	fromTable:String,
	toTable:String
}

typedef RailsMigrationValidationContext = {
	columnsByTable:Map<String, Map<String, Bool>>,
	snapshotColumnsByTable:Map<String, Map<String, Bool>>,
	externalTables:Map<String, Bool>,
	strictTables:Bool
}

typedef RailsEmittedMigration = {
	timestamp:String,
	className:String,
	source:String,
	pos:Position,
	createdTables:Array<String>,
	foreignKeys:Array<RailsMigrationForeignKeyRef>
}

typedef RailsTestDecl = {
	kind:String,
	description:Null<String>,
	body:TypedExpr,
	pos:Position
}

typedef RailsManifestEntry = {
	output:String,
	kind:String,
	source:String,
	content:String
}

typedef RubyMetadataField = {
	field:String,
	expr:haxe.macro.Expr
}

typedef RailsTemplateScope = {
	localNames:Map<Int, String>,
	localObjectNames:Map<Int, String>,
	?formBuilderName:String
}

typedef RailsComponentRef = {
	path:String,
	slotName:String
}

typedef LocalNameScope = {
	names:Map<Int, String>,
	nextByBase:Map<String, Int>
}

class RubyCompiler extends GenericCompiler<RubyFile, RubyFile, RubyExpr, RubyFile, RubyFile> {
	public var currentCompilationContext:Null<CompilationContext>;

	var emittedRubyPaths:Array<String> = [];
	var emittedAppRubyPaths:Array<String> = [];
	var emittedRailsMigrationPaths:Map<String, String> = [];
	var emittedRailsTestPaths:Map<String, String> = [];
	var emittedRailsMailerPreviewPaths:Map<String, String> = [];
	var emittedRailsRoutePaths:Map<String, String> = [];
	var emittedRailsMigrations:Array<RailsEmittedMigration> = [];
	var requireRegistry:RequireRegistry = new RequireRegistry();
	var buildContext:RubyBuildContext;
	var didEmitMain:Bool = false;

	static var needsDataDefine:Bool = false;
	static var needsHxException:Bool = false;
	static var localNameScope:Null<LocalNameScope> = null;

	public function new() {
		super();
		buildContext = RubyBuildContextResolver.resolve();
	}

	public function createCompilationContext():CompilationContext {
		return CompilationContext.fromBuildContext(RubyBuildContextResolver.resolve());
	}

	public function generateOutputIterator():Iterator<DataAndFileInfo<StringOrBytes>> {
		return new RubyOutputIterator(this);
	}

	override public function onCompileStart():Void {
		buildContext = RubyBuildContextResolver.resolve();
		emittedRubyPaths = [];
		emittedAppRubyPaths = [];
		emittedRailsMigrationPaths = [];
		emittedRailsTestPaths = [];
		emittedRailsMailerPreviewPaths = [];
		emittedRailsRoutePaths = [];
		emittedRailsMigrations = [];
		requireRegistry = new RequireRegistry();
		didEmitMain = false;
		needsDataDefine = false;
		needsHxException = false;
		localNameScope = null;
	}

	override public function onCompileEnd():Void {
		if (buildContext.railsMode) {
			setRailsAutoloadInitializer();
		}
		if (!didEmitMain) {
			return;
		}
		setRuntimeExtraFile("core.rb");
		if (needsDataDefine) {
			setRuntimeExtraFile("data_define.rb");
		}
		if (needsHxException) {
			setRuntimeExtraFile("hx_exception.rb");
		}
		var paths = [outputRelativePath("hxruby/core.rb", true)];
		if (needsDataDefine) {
			paths.push(outputRelativePath("hxruby/data_define.rb", true));
		}
		if (needsHxException) {
			paths.push(outputRelativePath("hxruby/hx_exception.rb", true));
		}
		var generatedPaths = emittedRubyPaths.copy();
		generatedPaths.sort((a, b) -> {
			if (a == "main.rb")
				return 1;
			if (b == "main.rb")
				return -1;
			return Reflect.compare(a, b);
		});
		paths = paths.concat(generatedPaths);
		var lines = ["# Generated by reflaxe.ruby", "$LOAD_PATH.unshift(__dir__)"];
		for (value in requireRegistry.requireValues()) {
			lines.push("require " + quoteRubyStringForCode(value));
		}
		for (value in requireRegistry.requireRelativeValues()) {
			lines.push("require_relative " + quoteRubyStringForCode(value));
		}
		for (path in paths) {
			lines.push("require_relative " + quoteRubyStringForCode(path.substr(0, path.length - 3)));
		}
		lines.push("Main.main");
		lines.push("");
		setExtraFile(OutputPath.fromStr("run.rb"), lines.join("\n"));
	}

	public function compileClassImpl(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>):Null<RubyFile> {
		if (isMacroOnlyRuntimeType(classType.pack)) {
			return null;
		}
		if (hasMeta(classType.meta, ":railsTest")) {
			emitRailsTestArtifact(classType, funcFields);
			return null;
		}
		if (hasMeta(classType.meta, ":railsMailerPreview")) {
			emitRailsMailerPreviewArtifact(classType, funcFields);
			return null;
		}
		if (hasMeta(classType.meta, ":railsRoutes")) {
			emitRailsRoutesArtifact(classType, varFields);
			return null;
		}
		setRubyOutputPath(classType.pack, classType.name);
		var moduleRequires = collectModuleRequires(classType.meta);
		if (hasMeta(classType.meta, ":railsMigration")) {
			emitRailsMigrationArtifact(classType, varFields);
		}
		if (hasMeta(classType.meta, ":railsTemplate")) {
			return compileRailsTemplateImpl(classType, varFields, funcFields, moduleRequires);
		}
		if (hasMeta(classType.meta, ":railsModel")) {
			requireRegistry.addRequire("active_record");
			moduleRequires.addRequire("active_record");
			if (railsModelHasAttachments(classType)) {
				requireRegistry.addRequire("active_storage/engine");
				moduleRequires.addRequire("active_storage/engine");
			}
			return compileRailsModelImpl(classType, varFields, funcFields, moduleRequires);
		}
		if (hasMeta(classType.meta, ":railsController")) {
			requireRegistry.addRequire("action_controller/railtie");
			moduleRequires.addRequire("action_controller/railtie");
			return compileRailsControllerImpl(classType, varFields, funcFields, moduleRequires);
		}
		if (hasMeta(classType.meta, ":railsMailer")) {
			requireRegistry.addRequire("action_mailer/railtie");
			moduleRequires.addRequire("action_mailer/railtie");
			return compileRailsMailerImpl(classType, varFields, funcFields, moduleRequires);
		}
		if (hasMeta(classType.meta, ":railsJob")) {
			requireRegistry.addRequire("active_job/railtie");
			moduleRequires.addRequire("active_job/railtie");
			return compileRailsJobImpl(classType, varFields, funcFields, moduleRequires);
		}
		if (hasMeta(classType.meta, ":railsChannel")) {
			requireRegistry.addRequire("action_cable/engine");
			moduleRequires.addRequire("action_cable/engine");
			return compileRailsChannelImpl(classType, varFields, funcFields, moduleRequires);
		}
		if (hasMeta(classType.meta, ":railsCableConnection")) {
			requireRegistry.addRequire("action_cable/engine");
			moduleRequires.addRequire("action_cable/engine");
			return compileRailsCableConnectionImpl(classType, varFields, funcFields, moduleRequires);
		}
		var isRubyModule = hasMeta(classType.meta, ":rubyModule");
		var isRubyConcern = hasMeta(classType.meta, ":rubyConcern");
		if (isRubyConcern) {
			requireRegistry.addRequire("active_support/concern");
			moduleRequires.addRequire("active_support/concern");
		}
		var classBody:Array<RubyStatement> = [];
		classBody.push(typeNameMetadata(fullTypeName(classType.pack, classType.name)));
		if (isRubyConcern) {
			classBody.push(RubyRawStatement("extend ActiveSupport::Concern"));
		}
		classBody = classBody.concat(rubyExtensionStatements(classType.meta, classType));
		for (field in varFields) {
			var mathConstant = mathConstantValue(classType.pack, classType.name, field.field.name);
			classBody.push(mathConstant == null ? compileVarField(field) : compileMathConstantField(field.field.name, mathConstant));
		}
		var concernClassMethods:Array<RubyStatement> = [];
		for (field in funcFields) {
			if (field.expr == null) {
				continue;
			}
			if (hasMeta(field.field.meta, ":rubyExternStub")) {
				continue;
			}
			if ((isRubyModule || isRubyConcern) && !field.isStatic && field.field.name == "new") {
				Context.error("@:rubyModule/@:rubyConcern types cannot define constructors; Ruby modules are included or extended, not instantiated.",
					field.field.pos);
				continue;
			}
			if (isRubyConcern && field.isStatic) {
				concernClassMethods.push(compileMethodAs(field, false));
			} else {
				classBody.push(compileMethod(field));
			}
		}
		if (concernClassMethods.length > 0) {
			classBody.push(RubyRawStatement("class_methods do\n" + indentLines(renderStatements(concernClassMethods), 1).join("\n") + "\nend"));
		}
		if (classBody.length == 0) {
			classBody.push(RubyComment("No Ruby members emitted for " + fullTypeName(classType.pack, classType.name)));
		}

		var statements = [
			RubyComment("Generated by reflaxe.ruby"),
			RubyComment("Generated type shell for Ruby output.")
		];
		statements = statements.concat(requirePreludeStatements(moduleRequires));
		statements.push(wrapInModules(classType.pack, rubyClassDeclaration(classType, classBody)));

		if (classType.pack.length == 0 && classType.name == "Main" && hasStaticMain(funcFields)) {
			didEmitMain = true;
			statements.push(RubyRawStatement("if __FILE__ == $PROGRAM_NAME\n  $LOAD_PATH.unshift(__dir__)\n  require_relative \"hxruby/core\"\n  Main.main()\nend"));
		}

		return {
			modulePath: classType.pack == null ? [] : classType.pack.copy(),
			statements: statements
		};
	}

	public function compileEnumImpl(enumType:EnumType, options:Array<EnumOptionData>):Null<RubyFile> {
		if (isMacroOnlyRuntimeType(enumType.pack)) {
			return null;
		}
		setRubyOutputPath(enumType.pack, enumType.name);
		var moduleRequires = collectModuleRequires(enumType.meta);
		needsDataDefine = true;
		var statements = [
			RubyComment("Generated by reflaxe.ruby"),
			RubyComment("Enum constructors use hxruby/data_define.rb for Data.define compatibility.")
		];
		statements = statements.concat(requirePreludeStatements(moduleRequires));
		statements.push(wrapInModules(enumType.pack, RubyModuleDecl(RubyNaming.toConstantName(enumType.name), compileEnumBody(enumType, options))));
		return {
			modulePath: enumType.pack == null ? [] : enumType.pack.copy(),
			statements: statements
		};
	}

	public function compileExpressionImpl(expr:TypedExpr, topLevel:Bool):Null<RubyExpr> {
		return withLocalNameScope([], () -> compileExpr(expr));
	}

	override public function compileTypedefImpl(typedefType:DefType):Null<RubyFile> {
		if (isMacroOnlyRuntimeType(typedefType.pack)) {
			return null;
		}
		setRubyOutputPath(typedefType.pack, typedefType.name);
		return typeShell(typedefType.pack, typedefType.name, RubyModuleDecl(RubyNaming.toConstantName(typedefType.name), [
			RubyComment("Haxe typedef " + fullTypeName(typedefType.pack, typedefType.name) + " has no Ruby runtime body.")
		]), collectModuleRequires(typedefType.meta));
	}

	override public function compileAbstractImpl(abstractType:AbstractType):Null<RubyFile> {
		if (isMacroOnlyRuntimeType(abstractType.pack)) {
			return null;
		}
		setRubyOutputPath(abstractType.pack, abstractType.name);
		return typeShell(abstractType.pack, abstractType.name, RubyModuleDecl(RubyNaming.toConstantName(abstractType.name), [
			RubyComment("Haxe abstract " + fullTypeName(abstractType.pack, abstractType.name) + " has no Ruby runtime body.")
		]), collectModuleRequires(abstractType.meta));
	}

	function compileRailsTemplateImpl(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>,
			moduleRequires:RequireRegistry):RubyFile {
		emitRailsTemplateArtifact(classType, varFields, funcFields);
		return typeShell(classType.pack, classType.name, RubyClassDecl(RubyNaming.toConstantName(classType.name), [
			RubyComment("Rails ActionView template marker. The ERB artifact is generated under app/views.")
		]), moduleRequires);
	}

	static function typeShell(pack:Array<String>, name:String, declaration:RubyStatement, ?moduleRequires:RequireRegistry):RubyFile {
		var statements:Array<RubyStatement> = [
			RubyComment("Generated by reflaxe.ruby"),
			RubyComment("Generated type shell for Ruby output.")
		];
		statements = statements.concat(requirePreludeStatements(moduleRequires));
		statements.push(wrapInModules(pack, declaration));
		return {
			modulePath: pack == null ? [] : pack.copy(),
			statements: statements
		};
	}

	static function rubyClassDeclaration(classType:ClassType, body:Array<RubyStatement>):RubyStatement {
		var constant = RubyNaming.toConstantName(classType.name);
		if (isRubyModuleType(classType) || fullTypeName(classType.pack, classType.name) == "Math") {
			return RubyModuleDecl(isRubyModuleType(classType) ? rubyModuleDeclarationName(classType) : constant, body);
		}
		var superclass = nativeExternSuperclassName(classType);
		return superclass == null ? RubyClassDecl(constant, body) : RubyClassDeclWithSuper(constant, superclass, body);
	}

	static function nativeExternSuperclassName(classType:ClassType):Null<String> {
		if (classType.superClass == null) {
			return null;
		}
		var superclass = classType.superClass.t.get();
		if (!superclass.isExtern) {
			return null;
		}
		var native = rubyNativeName(superclass.meta);
		if (native == null) {
			return null;
		}
		if (!isSafeRubyConstantPath(native)) {
			Context.error('@:native superclass "$native" is not a safe Ruby constant path for ${fullTypeName(classType.pack, classType.name)}.', classType.pos);
			return null;
		}
		return native;
	}

	static function isRubyModuleType(classType:ClassType):Bool {
		return hasMeta(classType.meta, ":rubyModule") || hasMeta(classType.meta, ":rubyConcern");
	}

	static function rubyModuleDeclarationName(classType:ClassType):String {
		return rubyMixinModuleName(classType.meta) ?? RubyNaming.toConstantName(classType.name);
	}

	function collectModuleRequires(meta:Null<haxe.macro.Type.MetaAccess>):RequireRegistry {
		var moduleRequires = new RequireRegistry();
		moduleRequires.collectMeta(meta);
		moduleRequires.collectTypeUsage(getTypeUsage());
		requireRegistry.addAll(moduleRequires);
		return moduleRequires;
	}

	static function requirePreludeStatements(registry:Null<RequireRegistry>):Array<RubyStatement> {
		if (registry == null) {
			return [];
		}
		var out:Array<RubyStatement> = [];
		for (value in registry.requireValues()) {
			out.push(RubyRawStatement("require " + quoteRubyStringForCode(value)));
		}
		for (value in registry.requireRelativeValues()) {
			out.push(RubyRawStatement("require_relative " + quoteRubyStringForCode(value)));
		}
		return out;
	}

	static function rubyExtensionStatements(meta:Null<haxe.macro.Type.MetaAccess>, ?owner:ClassType):Array<RubyStatement> {
		return [for (line in rubyExtensionLines(meta, owner)) RubyRawStatement(line)];
	}

	static function rubyExtensionLines(meta:Null<haxe.macro.Type.MetaAccess>, ?owner:ClassType):Array<String> {
		var lines:Array<String> = [];
		appendRubyExtensionLines(lines, meta, ":rubyInclude", "include", owner);
		appendRubyExtensionLines(lines, meta, ":rubyPrepend", "prepend", owner);
		appendRubyExtensionLines(lines, meta, ":rubyExtend", "extend", owner);
		return lines;
	}

	static function appendRubyExtensionLines(lines:Array<String>, meta:Null<haxe.macro.Type.MetaAccess>, metaName:String, rubyKeyword:String,
			?owner:ClassType):Void {
		if (meta == null || meta.extract == null) {
			return;
		}
		for (entry in meta.extract(metaName)) {
			if (entry.params == null || entry.params.length == 0) {
				continue;
			}
			var moduleName = rubyExtensionModuleName(entry.params[0], owner);
			if (moduleName != null && moduleName != "") {
				lines.push(rubyKeyword + " " + moduleName);
			}
		}
	}

	static function rubyExtensionModuleName(expr:haxe.macro.Expr, ?owner:ClassType):Null<String> {
		var path = metadataTypePath(expr);
		if (path == null) {
			return null;
		}
		return switch (rubyExtensionContractType(path, owner)) {
			case TInst(ref, _):
				var contract = ref.get();
				rubyMixinModuleName(contract.meta) ?? rubyNativeName(contract.meta) ?? rubyConstantPath(contract.pack, contract.name);
			case _:
				null;
		}
	}

	static function rubyExtensionContractType(path:String, ?owner:ClassType):Null<haxe.macro.Type> {
		var resolved = tryGetType(path);
		if (resolved != null || owner == null || path.indexOf(".") != -1 || owner.module == null || owner.module == "") {
			return resolved;
		}
		return tryGetType(owner.module + "." + path);
	}

	static function tryGetType(path:String):Null<haxe.macro.Type> {
		try {
			return Context.getType(path);
		} catch (_:Dynamic) {
			return null;
		}
	}

	static function rubyMixinModuleName(meta:Null<haxe.macro.Type.MetaAccess>):Null<String> {
		if (meta == null || meta.extract == null) {
			return null;
		}
		var entries = meta.extract(":rubyMixin");
		if (entries.length == 0) {
			entries = meta.extract(":rubyModule");
		}
		if (entries.length == 0) {
			entries = meta.extract(":rubyConcern");
		}
		if (entries.length == 0 || entries[0].params == null || entries[0].params.length == 0) {
			return null;
		}
		return rubyMixinModuleParam(entries[0].params[0]);
	}

	static function rubyMixinModuleParam(expr:haxe.macro.Expr):Null<String> {
		return switch (expr.expr) {
			case EConst(CString(value, _)) if (value.length > 0):
				value;
			case EObjectDecl(fields):
				var moduleName:Null<String> = null;
				for (field in (fields : Array<RubyMetadataField>)) {
					if (field.field == "module") {
						moduleName = metadataStringLiteral(field.expr);
					}
				}
				moduleName;
			case _:
				null;
		}
	}

	static function metadataTypePath(expr:haxe.macro.Expr):Null<String> {
		return switch (expr.expr) {
			case EConst(CIdent(name)): name;
			case EField(target, field):
				var parent = metadataTypePath(target);
				parent == null ? null : parent + "." + field;
			case _:
				null;
		}
	}

	static function wrapInModules(pack:Array<String>, statement:RubyStatement):RubyStatement {
		if (pack == null || pack.length == 0) {
			return statement;
		}
		var wrapped = statement;
		var i = pack.length - 1;
		while (i >= 0) {
			wrapped = RubyModuleDecl(rubyConstantName(pack[i]), [wrapped]);
			i -= 1;
		}
		return wrapped;
	}

	static function fullTypeName(pack:Array<String>, name:String):String {
		if (pack == null || pack.length == 0) {
			return name;
		}
		return pack.concat([name]).join(".");
	}

	static function rubyConstantName(raw:String):String {
		return RubyNaming.toConstantName(raw);
	}

	static function compileMethod(field:ClassFuncData):RubyStatement {
		return compileMethodAs(field, field.isStatic);
	}

	static function compileMethodAs(field:ClassFuncData, emitStatic:Bool):RubyStatement {
		return withLocalNameScope([for (arg in field.args) if (arg.tvar != null) arg.tvar], () -> {
			var name = RubyNaming.toMethodName(field.field.name);
			if (!emitStatic && field.field.name == "new") {
				name = "initialize";
			}
			if (emitStatic) {
				name = "self." + name;
			}
			var args = [
				for (arg in field.args)
					arg.tvar == null ? RubyNaming.toLocalName(arg.getName()) : localName(arg.tvar)
			];
			return RubyMethodDecl(name, args, compileFunctionBody(field.expr));
		});
	}

	static function compileRailsModelMethod(field:ClassFuncData):RubyStatement {
		if (!field.isStatic && field.field.name == "new") {
			return RubyRawStatement("def initialize(*args, **kwargs)\n  args = args + [kwargs] unless kwargs.empty?\n  super(*args)\nend");
		}
		return compileMethod(field);
	}

	static function compileRailsTestMethod(field:ClassFuncData):RubyStatement {
		return withLocalNameScope([for (arg in field.args) if (arg.tvar != null) arg.tvar], () -> {
			return RubyRawStatement(renderRailsTestBlock("test", railsTestDescription(field), field.expr));
		});
	}

	static function railsTestDescription(field:ClassFuncData):String {
		var label = metaStringValue(field.field.meta, ":test");
		if (label != null) {
			return label;
		}
		var name = RubyNaming.toMethodName(field.field.name);
		if (StringTools.startsWith(name, "test_")) {
			name = name.substr("test_".length);
		}
		return StringTools.replace(name, "_", " ");
	}

	static function compileRailsModelScope(field:ClassFuncData, classType:ClassType):String {
		validateRailsModelScope(field, false);
		var name = railsScopeName(field, ":railsScope");
		var lambda = railsScopeLambda(field, classType);
		return "scope :" + RubyNaming.toMethodName(name) + ", " + lambda;
	}

	static function compileRailsModelDefaultScope(field:ClassFuncData, classType:ClassType):String {
		validateRailsModelScope(field, true);
		return "default_scope " + railsScopeLambda(field, classType);
	}

	static function validateRailsModelScope(field:ClassFuncData, defaultScope:Bool):Void {
		var label = defaultScope ? "@:railsDefaultScope" : "@:railsScope";
		if (!field.isStatic) {
			Context.error(label + " must annotate a static model method.", field.field.pos);
		}
		if (field.field.name == "new") {
			Context.error(label + " cannot annotate a constructor.", field.field.pos);
		}
		if (field.expr == null) {
			Context.error(label + " requires a typed method body.", field.field.pos);
		}
		if (defaultScope && field.args.length > 0) {
			Context.error("@:railsDefaultScope methods cannot take arguments.", field.field.pos);
		}
	}

	static function railsScopeName(field:ClassFuncData, metaName:String):String {
		var explicit = metaStringValue(field.field.meta, metaName);
		if (explicit != null) {
			return explicit;
		}
		return field.field.name;
	}

	static function railsScopeLambda(field:ClassFuncData, classType:ClassType):String {
		return withLocalNameScope([for (arg in field.args) if (arg.tvar != null) arg.tvar], () -> {
			var args = [
				for (arg in field.args)
					arg.tvar == null ? RubyNaming.toLocalName(arg.getName()) : localName(arg.tvar)
			];
			var body = [
				for (line in renderStatements(compileRubyBlockBody(field.expr)))
					normalizeRailsScopeBody(line, classType)
			];
			if (canRenderInlineBlock(body)) {
				var prefix = args.length == 0 ? " " : "(" + args.join(", ") + ") ";
				return "->" + prefix + "{ " + body[0] + " }";
			}
			var lines = [args.length == 0 ? "lambda do" : "lambda do |" + args.join(", ") + "|"];
			appendIndentedLines(lines, body, 1);
			lines.push("end");
			return lines.join("\n");
		});
	}

	static function normalizeRailsScopeBody(line:String, classType:ClassType):String {
		var prefix = rubyConstantPath(classType.pack, classType.name) + ".";
		return StringTools.startsWith(line, prefix) ? line.substr(prefix.length) : line;
	}

	static function compileVarField(field:ClassVarData):RubyStatement {
		return withLocalNameScope([], () -> {
			var name = RubyNaming.toLocalName(field.field.name);
			if (!field.isStatic) {
				return RubyRawStatement("attr_accessor :" + name);
			}
			var init = field.findDefaultExpr();
			var initExpr = init == null ? compileUntypedConst(field.getDefaultUntypedExpr()) : compileExpr(init);
			return RubyRawStatement("class << self\n  attr_accessor :" + name + "\nend\n@" + name + " = " +
				reflaxe.ruby.ast.RubyASTPrinter.printExpr(initExpr));
		});
	}

	static function compileMathConstantField(name:String, value:String):RubyStatement {
		return RubyRawStatement("def self." + RubyNaming.toMethodName(name) + "()\n  " + value + "\nend");
	}

	static function mathConstantValue(pack:Array<String>, typeName:String, fieldName:String):Null<String> {
		if (fullTypeName(pack, typeName) != "Math") {
			return null;
		}
		return switch (fieldName) {
			case "PI": "::Math::PI";
			case "NEGATIVE_INFINITY": "-Float::INFINITY";
			case "POSITIVE_INFINITY": "Float::INFINITY";
			case "NaN": "Float::NAN";
			case _: null;
		}
	}

	static function typeNameMetadata(name:String):RubyStatement {
		return RubyRawStatement("def self.__hx_name()\n  " + quoteRubyStringForCode(name) + "\nend");
	}

	static function compileEnumBody(enumType:EnumType, options:Array<EnumOptionData>):Array<RubyStatement> {
		var out:Array<RubyStatement> = [typeNameMetadata(fullTypeName(enumType.pack, enumType.name))];
		var index = 0;
		var metadata:Array<String> = [];
		for (option in options) {
			var ctorName = RubyNaming.toConstantName(option.name);
			var methodName = RubyNaming.toMethodName(option.name);
			var argNames = [for (arg in option.args) RubyNaming.toLocalName(arg.name)];
			metadata.push("{name: " + quoteRubyStringForCode(option.name) + ", index: " + Std.string(index) + ", method: " + rubySymbolLiteral(methodName)
				+ ", arity: " + Std.string(argNames.length) + "}");
			var dataFields = argNames.concat(["__hx_tag", "__hx_index"]);
			out.push(RubyRawStatement(ctorName + " = Data.define(" + [for (name in dataFields) ":" + name].join(", ") + ")"));
			var ctorArgs = argNames.concat([quoteRubyStringForCode(option.name), Std.string(index)]);
			out.push(RubyRawStatement("def self." + methodName + "(" + argNames.join(", ") + ")\n  " + ctorName + ".new(" + ctorArgs.join(", ") + ")\nend"));
			index++;
		}
		out.insert(1, RubyRawStatement("def self.__hx_constructs()\n  [" + metadata.join(", ") + "]\nend"));
		if (out.length == 0) {
			out.push(RubyComment("empty enum"));
		}
		return out;
	}

	static function isMacroOnlyRuntimeType(pack:Array<String>):Bool {
		return pack.length >= 2 && ((pack[0] == "haxe" && pack[1] == "macro") || (pack[0] == "rails" && pack[1] == "macros"));
	}

	function setRubyOutputPath(pack:Array<String>, typeName:String):Void {
		setOutputFileName(RubyNaming.fileName(typeName));
		setOutputFileDir(outputRelativeDir(RubyNaming.fileDir(pack), !isStdRubyType(pack, typeName)));
		rememberRubyPath(pack, typeName);
	}

	function rememberRubyPath(pack:Array<String>, typeName:String):Void {
		var path = RubyNaming.fileName(typeName) + ".rb";
		var dir = outputRelativeDir(RubyNaming.fileDir(pack), !isStdRubyType(pack, typeName));
		if (dir != null && dir != "") {
			path = dir + "/" + path;
		}
		if (emittedRubyPaths.indexOf(path) == -1) {
			emittedRubyPaths.push(path);
		}
		if (!isStdRubyType(pack, typeName) && emittedAppRubyPaths.indexOf(path) == -1) {
			emittedAppRubyPaths.push(path);
		}
	}

	function compileRailsControllerImpl(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>,
			moduleRequires:RequireRegistry):RubyFile {
		validateDeviseCurrentRequiredFlow(varFields, funcFields);
		var body:Array<String> = [];
		body = body.concat(rubyExtensionLines(classType.meta, classType));
		body = body.concat(railsControllerLifecycleLines(classType, varFields));
		body = body.concat(railsControllerFilterLines(funcFields));
		for (field in varFields) {
			if (isRailsControllerLifecycleField(field)) {
				continue;
			}
			body = body.concat(renderStatements([compileVarField(field)]));
		}
		for (field in funcFields) {
			if (field.expr == null || hasMeta(field.field.meta, ":rubyExternStub")) {
				continue;
			}
			body = body.concat(renderStatements([compileMethod(field)]));
		}
		if (body.length == 0) {
			body.push("# Rails controller generated by reflaxe.ruby");
		}

		var lines = [
			"class " + RubyNaming.toConstantName(classType.name) + " < ActionController::Base"
		];
		for (line in body) {
			lines.push("  " + line);
		}
		lines.push("end");

		var statements:Array<RubyStatement> = [
			RubyComment("Generated by reflaxe.ruby"),
			RubyComment("Rails controller output; Zeitwerk path should match the Ruby constant.")
		];
		statements = statements.concat(requirePreludeStatements(moduleRequires));
		statements.push(wrapInModules(classType.pack, RubyRawStatement(lines.join("\n"))));
		return {
			modulePath: classType.pack == null ? [] : classType.pack.copy(),
			statements: statements
		};
	}

	function compileRailsMailerImpl(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>,
			moduleRequires:RequireRegistry):RubyFile {
		var body:Array<String> = [];
		body = body.concat(rubyExtensionLines(classType.meta, classType));
		for (field in varFields) {
			if (hasMeta(field.field.meta, ":rubyExternStub")) {
				continue;
			}
			body = body.concat(renderStatements([compileVarField(field)]));
		}
		for (field in funcFields) {
			if (field.expr == null || hasMeta(field.field.meta, ":rubyExternStub")) {
				continue;
			}
			body = body.concat(renderStatements([compileMethod(field)]));
		}
		if (body.length == 0) {
			body.push("# Rails mailer generated by reflaxe.ruby");
		}

		var lines = ["class " + RubyNaming.toConstantName(classType.name) + " < ActionMailer::Base"];
		for (line in body) {
			lines.push("  " + line);
		}
		lines.push("end");

		var statements:Array<RubyStatement> = [
			RubyComment("Generated by reflaxe.ruby"),
			RubyComment("Rails mailer output; Zeitwerk path should match the Ruby constant.")
		];
		statements = statements.concat(requirePreludeStatements(moduleRequires));
		statements.push(wrapInModules(classType.pack, RubyRawStatement(lines.join("\n"))));
		return {
			modulePath: classType.pack == null ? [] : classType.pack.copy(),
			statements: statements
		};
	}

	function compileRailsJobImpl(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>, moduleRequires:RequireRegistry):RubyFile {
		var body:Array<String> = [];
		body = body.concat(rubyExtensionLines(classType.meta, classType));
		body = body.concat(railsJobLifecycleLines(varFields));
		body = body.concat(railsJobMetadataLines(classType));
		for (field in varFields) {
			if (isRailsJobLifecycleField(field)) {
				continue;
			}
			body = body.concat(renderStatements([compileVarField(field)]));
		}
		for (field in funcFields) {
			if (field.expr == null || hasMeta(field.field.meta, ":rubyExternStub")) {
				continue;
			}
			body = body.concat(renderStatements([compileMethod(field)]));
		}
		if (body.length == 0) {
			body.push("# Rails job generated by reflaxe.ruby");
		}

		var lines = ["class " + RubyNaming.toConstantName(classType.name) + " < ActiveJob::Base"];
		for (line in body) {
			lines.push("  " + line);
		}
		lines.push("end");

		var statements:Array<RubyStatement> = [
			RubyComment("Generated by reflaxe.ruby"),
			RubyComment("Rails job output; Zeitwerk path should match the Ruby constant.")
		];
		statements = statements.concat(requirePreludeStatements(moduleRequires));
		statements.push(wrapInModules(classType.pack, RubyRawStatement(lines.join("\n"))));
		return {
			modulePath: classType.pack == null ? [] : classType.pack.copy(),
			statements: statements
		};
	}

	function compileRailsChannelImpl(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>,
			moduleRequires:RequireRegistry):RubyFile {
		var body:Array<String> = [];
		body = body.concat(rubyExtensionLines(classType.meta, classType));
		for (field in varFields) {
			body = body.concat(renderStatements([compileVarField(field)]));
		}
		for (field in funcFields) {
			if (field.field.name == "new" || field.expr == null || hasMeta(field.field.meta, ":rubyExternStub")) {
				continue;
			}
			body = body.concat(renderStatements([compileMethod(field)]));
		}
		if (body.length == 0) {
			body.push("# Rails ActionCable channel generated by reflaxe.ruby");
		}

		var lines = [
			"class " + RubyNaming.toConstantName(classType.name) + " < ActionCable::Channel::Base"
		];
		for (line in body) {
			lines.push("  " + line);
		}
		lines.push("end");

		var statements:Array<RubyStatement> = [
			RubyComment("Generated by reflaxe.ruby"),
			RubyComment("Rails ActionCable channel output; Zeitwerk path should match the Ruby constant.")
		];
		statements = statements.concat(requirePreludeStatements(moduleRequires));
		statements.push(wrapInModules(classType.pack, RubyRawStatement(lines.join("\n"))));
		return {
			modulePath: classType.pack == null ? [] : classType.pack.copy(),
			statements: statements
		};
	}

	function compileRailsCableConnectionImpl(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>,
			moduleRequires:RequireRegistry):RubyFile {
		var body:Array<String> = [];
		body = body.concat(rubyExtensionLines(classType.meta, classType));
		body = body.concat(railsCableConnectionIdentifierLines(classType, varFields));
		for (field in varFields) {
			if (isRailsCableConnectionInternalField(field)) {
				continue;
			}
			body = body.concat(renderStatements([compileVarField(field)]));
		}
		for (field in funcFields) {
			if (field.field.name == "new" || field.expr == null || hasMeta(field.field.meta, ":rubyExternStub")) {
				continue;
			}
			body = body.concat(renderStatements([compileMethod(field)]));
		}
		if (body.length == 0) {
			body.push("# Rails ActionCable connection generated by reflaxe.ruby");
		}

		var lines = [
			"class " + RubyNaming.toConstantName(classType.name) + " < ActionCable::Connection::Base"
		];
		for (line in body) {
			lines.push("  " + line);
		}
		lines.push("end");

		var statements:Array<RubyStatement> = [
			RubyComment("Generated by reflaxe.ruby"),
			RubyComment("Rails ActionCable connection output; Zeitwerk path should match the Ruby constant.")
		];
		statements = statements.concat(requirePreludeStatements(moduleRequires));
		statements.push(wrapInModules(classType.pack, RubyRawStatement(lines.join("\n"))));
		return {
			modulePath: classType.pack == null ? [] : classType.pack.copy(),
			statements: statements
		};
	}

	static function railsCableConnectionIdentifierLines(classType:ClassType, varFields:Array<ClassVarData>):Array<String> {
		var identifiers = railsCableConnectionIdentifiersField(varFields);
		if (identifiers == null) {
			Context.error('@:railsCableConnection class ${classType.name} must declare `static final identifiers = { identifiedBy(...); }`. Use `[]` when no identifiers are needed.',
				classType.pos);
			return [];
		}
		if (!identifiers.isStatic) {
			Context.error("Rails ActionCable connection identifiers must be static: `static final identifiers = { identifiedBy(...); }`.",
				identifiers.field.pos);
			return [];
		}
		var expr = identifiers.field.expr();
		if (expr == null) {
			Context.error("Rails ActionCable connection identifiers must have a block initializer: `static final identifiers = { identifiedBy(...); }`.",
				identifiers.field.pos);
			return [];
		}
		var lines:Array<String> = [];
		for (entry in railsCableConnectionIdentifierEntries(expr)) {
			var name = railsCableConnectionIdentifierDecl(entry);
			if (name.length > 0) {
				lines.push("identified_by " + rubySymbolLiteral(RubyNaming.toMethodName(name)));
			}
		}
		return lines;
	}

	static function railsCableConnectionIdentifiersField(varFields:Array<ClassVarData>):Null<ClassVarData> {
		var found:Null<ClassVarData> = null;
		for (field in varFields) {
			if (field.field.name == "identifiers") {
				found = field;
			}
		}
		return found;
	}

	static function isRailsCableConnectionInternalField(field:ClassVarData):Bool {
		return field.field.name == "identifiers" || isActionCableConnectionIdentifierType(field.field.type);
	}

	static function railsCableConnectionIdentifierEntries(expr:TypedExpr):Array<TypedExpr> {
		var unwrapped = unwrapTypedExpr(expr);
		return switch (unwrapped.expr) {
			case TBlock(entries):
				entries;
			case TArrayDecl(values) if (values.length == 0):
				[];
			case TCall(_, _):
				[unwrapped];
			case _:
				Context.error("Rails ActionCable connection identifiers must be a Haxe block: `static final identifiers = { identifiedBy(...); }`.",
					unwrapped.pos);
				[];
		}
	}

	static function railsCableConnectionIdentifierDecl(expr:TypedExpr):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall(callee, params) if (isRailsCableConnectionDeclMarker(callee, "identifiedBy") && params.length == 1):
				actionCableConnectionIdentifierName(params[0]);
			case _:
				Context.error("Rails ActionCable connection identifier entries must be produced by rails.macros.CableConnectionDsl.identifiedBy(...).",
					expr.pos);
				"";
		}
	}

	static function isRailsCableConnectionDeclMarker(expr:TypedExpr, name:String):Bool {
		return switch (unwrapTypedExpr(expr).expr) {
			case TField(_, FStatic(classRef, fieldRef)): fullTypeName(classRef.get().pack,
					classRef.get().name) == "rails.action_cable.ConnectionDecl" && fieldRef.get().name == name;
			case _:
				false;
		}
	}

	static function railsJobMetadataLines(classType:ClassType):Array<String> {
		var lines:Array<String> = [];
		var queue = metaStringValue(classType.meta, ":queueAs");
		if (queue != null) {
			lines.push("queue_as " + rubySymbolLiteral(RubyNaming.toMethodName(queue)));
		}
		if (classType.meta != null && classType.meta.extract != null) {
			for (entry in classType.meta.extract(":retryOn")) {
				lines.push("retry_on " + railsJobExceptionConstant(entry.params, 0, "@:retryOn") + railsJobOptionsSuffix(entry.params, 1, "@:retryOn"));
			}
			for (entry in classType.meta.extract(":discardOn")) {
				lines.push("discard_on " + railsJobExceptionConstant(entry.params, 0, "@:discardOn"));
			}
		}
		return lines;
	}

	static function railsJobLifecycleLines(varFields:Array<ClassVarData>):Array<String> {
		var lifecycle = railsJobLifecycleField(varFields);
		if (lifecycle == null) {
			return [];
		}
		if (!lifecycle.isStatic) {
			Context.error("Rails job lifecycle must be static: `static final lifecycle = { ... }`.", lifecycle.field.pos);
			return [];
		}
		var expr = lifecycle.field.expr();
		if (expr == null) {
			Context.error("Rails job lifecycle must have a block initializer: `static final lifecycle = { ... }`.", lifecycle.field.pos);
			return [];
		}
		var lines:Array<String> = [];
		for (entry in railsJobLifecycleEntries(expr)) {
			var decl = railsJobLifecycleDecl(entry);
			switch (decl.kind) {
				case "queue_as":
					lines.push("queue_as " + rubySymbolLiteral(RubyNaming.toMethodName(decl.queue)));
				case "retry_on":
					lines.push("retry_on " + decl.exception + railsJobLifecycleOptions(decl));
				case "discard_on":
					lines.push("discard_on " + decl.exception);
				case other:
					Context.error('Unsupported Rails job lifecycle declaration "$other". Use queueAs, retryOn, or discardOn.', entry.pos);
			}
		}
		return lines;
	}

	static function railsJobLifecycleField(varFields:Array<ClassVarData>):Null<ClassVarData> {
		var found:Null<ClassVarData> = null;
		for (field in varFields) {
			if (field.field.name == "lifecycle") {
				found = field;
			}
		}
		return found;
	}

	static function isRailsJobLifecycleField(field:ClassVarData):Bool {
		return field.field.name == "lifecycle";
	}

	static function railsJobLifecycleEntries(expr:TypedExpr):Array<TypedExpr> {
		var unwrapped = unwrapTypedExpr(expr);
		return switch (unwrapped.expr) {
			case TBlock(entries):
				entries;
			case TArrayDecl(values) if (values.length == 0):
				[];
			case _:
				Context.error("Rails job lifecycle must be a Haxe block: `static final lifecycle = { queueAs(...); retryOn(...); }`.", unwrapped.pos);
				[];
		}
	}

	static function railsJobLifecycleDecl(expr:TypedExpr):{
		kind:String,
		queue:String,
		exception:String,
		waitSeconds:Int,
		attempts:Int,
		retryQueue:String
	} {
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall(callee, params) if (isRailsJobLifecycleMarker(callee, "queue") && params.length == 1):
				{
					kind: "queue_as",
					queue: railsJobLifecycleStringValue(params[0], "queue"),
					exception: "",
					waitSeconds: -1,
					attempts: -1,
					retryQueue: ""
				};
			case TCall(callee, params) if (isRailsJobLifecycleMarker(callee, "retry") && params.length == 4):
				{
					kind: "retry_on",
					queue: "",
					exception: railsJobLifecycleStringValue(params[0], "retry exception"),
					waitSeconds: railsJobLifecycleIntValue(params[1], "retry waitSeconds"),
					attempts: railsJobLifecycleIntValue(params[2], "retry attempts"),
					retryQueue: railsJobLifecycleStringValue(params[3], "retry queue")
				};
			case TCall(callee, params) if (isRailsJobLifecycleMarker(callee, "discard") && params.length == 1):
				{
					kind: "discard_on",
					queue: "",
					exception: railsJobLifecycleStringValue(params[0], "discard exception"),
					waitSeconds: -1,
					attempts: -1,
					retryQueue: ""
				};
			case _:
				Context.error("Rails job lifecycle entries must be produced by rails.macros.JobDsl declarations.", expr.pos);
				{
					kind: "",
					queue: "",
					exception: "",
					waitSeconds: -1,
					attempts: -1,
					retryQueue: ""
				};
		}
	}

	static function isRailsJobLifecycleMarker(expr:TypedExpr, name:String):Bool {
		return switch (unwrapTypedExpr(expr).expr) {
			case TField(_, FStatic(classRef, fieldRef)): fullTypeName(classRef.get().pack,
					classRef.get().name) == "rails.active_job.LifecycleDecl" && fieldRef.get().name == name;
			case _:
				false;
		}
	}

	static function railsJobLifecycleOptions(decl:{
		kind:String,
		queue:String,
		exception:String,
		waitSeconds:Int,
		attempts:Int,
		retryQueue:String
	}):String {
		var options:Array<String> = [];
		if (decl.waitSeconds >= 0) {
			options.push("wait: " + decl.waitSeconds + ".seconds");
		}
		if (decl.attempts >= 0) {
			options.push("attempts: " + decl.attempts);
		}
		if (decl.retryQueue.length > 0) {
			options.push("queue: " + rubySymbolLiteral(RubyNaming.toMethodName(decl.retryQueue)));
		}
		return options.length == 0 ? "" : ", " + options.join(", ");
	}

	static function railsJobLifecycleStringValue(expr:TypedExpr, name:String):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)): value;
			case _:
				Context.error('Rails job lifecycle "$name" must be a string marker value.', expr.pos);
				"";
		}
	}

	static function railsJobLifecycleIntValue(expr:TypedExpr, name:String):Int {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TInt(value)): value;
			case _:
				Context.error('Rails job lifecycle "$name" must be an int marker value.', expr.pos);
				-1;
		}
	}

	static function railsJobExceptionConstant(params:Null<Array<haxe.macro.Expr>>, index:Int, metaName:String):String {
		if (params == null || params.length <= index) {
			Context.error(metaName + " expects a Ruby exception constant string.", Context.currentPos());
			return "StandardError";
		}
		return switch (params[index].expr) {
			case EConst(CString(value, _)) if (isSafeRubyConstantPath(value)):
				value;
			case EConst(CString(value, _)):
				Context.error(metaName + ' exception constant "$value" is not a safe Ruby constant path.', params[index].pos);
				"StandardError";
			case _:
				Context.error(metaName + " expects a Ruby exception constant string.", params[index].pos);
				"StandardError";
		}
	}

	static function railsJobOptionsSuffix(params:Null<Array<haxe.macro.Expr>>, index:Int, metaName:String):String {
		if (params == null || params.length <= index) {
			return "";
		}
		return switch (params[index].expr) {
			case EObjectDecl(fields):
				var options:Array<String> = [];
				for (field in fields) {
					switch (field.field) {
						case "waitSeconds":
							options.push("wait: " + railsJobIntOption(field.expr, metaName + " waitSeconds") + ".seconds");
						case "attempts":
							options.push("attempts: " + railsJobIntOption(field.expr, metaName + " attempts"));
						case "queue":
							options.push("queue: " + rubySymbolLiteral(RubyNaming.toMethodName(railsJobStringOption(field.expr, metaName + " queue"))));
						case other:
							Context.error(metaName + ' unsupported option "$other". Use waitSeconds, attempts, or queue.', field.expr.pos);
					}
				}
				options.length == 0 ? "" : ", " + options.join(", ");
			case _:
				Context.error(metaName + " options must be an object literal.", params[index].pos);
				"";
		}
	}

	static function railsJobIntOption(expr:haxe.macro.Expr, label:String):String {
		return switch (expr.expr) {
			case EConst(CInt(value, _)): value;
			case _:
				Context.error(label + " must be an integer literal.", expr.pos);
				"0";
		}
	}

	static function railsJobStringOption(expr:haxe.macro.Expr, label:String):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)) if (value.length > 0): value;
			case _:
				Context.error(label + " must be a non-empty string literal.", expr.pos);
				"";
		}
	}

	static function isSafeRubyConstantPath(value:String):Bool {
		return ~/^[A-Z][A-Za-z0-9_]*(::[A-Z][A-Za-z0-9_]*)*$/.match(value);
	}

	static function isSafeRubyIdentifier(value:String):Bool {
		return ~/^[a-z][a-z0-9_]*$/.match(value);
	}

	static function railsControllerLifecycleLines(classType:ClassType, varFields:Array<ClassVarData>):Array<String> {
		var lifecycle = railsControllerLifecycleField(varFields);
		if (lifecycle == null) {
			Context.error('@:railsController class ${classType.name} must declare `static final lifecycle = { ... }`. Use `[]` when the controller has no filters or rescues.',
				classType.pos);
			return [];
		}
		if (!lifecycle.isStatic) {
			Context.error("Rails controller lifecycle must be static: `static final lifecycle = { ... }`.", lifecycle.field.pos);
			return [];
		}
		var expr = lifecycle.field.expr();
		if (expr == null) {
			Context.error("Rails controller lifecycle must have a block initializer: `static final lifecycle = { ... }`.", lifecycle.field.pos);
			return [];
		}
		var lines:Array<String> = [];
		for (entry in railsControllerLifecycleEntries(expr)) {
			var decl = railsControllerLifecycleDecl(entry);
			switch (decl.kind) {
				case "before_action" | "after_action" | "around_action" | "skip_before_action" | "skip_after_action" | "skip_around_action":
					lines.push(decl.kind + " " + railsControllerLifecycleMethodSymbol(decl.method) + railsControllerLifecycleOptions(decl));
				case "protect_from_forgery":
					lines.push("protect_from_forgery " + railsControllerForgeryProtectionOptions(decl));
				case "rescue_from":
					if (decl.exceptions.length == 0) {
						Context.error("rescueFrom lifecycle declaration must include at least one exception.", entry.pos);
					} else {
						lines.push("rescue_from " + decl.exceptions.join(", ") + ", with: " + rubySymbolLiteral(RubyNaming.toMethodName(decl.method)));
					}
				case other:
					Context.error('Unsupported Rails controller lifecycle declaration "$other". Use beforeAction, afterAction, aroundAction, skipBeforeAction, skipAfterAction, skipAroundAction, protectFromForgery, or rescueFrom.',
						entry.pos);
			}
		}
		return lines;
	}

	static function railsControllerLifecycleMethodSymbol(method:String):String {
		return isRubyBangOrPredicateMethodName(method) ? rubySymbolLiteral(method) : rubySymbolLiteral(RubyNaming.toMethodName(method));
	}

	static function railsControllerLifecycleField(varFields:Array<ClassVarData>):Null<ClassVarData> {
		var found:Null<ClassVarData> = null;
		for (field in varFields) {
			if (field.field.name == "lifecycle") {
				found = field;
			}
		}
		return found;
	}

	static function isRailsControllerLifecycleField(field:ClassVarData):Bool {
		return field.field.name == "lifecycle";
	}

	static function railsControllerLifecycleEntries(expr:TypedExpr):Array<TypedExpr> {
		var unwrapped = unwrapTypedExpr(expr);
		return switch (unwrapped.expr) {
			case TBlock(entries):
				entries;
			case TArrayDecl(values) if (values.length == 0):
				[];
			case TCall(_, _):
				[unwrapped];
			case _:
				Context.error("Rails controller lifecycle must be a Haxe block: `static final lifecycle = { beforeAction(...); rescueFrom(...); }`.",
					unwrapped.pos);
				[];
		}
	}

	static function railsControllerLifecycleDecl(expr:TypedExpr):{
		kind:String,
		method:String,
		only:Array<String>,
		except:Array<String>,
		exceptions:Array<String>,
		strategy:String,
		prepend:Bool
	} {
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall(callee, params) if (isRailsControllerLifecycleMarker(callee, "filter") && params.length == 4):
				var kind = railsControllerLifecycleStringValue(params[0], "filter kind");
				var method = railsControllerLifecycleStringValue(params[1], "filter method");
				{
					kind: kind,
					method: method,
					only: railsControllerLifecycleStringArray(params[2], "only"),
					except: railsControllerLifecycleStringArray(params[3], "except"),
					exceptions: [],
					strategy: "",
					prepend: false
				};
			case TCall(callee, params) if (isRailsControllerLifecycleMarker(callee, "rescue") && params.length == 2):
				{
					kind: "rescue_from",
					method: railsControllerLifecycleStringValue(params[0], "rescue method"),
					only: [],
					except: [],
					exceptions: railsControllerLifecycleStringArray(params[1], "exceptions"),
					strategy: "",
					prepend: false
				};
			case TCall(callee, params) if (isRailsControllerLifecycleMarker(callee, "protectFromForgery") && params.length == 4):
				{
					kind: "protect_from_forgery",
					method: "",
					only: railsControllerLifecycleStringArray(params[2], "only"),
					except: railsControllerLifecycleStringArray(params[3], "except"),
					exceptions: [],
					strategy: railsControllerLifecycleStringValue(params[0], "forgery protection strategy"),
					prepend: railsControllerLifecycleBoolValue(params[1], "forgery protection prepend")
				};
			case _:
				Context.error("Rails controller lifecycle entries must be produced by rails.macros.ControllerDsl declarations.", expr.pos);
				{
					kind: "",
					method: "",
					only: [],
					except: [],
					exceptions: [],
					strategy: "",
					prepend: false
				};
		}
	}

	static function isRailsControllerLifecycleMarker(expr:TypedExpr, name:String):Bool {
		return switch (unwrapTypedExpr(expr).expr) {
			case TField(_, FStatic(classRef, fieldRef)): fullTypeName(classRef.get().pack,
					classRef.get().name) == "rails.action_controller.LifecycleDecl" && fieldRef.get().name == name;
			case _:
				false;
		}
	}

	static function railsControllerLifecycleOptions(decl:{
		kind:String,
		method:String,
		only:Array<String>,
		except:Array<String>,
		exceptions:Array<String>
	}):String {
		var options:Array<String> = [];
		if (decl.only.length > 0) {
			options.push("only: [" + [for (action in decl.only) rubySymbolLiteral(RubyNaming.toMethodName(action))].join(", ") + "]");
		}
		if (decl.except.length > 0) {
			options.push("except: [" + [for (action in decl.except) rubySymbolLiteral(RubyNaming.toMethodName(action))].join(", ") + "]");
		}
		return options.length == 0 ? "" : ", " + options.join(", ");
	}

	static function railsControllerForgeryProtectionOptions(decl:{
		kind:String,
		method:String,
		only:Array<String>,
		except:Array<String>,
		exceptions:Array<String>,
		strategy:String,
		prepend:Bool
	}):String {
		var options:Array<String> = ["with: " + rubySymbolLiteral(decl.strategy)];
		if (decl.prepend) {
			options.push("prepend: true");
		}
		if (decl.only.length > 0) {
			options.push("only: [" + [for (action in decl.only) rubySymbolLiteral(RubyNaming.toMethodName(action))].join(", ") + "]");
		}
		if (decl.except.length > 0) {
			options.push("except: [" + [for (action in decl.except) rubySymbolLiteral(RubyNaming.toMethodName(action))].join(", ") + "]");
		}
		return options.join(", ");
	}

	static function validateDeviseCurrentRequiredFlow(varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>):Void {
		if (!Context.defined("railshx_devise_strict_current_required")) {
			return;
		}
		var protectedScopesByAction = deviseProtectedScopesByAction(varFields, funcFields);
		for (field in funcFields) {
			if (field.isStatic || field.expr == null || hasMeta(field.field.meta, ":rubyExternStub")) {
				continue;
			}
			var action = field.field.name;
			var scopes = protectedScopesByAction.get(action);
			if (scopes == null) {
				scopes = new Map();
			}
			iterTypedExprRecursive(field.expr, function(expr:TypedExpr) {
				var requiredScope = deviseCurrentRequiredScope(expr);
				if (requiredScope == null) {
					return;
				}
				if (!scopes.exists(requiredScope)) {
					Context.error('DeviseHx currentRequired for scope "$requiredScope" in action "$action" requires a matching beforeAction(UserAuth.authenticate) guard. Add the guard, narrow the lifecycle only/except options, or use current(...) and handle Null explicitly.',
						expr.pos);
				}
			});
		}
	}

	static function iterTypedExprRecursive(expr:TypedExpr, visit:TypedExpr->Void):Void {
		visit(expr);
		TypedExprTools.iter(expr, function(child:TypedExpr) {
			iterTypedExprRecursive(child, visit);
		});
	}

	static function deviseProtectedScopesByAction(varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>):Map<String, Map<String, Bool>> {
		var out:Map<String, Map<String, Bool>> = new Map();
		var actions = [
			for (field in funcFields)
				if (!field.isStatic && field.expr != null && !hasMeta(field.field.meta, ":rubyExternStub")) field.field.name
		];
		var lifecycle = railsControllerLifecycleField(varFields);
		if (lifecycle == null || lifecycle.field.expr() == null) {
			return out;
		}
		for (entry in railsControllerLifecycleEntries(lifecycle.field.expr())) {
			var decl = railsControllerLifecycleDecl(entry);
			switch (decl.kind) {
				case "before_action":
					var scope = deviseAuthenticateScope(decl.method);
					if (scope == null) {
						continue;
					}
					for (action in actions) {
						if (!railsLifecycleCoversAction(decl.only, decl.except, action)) {
							continue;
						}
						var scopes = out.get(action);
						if (scopes == null) {
							scopes = new Map();
							out.set(action, scopes);
						}
						scopes.set(scope, true);
					}
				case "skip_before_action":
					var scope = deviseAuthenticateScope(decl.method);
					if (scope == null) {
						continue;
					}
					for (action in actions) {
						if (!railsLifecycleCoversAction(decl.only, decl.except, action)) {
							continue;
						}
						var scopes = out.get(action);
						if (scopes != null) {
							scopes.remove(scope);
						}
					}
				case _:
					continue;
			}
		}
		return out;
	}

	static function railsLifecycleCoversAction(only:Array<String>, except:Array<String>, action:String):Bool {
		if (only.length > 0 && only.indexOf(action) == -1) {
			return false;
		}
		if (except.indexOf(action) != -1) {
			return false;
		}
		return true;
	}

	static function deviseAuthenticateScope(method:String):Null<String> {
		var prefix = "authenticate_";
		var suffix = "!";
		if (!StringTools.startsWith(method, prefix) || !StringTools.endsWith(method, suffix)) {
			return null;
		}
		var scope = method.substr(prefix.length, method.length - prefix.length - suffix.length);
		return ~/^[a-z][a-z0-9_]*$/.match(scope) ? scope : null;
	}

	static function deviseCurrentRequiredScope(expr:TypedExpr):Null<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall(callee, params):
				var info = staticFieldInfo(callee);
				if (info != null) {
					var meta = metadataObject(info.field.meta, ":deviseHxHelper");
					if (meta != null && metadataObjectString(meta, "kind", info.field.pos) == "currentRequired") {
						var scope = metadataObjectString(meta, "mappingScope", info.field.pos);
						validateDeviseMappingScope(scope, info.field.pos);
						return scope;
					}
				}
				var call = staticCallInfo(callee);
				if (call != null && call.owner == "devisehx.Auth" && call.name == "currentRequired" && params.length == 2) {
					return deviseMappingScopeFromArg(params[1]);
				}
				null;
			case _:
				null;
		}
	}

	static function railsControllerLifecycleStringValue(expr:TypedExpr, name:String):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)): value;
			case _:
				Context.error('Rails controller lifecycle "$name" must be a string marker value.', expr.pos);
				"";
		}
	}

	static function railsControllerLifecycleBoolValue(expr:TypedExpr, name:String):Bool {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TBool(value)): value;
			case _:
				Context.error('Rails controller lifecycle "$name" must be a boolean marker value.', expr.pos);
				false;
		}
	}

	static function railsControllerLifecycleStringArray(expr:TypedExpr, name:String):Array<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TArrayDecl(values):
				[for (value in values) railsControllerLifecycleStringArrayValue(value, name)];
			case _:
				Context.error('Rails controller lifecycle "$name" must be an array marker value.', expr.pos);
				[];
		}
	}

	static function railsControllerLifecycleStringArrayValue(expr:TypedExpr, name:String):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)): value;
			case _:
				Context.error('Rails controller lifecycle field "$name" must contain only string carrier values.', expr.pos);
				"";
		}
	}

	static function railsControllerFilterLines(funcFields:Array<ClassFuncData>):Array<String> {
		var lines:Array<String> = [];
		for (field in funcFields) {
			for (filter in railsControllerFilters(field)) {
				lines.push(filter.kind + " " + rubySymbolLiteral(filter.method) + filter.options);
			}
		}
		return lines;
	}

	static function railsControllerFilters(field:ClassFuncData):Array<{kind:String, method:String, options:String}> {
		var filters:Array<{kind:String, method:String, options:String}> = [];
		var meta = field.field.meta;
		if (meta == null || meta.extract == null) {
			return filters;
		}
		var pairs:Array<{metaName:String, rubyName:String}> = [
			{metaName: ":beforeAction", rubyName: "before_action"},
			{metaName: ":afterAction", rubyName: "after_action"},
			{metaName: ":aroundAction", rubyName: "around_action"}
		];
		for (pair in pairs) {
			for (entry in meta.extract(pair.metaName)) {
				railsControllerValidateFilter(field, pair.metaName);
				filters.push({
					kind: pair.rubyName,
					method: RubyNaming.toMethodName(field.field.name),
					options: railsControllerFilterOptions(entry.params)
				});
			}
		}
		for (entry in meta.extract(":railsFilter")) {
			railsControllerValidateFilter(field, ":railsFilter");
			if (entry.params == null || entry.params.length == 0) {
				Context.error("@:railsFilter expects a Rails filter name such as \"before_action\".", field.field.pos);
				continue;
			}
			var kind = switch (entry.params[0].expr) {
				case EConst(CString(value, _)) if (isSupportedRailsControllerFilter(value)):
					RubyNaming.toMethodName(value);
				case EConst(CString(value, _)):
					Context.error('@:railsFilter unsupported filter "$value". Use before_action, after_action, or around_action.', entry.params[0].pos);
					"before_action";
				case _:
					Context.error("@:railsFilter first argument must be a string literal.", entry.params[0].pos);
					"before_action";
			}
			filters.push({
				kind: kind,
				method: RubyNaming.toMethodName(field.field.name),
				options: railsControllerFilterOptions(entry.params.slice(1))
			});
		}
		return filters;
	}

	static function railsControllerValidateFilter(field:ClassFuncData, metaName:String):Void {
		if (field.isStatic) {
			Context.error(metaName + " must annotate an instance method.", field.field.pos);
		}
		if (field.field.name == "new") {
			Context.error(metaName + " cannot annotate a constructor.", field.field.pos);
		}
		if (field.args.length > 0) {
			Context.error(metaName + " callback method must not declare Haxe arguments; Rails calls controller filters without Haxe parameters.",
				field.field.pos);
		}
	}

	static function isSupportedRailsControllerFilter(value:String):Bool {
		var normalized = RubyNaming.toMethodName(value);
		return normalized == "before_action" || normalized == "after_action" || normalized == "around_action";
	}

	static function railsControllerFilterOptions(params:Null<Array<haxe.macro.Expr>>):String {
		if (params == null || params.length == 0) {
			return "";
		}
		var options = switch (params[0].expr) {
			case EObjectDecl(fields):
				[for (field in fields) railsControllerFilterOption(field.field, field.expr)];
			case _:
				Context.error("@:beforeAction/@:afterAction/@:aroundAction filter options must be an object literal.", params[0].pos);
				[];
		}
		return options.length == 0 ? "" : ", " + options.join(", ");
	}

	static function railsControllerFilterOption(name:String, expr:haxe.macro.Expr):String {
		var rubyName = RubyNaming.toMethodName(name);
		var value = switch (name) {
			case "only" | "except":
				railsControllerActionListOption(expr);
			case _:
				metadataValueCode(expr);
		}
		return rubyName + ": " + value;
	}

	static function railsControllerActionListOption(expr:haxe.macro.Expr):String {
		return switch (expr.expr) {
			case EArrayDecl(values):
				"[" + [for (value in values) railsControllerActionSymbolOption(value)].join(", ") + "]";
			case EConst(CString(value, _)):
				rubySymbolLiteral(RubyNaming.toMethodName(value));
			case _:
				metadataValueCode(expr);
		}
	}

	static function railsControllerActionSymbolOption(expr:haxe.macro.Expr):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)):
				rubySymbolLiteral(RubyNaming.toMethodName(value));
			case _:
				metadataValueCode(expr);
		}
	}

	function compileRailsModelImpl(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>,
			moduleRequires:RequireRegistry):RubyFile {
		var body:Array<String> = [];
		var tableName = railsModelTableName(classType);
		if (tableName != null) {
			body.push("self.table_name = " + quoteRubyStringForCode(tableName));
		}
		body = body.concat(rubyExtensionLines(classType.meta, classType));
		body = body.concat(railsDeviseModelLines(classType, varFields));
		body = body.concat(railsSchemaRegistryLines(tableName, varFields, classType));
		for (field in varFields) {
			if (hasMeta(field.field.meta, ":belongsTo")) {
				body.push("belongs_to :" + RubyNaming.toMethodName(field.field.name) + railsAssociationOptionsSuffix(field.field.meta, ":belongsTo"));
			}
			if (hasMeta(field.field.meta, ":hasMany")) {
				body.push("has_many :" + RubyNaming.toMethodName(field.field.name) + railsAssociationOptionsSuffix(field.field.meta, ":hasMany"));
			}
			if (hasMeta(field.field.meta, ":hasOne")) {
				body.push("has_one :" + RubyNaming.toMethodName(field.field.name) + railsAssociationOptionsSuffix(field.field.meta, ":hasOne"));
			}
			if (hasMeta(field.field.meta, ":hasOneAttached")) {
				body.push("has_one_attached :" + RubyNaming.toMethodName(field.field.name));
			}
			if (hasMeta(field.field.meta, ":hasManyAttached")) {
				body.push("has_many_attached :" + RubyNaming.toMethodName(field.field.name));
			}
		}
		for (field in varFields) {
			if (hasMeta(field.field.meta, ":railsEnum")) {
				body.push("enum :" + RubyNaming.toMethodName(field.field.name) + ", " + railsEnumOptions(field.field.meta));
			}
		}
		for (field in funcFields) {
			if (hasMeta(field.field.meta, ":railsScope")) {
				body.push(compileRailsModelScope(field, classType));
			}
			if (hasMeta(field.field.meta, ":railsDefaultScope")) {
				body.push(compileRailsModelDefaultScope(field, classType));
			}
		}
		for (field in varFields) {
			if (hasMeta(field.field.meta, ":railsColumn")) {
				body.push("# haxe column " + RubyNaming.toMethodName(field.field.name) + ": " + typeLabel(field.field.type));
			}
		}
		for (field in varFields) {
			if (hasMeta(field.field.meta, ":validates")) {
				var options = validationOptions(field.field.meta);
				var suffix = options.length == 0 ? "" : ", " + options.join(", ");
				body.push("validates :" + validationTargetName(field) + suffix);
			}
		}
		for (field in funcFields) {
			var callbacks = railsCallbackNames(field.field.meta);
			for (callback in callbacks) {
				body.push(callback + " :" + RubyNaming.toMethodName(field.field.name));
			}
		}
		for (field in funcFields) {
			if (field.expr == null || hasMeta(field.field.meta, ":rubyExternStub")) {
				continue;
			}
			if (hasMeta(field.field.meta, ":railsScope") || hasMeta(field.field.meta, ":railsDefaultScope")) {
				continue;
			}
			body = body.concat(renderStatements([compileRailsModelMethod(field)]));
		}
		if (body.length == 0) {
			body.push("# Rails model generated by reflaxe.ruby");
		}

		var lines = ["class " + RubyNaming.toConstantName(classType.name) + " < ::ApplicationRecord"];
		for (line in body) {
			lines.push("  " + line);
		}
		lines.push("end");

		var statements:Array<RubyStatement> = [
			RubyComment("Generated by reflaxe.ruby"),
			RubyComment("Rails model output; Zeitwerk path should match the Ruby constant.")
		];
		statements = statements.concat(requirePreludeStatements(moduleRequires));
		statements.push(wrapInModules(classType.pack, RubyRawStatement(lines.join("\n"))));
		return {
			modulePath: classType.pack == null ? [] : classType.pack.copy(),
			statements: statements
		};
	}

	static function railsDeviseModelLines(classType:ClassType, varFields:Array<ClassVarData>):Array<String> {
		var entries = classType.meta.extract(":devise");
		if (entries.length == 0) {
			return [];
		}
		if (entries.length > 1) {
			Context.error("@:devise can only be declared once per Rails model.", classType.pos);
		}
		var entry = entries[0];
		if (entry.params.length != 2) {
			Context.error("@:devise expects a generated Devise scope and an array of Devise module tokens.", entry.pos);
		}
		var modules = railsDeviseModuleSymbols(entry.params[1]);
		if (modules.length == 0) {
			Context.error("@:devise requires at least one Devise module token.", entry.pos);
		}
		validateRailsDeviseSchema(classType, varFields, modules, entry.pos);
		return ["devise " + [for (name in modules) rubySymbolLiteral(name)].join(", ")];
	}

	static function railsDeviseModuleSymbols(expr:haxe.macro.Expr):Array<String> {
		return switch expr.expr {
			case EArrayDecl(items):
				[for (item in items) railsDeviseModuleSymbol(item)];
			case _:
				Context.error("@:devise module list must be an array literal so RailsHx can emit deterministic `devise :...` Ruby.", expr.pos);
				[];
		}
	}

	static function railsDeviseModuleSymbol(expr:haxe.macro.Expr):String {
		return switch expr.expr {
			case EConst(CIdent(name)):
				railsDeviseKnownModule(name, expr.pos);
			case EField(_, name):
				railsDeviseKnownModule(name, expr.pos);
			case ECall(callee, args):
				railsDeviseCalledModuleSymbol(callee, args, expr.pos);
			case _:
				Context.error("@:devise module entries must be known DeviseHx module tokens imported from devisehx.model.DeviseModule.", expr.pos);
				"database_authenticatable";
		}
	}

	static function railsDeviseCalledModuleSymbol(callee:haxe.macro.Expr, args:Array<haxe.macro.Expr>, pos:haxe.macro.Expr.Position):String {
		return switch callee.expr {
			case EConst(CIdent("omniauthable")) | EField(_, "omniauthable"):
				if (args.length != 1) {
					Context.error("@:devise omniauthable(...) expects one providers array argument.", pos);
				}
				"omniauthable";
			case EConst(CIdent("unsafeCustom")) | EField(_, "unsafeCustom"):
				if (args.length != 1) {
					Context.error("@:devise unsafeCustom(...) expects one custom module name literal.", pos);
				}
				switch args[0].expr {
					case EConst(CString(name, _)) if (isSafeRubyIdentifier(name)):
						RubyNaming.toMethodName(name);
					case _:
						Context.error("@:devise unsafeCustom(...) requires a safe snake_case custom module name literal.", args[0].pos);
						"database_authenticatable";
				}
			case _:
				Context.error("@:devise module calls must be supported DeviseHx tokens such as omniauthable([...]) or unsafeCustom(\"magic_auth\").", pos);
				"database_authenticatable";
		}
	}

	static function railsDeviseKnownModule(name:String, pos:haxe.macro.Expr.Position):String {
		return switch name {
			case "databaseAuthenticatable": "database_authenticatable";
			case "registerable": "registerable";
			case "recoverable": "recoverable";
			case "rememberable": "rememberable";
			case "validatable": "validatable";
			case "confirmable": "confirmable";
			case "lockable": "lockable";
			case "trackable": "trackable";
			case "timeoutable": "timeoutable";
			case _:
				Context.error('Unsupported @:devise module token "$name". Use a known devisehx.model.DeviseModule token, unsafeCustom("..."), or keep the model Rails-owned.',
					pos);
				"database_authenticatable";
		}
	}

	static function validateRailsDeviseSchema(classType:ClassType, varFields:Array<ClassVarData>, modules:Array<String>, pos:Position):Void {
		var columns:Map<String, Position> = [];
		for (field in varFields) {
			if (hasMeta(field.field.meta, ":railsColumn")) {
				columns.set(railsColumnInfo(field).rubyName, field.field.pos);
			}
		}
		var required:Array<String> = [];
		for (moduleName in modules) {
			for (column in railsDeviseRequiredColumns(moduleName)) {
				if (required.indexOf(column) < 0) {
					required.push(column);
				}
			}
		}
		var missing = [for (column in required) if (!columns.exists(column)) column];
		if (missing.length > 0) {
			Context.error("@:devise on "
				+ classType.name
				+ " requires typed @:railsColumn field(s) for Devise module schema: "
				+ missing.join(", ")
				+ ". Add the fields to the Haxe model or keep this model Rails-owned through a generated extern/adoption contract.",
				pos);
		}
	}

	static function railsDeviseRequiredColumns(moduleName:String):Array<String> {
		return switch moduleName {
			case "database_authenticatable": ["email", "encrypted_password"];
			case "recoverable": ["reset_password_token", "reset_password_sent_at"];
			case "rememberable": ["remember_created_at"];
			case "confirmable": ["confirmation_token", "confirmed_at", "confirmation_sent_at"];
			case "lockable": ["failed_attempts", "unlock_token", "locked_at"];
			case "trackable": [
					"sign_in_count",
					"current_sign_in_at",
					"last_sign_in_at",
					"current_sign_in_ip",
					"last_sign_in_ip"
				];
			case _: [];
		}
	}

	static function railsSchemaRegistryLines(tableName:Null<String>, varFields:Array<ClassVarData>, classType:ClassType):Array<String> {
		var columns = [
			for (field in varFields)
				if (hasMeta(field.field.meta, ":railsColumn")) railsColumnInfo(field)
		];
		var lines = [
			"def self.__hx_rails_schema()",
			"  {",
			"    table_name: " + quoteRubyStringForCode(tableName == null ? railsModelTableName(classType) : tableName) + ",",
			"    timestamps: " + (hasMeta(classType.meta, ":railsTimestamps") ? "true" : "false") + ",",
			"    columns: ["
		];
		for (index in 0...columns.length) {
			var suffix = index == columns.length - 1 ? "" : ",";
			lines.push("      " + railsColumnInfoCode(columns[index]) + suffix);
		}
		lines.push("    ]");
		lines.push("  }");
		lines.push("end");
		lines.push("def self.typed_column_count()");
		lines.push("  __hx_rails_schema()[:columns].length");
		lines.push("end");
		return lines;
	}

	static function railsColumnInfo(field:ClassVarData):RailsColumnInfo {
		return railsColumnInfoFromField(field.field);
	}

	static function railsColumnInfoFromField(field:haxe.macro.Type.ClassField):RailsColumnInfo {
		var haxeType = railsColumnTypeLabel(field.type);
		var explicitDbType = railsColumnStringOption(field.meta, "dbType");
		return {
			haxeName: field.name,
			rubyName: RubyNaming.toMethodName(field.name),
			haxeType: haxeType,
			railsType: explicitDbType != null ? explicitDbType : railsTypeName(haxeType),
			nullable: railsColumnBoolOption(field.meta, "nullable", isNullableType(field.type)),
			defaultValue: railsColumnValueOption(field.meta, "defaultValue"),
			primaryKey: railsColumnBoolOption(field.meta, "primaryKey", false),
			index: railsColumnBoolOption(field.meta, "index", false),
			unique: railsColumnBoolOption(field.meta, "unique", false),
			dbType: explicitDbType
		};
	}

	static function railsColumnInfoCode(info:RailsColumnInfo):String {
		var parts = [
			"name: " + rubySymbolLiteral(info.rubyName),
			"haxe_name: " + quoteRubyStringForCode(info.haxeName),
			"ruby_name: " + quoteRubyStringForCode(info.rubyName),
			"haxe_type: " + quoteRubyStringForCode(info.haxeType),
			"rails_type: " + rubySymbolLiteral(info.railsType),
			"nullable: " + (info.nullable ? "true" : "false"),
			"default: " + (info.defaultValue == null ? "nil" : info.defaultValue),
			"primary_key: " + (info.primaryKey ? "true" : "false"),
			"index: " + (info.index ? "true" : "false"),
			"unique: " + (info.unique ? "true" : "false"),
			"db_type: " + (info.dbType == null ? "nil" : rubySymbolLiteral(info.dbType))
		];
		return "{" + parts.join(", ") + "}";
	}

	static function isStdRubyType(pack:Array<String>, typeName:String):Bool {
		if (pack != null && pack.length > 0) {
			if (["_Any", "_EnumValue"].indexOf(pack[0]) != -1) {
				return true;
			}
			return pack[0] == "haxe" || pack[0] == "sys" || pack[0] == "ruby" || pack[0] == "rails";
		}
		return [
			"Any",
			"Bool",
			"Class",
			"Dynamic",
			"EReg",
			"Enum",
			"EnumValue",
			"Float",
			"IMap",
			"Int",
			"IntIterator",
			"Iterable",
			"Iterator",
			"KeyValueIterable",
			"KeyValueIterator",
			"Map",
			"Null",
			"StringBuf",
			"StringTools",
			"Std",
			"Sys",
			"Date",
			"Lambda",
			"ValueType",
			"Void"
		].indexOf(typeName) != -1;
	}

	static function hasStaticMain(funcFields:Array<ClassFuncData>):Bool {
		for (field in funcFields) {
			if (field.isStatic && field.field.name == "main") {
				return true;
			}
		}
		return false;
	}

	static function compileFunctionBody(expr:TypedExpr):Array<RubyStatement> {
		return switch (expr.expr) {
			case TBlock(exprs):
				compileStatementList(exprs);
			case _:
				[compileStatement(expr)];
		}
	}

	static function compileStatementList(exprs:Array<TypedExpr>):Array<RubyStatement> {
		var out = new Array<RubyStatement>();
		for (expr in exprs) {
			out.push(compileStatement(expr));
		}
		if (out.length == 0) {
			out.push(RubyNilStatement());
		}
		return out;
	}

	static function compileStatement(expr:TypedExpr):RubyStatement {
		if (expr == null) {
			return RubyExprStatement(RubyNil);
		}
		var special = compileSpecialStatement(expr);
		if (special != null) {
			return special;
		}
		switch (expr.expr) {
			case TBlock(exprs):
				return RubyRawStatement([for (stmt in compileStatementList(exprs)) statementToInlineRuby(stmt)].join("\n"));
			case TVar(v, init):
				return RubyAssign(RubyLocal(localName(v)), init == null ? RubyNil : compileExpr(init));
			case TBinop(OpAssign, lhs, rhs):
				return RubyAssign(compileAssignable(lhs), compileExpr(rhs));
			case TBinop(OpAssignOp(op), lhs, rhs):
				return RubyAssign(compileAssignable(lhs), RubyBinary(binopToRuby(op), compileExpr(lhs), compileExpr(rhs)));
			case TUnop(OpIncrement, _, inner):
				return RubyAssign(compileAssignable(inner), RubyBinary("+", compileExpr(inner), RubyInt("1")));
			case TUnop(OpDecrement, _, inner):
				return RubyAssign(compileAssignable(inner), RubyBinary("-", compileExpr(inner), RubyInt("1")));
			case TIf(cond, eThen, eElse):
				return RubyIfStmt(compileExpr(cond), compileFunctionBody(eThen), eElse == null ? null : compileFunctionBody(eElse));
			case TWhile(cond, body, _):
				return RubyWhileStmt(compileExpr(cond), compileFunctionBody(body));
			case TFor(v, iterable, body):
				return RubyRawStatement(renderFor(v, iterable, body));
			case TSwitch(switchExpr, cases, edef):
				return RubyRawStatement(renderSwitch(switchExpr, cases, edef));
			case TTry(tryExpr, catches):
				needsHxException = true;
				return RubyRawStatement(renderTry(tryExpr, catches));
			case TThrow(thrown):
				needsHxException = true;
				return RubyRawStatement("raise HxException.new(" + printInlineExpr(thrown) + ")");
			case TReturn(value):
				return RubyReturn(value == null ? null : compileExpr(value));
			case _:
				return RubyExprStatement(compileExpr(expr));
		}
	}

	static function compileExpr(expr:TypedExpr):RubyExpr {
		if (expr == null) {
			return RubyNil;
		}
		var special = compileSpecialExpr(expr);
		if (special != null) {
			return special;
		}
		return switch (expr.expr) {
			case TConst(TNull): RubyNil;
			case TConst(TBool(value)): RubyBool(value);
			case TConst(TInt(value)): RubyInt(Std.string(value));
			case TConst(TFloat(value)): RubyFloat(value);
			case TConst(TString(value)): RubyString(value);
			case TConst(TThis): RubyLocal("self");
			case TConst(TSuper): RubyLocal("super");
			case TLocal(v): RubyLocal(localName(v));
			case TArray(target, index): RubyRawExpr(printInlineExpr(target) + "[" + printInlineExpr(index) + "]");
			case TArrayDecl(values): RubyArray([for (value in values) compileExpr(value)]);
			case TObjectDecl(fields): RubyHash([for (field in fields) {key: field.name, value: compileExpr(field.expr)}]);
			case TBinop(op, lhs, rhs): RubyBinary(binopToRuby(op), compileExpr(lhs), compileExpr(rhs));
			case TUnop(op, _, inner): RubyUnary(unopToRuby(op), compileExpr(inner));
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _): compileExpr(inner);
			case TFunction(fn):
				RubyLambda([for (arg in fn.args) localName(arg.v)], lambdaBody(fn.expr));
			case TNew(classRef, _, params):
				var classType = classRef.get();
				RubyCall(RubyLocal(rubyNativeName(classType.meta) ?? rubyConstantPath(classType.pack, classType.name)), "new",
					[for (param in params) compileExpr(param)]);
			case TBlock(exprs):
				RubyRawExpr("begin\n" + [for (stmt in compileStatementList(exprs)) "  " + statementToInlineRuby(stmt)].join("\n") + "\nend");
			case TIf(cond, eThen, eElse):
				RubyRawExpr("(if " + printInlineExpr(cond) + " then " + printInlineExpr(eThen) + " else " + (eElse == null ? "nil" : printInlineExpr(eElse))
					+ " end)");
			case TSwitch(switchExpr, cases, edef):
				RubyRawExpr(renderSwitch(switchExpr, cases, edef));
			case TTry(tryExpr, catches):
				needsHxException = true;
				RubyRawExpr(renderTry(tryExpr, catches));
			case TThrow(thrown):
				needsHxException = true;
				RubyRawExpr("(raise HxException.new(" + printInlineExpr(thrown) + "))");
			case TEnumIndex(enumExpr):
				RubyRawExpr(printInlineExpr(enumExpr) + ".__hx_index");
			case TCall({expr: TField(_, FEnum(enumRef, field))}, params):
				RubyCall(RubyLocal(RubyNaming.toConstantName(enumRef.get().name)), RubyNaming.toMethodName(field.name),
					[for (param in params) compileExpr(param)]);
			case TCall({expr: TField(_, FStatic(classRef, fieldRef))}, []) if (actionControllerStaticToken(classRef.get(), fieldRef.get().name) != null):
				RubyRawExpr(actionControllerStaticToken(classRef.get(), fieldRef.get().name));
			case TCall({expr: TField(target, access)}, params) if (isRubyInteropCall(access)):
				compileRubyInteropCall(target, access, params);
			case TCall({expr: TField(target, access)}, params):
				RubyCall(compileExpr(target), fieldAccessName(access), [for (param in params) compileExpr(param)]);
			case TCall({expr: TConst(TSuper)}, params):
				RubyCall(null, "super", [for (param in params) compileExpr(param)]);
			case TCall(callee, params):
				RubyCall(compileExpr(callee), "call", [for (param in params) compileExpr(param)]);
			case TField(_, FEnum(enumRef, field)):
				RubyCall(RubyLocal(RubyNaming.toConstantName(enumRef.get().name)), RubyNaming.toMethodName(field.name), []);
			case TField(_, FStatic(classRef, fieldRef)):
				var classType = classRef.get();
				var token = actionControllerStaticToken(classType, fieldRef.get().name);
				var constant = token ?? mathConstantValue(classType.pack, classType.name, fieldRef.get().name);
				constant == null ? RubyRawExpr((rubyNativeName(classType.meta) ?? rubyConstantPath(classType.pack, classType.name))
					+ "."
					+ rubyFieldName(fieldRef.get().name, fieldRef.get().meta)) : RubyRawExpr(constant);
			case TField(target, access):
				RubyRawExpr(printInlineExpr(target) + "." + fieldAccessName(access));
			case TTypeExpr(moduleType):
				RubyLocal(moduleTypeName(moduleType));
			case _:
				RubyRawExpr("nil # TODO: unsupported expression " + Std.string(expr.expr));
		}
	}

	static function compileAssignable(expr:TypedExpr):RubyExpr {
		return switch (expr.expr) {
			case TLocal(v): RubyLocal(localName(v));
			case TArray(target, index): RubyRawExpr(printInlineExpr(target) + "[" + printInlineExpr(index) + "]");
			case TField(target, access): RubyRawExpr(printInlineExpr(target) + "." + fieldAccessName(access));
			case _: RubyRawExpr(printInlineExpr(expr));
		}
	}

	static function compileUntypedConst(expr:Null<haxe.macro.Expr>):RubyExpr {
		if (expr == null) {
			return RubyNil;
		}
		return switch (expr.expr) {
			case EConst(CInt(value, _)): RubyInt(value);
			case EConst(CFloat(value, _)): RubyFloat(value);
			case EConst(CString(value, _)): RubyString(value);
			case EConst(CIdent("true")): RubyBool(true);
			case EConst(CIdent("false")): RubyBool(false);
			case EConst(CIdent("null")): RubyNil;
			case _: RubyNil;
		}
	}

	static function compileSpecialStatement(expr:TypedExpr):Null<RubyStatement> {
		return switch (expr.expr) {
			case TCall(callee, params):
				var special = compileSpecialCall(callee, params);
				special == null ? null : RubyExprStatement(special);
			case _:
				null;
		}
	}

	static function compileSpecialExpr(expr:TypedExpr):Null<RubyExpr> {
		var activeSupportPayloadField = compileActiveSupportNotificationPayloadField(expr);
		if (activeSupportPayloadField != null) {
			return activeSupportPayloadField;
		}
		return switch (expr.expr) {
			case TCall(callee, params):
				compileSpecialCall(callee, params);
			case _:
				null;
		}
	}

	static function compileSpecialCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		var injected = compileRubyInjection(callee, params);
		if (injected != null) {
			return injected;
		}
		var rubyPatchCall = compileRubyPatchCall(callee, params);
		if (rubyPatchCall != null) {
			return rubyPatchCall;
		}
		if (isIdentifierCallee(callee, "__is__")) {
			return RubyCall(RubyLocal("HXRuby"), "is_of_type", [compileParam(params, 0), compileParam(params, 1)]);
		}
		var activeRecordCall = compileActiveRecordRelationCall(callee, params);
		if (activeRecordCall != null) {
			return activeRecordCall;
		}
		var activeRecordProjectionCall = compileActiveRecordProjectionStaticCall(callee, params);
		if (activeRecordProjectionCall != null) {
			return activeRecordProjectionCall;
		}
		var activeRecordGroupCall = compileActiveRecordGroupStaticCall(callee, params);
		if (activeRecordGroupCall != null) {
			return activeRecordGroupCall;
		}
		var activeRecordSqlCall = compileActiveRecordSqlStaticCall(callee, params);
		if (activeRecordSqlCall != null) {
			return activeRecordSqlCall;
		}
		var arrayCall = compileArrayCall(callee, params);
		if (arrayCall != null) {
			return arrayCall;
		}
		var stringCall = compileStringCall(callee, params);
		if (stringCall != null) {
			return stringCall;
		}
		var actionControllerStoreCall = compileActionControllerStoreCall(callee, params);
		if (actionControllerStoreCall != null) {
			return actionControllerStoreCall;
		}
		var actionControllerParamsCall = compileActionControllerParamsCall(callee, params);
		if (actionControllerParamsCall != null) {
			return actionControllerParamsCall;
		}
		var actionControllerParamsRuntimeCall = compileActionControllerParamsRuntimeCall(callee, params);
		if (actionControllerParamsRuntimeCall != null) {
			return actionControllerParamsRuntimeCall;
		}
		var actionControllerResponseCall = compileActionControllerResponseCall(callee, params);
		if (actionControllerResponseCall != null) {
			return actionControllerResponseCall;
		}
		var activeStorageCall = compileActiveStorageCall(callee, params);
		if (activeStorageCall != null) {
			return activeStorageCall;
		}
		var actionCableCall = compileActionCableCall(callee, params);
		if (actionCableCall != null) {
			return actionCableCall;
		}
		var actionMailerCall = compileActionMailerCall(callee, params);
		if (actionMailerCall != null) {
			return actionMailerCall;
		}
		var info = staticCallInfo(callee);
		if (info == null) {
			return null;
		}
		var railsTestAssertion = compileRailsTestAssertionCall(info, params);
		if (railsTestAssertion != null) {
			return railsTestAssertion;
		}
		var railsTestRequest = compileRailsTestRequestCall(info, params);
		if (railsTestRequest != null) {
			return railsTestRequest;
		}
		var railsTestRequestParams = compileRailsTestRequestParamsCall(info, params);
		if (railsTestRequestParams != null) {
			return railsTestRequestParams;
		}
		var deviseTestHelperCall = compileDeviseTestHelperCall(info, params);
		if (deviseTestHelperCall != null) {
			return deviseTestHelperCall;
		}
		var deviseParamsCall = compileDeviseParamsCall(info, params);
		if (deviseParamsCall != null) {
			return deviseParamsCall;
		}
		var generatedDeviseHelperCall = compileGeneratedDeviseHelperCall(callee, params);
		if (generatedDeviseHelperCall != null) {
			return generatedDeviseHelperCall;
		}
		var deviseAuthCall = compileDeviseAuthCall(info, params);
		if (deviseAuthCall != null) {
			return deviseAuthCall;
		}
		if (info.owner == "rails.test.Dsl" && (info.name == "test" || info.name == "setup" || info.name == "teardown")) {
			Context.error('rails.test.Dsl.${info.name} is a compiler-erased RailsHx test declaration and can only be used at top level inside @:railsTests.',
				callee.pos);
			return RubyNil;
		}
		var actionCableStaticCall = compileActionCableStaticCall(info, params);
		if (actionCableStaticCall != null) {
			return actionCableStaticCall;
		}
		var turboStreamsCall = compileTurboStreamsCall(info, params);
		if (turboStreamsCall != null) {
			return turboStreamsCall;
		}
		var activeSupportNotificationsCall = compileActiveSupportNotificationsCall(info, params);
		if (activeSupportNotificationsCall != null) {
			return activeSupportNotificationsCall;
		}
		var activeStorageStaticCall = compileActiveStorageStaticCall(info, params);
		if (activeStorageStaticCall != null) {
			return activeStorageStaticCall;
		}
		var activeJobStaticCall = compileActiveJobStaticCall(info, params);
		if (activeJobStaticCall != null) {
			return activeJobStaticCall;
		}
		var actionMailerStaticCall = compileActionMailerStaticCall(info, params);
		if (actionMailerStaticCall != null) {
			return actionMailerStaticCall;
		}
		if ((info.owner == "ruby.Symbol" || StringTools.endsWith(info.owner, ".Symbol_Impl_")) && info.name == "of") {
			return compileRubySymbol(params);
		}
		return switch [info.owner, info.name] {
			case ["rails.action_controller.PermitSpec", "field"]:
				compileRailsPermitSpecField(params);
			case ["rails.action_controller.PermitSpec", "nested"]:
				compileRailsPermitSpecNested(params);
			case ["Std", "string"]:
				RubyCall(RubyLocal("HXRuby"), "stringify", [compileParam(params, 0)]);
			case ["Std", "is"] | ["Std", "isOfType"]:
				compileStdIsOfType(params);
			case ["Std", "parseInt"]:
				RubyCall(RubyLocal("HXRuby"), "parse_int", [compileParam(params, 0)]);
			case ["Std", "parseFloat"]:
				RubyCall(RubyLocal("HXRuby"), "parse_float", [compileParam(params, 0)]);
			case ["Sys", "println"]:
				RubyCall(null, "puts", [RubyCall(RubyLocal("HXRuby"), "stringify", [compileParam(params, 0)])]);
			case ["Sys", "print"]:
				RubyCall(null, "print", [RubyCall(RubyLocal("HXRuby"), "stringify", [compileParam(params, 0)])]);
			case ["Sys", "args"]:
				RubyRawExpr("ARGV");
			case ["Sys", "getEnv"]:
				RubyRawExpr("ENV[" + printParam(params, 0) + "]");
			case ["Sys", "putEnv"]:
				RubyRawExpr("ENV[" + printParam(params, 0) + "] = " + printParam(params, 1));
			case ["Sys", "getCwd"]:
				RubyRawExpr("Dir.pwd");
			case ["Sys", "setCwd"]:
				RubyRawExpr("Dir.chdir(" + printParam(params, 0) + ")");
			case ["Sys", "time"]:
				RubyRawExpr("Time.now.to_f");
			case ["Sys", "systemName"]:
				RubyRawExpr("RUBY_PLATFORM");
			case ["Sys", "exit"]:
				RubyRawExpr("exit(" + printParam(params, 0) + ")");
			case ["StringTools", "trim"]:
				RubyCall(compileParam(params, 0), "strip", []);
			case ["StringTools", "ltrim"]:
				RubyCall(compileParam(params, 0), "lstrip", []);
			case ["StringTools", "rtrim"]:
				RubyCall(compileParam(params, 0), "rstrip", []);
			case ["StringTools", "replace"]:
				RubyCall(compileParam(params, 0), "gsub", [compileParam(params, 1), compileParam(params, 2)]);
			case ["StringTools", "startsWith"]:
				RubyCall(compileParam(params, 0), "start_with?", [compileParam(params, 1)]);
			case ["StringTools", "endsWith"]:
				RubyCall(compileParam(params, 0), "end_with?", [compileParam(params, 1)]);
			case ["StringTools", "contains"]:
				RubyCall(compileParam(params, 0), "include?", [compileParam(params, 1)]);
			case ["StringTools", "hex"]:
				RubyCall(RubyLocal("HXRuby"), "hex", [compileParam(params, 0), params.length > 1 ? compileExpr(params[1]) : RubyNil]);
			case ["StringTools", "urlEncode"]:
				RubyCall(RubyLocal("HXRuby"), "url_encode", [compileParam(params, 0)]);
			case ["StringTools", "urlDecode"]:
				RubyCall(RubyLocal("HXRuby"), "url_decode", [compileParam(params, 0)]);
			case _:
				null;
		}
	}

	static function compileGeneratedDeviseHelperCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		var info = staticFieldInfo(callee);
		if (info == null) {
			return null;
		}
		var meta = metadataObject(info.field.meta, ":deviseHxHelper");
		if (meta == null) {
			return null;
		}
		var schema = metadataObjectInt(meta, "schema", info.field.pos);
		if (schema != 1) {
			Context.error("Unsupported DeviseHx helper schema " + schema + " on " + info.typeName + "." + info.fieldName
				+ ". Regenerate the DeviseHx contract.",
				info.field.pos);
		}
		var kind = metadataObjectString(meta, "kind", info.field.pos);
		var scope = metadataObjectString(meta, "mappingScope", info.field.pos);
		validateDeviseMappingScope(scope, info.field.pos);
		return switch kind {
			case "current" if (params.length == 1):
				RubyCall(null, "current_" + scope, []);
			case "currentRequired" if (params.length == 1):
				RubyCall(null, "current_" + scope, []);
			case "signedIn" if (params.length == 1):
				RubyCall(null, scope + "_signed_in?", []);
			case "signIn" if (params.length == 2):
				RubyCall(null, "sign_in", [RubyRawExpr(rubySymbolLiteral(scope)), compileExpr(params[1])]);
			case "signOut" if (params.length == 1):
				RubyCall(null, "sign_out", [RubyRawExpr(rubySymbolLiteral(scope))]);
			case _:
				Context.error('Unsupported DeviseHx helper "$kind" on ${info.typeName}.${info.fieldName}. Regenerate the DeviseHx contract.', info.field.pos);
				RubyNil;
		}
	}

	static function compileDeviseAuthCall(info:{owner:String, name:String}, params:Array<TypedExpr>):Null<RubyExpr> {
		if (info.owner != "devisehx.Auth") {
			return null;
		}
		return switch info.name {
			case "current" if (params.length == 2):
				var scope = deviseMappingScopeFromArg(params[1]);
				RubyCall(null, "current_" + scope, []);
			case "currentRequired" if (params.length == 2):
				var scope = deviseMappingScopeFromArg(params[1]);
				RubyCall(null, "current_" + scope, []);
			case "signedIn" if (params.length == 2):
				var scope = deviseMappingScopeFromArg(params[1]);
				RubyCall(null, scope + "_signed_in?", []);
			case "signIn" if (params.length == 3 || params.length == 4):
				var scope = deviseMappingScopeFromArg(params[1]);
				RubyCall(null, "sign_in", [RubyRawExpr(rubySymbolLiteral(scope)), compileExpr(params[2])]);
			case "bypassSignIn" if (params.length == 3):
				var scope = deviseMappingScopeFromArg(params[1]);
				RubyRawExpr("bypass_sign_in(" + printInlineExpr(params[2]) + ", scope: " + rubySymbolLiteral(scope) + ")");
			case "signOut" if (params.length == 2):
				var scope = deviseMappingScopeFromArg(params[1]);
				RubyCall(null, "sign_out", [RubyRawExpr(rubySymbolLiteral(scope))]);
			case "signOutAll" if (params.length == 1):
				RubyCall(null, "sign_out_all_scopes", []);
			case _:
				null;
		}
	}

	static function deviseMappingScopeFromArg(expr:TypedExpr):String {
		var info = staticFieldInfo(expr);
		if (info == null) {
			Context.error("DeviseHx auth helpers expect a direct generated Devise scope field such as UserAuth.scope; runtime DeviseScope values, locals, and function calls cannot be inspected safely.",
				expr.pos);
			return "user";
		}
		var meta = metadataObject(info.field.meta, ":deviseHxRoute");
		if (meta == null) {
			Context.error("DeviseHx auth helpers expected a generated DeviseHx route contract on "
				+ info.typeName
				+ "."
				+ info.fieldName
				+ ". Regenerate the DeviseHx contract.",
				expr.pos);
			return "user";
		}
		var schema = metadataObjectInt(meta, "schema", expr.pos);
		if (schema != 1) {
			Context.error("Unsupported DeviseHx route contract schema "
				+ schema
				+ " on "
				+ info.typeName
				+ "."
				+ info.fieldName
				+ ". Regenerate the DeviseHx contract with the current toolchain.",
				expr.pos);
		}
		var scope = metadataObjectString(meta, "mappingScope", expr.pos);
		validateDeviseMappingScope(scope, expr.pos);
		return scope;
	}

	static function compileDeviseTestHelperCall(info:{owner:String, name:String}, params:Array<TypedExpr>):Null<RubyExpr> {
		if (info.owner != "devisehx.test.IntegrationHelpers") {
			return null;
		}
		return switch info.name {
			case "signIn" if (params.length == 2):
				var scope = deviseMappingScopeFromArg(params[0]);
				RubyCall(null, "sign_in", [RubyRawExpr(rubySymbolLiteral(scope)), compileExpr(params[1])]);
			case "signOut" if (params.length == 1):
				var scope = deviseMappingScopeFromArg(params[0]);
				RubyCall(null, "sign_out", [RubyRawExpr(rubySymbolLiteral(scope))]);
			case _:
				Context.error('Unsupported DeviseHx test helper devisehx.test.IntegrationHelpers.${info.name}.',
					params.length > 0 ? params[0].pos : Context.currentPos());
				RubyNil;
		}
	}

	static function compileDeviseParamsCall(info:{owner:String, name:String}, params:Array<TypedExpr>):Null<RubyExpr> {
		if (info.owner != "devisehx.params.DeviseParams") {
			return null;
		}
		return switch info.name {
			case "permit" if (params.length == 3):
				deviseMappingScopeFromArg(params[0]);
				var scopeModel = deviseScopeModelNameFromType(params[0].t);
				var action = deviseSanitizerActionFromArg(params[1]);
				var keys = deviseSanitizerKeys(params[2], false, scopeModel);
				RubyRawExpr("devise_parameter_sanitizer.permit("
					+ rubySymbolLiteral(action)
					+ ", keys: ["
					+ [for (key in keys) rubySymbolLiteral(key)].join(", ") + "])");
			case "unsafePermit" if (params.length == 3):
				deviseMappingScopeFromArg(params[0]);
				var action = deviseSanitizerActionFromArg(params[1]);
				var keys = deviseSanitizerKeys(params[2], true, null);
				RubyRawExpr("devise_parameter_sanitizer.permit("
					+ rubySymbolLiteral(action)
					+ ", keys: ["
					+ [for (key in keys) rubySymbolLiteral(key)].join(", ") + "])");
			case _:
				Context.error('Unsupported DeviseHx params helper devisehx.params.DeviseParams.${info.name}.',
					params.length > 0 ? params[0].pos : Context.currentPos());
				RubyNil;
		}
	}

	static function deviseSanitizerActionFromArg(expr:TypedExpr):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TField(_, access):
				var action = fieldAccessDeviseSanitizerAction(access);
				if (action == null) {
					Context.error("DeviseParams.permit expects a typed SanitizerAction such as SanitizerAction.signUp.", expr.pos);
					"sign_up";
				} else {
					validateDeviseMappingScope(action, expr.pos);
					action;
				}
			case _:
				Context.error("DeviseParams.permit expects a typed SanitizerAction such as SanitizerAction.signUp.", expr.pos);
				"sign_up";
		}
	}

	static function deviseSanitizerKeys(expr:TypedExpr, allowStrings:Bool, expectedModel:Null<String>):Array<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TArrayDecl(values):
				[for (value in values) deviseSanitizerKey(value, allowStrings, expectedModel)];
			case _:
				Context.error("DeviseParams.permit keys must be an array literal of generated model field refs.", expr.pos);
				[];
		}
	}

	static function deviseSanitizerKey(expr:TypedExpr, allowStrings:Bool, expectedModel:Null<String>):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TField(_, access):
				var name = fieldAccessRailsFieldName(access);
				if (name == null) {
					Context.error("DeviseParams.permit keys must use generated RailsHx model field refs such as User.f.name.", expr.pos);
					"";
				} else {
					var fieldModel = activeRecordFieldModelNameFromType(expr.t);
					if (expectedModel != null && fieldModel != null && !sameHaxeModelName(expectedModel, fieldModel)) {
						Context.error("DeviseParams.permit field refs must belong to the same model as the generated Devise scope.", expr.pos);
					}
					RubyNaming.toMethodName(name);
				}
			case TConst(TString(value)) if (allowStrings):
				RubyNaming.toMethodName(value);
			case TConst(TString(_)):
				Context.error("DeviseParams.permit keys must use generated RailsHx model field refs; use unsafePermit(...) for reviewed custom string keys.",
					expr.pos);
				"";
			case _:
				Context.error(allowStrings ? "DeviseParams.unsafePermit keys must be literal strings." : "DeviseParams.permit keys must use generated RailsHx model field refs such as User.f.name.",
					expr.pos);
				"";
		}
	}

	static function fieldAccessDeviseSanitizerAction(access:haxe.macro.Type.FieldAccess):Null<String> {
		var meta = switch (access) {
			case FInstance(_, _, field) | FStatic(_, field): field.get().meta;
			case FAnon(fieldRef) | FClosure(_, fieldRef): fieldRef.get().meta;
			case FEnum(_, field): field.meta;
			case FDynamic(_): null;
		}
		return metaStringParam(meta, ":deviseHxSanitizerAction", 0);
	}

	static function deviseScopeModelNameFromType(type:haxe.macro.Type):Null<String> {
		return switch (TypeTools.follow(type)) {
			case TInst(ref, params):
				var classType = ref.get();
				if (fullTypeName(classType.pack, classType.name) == "devisehx.DeviseScope" && params.length > 0) {
					haxeModelNameFromType(params[0]);
				} else {
					null;
				}
			case _:
				null;
		}
	}

	static function activeRecordFieldModelNameFromType(type:haxe.macro.Type):Null<String> {
		return switch (TypeTools.follow(type)) {
			case TAbstract(ref, params):
				var abstractType = ref.get();
				var name = fullTypeName(abstractType.pack, abstractType.name);
				if ((name == "rails.active_record.Field" || name == "rails.active_record.NullableField") && params.length > 0) {
					haxeModelNameFromType(params[0]);
				} else {
					null;
				}
			case _:
				null;
		}
	}

	static function haxeModelNameFromType(type:haxe.macro.Type):Null<String> {
		return switch (TypeTools.follow(type)) {
			case TInst(ref, _):
				var classType = ref.get();
				fullTypeName(classType.pack, classType.name);
			case _:
				null;
		}
	}

	static function sameHaxeModelName(left:String, right:String):Bool {
		return left == right || left.split(".").pop() == right.split(".").pop();
	}

	static function compileRailsTestAssertionCall(info:{owner:String, name:String}, params:Array<TypedExpr>):Null<RubyExpr> {
		if (info.owner != "rails.test.Assert") {
			return null;
		}
		var args = [for (param in params) compileExpr(param)];
		return switch (info.name) {
			case "equal":
				RubyCall(null, "assert_equal", args);
			case "assertEqual":
				RubyCall(null, "assert_equal", args);
			case "notEqual":
				RubyCall(null, "assert_not_equal", args);
			case "assertNotEqual":
				RubyCall(null, "assert_not_equal", args);
			case "truthy":
				RubyCall(null, "assert", args);
			case "assertTrue":
				RubyCall(null, "assert", args);
			case "falsy":
				RubyCall(null, "assert_not", args);
			case "assertFalse":
				RubyCall(null, "assert_not", args);
			case "includes":
				RubyCall(null, "assert_includes", args);
			case "assertIncludes":
				RubyCall(null, "assert_includes", args);
			case "notIncludes":
				RubyCall(null, "assert_not_includes", args);
			case "assertNotIncludes":
				RubyCall(null, "assert_not_includes", args);
			case "nilValue":
				RubyCall(null, "assert_nil", args);
			case "assertNil":
				RubyCall(null, "assert_nil", args);
			case "notNil":
				RubyCall(null, "assert_not_nil", args);
			case "assertNotNil":
				RubyCall(null, "assert_not_nil", args);
			case "assertResponse" if (params.length == 1):
				var status = railsStatusArg(params[0]);
				status == null ? RubyCall(null, "assert_response", args) : RubyCall(null, "assert_response", [RubyRawExpr(status)]);
			case "assertRedirectedTo":
				RubyCall(null, "assert_redirected_to", args);
			case "assertDifference" if (params.length == 3):
				RubyRawExpr("assert_difference(" + renderRubyProc(params[0]) + ", " + printInlineExpr(params[1]) + ") " + renderRubyBlock(params[2]));
			case "assertNoDifference" if (params.length == 2):
				RubyRawExpr("assert_no_difference(" + renderRubyProc(params[0]) + ") " + renderRubyBlock(params[1]));
			case _:
				null;
		}
	}

	static function compileRailsTestRequestCall(info:{owner:String, name:String}, params:Array<TypedExpr>):Null<RubyExpr> {
		if (info.owner != "rails.test.Request") {
			return null;
		}
		return switch info.name {
			case "get" | "post" | "patch" | "delete" if (params.length == 1 || params.length == 2):
				var args = [simplifyRubyIdentityBegin(printInlineExpr(params[0]))];
				if (params.length == 2) {
					args = args.concat(renderKeywordArgs(params[1]));
				}
				RubyRawExpr(info.name + "(" + args.join(", ") + ")");
			case _:
				null;
		}
	}

	static function compileRailsTestRequestParamsCall(info:{owner:String, name:String}, params:Array<TypedExpr>):Null<RubyExpr> {
		if (info.owner != "rails.test.RequestParams") {
			return null;
		}
		return switch info.name {
			case "modelRoot" if (params.length == 2):
				var root = typedStringLiteral(params[0]);
				var attrs = activeRecordCriteriaArg(params[1]);
				if (root == null || attrs == null) {
					Context.error("RequestParams.model must lower to a literal root and object-literal attrs.", params[0].pos);
					RubyNil;
				} else {
					RubyRawExpr("{" + quoteRubyStringForCode(root) + " => {" + attrs + "}}");
				}
			case _:
				null;
		}
	}

	static function compileArrayCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch (callee.expr) {
			case TField(target, access) if (isArrayFieldAccess(access)):
				var receiver = compileExpr(target);
				switch (fieldAccessRawName(access)) {
					case "concat":
						RubyCall(RubyLocal("HXRuby"), "array_concat", [receiver, compileParam(params, 0)]);
					case "join":
						RubyCall(RubyLocal("HXRuby"), "array_join", [receiver, compileParam(params, 0)]);
					case "push":
						RubyCall(RubyLocal("HXRuby"), "array_push", [receiver, compileParam(params, 0)]);
					case "reverse":
						RubyCall(RubyLocal("HXRuby"), "array_reverse", [receiver]);
					case "slice":
						RubyCall(RubyLocal("HXRuby"), "array_slice", [
							receiver,
							compileParam(params, 0),
							params.length > 1 ? compileExpr(params[1]) : RubyNil
						]);
					case "sort":
						RubyCall(RubyLocal("HXRuby"), "array_sort", [receiver, compileParam(params, 0)]);
					case "splice":
						RubyCall(RubyLocal("HXRuby"), "array_splice", [receiver, compileParam(params, 0), compileParam(params, 1)]);
					case "toString":
						RubyCall(RubyLocal("HXRuby"), "stringify", [receiver]);
					case "insert":
						RubyCall(RubyLocal("HXRuby"), "array_insert", [receiver, compileParam(params, 0), compileParam(params, 1)]);
					case "remove":
						RubyCall(RubyLocal("HXRuby"), "array_remove", [receiver, compileParam(params, 0)]);
					case "contains":
						RubyCall(RubyLocal("HXRuby"), "array_contains", [receiver, compileParam(params, 0)]);
					case "indexOf":
						RubyCall(RubyLocal("HXRuby"), "array_index_of", [
							receiver,
							compileParam(params, 0),
							params.length > 1 ? compileExpr(params[1]) : RubyNil
						]);
					case "lastIndexOf":
						RubyCall(RubyLocal("HXRuby"), "array_last_index_of", [
							receiver,
							compileParam(params, 0),
							params.length > 1 ? compileExpr(params[1]) : RubyNil
						]);
					case "copy":
						RubyCall(RubyLocal("HXRuby"), "array_copy", [receiver]);
					case "map":
						RubyCall(RubyLocal("HXRuby"), "array_map", [receiver, compileParam(params, 0)]);
					case "filter":
						RubyCall(RubyLocal("HXRuby"), "array_filter", [receiver, compileParam(params, 0)]);
					case "resize":
						RubyCall(RubyLocal("HXRuby"), "array_resize", [receiver, compileParam(params, 0)]);
					case _:
						null;
				}
			case _:
				null;
		}
	}

	static function compileStringCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch (callee.expr) {
			case TField(target, access) if (isStringExpr(target)):
				var receiver = printInlineExpr(target);
				switch (fieldAccessRawName(access)) {
					case "substr" if (params.length == 1):
						RubyRawExpr(receiver + "[" + printParam(params, 0) + "..]");
					case "substr" if (params.length == 2):
						RubyRawExpr(receiver + "[" + printParam(params, 0) + ", " + printParam(params, 1) + "]");
					case "charAt" if (params.length == 1):
						RubyRawExpr("(" + receiver + "[" + printParam(params, 0) + "] || \"\")");
					case "toUpperCase" if (params.length == 0):
						RubyCall(compileExpr(target), "upcase", []);
					case "toLowerCase" if (params.length == 0):
						RubyCall(compileExpr(target), "downcase", []);
					case _:
						null;
				}
			case _:
				null;
		}
	}

	static function isStringExpr(expr:TypedExpr):Bool {
		return TypeTools.toString(expr.t) == "String";
	}

	static function compileActiveRecordRelationCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch (callee.expr) {
			case TField(target, access)
				if (fieldAccessRawName(access) == "transaction"
					&& (params.length == 1 || params.length == 2)
					&& isFunctionExpr(params[0])):
				var options = params.length == 2 ? activeRecordTransactionOptions(params[1]) : [];
				RubyRawExpr(printInlineExpr(target) + ".transaction(" + options.join(", ") + ") " + renderRubyBlock(params[0]));
			case TField(target, access) if ((fieldAccessRawName(access) == "where" || fieldAccessRawName(access) == "rewhere")
				&& params.length == 1):
				var criteria = activeRecordCriteriaArg(params[0]);
				if (criteria != null) {
					RubyCall(compileExpr(target), fieldAccessRawName(access), [RubyRawExpr(criteria)]);
				} else if (fieldAccessRawName(access) == "where") {
					var predicate = activeRecordPredicateArg(params[0]);
					predicate == null ? null : RubyCall(compileExpr(target), "where", [RubyRawExpr(predicate)]);
				} else {
					null;
				}
			case TField(target, access) if ((fieldAccessRawName(access) == "whereNot" || fieldAccessRawName(access) == "where_not")
				&& params.length == 1):
				var criteria = activeRecordCriteriaArg(params[0]);
				if (criteria != null) {
					RubyRawExpr(printInlineExpr(target) + ".where.not(" + criteria + ")");
				} else {
					var predicate = activeRecordPredicateArg(params[0]);
					predicate == null ? null : RubyRawExpr(printInlineExpr(target) + ".where.not(" + predicate + ")");
				}
			case TField(target, access) if (fieldAccessRawName(access) == "whereExpr" && params.length == 1):
				var predicate = activeRecordPredicateArg(params[0]);
				predicate == null ? null : RubyCall(compileExpr(target), "where", [RubyRawExpr(predicate)]);
			case TField(target, access) if (fieldAccessRawName(access) == "whereNotExpr" && params.length == 1):
				var predicate = activeRecordPredicateArg(params[0]);
				predicate == null ? null : RubyRawExpr(printInlineExpr(target) + ".where.not(" + predicate + ")");
			case TField(target, access) if (fieldAccessRawName(access) == "whereSql" && params.length == 1):
				RubyCall(compileExpr(target), "where", [RubyRawExpr(activeRecordSqlArg(params[0]))]);
			case TField(target, access) if (fieldAccessRawName(access) == "whereNotSql" && params.length == 1):
				RubyRawExpr(printInlineExpr(target) + ".where.not(" + activeRecordSqlArg(params[0]) + ")");
			case TField(target, access) if (fieldAccessRawName(access) == "whereIn" && params.length == 2):
				var criteria = activeRecordFieldCriteriaArg(params[0], params[1]);
				criteria == null ? null : RubyCall(compileExpr(target), "where", [RubyRawExpr(criteria)]);
			case TField(target, access) if (fieldAccessRawName(access) == "whereNotIn" && params.length == 2):
				var criteria = activeRecordFieldCriteriaArg(params[0], params[1]);
				criteria == null ? null : RubyRawExpr(printInlineExpr(target) + ".where.not(" + criteria + ")");
			case TField(target, access) if (fieldAccessRawName(access) == "whereBetween" && params.length == 3):
				var criteria = activeRecordFieldRangeCriteriaArg(params[0], params[1], params[2]);
				criteria == null ? null : RubyCall(compileExpr(target), "where", [RubyRawExpr(criteria)]);
			case TField(target, access) if (fieldAccessRawName(access) == "whereNotBetween" && params.length == 3):
				var criteria = activeRecordFieldRangeCriteriaArg(params[0], params[1], params[2]);
				criteria == null ? null : RubyRawExpr(printInlineExpr(target) + ".where.not(" + criteria + ")");
			case TField(target, access) if (isActiveRecordComparisonPredicate(fieldAccessRawName(access)) && params.length == 2):
				var predicate = activeRecordComparisonPredicateArg(params[0], activeRecordComparisonOp(fieldAccessRawName(access)), params[1]);
				predicate == null ? null : RubyCall(compileExpr(target), "where", [RubyRawExpr(predicate)]);
			case TField(target, access) if (isActiveRecordNegatedComparisonPredicate(fieldAccessRawName(access)) && params.length == 2):
				var predicate = activeRecordComparisonPredicateArg(params[0], activeRecordComparisonOp(fieldAccessRawName(access)), params[1]);
				predicate == null ? null : RubyRawExpr(printInlineExpr(target) + ".where.not(" + predicate + ")");
			case TField(target, access) if (fieldAccessRawName(access) == "whereNull" && params.length == 1):
				var criteria = activeRecordFieldNilCriteriaArg(params[0]);
				criteria == null ? null : RubyCall(compileExpr(target), "where", [RubyRawExpr(criteria)]);
			case TField(target, access) if (fieldAccessRawName(access) == "whereNotNull" && params.length == 1):
				var criteria = activeRecordFieldNilCriteriaArg(params[0]);
				criteria == null ? null : RubyRawExpr(printInlineExpr(target) + ".where.not(" + criteria + ")");
			case TField(target, access)
				if ((fieldAccessRawName(access) == "create"
					|| fieldAccessRawName(access) == "createBang"
					|| fieldAccessRawName(access) == "build")
					&& params.length == 1):
				var attrs = activeRecordCriteriaArg(params[0]);
				if (attrs == null) {
					null;
				} else {
					var methodName = switch (fieldAccessRawName(access)) {
						case "createBang": "create!";
						case "build": "new";
						case _: "create";
					}
					RubyCall(compileExpr(target), methodName, [RubyRawExpr(attrs)]);
				}
			case TField(target, access) if ((fieldAccessRawName(access) == "findBy" || fieldAccessRawName(access) == "find_by")
				&& params.length == 1):
				var criteria = activeRecordCriteriaArg(params[0]);
				criteria == null ? null : RubyCall(compileExpr(target), "find_by", [RubyRawExpr(criteria)]);
			case TField(target, access) if ((fieldAccessRawName(access) == "exists" || fieldAccessRawName(access) == "exists?")
				&& params.length <= 1):
				if (params.length == 0) {
					RubyCall(compileExpr(target), "exists?", []);
				} else {
					var criteria = activeRecordCriteriaArg(params[0]);
					criteria == null ? null : RubyCall(compileExpr(target), "exists?", [RubyRawExpr(criteria)]);
				}
			case TField(target, access) if ((fieldAccessRawName(access) == "order" || fieldAccessRawName(access) == "reorder")
				&& params.length == 1):
				var orderArg = activeRecordOrderArg(params[0]);
				orderArg == null ? null : RubyCall(compileExpr(target), fieldAccessRawName(access), [RubyRawExpr(orderArg)]);
			case TField(target, access) if ((fieldAccessRawName(access) == "orderSql" || fieldAccessRawName(access) == "reorderSql")
				&& params.length == 1):
				var methodName = fieldAccessRawName(access) == "orderSql" ? "order" : "reorder";
				RubyCall(compileExpr(target), methodName, [RubyRawExpr(activeRecordSqlArg(params[0]))]);
			case TField(target, access) if (fieldAccessRawName(access) == "pluck" && params.length == 1):
				var fieldName = activeRecordFieldName(params[0]);
				fieldName == null ? null : RubyCall(compileExpr(target), "pluck", [RubyRawExpr(":" + RubyNaming.toMethodName(fieldName))]);
			case TField(target, access)
				if ((fieldAccessRawName(access) == "minimum"
					|| fieldAccessRawName(access) == "maximum"
					|| fieldAccessRawName(access) == "sum"
					|| fieldAccessRawName(access) == "average")
					&& params.length == 1):
				var fieldName = activeRecordFieldName(params[0]);
				fieldName == null ? null : RubyCall(compileExpr(target), fieldAccessRawName(access), [RubyRawExpr(":" + RubyNaming.toMethodName(fieldName))]);
			case TField(target, access) if (fieldAccessRawName(access) == "select" && params.length == 1):
				var fieldName = activeRecordFieldName(params[0]);
				fieldName == null ? null : RubyCall(compileExpr(target), "select", [RubyRawExpr(":" + RubyNaming.toMethodName(fieldName))]);
			case TField(target, access) if (isActiveRecordAssociationRelationMethod(fieldAccessRawName(access)) && params.length == 1):
				var associationArg = activeRecordAssociationArg(params[0]);
				associationArg == null ? null : RubyCall(compileExpr(target), activeRecordAssociationRelationMethodName(fieldAccessRawName(access)),
					[RubyRawExpr(associationArg)]);
			case TField(target, access) if (fieldAccessRawName(access) == "lock" && params.length <= 1):
				if (params.length == 0) {
					RubyCall(compileExpr(target), "lock", []);
				} else {
					RubyCall(compileExpr(target), "lock", [activeRecordLockArg(params[0])]);
				}
			case _:
				null;
		}
	}

	static function compileActiveRecordProjectionStaticCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		var info = staticCallInfo(callee);
		if (info == null || info.owner != "rails.active_record.ProjectionRuntime") {
			return null;
		}
		if (info.name == "pluck" && params.length == 3) {
			var fieldNames = staticStringArray(params[1]);
			var keys = staticStringArray(params[2]);
			if (fieldNames == null || keys == null || fieldNames.length == 0 || fieldNames.length != keys.length) {
				Context.error("ProjectionRuntime.pluck expects matching static field and key arrays emitted by Projection.pluck.", callee.pos);
			}
			var pluckArgs = [
				for (fieldName in fieldNames)
					RubyRawExpr(":" + RubyNaming.toMethodName(fieldName))
			];
			var keyArray = RubyRawExpr("[" + [for (key in keys) quoteRubyStringForCode(key)].join(", ") + "]");
			return RubyCall(RubyLocal("HXRuby"), "active_record_projection", [RubyCall(compileExpr(params[0]), "pluck", pluckArgs), keyArray]);
		}
		if (info.name == "group" && params.length == 4) {
			var groupField = staticString(params[1]);
			var keys = staticStringArray(params[2]);
			var values = staticArrayElements(params[3]);
			if (groupField == null || keys == null || values == null || keys.length == 0 || keys.length != values.length) {
				Context.error("ProjectionRuntime.group expects a static group field, matching keys, and expression array emitted by Projection.group.",
					callee.pos);
			}
			var pluckArgs = [];
			for (value in values) {
				var arg = activeRecordProjectionArg(value);
				if (arg == null) {
					Context.error("ProjectionRuntime.group expects field refs or typed aggregate expressions emitted by Projection.group.", value.pos);
				}
				pluckArgs.push(RubyRawExpr(arg));
			}
			var grouped = RubyCall(compileExpr(params[0]), "group", [RubyRawExpr(":" + RubyNaming.toMethodName(groupField))]);
			var keyArray = RubyRawExpr("[" + [for (key in keys) quoteRubyStringForCode(key)].join(", ") + "]");
			return RubyCall(RubyLocal("HXRuby"), "active_record_projection", [RubyCall(grouped, "pluck", pluckArgs), keyArray]);
		}
		return null;
	}

	static function compileActiveRecordGroupStaticCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		var info = staticCallInfo(callee);
		if (info == null || info.owner != "rails.active_record.GroupRuntime") {
			return null;
		}
		if (info.name == "count" && params.length == 3) {
			var fieldName = staticString(params[1]);
			var keyKind = staticString(params[2]);
			if (fieldName == null || keyKind == null) {
				Context.error("GroupRuntime.count expects static field and key-kind strings emitted by Group.count.", callee.pos);
			}
			var groupedCount = RubyCall(RubyCall(compileExpr(params[0]), "group", [RubyRawExpr(":" + RubyNaming.toMethodName(fieldName))]), "count", []);
			return RubyCall(RubyLocal("HXRuby"), "active_record_group_count", [groupedCount, RubyRawExpr(":" + RubyNaming.toMethodName(keyKind))]);
		}
		if (info.name == "countHaving" && params.length == 4) {
			var fieldName = staticString(params[1]);
			var keyKind = staticString(params[2]);
			var predicate = activeRecordPredicateArg(params[3]);
			if (fieldName == null || keyKind == null || predicate == null) {
				Context.error("GroupRuntime.countHaving expects static field/key strings and a typed predicate emitted by Group.countHaving.", callee.pos);
			}
			var grouped = RubyCall(compileExpr(params[0]), "group", [RubyRawExpr(":" + RubyNaming.toMethodName(fieldName))]);
			var having = RubyCall(grouped, "having", [RubyRawExpr(predicate)]);
			return RubyCall(RubyLocal("HXRuby"), "active_record_group_count", [
				RubyCall(having, "count", []),
				RubyRawExpr(":" + RubyNaming.toMethodName(keyKind))
			]);
		}
		return null;
	}

	static function compileActiveRecordSqlStaticCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		var info = staticCallInfo(callee);
		if (info == null || !isActiveRecordSqlOwner(info.owner) || !isActiveRecordSqlUnsafeCall(info.name) || params.length != 1) {
			return null;
		}
		return compileExpr(params[0]);
	}

	static function staticString(expr:TypedExpr):Null<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)): value;
			case _:
				null;
		}
	}

	static function staticStringArray(expr:TypedExpr):Null<Array<String>> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TArrayDecl(values):
				var out:Array<String> = [];
				for (value in values) {
					switch (unwrapTypedExpr(value).expr) {
						case TConst(TString(raw)):
							out.push(raw);
						case _:
							return null;
					}
				}
				out;
			case _:
				null;
		}
	}

	static function staticArrayElements(expr:TypedExpr):Null<Array<TypedExpr>> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TArrayDecl(values): values;
			case _: null;
		}
	}

	static function compileActiveStorageCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch (callee.expr) {
			case TField(target, access):
				var attachment = typedExprRailsAttachmentName(target);
				if (attachment == null || params.length == 0) {
					null;
				} else {
					var receiver = RubyCall(compileExpr(params[0]), RubyNaming.toMethodName(attachment), []);
					switch (fieldAccessRawName(access)) {
						case "attached":
							RubyCall(receiver, "attached?", []);
						case "attach" | "attachUnchecked" if (params.length == 2):
							RubyCall(receiver, "attach", [RubyRawExpr(printActiveStorageAttachableValue(params[1]))]);
						case "purge":
							RubyCall(receiver, "purge", []);
						case _:
							null;
					}
				}
			case _:
				null;
		}
	}

	static function compileActiveStorageStaticCall(info:{owner:String, name:String}, params:Array<TypedExpr>):Null<RubyExpr> {
		if (isActiveStorageAttachableOwner(info.owner)) {
			return compileActiveStorageAttachableStaticCall(info.name, params);
		}
		if (isActiveStorageAttachablesOwner(info.owner)) {
			return compileActiveStorageAttachablesStaticCall(info.name, params);
		}
		if (info.owner.indexOf("rails.active_storage") == -1 || params.length < 2) {
			return null;
		}
		var attachment = typedExprRailsAttachmentName(params[0]);
		if (attachment == null) {
			return null;
		}
		var receiver = RubyCall(compileExpr(params[1]), RubyNaming.toMethodName(attachment), []);
		return switch (info.name) {
			case "attached":
				RubyCall(receiver, "attached?", []);
			case "attach" | "attachUnchecked" if (params.length == 3):
				RubyCall(receiver, "attach", [RubyRawExpr(printActiveStorageAttachableValue(params[2]))]);
			case "purge":
				RubyCall(receiver, "purge", []);
			case _:
				null;
		}
	}

	static function compileActiveStorageAttachableStaticCall(name:String, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch name {
			case "signedId" | "typedSignedId" | "blob" if (params.length == 1):
				RubyRawExpr(printInlineExpr(params[0]));
			case "io" if (params.length == 2 || params.length == 3):
				RubyRawExpr(printActiveStorageAttachableHash(params[0], params[1], params.length == 3 ? params[2] : null));
			case "unchecked" if (params.length == 1):
				RubyRawExpr(printInlineExpr(params[0]));
			case _:
				null;
		}
	}

	static function compileActiveStorageAttachablesStaticCall(name:String, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch name {
			case "signedIds" | "typedSignedIds" if (params.length == 1):
				RubyRawExpr(printInlineExpr(params[0]));
			case "of" if (params.length == 1):
				RubyRawExpr(printActiveStorageAttachablesArray(params[0]));
			case "unchecked" if (params.length == 1):
				RubyRawExpr(printInlineExpr(params[0]));
			case _:
				null;
		}
	}

	static function compileActiveJobStaticCall(info:{owner:String, name:String}, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch [info.owner, info.name] {
			case [
				"rails.active_job.DeserializationError" | "ActiveJob::DeserializationError",
				"raise"
			] if (params.length == 0):
				RubyRawExpr("(raise ActiveJob::DeserializationError.new)");
			case [
				"rails.active_job.DeserializationError" | "ActiveJob::DeserializationError",
				"raise"
			] if (params.length == 1):
				RubyRawExpr("(raise ActiveJob::DeserializationError.new(" + printInlineExpr(params[0]) + "))");
			case _:
				null;
		}
	}

	static function printActiveStorageAttachableValue(value:TypedExpr):String {
		return switch (unwrapTypedExpr(value).expr) {
			case TCall(callee, params):
				var info = staticCallInfo(callee);
				if (info != null && isActiveStorageAttachableOwner(info.owner)) {
					switch (info.name) {
						case "signedId" | "typedSignedId" | "blob" if (params.length == 1):
							printInlineExpr(params[0]);
						case "io" if (params.length == 2 || params.length == 3):
							printActiveStorageAttachableHash(params[0], params[1], params.length == 3 ? params[2] : null);
						case "unchecked" if (params.length == 1):
							printInlineExpr(params[0]);
						case _:
							printInlineExpr(value);
					}
				} else if (info != null && isActiveStorageAttachablesOwner(info.owner)) {
					switch (info.name) {
						case "signedIds" | "typedSignedIds" if (params.length == 1):
							printInlineExpr(params[0]);
						case "of" if (params.length == 1):
							printActiveStorageAttachablesArray(params[0]);
						case "unchecked" if (params.length == 1):
							printInlineExpr(params[0]);
						case _:
							printInlineExpr(value);
					}
				} else {
					printInlineExpr(value);
				}
			case TArrayDecl(_):
				printInlineExpr(value);
			case _:
				printInlineExpr(value);
		}
	}

	static function printActiveStorageAttachablesArray(values:TypedExpr):String {
		return switch (unwrapTypedExpr(values).expr) {
			case TArrayDecl(items):
				"[" + [for (item in items) printActiveStorageAttachableValue(item)].join(", ") + "]";
			case _:
				Context.error("Attachables.of(...) expects an array literal so RailsHx can emit deterministic Rails attachables.", values.pos);
		}
	}

	static function printActiveStorageAttachableHash(io:TypedExpr, filename:TypedExpr, options:Null<TypedExpr>):String {
		var fields = [
			quoteRubyStringForCode("io") + " => " + printInlineExpr(io),
			quoteRubyStringForCode("filename") + " => " + printInlineExpr(filename)
		];
		if (options != null) {
			for (field in activeStorageAttachableOptionFields(options)) {
				switch field.name {
					case "contentType":
						fields.push(quoteRubyStringForCode("content_type") + " => " + printInlineExpr(field.expr));
					case _:
						Context.error("Attachable.io options support only contentType.", field.expr.pos);
				}
			}
		}
		return "{" + fields.join(", ") + "}";
	}

	static function activeStorageAttachableOptionFields(options:TypedExpr):Array<{name:String, expr:TypedExpr}> {
		return switch (unwrapTypedExpr(options).expr) {
			case TObjectDecl(fields):
				fields;
			case TConst(TNull):
				[];
			case _:
				Context.error("Attachable.io options must be an object literal so RailsHx can emit deterministic Rails attachable kwargs.", options.pos);
		}
	}

	static function isActiveStorageAttachableOwner(owner:String):Bool {
		return owner == "rails.active_storage.Attachable" || StringTools.endsWith(owner, ".Attachable_Impl_");
	}

	static function isActiveStorageAttachablesOwner(owner:String):Bool {
		return owner == "rails.active_storage.Attachables" || StringTools.endsWith(owner, ".Attachables_Impl_");
	}

	static function compileActionCableCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch (callee.expr) {
			case TField(_, access) if (hasFieldAccessMeta(access, ":railsActionCableParam") && params.length == 1):
				RubyRawExpr("params[" + actionCableParamKey(params[0]) + "]");
			case TField(_, access) if (hasFieldAccessMeta(access, ":railsActionCableConnectionParam") && params.length == 1):
				RubyRawExpr("request.params[" + actionCableConnectionParamKey(params[0]) + "]");
			case TField(_, access) if (hasFieldAccessMeta(access, ":railsActionCableConnectionAssign") && params.length == 2):
				RubyRawExpr("self." + actionCableConnectionIdentifierName(params[0]) + " = " + printParam(params, 1));
			case TField(_, access) if (hasFieldAccessMeta(access, ":railsActionCableConnectionAccess") && params.length == 1):
				RubyRawExpr(actionCableConnectionIdentifierName(params[0]));
			case _:
				null;
		}
	}

	static function compileActionCableStaticCall(info:{owner:String, name:String}, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch [info.owner, info.name] {
			case ["rails.ActionCable", "broadcast"] if (params.length == 2):
				RubyRawExpr("ActionCable.server.broadcast(" + printParam(params, 0) + ", " + printParam(params, 1) + ")");
			case _:
				if (info.name == "named"
					&& params.length == 1
					&& (isActionCableStreamOwner(info.owner)
						|| isActionCableSubscriptionParamOwner(info.owner)
						|| isActionCableConnectionIdentifierOwner(info.owner)
						|| isActionCableConnectionParamOwner(info.owner))) {
					compileExpr(params[0]);
				} else {
					null;
				}
		}
	}

	static function compileActionMailerCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch (callee.expr) {
			case TField(target, access) if (fieldAccessRawName(access) == "param"
				&& params.length == 1
				&& isActionMailerBaseType(target.t)):
				RubyRawExpr("params[" + actionMailerParamKey(params[0]) + "]");
			case TField(target, access)
				if ((fieldAccessRawName(access) == "add" || fieldAccessRawName(access) == "addUnchecked")
					&& params.length == 2
					&& isActionMailerAttachmentsType(target.t)):
				compileActionMailerAttachmentAssign(target, params[0], params[1]);
			case _:
				null;
		}
	}

	static function compileActionMailerStaticCall(info:{owner:String, name:String}, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch [info.owner, info.name] {
			case [owner, "add" | "addUnchecked"] if (params.length == 3 && isActionMailerAttachmentsOwner(owner)):
				compileActionMailerAttachmentAssign(params[0], params[1], params[2]);
			case [owner, "ofString"] if (params.length == 1 && isActionMailerAttachmentValueOwner(owner)):
				RubyRawExpr(printInlineExpr(params[0]));
			case [owner, "content"] if ((params.length == 1 || params.length == 2) && isActionMailerAttachmentValueOwner(owner)):
				RubyRawExpr(printActionMailerAttachmentHash(params[0], params.length == 2 ? params[1] : null));
			case [owner, "unchecked"] if (params.length == 1 && isActionMailerAttachmentValueOwner(owner)):
				RubyRawExpr(printInlineExpr(params[0]));
			case _:
				null;
		}
	}

	static function compileActionMailerAttachmentAssign(target:TypedExpr, name:TypedExpr, value:TypedExpr):RubyExpr {
		return RubyRawExpr(printActionMailerAttachmentTarget(target)
			+ "["
			+ printInlineExpr(name)
			+ "] = "
			+ printActionMailerAttachmentValue(value));
	}

	static function printActionMailerAttachmentTarget(target:TypedExpr):String {
		return switch (unwrapTypedExpr(target).expr) {
			case TCall(callee, params):
				var info = staticCallInfo(callee);
				if (info != null
					&& (info.name == "inlineAttachments" || info.name == "inline")
					&& params.length == 1
					&& isActionMailerAttachmentsOwner(info.owner)) {
					printInlineExpr(params[0]) + ".inline()";
				} else {
					printInlineExpr(target);
				}
			case _:
				printInlineExpr(target);
		}
	}

	static function printActionMailerAttachmentValue(value:TypedExpr):String {
		return switch (unwrapTypedExpr(value).expr) {
			case TCall(callee, params):
				var info = staticCallInfo(callee);
				if (info == null || !isActionMailerAttachmentValueOwner(info.owner)) {
					printInlineExpr(value);
				} else {
					switch (info.name) {
						case "ofString" if (params.length == 1):
							printInlineExpr(params[0]);
						case "content" if (params.length == 1 || params.length == 2):
							printActionMailerAttachmentHash(params[0], params.length == 2 ? params[1] : null);
						case "unchecked" if (params.length == 1):
							printInlineExpr(params[0]);
						case _:
							printInlineExpr(value);
					}
				}
			case _:
				printInlineExpr(value);
		}
	}

	static function printActionMailerAttachmentHash(content:TypedExpr, options:Null<TypedExpr>):String {
		var fields = ["content: " + printInlineExpr(content)];
		if (options != null) {
			for (field in actionMailerAttachmentOptionFields(options)) {
				switch (field.name) {
					case "mimeType":
						fields.push("mime_type: " + printInlineExpr(field.expr));
					case "encoding":
						fields.push("encoding: " + printInlineExpr(field.expr));
					case _:
						Context.error("AttachmentValue.content options support only mimeType and encoding.", field.expr.pos);
				}
			}
		}
		return "{" + fields.join(", ") + "}";
	}

	static function actionMailerAttachmentOptionFields(options:TypedExpr):Array<{name:String, expr:TypedExpr}> {
		return switch (unwrapTypedExpr(options).expr) {
			case TObjectDecl(fields):
				fields;
			case TConst(TNull):
				[];
			case _:
				Context.error("AttachmentValue.content options must be an object literal so RailsHx can emit deterministic Rails attachment kwargs.",
					options.pos);
		}
	}

	static function isActionMailerAttachmentsType(type:haxe.macro.Type):Bool {
		return switch (TypeTools.follow(type)) {
			case TAbstract(ref, _):
				isActionMailerAttachmentsOwner(fullTypeName(ref.get().pack, ref.get().name));
			case _:
				false;
		}
	}

	static function isActionMailerAttachmentsOwner(owner:String):Bool {
		return owner == "rails.action_mailer.Attachments"
			|| owner == "rails.action_mailer.Attachments.AttachmentsImpl"
			|| StringTools.endsWith(owner, ".Attachments_Impl_")
			|| StringTools.endsWith(owner, ".Attachments.AttachmentsImpl");
	}

	static function isActionMailerAttachmentValueOwner(owner:String):Bool {
		return owner == "rails.action_mailer.AttachmentValue" || StringTools.endsWith(owner, ".AttachmentValue_Impl_");
	}

	static function actionMailerParamKey(expr:TypedExpr):String {
		var literal = actionMailerStaticString(expr);
		if (literal != null) {
			return rubySymbolLiteral(RubyNaming.toMethodName(literal));
		}
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall(callee, params) if (params.length == 1):
				var info = staticCallInfo(callee);
				var value = staticString(params[0]);
				if (info != null && info.name == "named" && isActionMailerParamOwner(info.owner) && value != null) {
					rubySymbolLiteral(RubyNaming.toMethodName(value));
				} else {
					printInlineExpr(expr);
				}
			case TField(target, access) if (isActionMailerGeneratedParamTokenAccess(target)):
				rubySymbolLiteral(RubyNaming.toMethodName(fieldAccessRawName(access)));
			case TField(_, FStatic(_, fieldRef)):
				var field = fieldRef.get();
				var fieldExpr = field.expr();
				fieldExpr == null ? rubySymbolLiteral(RubyNaming.toMethodName(field.name)) : actionMailerParamKey(fieldExpr);
			case _:
				printInlineExpr(expr);
		}
	}

	static function isActionMailerGeneratedParamTokenAccess(target:TypedExpr):Bool {
		return switch (unwrapTypedExpr(target).expr) {
			case TField(_, FStatic(_, fieldRef)): var field = fieldRef.get(); field.name == "p" && hasMeta(field.meta, ":rubyExternStub");
			case _:
				false;
		}
	}

	static function actionMailerStaticString(expr:TypedExpr):Null<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)):
				value;
			case TBlock(exprs):
				var locals = new Map<Int, String>();
				for (entry in exprs) {
					switch (unwrapTypedExpr(entry).expr) {
						case TVar(v, init):
							if (init != null) {
								var value = actionMailerStaticString(init);
								if (value != null) {
									locals.set(v.id, value);
								}
							}
						case TBinop(OpAssign, {expr: TLocal(v)}, rhs):
							var value = actionMailerStaticString(rhs);
							if (value != null) {
								locals.set(v.id, value);
							}
						case _:
					}
				}
				if (exprs.length == 0) {
					null;
				} else {
					switch (unwrapTypedExpr(exprs[exprs.length - 1]).expr) {
						case TLocal(v): locals.get(v.id);
						case _: actionMailerStaticString(exprs[exprs.length - 1]);
					}
				}
			case _:
				null;
		}
	}

	static function isActionMailerParamOwner(owner:String):Bool {
		return owner == "rails.action_mailer.MailParam" || StringTools.endsWith(owner, ".MailParam_Impl_");
	}

	static function isActionMailerBaseType(type:haxe.macro.Type):Bool {
		return switch (TypeTools.follow(type)) {
			case TInst(classRef, _): var classType = classRef.get(); fullTypeName(classType.pack,
					classType.name) == "rails.action_mailer.Base" || classExtends(classType, "rails.action_mailer.Base");
			case _:
				false;
		}
	}

	static function isActionCableStreamOwner(owner:String):Bool {
		return owner == "rails.action_cable.Stream" || StringTools.endsWith(owner, ".Stream_Impl_");
	}

	static function isActionCableSubscriptionParamOwner(owner:String):Bool {
		return owner == "rails.action_cable.SubscriptionParam" || StringTools.endsWith(owner, ".SubscriptionParam_Impl_");
	}

	static function isActionCableConnectionIdentifierOwner(owner:String):Bool {
		return owner == "rails.action_cable.ConnectionIdentifier" || StringTools.endsWith(owner, ".ConnectionIdentifier_Impl_");
	}

	static function isActionCableConnectionParamOwner(owner:String):Bool {
		return owner == "rails.action_cable.ConnectionParam" || StringTools.endsWith(owner, ".ConnectionParam_Impl_");
	}

	static function isActionCableConnectionIdentifierType(type:haxe.macro.Type):Bool {
		return switch (TypeTools.follow(type)) {
			case TAbstract(ref, _):
				isActionCableConnectionIdentifierOwner(fullTypeName(ref.get().pack, ref.get().name));
			case _:
				false;
		}
	}

	static function compileTurboStreamsCall(info:{owner:String, name:String}, params:Array<TypedExpr>):Null<RubyExpr> {
		if (info.name == "named"
			&& (info.owner == "rails.turbo.StreamTarget"
				|| StringTools.endsWith(info.owner, ".StreamTarget_Impl_")
				|| info.owner == "rails.turbo.StreamName"
				|| StringTools.endsWith(info.owner, ".StreamName_Impl_"))
			&& params.length == 1) {
			return compileExpr(params[0]);
		}
		if (info.owner != "rails.turbo.TurboStreams") {
			return null;
		}
		return switch (info.name) {
			case "append" if (params.length == 3):
				compileTurboStreamRenderCall("append", params);
			case "prepend" if (params.length == 3):
				compileTurboStreamRenderCall("prepend", params);
			case "before" if (params.length == 3):
				compileTurboStreamRenderCall("before", params);
			case "after" if (params.length == 3):
				compileTurboStreamRenderCall("after", params);
			case "replace" if (params.length == 3):
				compileTurboStreamRenderCall("replace", params);
			case "update" if (params.length == 3):
				compileTurboStreamRenderCall("update", params);
			case "remove" if (params.length == 1):
				RubyRawExpr("turbo_stream.remove(" + printParam(params, 0) + ")");
			case "broadcastAppendTo" if (params.length == 4):
				compileTurboStreamBroadcastCall("append", params);
			case "broadcastPrependTo" if (params.length == 4):
				compileTurboStreamBroadcastCall("prepend", params);
			case "broadcastBeforeTo" if (params.length == 4):
				compileTurboStreamBroadcastCall("before", params);
			case "broadcastAfterTo" if (params.length == 4):
				compileTurboStreamBroadcastCall("after", params);
			case "broadcastReplaceTo" if (params.length == 4):
				compileTurboStreamBroadcastCall("replace", params);
			case "broadcastUpdateTo" if (params.length == 4):
				compileTurboStreamBroadcastCall("update", params);
			case "broadcastRemoveTo" if (params.length == 2):
				RubyRawExpr("Turbo::StreamsChannel.broadcast_remove_to(" + printParam(params, 0) + ", target: " + printParam(params, 1) + ")");
			case _:
				null;
		}
	}

	static function compileTurboStreamRenderCall(action:String, params:Array<TypedExpr>):RubyExpr {
		return RubyRawExpr("turbo_stream." + action + "(" + printParam(params, 0) + ", partial: " + turboStreamPartialPath(params[1]) + ", locals: "
			+ turboStreamLocals(params[2]) + ")");
	}

	static function compileTurboStreamBroadcastCall(action:String, params:Array<TypedExpr>):RubyExpr {
		return RubyRawExpr("Turbo::StreamsChannel.broadcast_" + action + "_to(" + printParam(params, 0) + ", target: " + printParam(params, 1)
			+ ", partial: " + turboStreamPartialPath(params[2]) + ", locals: " + turboStreamLocals(params[3]) + ")");
	}

	static function turboStreamPartialPath(template:TypedExpr):String {
		var path = extractTypedTemplatePath(template);
		if (path == null) {
			Context.error("TurboStreams template arguments expect Template.of(ViewClass), Template.existing(\"path\"), Template.named(\"path\"), or Template.external(\"path\").",
				template.pos);
			return "\"\"";
		}
		return quoteRubyStringForCode(path);
	}

	static function turboStreamLocals(locals:TypedExpr):String {
		var hash = printRailsLocalsHash(locals);
		return hash == null ? printInlineExpr(locals) : hash;
	}

	static function compileActiveSupportNotificationsCall(info:{owner:String, name:String}, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch [info.owner, info.name] {
			case ["rails.active_support.Notifications", "instrument"] if (params.length == 3 && isFunctionExpr(params[2])):
				RubyRawExpr("ActiveSupport::Notifications.instrument(" + printParam(params, 0) + ", " + activeSupportNotificationPayload(params[1]) + ") "
					+ renderRubyBlock(params[2]));
			case ["rails.active_support.Notifications", "subscribe"] if (params.length == 2 && isFunctionExpr(params[1])):
				RubyRawExpr("ActiveSupport::Notifications.subscribe(" + printParam(params, 0) + ") " + renderRubyBlock(params[1]));
			case ["rails.active_support.Notifications", "monotonicSubscribe"] if (params.length == 2 && isFunctionExpr(params[1])):
				RubyRawExpr("ActiveSupport::Notifications.monotonic_subscribe(" + printParam(params, 0) + ") " + renderRubyBlock(params[1]));
			case ["rails.active_support.Notifications", "unsubscribe"] if (params.length == 1):
				RubyRawExpr("ActiveSupport::Notifications.unsubscribe(" + printParam(params, 0) + ")");
			case ["rails.active_support.EventName", "named"] if (params.length == 1):
				compileExpr(params[0]);
			case _:
				null;
		}
	}

	static function compileActiveSupportNotificationPayloadField(expr:TypedExpr):Null<RubyExpr> {
		return switch (expr.expr) {
			case TField(target, access):
				var receiver = activeSupportNotificationPayloadReceiver(target);
				receiver == null ? null : RubyRawExpr(receiver + "[" + rubySymbolLiteral(RubyNaming.toMethodName(fieldAccessRawName(access))) + "]");
			case _:
				null;
		}
	}

	static function activeSupportNotificationPayloadReceiver(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TField(eventExpr, access) if (fieldAccessRawName(access) == "payload" && isActiveSupportNotificationEventExpr(eventExpr)):
				printInlineExpr(eventExpr) + ".payload";
			case _:
				null;
		}
	}

	static function isActiveSupportNotificationEventExpr(expr:TypedExpr):Bool {
		return switch (expr.t) {
			case TInst(classRef, _):
				var classType = classRef.get();
				fullTypeName(classType.pack, classType.name) == "rails.active_support.NotificationEvent";
			case _:
				false;
		}
	}

	static function activeSupportNotificationPayload(expr:TypedExpr):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TObjectDecl(fields):
				"{" + [
					for (field in fields)
						RubyNaming.toMethodName(field.name) + ": " + printInlineExpr(field.expr)
				].join(", ") + "}";
			case _:
				printInlineExpr(expr);
		}
	}

	static function actionCableParamKey(expr:TypedExpr):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)):
				quoteRubyStringForCode(RubyNaming.toMethodName(value));
			case TCall(callee, params) if (params.length == 1):
				var info = staticCallInfo(callee);
				var value = staticString(params[0]);
				if (info != null && info.name == "named" && isActionCableSubscriptionParamOwner(info.owner) && value != null) {
					quoteRubyStringForCode(RubyNaming.toMethodName(value));
				} else {
					printInlineExpr(expr);
				}
			case _:
				printInlineExpr(expr);
		}
	}

	static function actionCableConnectionParamKey(expr:TypedExpr):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)):
				quoteRubyStringForCode(RubyNaming.toMethodName(value));
			case TCall(callee, params) if (params.length == 1):
				var info = staticCallInfo(callee);
				var value = staticString(params[0]);
				if (info != null && info.name == "named" && isActionCableConnectionParamOwner(info.owner) && value != null) {
					quoteRubyStringForCode(RubyNaming.toMethodName(value));
				} else {
					printInlineExpr(expr);
				}
			case TField(_, FStatic(_, fieldRef)):
				var field = fieldRef.get();
				var fieldExpr = field.expr();
				fieldExpr == null ? RubyNaming.toMethodName(field.name) : actionCableConnectionParamKey(fieldExpr);
			case _:
				printInlineExpr(expr);
		}
	}

	static function actionCableConnectionIdentifierName(expr:TypedExpr):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)):
				RubyNaming.toMethodName(value);
			case TCall(callee, params) if (params.length == 1):
				var info = staticCallInfo(callee);
				var value = staticString(params[0]);
				if (info != null && info.name == "named" && isActionCableConnectionIdentifierOwner(info.owner) && value != null) {
					RubyNaming.toMethodName(value);
				} else {
					printInlineExpr(expr);
				}
			case TField(_, FStatic(_, fieldRef)):
				var field = fieldRef.get();
				var fieldExpr = field.expr();
				fieldExpr == null ? RubyNaming.toMethodName(field.name) : actionCableConnectionIdentifierName(fieldExpr);
			case _:
				printInlineExpr(expr);
		}
	}

	static function typedExprRailsAttachmentName(expr:TypedExpr):Null<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TField(_, access):
				fieldAccessRailsAttachmentName(access);
			case _:
				null;
		}
	}

	static function compileActionControllerStoreCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch (callee.expr) {
			case TField(target, access) if (isActionControllerFlashStore(target)):
				switch (fieldAccessRawName(access)) {
					case "notice" if (params.length == 1):
						RubyRawExpr(printActionControllerStoreTarget(target) + "[:notice] = " + printInlineExpr(params[0]));
					case "alert" if (params.length == 1):
						RubyRawExpr(printActionControllerStoreTarget(target) + "[:alert] = " + printInlineExpr(params[0]));
					case _:
						null;
				}
			case TField(target, access) if (isActionControllerKeyValueStore(target)):
				switch (fieldAccessRawName(access)) {
					case "get" if (params.length == 1):
						RubyRawExpr(printActionControllerStoreTarget(target) + "[" + railsStoreKey(params[0]) + "]");
					case "set" if (params.length == 2):
						RubyRawExpr(printActionControllerStoreTarget(target) + "[" + railsStoreKey(params[0]) + "] = " + printInlineExpr(params[1]));
					case "delete" if (params.length == 1):
						RubyRawExpr(printActionControllerStoreTarget(target) + ".delete(" + railsStoreKey(params[0]) + ")");
					case _:
						null;
				}
			case _:
				null;
		}
	}

	static function isActionControllerKeyValueStore(expr:TypedExpr):Bool {
		return switch (expr.t) {
			case TInst(classRef, _): var classType = classRef.get(); classType.pack.join(".") == "rails.action_controller" && (classType.name == "KeyValueStore"
					|| classType.name == "FlashStore");
			case _:
				false;
		}
	}

	static function isActionControllerFlashStore(expr:TypedExpr):Bool {
		return switch (expr.t) {
			case TInst(classRef, _): var classType = classRef.get(); classType.pack.join(".") == "rails.action_controller" && classType.name == "FlashStore";
			case _:
				false;
		}
	}

	static function printActionControllerStoreTarget(expr:TypedExpr):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall(fn, []) if (isActionControllerFlashStore(expr)):
				switch (unwrapTypedExpr(fn).expr) {
					case TField(receiver, access):
						var name = fieldAccessRawName(access);
						if (name == "get_flash" || name == "flash") {
							printInlineExpr(receiver) + ".flash()";
						} else {
							printInlineExpr(expr);
						}
					case _:
						printInlineExpr(expr);
				}
			case TField(receiver, access) if (isActionControllerFlashStore(expr)):
				var name = fieldAccessRawName(access);
				if (name == "get_flash" || name == "flash") {
					printInlineExpr(receiver) + ".flash()";
				} else {
					printInlineExpr(expr);
				}
			case _:
				printInlineExpr(expr);
		}
	}

	static function compileActionControllerParamsCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch (callee.expr) {
			case TField(target, access) if (isActionControllerParams(target)):
				switch (fieldAccessRawName(access)) {
					case "get" if (params.length == 1):
						RubyRawExpr(printInlineExpr(target) + "[" + railsStoreKey(params[0]) + "]");
					case _:
						null;
				}
			case _:
				null;
		}
	}

	static function compileActionControllerParamsRuntimeCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		var info = staticCallInfo(callee);
		if (info == null || info.owner != "rails.action_controller.ParamsRuntime" || info.name != "mergeField" || params.length != 3) {
			return null;
		}
		var field = activeRecordFieldName(params[1]);
		if (field == null) {
			Context.error("ParamsRuntime.mergeField expects a generated RailsHx model field ref.", params[1].pos);
			return RubyRawExpr("nil");
		}
		return RubyRawExpr(printInlineExpr(params[0]) + ".merge(" + RubyNaming.toMethodName(field) + ": " + printInlineExpr(params[2]) + ")");
	}

	static function isActionControllerParams(expr:TypedExpr):Bool {
		return switch (expr.t) {
			case TInst(classRef, _): var classType = classRef.get(); classType.pack.join(".") == "rails.action_controller" && classType.name == "Params";
			case _:
				false;
		}
	}

	static function railsStoreKey(expr:TypedExpr):String {
		return switch (expr.expr) {
			case TConst(TString(value)):
				rubySymbolLiteral(RubyNaming.toLocalName(value));
			case _:
				printInlineExpr(expr);
		}
	}

	static function compileActionControllerResponseCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		return switch (callee.expr) {
			case TField(target, access) if (fieldAccessRawName(access) == "head" && params.length == 1):
				var status = railsStatusArg(params[0]);
				status == null ? null : RubyCall(compileExpr(target), "head", [RubyRawExpr(status)]);
			case _:
				null;
		}
	}

	static function railsStatusArg(expr:TypedExpr):Null<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)):
				rubySymbolLiteral(RubyNaming.toLocalName(value));
			case TField(_, FStatic(classRef, fieldRef)) if (isActionControllerStatusType(classRef.get())):
				rubySymbolLiteral(RubyNaming.toLocalName(fieldRef.get().name));
			case TCall(callee, [valueExpr]) if (isActionControllerStatusNamedCall(callee)):
				switch (unwrapTypedExpr(valueExpr).expr) {
					case TConst(TString(value)):
						rubySymbolLiteral(RubyNaming.toLocalName(value));
					case _:
						printInlineExpr(valueExpr);
				}
			case _:
				null;
		}
	}

	static function isActionControllerStatusNamedCall(callee:TypedExpr):Bool {
		var info = staticCallInfo(callee);
		return info != null
			&& info.name == "named"
			&& (info.owner == "rails.action_controller.Status" || StringTools.endsWith(info.owner, ".Status_Impl_"));
	}

	static function isActionControllerStatusType(classType:ClassType):Bool {
		return fullTypeName(classType.pack, classType.name) == "rails.action_controller.Status"
			|| fullTypeName(classType.pack, classType.name) == "rails.action_controller.Status_Impl_";
	}

	static function activeRecordCriteriaArg(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _):
				activeRecordCriteriaArg(inner);
			case TObjectDecl(fields):
				[for (field in fields) activeRecordCriteriaField(field.name, field.expr)].join(", ");
			case _:
				null;
		}
	}

	static function activeRecordCriteriaField(name:String, expr:TypedExpr):String {
		return RubyNaming.toMethodName(name) + ": " + activeRecordCriteriaValue(expr);
	}

	static function activeRecordFieldCriteriaArg(fieldExpr:TypedExpr, valueExpr:TypedExpr):Null<String> {
		var fieldName = activeRecordFieldName(fieldExpr);
		return fieldName == null ? null : RubyNaming.toMethodName(fieldName) + ": " + printInlineExpr(valueExpr);
	}

	static function activeRecordFieldRangeCriteriaArg(fieldExpr:TypedExpr, minExpr:TypedExpr, maxExpr:TypedExpr):Null<String> {
		var fieldName = activeRecordFieldName(fieldExpr);
		return fieldName == null ? null : RubyNaming.toMethodName(fieldName)
			+ ": "
			+ printInlineExpr(minExpr)
			+ ".."
			+ printInlineExpr(maxExpr);
	}

	static function activeRecordComparisonPredicateArg(fieldExpr:TypedExpr, op:Null<String>, valueExpr:TypedExpr):Null<String> {
		var field = activeRecordArelField(fieldExpr);
		return field == null ? null : activeRecordExpressionPredicateArg(field, op, valueExpr);
	}

	static function activeRecordFieldNilCriteriaArg(fieldExpr:TypedExpr):Null<String> {
		var fieldName = activeRecordFieldName(fieldExpr);
		return fieldName == null ? null : RubyNaming.toMethodName(fieldName) + ": nil";
	}

	static function isActiveRecordComparisonPredicate(name:String):Bool {
		return ["whereGt", "whereGte", "whereLt", "whereLte"].indexOf(name) >= 0;
	}

	static function isActiveRecordNegatedComparisonPredicate(name:String):Bool {
		return ["whereNotGt", "whereNotGte", "whereNotLt", "whereNotLte"].indexOf(name) >= 0;
	}

	static function activeRecordComparisonOp(name:String):Null<String> {
		return switch (name) {
			case "whereGt" | "whereNotGt": "gt";
			case "whereGte" | "whereNotGte": "gteq";
			case "whereLt" | "whereNotLt": "lt";
			case "whereLte" | "whereNotLte": "lteq";
			case _: null;
		}
	}

	static function activeRecordCriteriaValue(expr:TypedExpr):String {
		return switch (expr.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _):
				activeRecordCriteriaValue(inner);
			case TObjectDecl(fields):
				"{" + [for (field in fields) activeRecordCriteriaField(field.name, field.expr)].join(", ") + "}";
			case _:
				printInlineExpr(expr);
		}
	}

	static function activeRecordOrderArg(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _):
				activeRecordOrderArg(inner);
			case TCall(callee, [exprArg]) if (isActiveRecordExprOrderCall(callee)):
				activeRecordOrderArgForExpressionOrField(exprArg, staticCallInfo(callee).name);
			case TCall({expr: TField(fieldExpr, access)}, []) if (isOrderDirection(fieldAccessRawName(access))):
				activeRecordOrderArgForExpressionOrField(fieldExpr, fieldAccessRawName(access));
			case TCall({expr: TField(_, access)}, [fieldExpr]) if (isOrderDirection(fieldAccessRawName(access))):
				activeRecordOrderArgForField(fieldExpr, fieldAccessRawName(access));
			case TCall({expr: TField(_, access)}, [fieldExpr, directionExpr]) if (fieldAccessRawName(access) == "named"): var fieldName = activeRecordFieldName(fieldExpr); var direction = activeRecordDirectionName(directionExpr); fieldName == null || direction == null ? null : RubyNaming.toMethodName(fieldName) + ": :" + direction;
			case TCall({expr: TField(_, access)}, [ordersExpr]) if (fieldAccessRawName(access) == "many"):
				activeRecordOrderManyArg(ordersExpr);
			case _:
				null;
		}
	}

	static function activeRecordOrderManyArg(expr:TypedExpr):Null<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TArrayDecl(values):
				if (values.length == 0) {
					Context.error("Order.many expects at least one typed order.", expr.pos);
				}
				var out:Array<String> = [];
				for (value in values) {
					var orderArg = activeRecordOrderArg(value);
					if (orderArg == null) {
						Context.error("Order.many expects an array literal of typed field order expressions.", value.pos);
					}
					out.push(orderArg);
				}
				out.join(", ");
			case _:
				Context.error("Order.many expects a static array literal so RailsHx can emit Rails-native order arguments.", expr.pos);
				null;
		}
	}

	static function activeRecordOrderArgForField(fieldExpr:TypedExpr, direction:String):Null<String> {
		var fieldName = activeRecordFieldName(fieldExpr);
		return fieldName == null ? null : RubyNaming.toMethodName(fieldName) + ": :" + direction;
	}

	static function activeRecordOrderArgForExpressionOrField(expr:TypedExpr, direction:String):Null<String> {
		var expression = activeRecordExpressionArg(expr);
		return expression == null ? activeRecordOrderArgForField(expr, direction) : expression + "." + direction;
	}

	static function activeRecordSqlArg(expr:TypedExpr):String {
		return printInlineExpr(expr);
	}

	static function activeRecordPredicateArg(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _):
				activeRecordPredicateArg(inner);
			case TCall(callee, [expressionExpr, valueExpr]) if (isActiveRecordExprPredicateCall(callee)):
				var op = activeRecordExpressionPredicateOp(staticCallInfo(callee).name);
				var expression = activeRecordExpressionArg(expressionExpr);
				expression == null ? null : activeRecordExpressionPredicateArg(expression, op, valueExpr);
			case TCall({expr: TField(expressionExpr, access)}, [valueExpr]):
				var op = activeRecordExpressionPredicateOp(fieldAccessRawName(access));
				var expression = activeRecordExpressionArg(expressionExpr);
				expression == null ? null : activeRecordExpressionPredicateArg(expression, op, valueExpr);
			case _:
				null;
		}
	}

	static function activeRecordExpressionPredicateArg(expression:String, op:Null<String>, valueExpr:TypedExpr):Null<String> {
		// Keep RailsHx's two authoring surfaces on one backend:
		// `whereGt(Todo.f.id, 1)` and
		// `whereExpr(Expr.field(Todo.f.id).gt(1))` both lower through this
		// Arel predicate printer. That makes future typed predicate builders
		// additive instead of creating parallel SQL-lowering paths.
		return op == null ? null : expression + "." + op + "(" + printInlineExpr(valueExpr) + ")";
	}

	static function activeRecordExpressionPredicateOp(name:String):Null<String> {
		return switch (name) {
			case "eq": "eq";
			case "gt": "gt";
			case "gte": "gteq";
			case "lt": "lt";
			case "lte": "lteq";
			case _: null;
		}
	}

	static function activeRecordExpressionArg(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _):
				activeRecordExpressionArg(inner);
			case TBlock(values) if (values.length > 0):
				activeRecordExpressionArg(values[values.length - 1]);
			case TField(_, _):
				activeRecordArelField(expr);
			case TCall({expr: TField(fieldExpr, access)}, []) if (fieldAccessRawName(access) == "lower"):
				var field = activeRecordArelField(fieldExpr);
				field == null ? null : field + ".lower";
			case TCall({expr: TField(fieldExpr, access)}, []) if (activeRecordAggregateMethod(fieldAccessRawName(access)) != null): var field = activeRecordArelField(fieldExpr); var method = activeRecordAggregateMethod(fieldAccessRawName(access)); field == null || method == null ? null : field + "." + method;
			case TCall(callee, [fieldExpr]) if (isActiveRecordExprFieldCall(callee)):
				activeRecordArelField(fieldExpr);
			case TCall(callee, [fieldExpr]) if (isActiveRecordExprLowerCall(callee)):
				var field = activeRecordArelField(fieldExpr);
				field == null ? null : field + ".lower";
			case TCall(callee, [fieldExpr]) if (isActiveRecordAggregateCall(callee)): var field = activeRecordArelField(fieldExpr); var method = activeRecordAggregateMethod(staticCallInfo(callee)
					.name); field == null || method == null ? null : field + "." + method;
			case _:
				null;
		}
	}

	static function activeRecordProjectionArg(expr:TypedExpr):Null<String> {
		var fieldName = activeRecordFieldName(expr);
		if (fieldName != null) {
			return ":" + RubyNaming.toMethodName(fieldName);
		}
		return activeRecordExpressionArg(expr);
	}

	static function activeRecordArelField(fieldExpr:TypedExpr):Null<String> {
		var fieldName = activeRecordFieldName(fieldExpr);
		var model = activeRecordFieldModelRubyPath(fieldExpr);
		return fieldName == null || model == null ? null : model + ".arel_table[:" + RubyNaming.toMethodName(fieldName) + "]";
	}

	static function isActiveRecordExprFieldCall(callee:TypedExpr):Bool {
		var info = staticCallInfo(callee);
		return info != null && info.name == "field" && (isActiveRecordExprOwner(info.owner) || isActiveRecordFieldToolsOwner(info.owner));
	}

	static function isActiveRecordExprLowerCall(callee:TypedExpr):Bool {
		var info = staticCallInfo(callee);
		return info != null
			&& info.name == "lower"
			&& (isActiveRecordExprOwner(info.owner) || isActiveRecordOrderOwner(info.owner) || isActiveRecordFieldToolsOwner(info.owner));
	}

	static function isActiveRecordExprOrderCall(callee:TypedExpr):Bool {
		var info = staticCallInfo(callee);
		return info != null && isOrderDirection(info.name) && isActiveRecordExprOwner(info.owner);
	}

	static function isActiveRecordExprPredicateCall(callee:TypedExpr):Bool {
		var info = staticCallInfo(callee);
		return info != null
			&& activeRecordExpressionPredicateOp(info.name) != null
			&& (isActiveRecordExprOwner(info.owner) || isActiveRecordFieldToolsOwner(info.owner));
	}

	static function isActiveRecordAggregateCall(callee:TypedExpr):Bool {
		var info = staticCallInfo(callee);
		return info != null
			&& activeRecordAggregateMethod(info.name) != null
			&& (info.owner == "rails.active_record.Aggregate" || isActiveRecordFieldToolsOwner(info.owner));
	}

	static function activeRecordAggregateMethod(name:String):Null<String> {
		return switch (name) {
			case "count" | "sum" | "average" | "minimum" | "maximum":
				name;
			case _:
				null;
		}
	}

	static function isActiveRecordExprOwner(owner:String):Bool {
		return owner == "rails.active_record.Expr" || StringTools.endsWith(owner, ".Expr_Impl_");
	}

	static function isActiveRecordOrderOwner(owner:String):Bool {
		return owner == "rails.active_record.Order" || StringTools.endsWith(owner, ".Order_Impl_");
	}

	static function isActiveRecordFieldToolsOwner(owner:String):Bool {
		return owner == "rails.active_record.FieldTools";
	}

	static function isActiveRecordSqlOwner(owner:String):Bool {
		return owner == "rails.active_record.Sql" || StringTools.endsWith(owner, ".Sql_Impl_");
	}

	static function isActiveRecordSqlUnsafeCall(name:String):Bool {
		return switch (name) {
			case "unsafeWhere" | "unsafe_where" | "unsafeOrder" | "unsafe_order":
				true;
			case _:
				false;
		}
	}

	static function activeRecordAssociationArg(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _):
				activeRecordAssociationArg(inner);
			case TCall(callee, [parent, child]) if (isActiveRecordAssociationNestedCall(callee)): var parentName = activeRecordAssociationKey(parent); var childArg = activeRecordAssociationArg(child); parentName == null || childArg == null ? null : "{" + parentName + ": " + childArg + "}";
			case TField(_, access):
				var value = fieldAccessRailsAssociationName(access);
				if (value == null) {
					value = fieldAccessRawName(access);
				}
				":" + RubyNaming.toMethodName(value);
			case TConst(TString(value)):
				":" + RubyNaming.toMethodName(value);
			case _:
				null;
		}
	}

	static function activeRecordAssociationKey(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _):
				activeRecordAssociationKey(inner);
			case TField(_, access):
				var value = fieldAccessRailsAssociationName(access);
				if (value == null) {
					value = fieldAccessRawName(access);
				}
				RubyNaming.toMethodName(value);
			case TConst(TString(value)):
				RubyNaming.toMethodName(value);
			case _:
				null;
		}
	}

	static function isActiveRecordAssociationNestedCall(callee:TypedExpr):Bool {
		var info = staticCallInfo(callee);
		if (info != null && info.owner == "rails.active_record.Association" && info.name == "nested") {
			return true;
		}
		return switch (callee.expr) {
			case TField(_, access):
				fieldAccessRawName(access) == "nested";
			case _:
				false;
		}
	}

	static function isActiveRecordAssociationRelationMethod(name:String):Bool {
		return switch (name) {
			case "includes" | "preload" | "joins" | "eagerLoad" | "eager_load":
				true;
			case _:
				false;
		}
	}

	static function activeRecordAssociationRelationMethodName(name:String):String {
		return switch (name) {
			case "eagerLoad": "eager_load";
			case _: name;
		}
	}

	static function activeRecordLockArg(expr:TypedExpr):RubyExpr {
		var value = staticString(expr);
		return value == null ? compileExpr(expr) : RubyString(value);
	}

	static function activeRecordTransactionOptions(expr:TypedExpr):Array<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TObjectDecl(fields):
				[for (field in fields) activeRecordTransactionOption(field.name, field.expr)];
			case _:
				[printInlineExpr(expr)];
		}
	}

	static function activeRecordTransactionOption(name:String, expr:TypedExpr):String {
		return switch (name) {
			case "requiresNew":
				"requires_new: " + printInlineExpr(expr);
			case "joinable":
				"joinable: " + printInlineExpr(expr);
			case "isolation":
				"isolation: " + activeRecordIsolationArg(expr);
			case _:
				RubyNaming.toMethodName(name) + ": " + printInlineExpr(expr);
		}
	}

	static function activeRecordIsolationArg(expr:TypedExpr):String {
		var value = staticString(expr);
		return value == null ? printInlineExpr(expr) : ":" + RubyNaming.toMethodName(value);
	}

	static function activeRecordFieldName(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _):
				activeRecordFieldName(inner);
			case TField(_, access):
				var value = fieldAccessRailsFieldName(access);
				if (value == null) {
					var raw = fieldAccessRawName(access);
					value = StringTools.endsWith(raw, "Field") ? raw.substr(0, raw.length - "Field".length) : null;
				}
				value;
			case TConst(TString(value)):
				value;
			case _:
				null;
		}
	}

	static function activeRecordFieldModelRubyPath(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _):
				activeRecordFieldModelRubyPath(inner);
			case _:
				activeRecordFieldModelRubyPathFromType(expr.t);
		}
	}

	static function activeRecordFieldModelRubyPathFromType(type:haxe.macro.Type):Null<String> {
		// Field refs are Haxe abstracts whose first type parameter is the owning
		// model. Reading that parameter lets relation calls such as
		// `assigned.whereGt(Todo.f.id, 1)` still lower to the correct
		// `Models::Todo.arel_table[...]` expression without a stringly model name.
		return switch (TypeTools.follow(type)) {
			case TAbstract(ref, params):
				var abstractType = ref.get();
				var name = fullTypeName(abstractType.pack, abstractType.name);
				if ((name == "rails.active_record.Field" || name == "rails.active_record.NullableField") && params.length > 0) {
					activeRecordModelRubyPathFromType(params[0]);
				} else {
					null;
				}
			case _:
				null;
		}
	}

	static function activeRecordModelRubyPathFromType(type:haxe.macro.Type):Null<String> {
		return switch (TypeTools.follow(type)) {
			case TInst(ref, _):
				var classType = ref.get();
				rubyNativeName(classType.meta) ?? rubyConstantPath(classType.pack, classType.name);
			case _:
				null;
		}
	}

	static function activeRecordDirectionName(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _):
				activeRecordDirectionName(inner);
			case TConst(TString("asc")):
				"asc";
			case TConst(TString("desc")):
				"desc";
			case _:
				null;
		}
	}

	static function isOrderDirection(name:String):Bool {
		return name == "asc" || name == "desc";
	}

	static function compileStdIsOfType(params:Array<TypedExpr>):RubyExpr {
		return RubyCall(RubyLocal("HXRuby"), "is_of_type", [compileParam(params, 0), compileTypeCheckParam(params, 1)]);
	}

	static function compileTypeCheckParam(params:Array<TypedExpr>, index:Int):RubyExpr {
		if (index >= params.length) {
			return RubyNil;
		}
		return switch (params[index].expr) {
			case TTypeExpr(moduleType):
				RubyLocal(moduleTypeName(moduleType));
			case _:
				compileExpr(params[index]);
		}
	}

	static function compileRubyInteropCall(target:TypedExpr, access:haxe.macro.Type.FieldAccess, params:Array<TypedExpr>):RubyExpr {
		return compileRubyReceiverCall(target, fieldAccessName(access), params, hasFieldAccessMeta(access, ":rubyKwargs"),
			hasFieldAccessMeta(access, ":rubyBlockArg"));
	}

	static function compileRubyPatchCall(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		var info = rubyPatchCallInfo(callee);
		if (info == null) {
			return null;
		}
		if (params.length == 0) {
			Context.error("@:rubyPatch method " + info.className + "." + info.field.name + " requires the receiver as its first argument.", callee.pos);
			return RubyNil;
		}
		var receiver = params[0];
		var remaining = params.slice(1);
		return compileRubyReceiverCall(receiver, rubyFieldName(info.field.name, info.field.meta), remaining, hasMeta(info.field.meta, ":rubyKwargs"),
			hasMeta(info.field.meta, ":rubyBlockArg"));
	}

	static function rubyPatchCallInfo(callee:TypedExpr):Null<{className:String, field:ClassField}> {
		return switch (callee.expr) {
			case TField(_, FStatic(classRef, fieldRef)):
				var classType = classRef.get();
				if (!hasMeta(classType.meta, ":rubyPatch")) {
					null;
				} else {
					{className: fullTypeName(classType.pack, classType.name), field: fieldRef.get()};
				}
			case _:
				null;
		}
	}

	static function compileRubyReceiverCall(target:TypedExpr, method:String, params:Array<TypedExpr>, useKwargs:Bool, useBlockArg:Bool):RubyExpr {
		var receiver = reflaxe.ruby.ast.RubyASTPrinter.printExpr(compileExpr(target));
		var remaining = params.copy();
		var block:Null<TypedExpr> = null;
		if (useBlockArg && remaining.length > 0 && isFunctionExpr(remaining[remaining.length - 1])) {
			block = remaining.pop();
		}
		var keywordSource:Null<TypedExpr> = null;
		if (useKwargs && remaining.length > 0 && isObjectDeclExpr(remaining[remaining.length - 1])) {
			keywordSource = remaining.pop();
		}
		var args = [for (param in remaining) simplifyRubyIdentityBegin(printInlineExpr(param))];
		if (keywordSource != null) {
			args = args.concat(renderKeywordArgs(keywordSource));
		}
		var code = receiver + "." + method + "(" + args.join(", ") + ")";
		if (block != null) {
			code += " " + renderRubyBlock(block);
		}
		return RubyRawExpr(code);
	}

	static function compileRubySymbol(params:Array<TypedExpr>):RubyExpr {
		if (params.length == 0) {
			return RubyRawExpr(":\"\"");
		}
		return switch (params[0].expr) {
			case TConst(TString(value)):
				RubyRawExpr(rubySymbolLiteral(value));
			case _:
				RubyRawExpr("(" + printParam(params, 0) + ").to_sym");
		}
	}

	static function compileRailsPermitSpecField(params:Array<TypedExpr>):RubyExpr {
		if (params.length == 0) {
			return RubyRawExpr(":\"\"");
		}
		return switch (unwrapTypedExpr(params[0]).expr) {
			case TConst(TString(value)):
				RubyRawExpr(rubySymbolLiteral(RubyNaming.toMethodName(value)));
			case _:
				RubyRawExpr("(" + printParam(params, 0) + ").to_sym");
		}
	}

	static function compileRailsPermitSpecNested(params:Array<TypedExpr>):RubyExpr {
		if (params.length < 2) {
			return RubyRawExpr("{}");
		}
		var key = switch (unwrapTypedExpr(params[0]).expr) {
			case TConst(TString(value)):
				RubyNaming.toMethodName(value);
			case _:
				null;
		}
		var children = printParam(params, 1);
		return key == null ? RubyRawExpr("{(" + printParam(params, 0) + ").to_sym => " + children + "}") : RubyRawExpr("{" + key + ": " + children + "}");
	}

	static function compileRubyInjection(callee:TypedExpr, params:Array<TypedExpr>):Null<RubyExpr> {
		if (!isRubyInjectionCallee(callee)) {
			return null;
		}
		if (params.length == 0) {
			Context.error("__ruby__ requires at least one String argument.", callee.pos);
			return RubyNil;
		}
		var template = switch (params[0].expr) {
			case TConst(TString(value)): value;
			case _:
				Context.error("__ruby__ first parameter must be a constant String.", params[0].pos);
				"";
		}
		var code = ~/{(\d+)}/g.map(template, ereg -> {
			var index = Std.parseInt(ereg.matched(1));
			if (index == null || index + 1 >= params.length) {
				return ereg.matched(0);
			}
			return printInlineExpr(params[index + 1]);
		});
		return RubyRawExpr(code);
	}

	static function isRubyInjectionCallee(callee:TypedExpr):Bool {
		return isIdentifierCallee(callee, "__ruby__");
	}

	static function isIdentifierCallee(callee:TypedExpr, name:String):Bool {
		return switch (callee.expr) {
			case TIdent(value) if (value == name): true;
			case TLocal(variable) if (variable.name == name): true;
			case TField(_, access):
				fieldAccessName(access) == name;
			case _:
				false;
		}
	}

	static function renderKeywordArgs(expr:TypedExpr):Array<String> {
		return switch (expr.expr) {
			case TObjectDecl(fields):
				[
					for (field in fields)
						RubyNaming.toMethodName(field.name) + ": " + printKeywordArgValue(field.name, field.expr)
				];
			case _:
				[printInlineExpr(expr)];
		}
	}

	static function printKeywordArgValue(fieldName:String, expr:TypedExpr):String {
		var abstractValue = abstractIdentityBlockValue(expr);
		if (abstractValue != null) {
			return printKeywordArgValue(fieldName, abstractValue);
		}
		if (fieldName == "locals") {
			var locals = printRailsLocalsHash(expr);
			if (locals != null) {
				return locals;
			}
		}
		if (fieldName == "status") {
			var status = railsStatusArg(expr);
			if (status != null) {
				return status;
			}
		}
		return simplifyRubyIdentityBegin(printInlineExpr(expr));
	}

	static function abstractIdentityBlockValue(expr:TypedExpr):Null<TypedExpr> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TBlock([
				{expr: TVar(valueLocal, valueInit)},
				{expr: TVar(boxLocal, _)},
				{expr: TBinop(OpAssign, {expr: TLocal(assignLocal)}, {expr: TLocal(sourceLocal)})},
				{expr: TLocal(retLocal)}
			]) if (valueInit != null && boxLocal.name == assignLocal.name && boxLocal.name == retLocal.name && valueLocal.name == sourceLocal.name):
				valueInit;
			case TBlock([decl, assign, ret]):
				switch [decl.expr, assign.expr, ret.expr] {
					case [
						TVar(local, _),
						TBinop(OpAssign, {expr: TLocal(assignLocal)}, value),
						TLocal(retLocal)
					] if (local.name == assignLocal.name && local.name == retLocal.name):
						value;
					case _:
						null;
				}
			case _:
				null;
		}
	}

	static function simplifyRubyIdentityBegin(code:String):String {
		var lines = code.split("\n");
		if (lines.length == 6 && lines[0] == "begin" && lines[5] == "end") {
			var firstPrefix = "  ";
			var nilSuffix = " = nil";
			if (StringTools.startsWith(lines[1], firstPrefix)
				&& StringTools.startsWith(lines[2], firstPrefix)
				&& StringTools.endsWith(lines[2], nilSuffix)) {
				var valueAssign = lines[1].substr(firstPrefix.length);
				var eq = valueAssign.indexOf(" = ");
				var valueLocal = eq < 0 ? "" : valueAssign.substr(0, eq);
				var valueExpr = eq < 0 ? "" : valueAssign.substr(eq + " = ".length);
				var boxLocal = lines[2].substr(firstPrefix.length, lines[2].length - firstPrefix.length - nilSuffix.length);
				if (valueLocal != "" && boxLocal != "" && lines[3] == boxLocal + " = " + valueLocal && lines[4] == boxLocal) {
					return valueExpr;
				}
			}
		}
		if (lines.length != 5 || lines[0] != "begin" || lines[4] != "end") {
			return code;
		}
		var prefix = "  ";
		var nilSuffix = " = nil";
		if (!StringTools.startsWith(lines[1], prefix) || !StringTools.endsWith(lines[1], nilSuffix)) {
			return code;
		}
		var local = lines[1].substr(prefix.length, lines[1].length - prefix.length - nilSuffix.length);
		var assignPrefix = prefix + local + " = ";
		if (local == "" || !StringTools.startsWith(lines[2], assignPrefix) || lines[3] != prefix + local) {
			return code;
		}
		return lines[2].substr(assignPrefix.length);
	}

	static function printRailsLocalsHash(expr:TypedExpr):Null<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TObjectDecl(fields):
				"{" + [
					for (field in fields)
						RubyNaming.toLocalName(field.name) + ": " + printInlineExpr(field.expr)
				].join(", ") + "}";
			case _:
				printRailsLocalsHashFromTypedValue(expr);
		}
	}

	static function printRailsLocalsHashFromTypedValue(expr:TypedExpr):Null<String> {
		if (!isStableRailsLocalsProjectionSource(expr)) {
			return null;
		}
		var fields = switch (TypeTools.follow(expr.t)) {
			case TAnonymous(anonRef):
				anonRef.get().fields;
			case _:
				null;
		}
		if (fields == null || fields.length == 0) {
			return null;
		}
		var receiver = printInlineExpr(expr);
		return "{" + [
			for (field in fields)
				RubyNaming.toLocalName(field.name) + ": (" + receiver + ")[" + quoteRubyStringForCode(field.name) + "]"
		].join(", ") + "}";
	}

	static function isStableRailsLocalsProjectionSource(expr:TypedExpr):Bool {
		return switch (unwrapTypedExpr(expr).expr) {
			case TLocal(_): true;
			case _: false;
		}
	}

	static function renderRubyBlock(expr:TypedExpr):String {
		return switch (expr.expr) {
			case TFunction(fn):
				var args = [for (arg in fn.args) localName(arg.v)].join(", ");
				var body = renderStatements(compileRubyBlockBody(fn.expr));
				if (canRenderInlineBlock(body)) {
					var prefix = args == "" ? "" : "|" + args + "| ";
					"{ " + prefix + body[0] + " }";
				} else {
					var lines = [args == "" ? "do" : "do |" + args + "|"];
					appendIndentedLines(lines, body, 1);
					lines.push("end");
					lines.join("\n");
				}
			case _:
				"{ |value| " + printInlineExpr(expr) + ".call(value) }";
		}
	}

	static function renderRubyProc(expr:TypedExpr):String {
		return switch (expr.expr) {
			case TFunction(fn):
				var args = [for (arg in fn.args) localName(arg.v)].join(", ");
				var body = renderStatements(compileRubyBlockBody(fn.expr));
				if (canRenderInlineBlock(body)) {
					var prefix = args == "" ? "" : "|" + args + "| ";
					"-> { " + prefix + body[0] + " }";
				} else {
					var lines = [args == "" ? "-> do" : "-> do |" + args + "|"];
					appendIndentedLines(lines, body, 1);
					lines.push("end");
					lines.join("\n");
				}
			case _:
				printInlineExpr(expr);
		}
	}

	static function compileRubyBlockBody(expr:TypedExpr):Array<RubyStatement> {
		var body = compileFunctionBody(expr);
		if (body.length == 0) {
			return [RubyNilStatement()];
		}
		return switch (body[body.length - 1]) {
			case RubyReturn(value):
				body.slice(0, body.length - 1).concat([RubyExprStatement(value == null ? RubyNil : value)]);
			case _:
				body;
		}
	}

	static function canRenderInlineBlock(body:Array<String>):Bool {
		if (body.length != 1) {
			return false;
		}
		var line = body[0];
		return line.indexOf("\n") == -1 && !StringTools.startsWith(StringTools.trim(line), "return");
	}

	static function isRubyInteropCall(access:haxe.macro.Type.FieldAccess):Bool {
		return hasFieldAccessMeta(access, ":rubyKwargs") || hasFieldAccessMeta(access, ":rubyBlockArg");
	}

	static function isFunctionExpr(expr:TypedExpr):Bool {
		return switch (expr.expr) {
			case TFunction(_): true;
			case _: false;
		}
	}

	static function isObjectDeclExpr(expr:TypedExpr):Bool {
		return switch (expr.expr) {
			case TObjectDecl(_): true;
			case _: false;
		}
	}

	static function staticCallInfo(callee:TypedExpr):Null<{owner:String, name:String}> {
		return switch (callee.expr) {
			case TField(_, FStatic(classRef, fieldRef)):
				var classType = classRef.get();
				{owner: fullTypeName(classType.pack, classType.name), name: fieldRef.get().name};
			case _:
				null;
		}
	}

	static function staticFieldInfo(expr:TypedExpr):Null<{typeName:String, fieldName:String, field:ClassField}> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TField(_, FStatic(classRef, fieldRef)):
				var classType = classRef.get();
				{typeName: fullTypeName(classType.pack, classType.name), fieldName: fieldRef.get().name, field: fieldRef.get()};
			case _:
				null;
		}
	}

	static function actionControllerStaticToken(classType:ClassType, fieldName:String):Null<String> {
		return switch (fullTypeName(classType.pack, classType.name)) {
			case "rails.action_controller.Mime":
				switch (fieldName) {
					case "html" | "get_html": "Mime[:html]";
					case "json" | "get_json": "Mime[:json]";
					case "turboStream" | "get_turboStream": "Mime[:turbo_stream]";
					case "xml" | "get_xml": "Mime[:xml]";
					case "all" | "get_all": "Mime::ALL";
					case _: null;
				}
			case "rails.action_controller.RequestVariantToken":
				switch (fieldName) {
					case "phone" | "get_phone": ":phone";
					case "tablet" | "get_tablet": ":tablet";
					case "desktop" | "get_desktop": ":desktop";
					case "nativeApp" | "get_nativeApp": ":native_app";
					case _: null;
				}
			case _:
				null;
		}
	}

	static function compileParam(params:Array<TypedExpr>, index:Int):RubyExpr {
		return index < params.length ? compileExpr(params[index]) : RubyNil;
	}

	static function printParam(params:Array<TypedExpr>, index:Int):String {
		return reflaxe.ruby.ast.RubyASTPrinter.printExpr(compileParam(params, index));
	}

	static function renderSwitch(switchExpr:TypedExpr, cases:Array<{values:Array<TypedExpr>, expr:TypedExpr}>, edef:Null<TypedExpr>):String {
		var usesEnumIndex = switch (switchExpr.expr) {
			case TEnumIndex(_): true;
			case _: false;
		}
		var lines = ["case " + switchScrutineeCode(switchExpr)];
		for (branch in cases) {
			var values = [for (value in branch.values) switchValueCode(value, usesEnumIndex)];
			lines.push("when " + values.join(", "));
			appendIndentedLines(lines, renderStatements(compileFunctionBody(branch.expr)), 1);
		}
		if (edef != null) {
			lines.push("else");
			appendIndentedLines(lines, renderStatements(compileFunctionBody(edef)), 1);
		}
		lines.push("end");
		return lines.join("\n");
	}

	static function renderTry(tryExpr:TypedExpr, catches:Array<{v:TVar, expr:TypedExpr}>):String {
		var lines = ["begin"];
		appendIndentedLines(lines, renderStatements(compileFunctionBody(tryExpr)), 1);
		if (catches.length > 0) {
			var first = catches[0];
			lines.push("rescue HxException => __hx_ex");
			lines.push("  " + localName(first.v) + " = __hx_ex.value");
			appendIndentedLines(lines, renderStatements(compileFunctionBody(first.expr)), 1);
		}
		lines.push("end");
		return lines.join("\n");
	}

	static function renderFor(v:TVar, iterable:TypedExpr, body:TypedExpr):String {
		var iteratorName = loopIteratorName(v, iterable);
		var lines = [
			iteratorName + " = " + printInlineExpr(iterable),
			"while " + iteratorName + ".has_next()",
			"  " + localName(v) + " = " + iteratorName + ".next_()"
		];
		appendIndentedLines(lines, renderStatements(compileFunctionBody(body)), 1);
		lines.push("end");
		return lines.join("\n");
	}

	static function switchScrutineeCode(expr:TypedExpr):String {
		return switch (expr.expr) {
			case TEnumIndex(enumExpr):
				printInlineExpr(enumExpr) + ".__hx_index";
			case _:
				printInlineExpr(expr);
		}
	}

	static function switchValueCode(expr:TypedExpr, usesEnumIndex:Bool):String {
		if (usesEnumIndex) {
			return printInlineExpr(expr);
		}
		return switch (expr.expr) {
			case TField(_, FEnum(_, field)):
				quoteRubyStringForCode(field.name);
			case _:
				printInlineExpr(expr);
		}
	}

	static function renderStatements(statements:Array<RubyStatement>):Array<String> {
		var file = {
			modulePath: [],
			statements: statements
		};
		var printed = reflaxe.ruby.ast.RubyASTPrinter.printFile(file).split("\n");
		if (printed.length > 0 && printed[printed.length - 1] == "") {
			printed.pop();
		}
		return printed;
	}

	static function appendIndentedLines(target:Array<String>, lines:Array<String>, indentLevel:Int):Void {
		var indent = "";
		for (_ in 0...indentLevel) {
			indent += "  ";
		}
		for (line in lines) {
			target.push(indent + line);
		}
	}

	static function indentLines(lines:Array<String>, indentLevel:Int):Array<String> {
		var out:Array<String> = [];
		appendIndentedLines(out, lines, indentLevel);
		return out;
	}

	function setRuntimeExtraFile(name:String):Void {
		setExtraFile(OutputPath.fromStr(outputRelativePath("hxruby/" + name, true)), runtimeFileContent(name));
	}

	function setRailsAutoloadInitializer():Void {
		var root = buildContext.railsOutputRoot;
		var lines = [
			"# Generated by reflaxe.ruby",
			"hxruby_root = Rails.root.join(" + quoteRubyStringForCode(root) + ")",
			"hxruby_runtime_root = hxruby_root.join(\"hxruby\")",
			"Rails.autoloaders.main.ignore(hxruby_runtime_root) if defined?(Rails.autoloaders) && hxruby_runtime_root.exist?",
			"Dir[hxruby_runtime_root.join(\"*.rb\")].sort.each { |path| require path }",
			"Rails.application.config.autoload_paths << hxruby_root",
			"Rails.application.config.eager_load_paths << hxruby_root",
			""
		];
		setRailsExtraFile("config/initializers/hxruby_autoload.rb", lines.join("\n"), Context.currentPos());
	}

	function emitRailsMigrationArtifact(classType:ClassType, varFields:Array<ClassVarData>):Void {
		if (!buildContext.railsMode) {
			Context.error("@:railsMigration requires -D reflaxe_ruby_rails.", classType.pos);
			return;
		}
		var config = railsMigrationConfig(classType, varFields);
		if (config == null) {
			return;
		}
		var body = railsMigrationBody(config);
		var fileName = config.timestamp + "_" + RubyNaming.fileName(config.className) + ".rb";
		var outputPath = "db/migrate/" + fileName;
		if (emittedRailsMigrationPaths.exists(outputPath)) {
			Context.error('@:railsMigration emits duplicate migration file ${outputPath}; first emitted by ${emittedRailsMigrationPaths.get(outputPath)}.',
				classType.pos);
			return;
		}
		var source = fullTypeName(classType.pack, classType.name);
		registerRailsMigration(config, source, classType.pos);
		emittedRailsMigrationPaths.set(outputPath, source);
		setRailsExtraFile(outputPath, normalizeGeneratedText(body), classType.pos);
	}

	function registerRailsMigration(config:RailsMigrationConfig, source:String, pos:Position):Void {
		emittedRailsMigrations.push({
			timestamp: config.timestamp,
			className: config.className,
			source: source,
			pos: pos,
			createdTables: [for (model in config.models) railsModelTableName(model)],
			foreignKeys: railsMigrationForeignKeys(config)
		});
		validateRailsMigrationRegistry();
	}

	function validateRailsMigrationRegistry():Void {
		var timestamps:Map<String, RailsEmittedMigration> = [];
		var tableCreators:Map<String, RailsEmittedMigration> = [];
		for (migration in emittedRailsMigrations) {
			if (timestamps.exists(migration.timestamp)) {
				var first = timestamps.get(migration.timestamp);
				Context.error('@:railsMigration timestamp ${migration.timestamp} is already used by ${first.source}; migration timestamps must be unique for deterministic Rails ordering.',
					migration.pos);
			}
			timestamps.set(migration.timestamp, migration);
			for (table in migration.createdTables) {
				if (!tableCreators.exists(table) || tableCreators.get(table).timestamp > migration.timestamp) {
					tableCreators.set(table, migration);
				}
			}
		}
		for (migration in emittedRailsMigrations) {
			for (foreignKey in migration.foreignKeys) {
				validateRailsMigrationForeignKeyTable(tableCreators, migration, foreignKey.fromTable, "source");
				validateRailsMigrationForeignKeyTable(tableCreators, migration, foreignKey.toTable, "target");
			}
		}
	}

	function validateRailsMigrationForeignKeyTable(tableCreators:Map<String, RailsEmittedMigration>, migration:RailsEmittedMigration, table:String,
			label:String):Void {
		var creator = tableCreators.get(table);
		if (creator != null && creator.timestamp > migration.timestamp) {
			Context.error('@:railsMigration foreign key ${label} table "$table" is created by ${creator.source} at ${creator.timestamp}, after ${migration.source} at ${migration.timestamp}. Move the foreign key to a later migration or adjust timestamps.',
				migration.pos);
		}
	}

	static function railsMigrationForeignKeys(config:RailsMigrationConfig):Array<RailsMigrationForeignKeyRef> {
		var out:Array<RailsMigrationForeignKeyRef> = [];
		for (model in config.models) {
			var table = railsModelTableName(model);
			for (assoc in railsBelongsToInfo(model)) {
				out.push({fromTable: table, toTable: assoc.referencedTable});
			}
		}
		for (operation in config.operations) {
			out = out.concat(operation.foreignKeys);
		}
		return out;
	}

	static function railsMigrationConfig(classType:ClassType, varFields:Array<ClassVarData>):Null<RailsMigrationConfig> {
		var entries = classType.meta.extract(":railsMigration");
		if (entries.length == 0 || entries[0].params == null || entries[0].params.length == 0) {
			Context.error("@:railsMigration expects an options object with timestamp, className, and models.", classType.pos);
			return null;
		}
		var timestamp:Null<String> = null;
		var className:Null<String> = null;
		var version = "7.1";
		var modelPaths:Array<String> = [];
		var knownModelPaths:Array<String> = [];
		var externalTables:Array<String> = [];
		switch (entries[0].params[0].expr) {
			case EObjectDecl(fields):
				for (field in (fields : Array<RubyMetadataField>)) {
					switch (field.field) {
						case "timestamp":
							timestamp = metadataStringLiteral(field.expr);
						case "className" | "name":
							className = metadataStringLiteral(field.expr);
						case "version" | "migrationVersion":
							version = metadataStringLiteral(field.expr);
						case "models":
							modelPaths = metadataStringArray(field.expr, "models");
						case "knownModels":
							knownModelPaths = metadataStringArray(field.expr, "knownModels");
						case "externalTables":
							externalTables = [
								for (table in metadataStringArray(field.expr, "externalTables"))
									safeRailsMigrationExternalTable(table, field.expr.pos)
							];
						case other:
							Context.error('@:railsMigration unknown option $other.', field.expr.pos);
					}
				}
			case _:
				Context.error("@:railsMigration expects an options object.", entries[0].params[0].pos);
		}
		if (timestamp == null || !~/^[0-9]{14}$/.match(timestamp)) {
			Context.error("@:railsMigration timestamp must be a 14-digit string.", classType.pos);
			return null;
		}
		if (className == null || className == "") {
			Context.error("@:railsMigration className must be a non-empty string.", classType.pos);
			return null;
		}
		if (!~/^[0-9]+[.][0-9]+$/.match(version)) {
			Context.error('@:railsMigration version must be a Rails migration version string such as "7.1" or "8.1".', classType.pos);
			return null;
		}
		var tableNames:Map<String, String> = [];
		var models = railsMigrationResolveModels(modelPaths, tableNames, classType, false);
		var knownModels = railsMigrationResolveModels(knownModelPaths, tableNames, classType, true);
		var validationContext = railsMigrationValidationContext(models, knownModels, externalTables);
		var operations = railsMigrationOperations(varFields, classType, validationContext);
		if (modelPaths.length == 0 && operations.length == 0) {
			Context.error("@:railsMigration models must include at least one model path unless typed operations are provided.", classType.pos);
			return null;
		}
		return {
			timestamp: timestamp,
			className: className,
			version: version,
			models: models,
			knownModels: knownModels,
			externalTables: externalTables,
			operations: operations
		};
	}

	static function safeRailsMigrationExternalTable(table:String, pos:haxe.macro.Expr.Position):String {
		var normalized = RubyNaming.toMethodName(table);
		if (table == null || table == "" || table.indexOf("/") != -1 || table.indexOf("\\") != -1 || table.indexOf(".") != -1
			|| !~/^[a-z][a-z0-9_]*$/.match(normalized)) {
			Context.error('@:railsMigration externalTables entries must be safe Rails table identifiers such as "legacy_events".', pos);
		}
		return normalized;
	}

	static function railsMigrationResolveModels(modelPaths:Array<String>, tableNames:Map<String, String>, classType:ClassType,
			validationOnly:Bool):Array<ClassType> {
		var models:Array<ClassType> = [];
		for (path in modelPaths) {
			switch (Context.getType(path)) {
				case TInst(ref, _):
					var model = ref.get();
					if (!hasMeta(model.meta, ":railsModel")) {
						Context.error('@:railsMigration model "$path" must be annotated with @:railsModel.', classType.pos);
					}
					var tableName = railsModelTableName(model);
					if (!validationOnly && tableNames.exists(tableName)) {
						Context.error('@:railsMigration cannot create table "$tableName" more than once; already provided by ${tableNames.get(tableName)}.',
							classType.pos);
					}
					if (!validationOnly) {
						tableNames.set(tableName, path);
					}
					models.push(model);
				case _:
					Context.error('@:railsMigration model "$path" must resolve to a class.', classType.pos);
			}
		}
		return models;
	}

	static function railsMigrationValidationContext(models:Array<ClassType>, knownModels:Array<ClassType>,
			externalTables:Array<String>):Null<RailsMigrationValidationContext> {
		if (models.length == 0 && knownModels.length == 0) {
			return null;
		}
		var columnsByTable:Map<String, Map<String, Bool>> = [];
		var snapshotColumnsByTable:Map<String, Map<String, Bool>> = [];
		for (model in models) {
			var table = railsModelTableName(model);
			var columns = railsMigrationModelColumns(model);
			columnsByTable.set(table, columns);
			snapshotColumnsByTable.set(table, columns.copy());
		}
		for (model in knownModels) {
			var table = railsModelTableName(model);
			if (!columnsByTable.exists(table)) {
				columnsByTable.set(table, railsMigrationModelColumns(model));
			}
		}
		var external:Map<String, Bool> = [];
		for (table in externalTables) {
			external.set(table, true);
		}
		return {
			columnsByTable: columnsByTable,
			snapshotColumnsByTable: snapshotColumnsByTable,
			externalTables: external,
			strictTables: true
		};
	}

	static function railsMigrationModelColumns(model:ClassType):Map<String, Bool> {
		var columns:Map<String, Bool> = [];
		for (field in model.fields.get()) {
			if (hasMeta(field.meta, ":railsColumn")) {
				columns.set(railsColumnInfoFromField(field).rubyName, true);
			}
		}
		for (assoc in railsBelongsToInfo(model)) {
			columns.set(assoc.columnName, true);
		}
		return columns;
	}

	static function railsMigrationBody(config:RailsMigrationConfig):String {
		var lines = ["# Generated by RailsHx from @:railsMigration.",
			"class "
			+ RubyNaming.toConstantName(config.className)
			+ " < ActiveRecord::Migration["
			+ config.version
			+ "]",
			"  def change"
		];
		for (index in 0...config.models.length) {
			if (index > 0) {
				lines.push("");
			}
			appendRailsCreateTableMigration(lines, config.models[index]);
		}
		if (config.operations.length > 0) {
			if (config.models.length > 0) {
				lines.push("");
			}
			for (operation in config.operations) {
				for (line in operation.lines) {
					lines.push(line == "" ? "" : "    " + line);
				}
			}
		}
		lines.push("  end");
		lines.push("end");
		return lines.join("\n");
	}

	static function appendRailsCreateTableMigration(lines:Array<String>, model:ClassType):Void {
		var tableName = railsModelTableName(model);
		var belongsTo = railsBelongsToInfo(model);
		lines.push("    create_table :" + tableName + " do |t|");
		for (field in model.fields.get()) {
			if (!hasMeta(field.meta, ":railsColumn")) {
				continue;
			}
			var info = railsColumnInfoFromField(field);
			if (info.primaryKey && info.rubyName == "id") {
				continue;
			}
			var assoc = belongsTo.get(info.rubyName);
			if (assoc != null) {
				var options = railsMigrationColumnOptions(info);
				options.push("foreign_key: true");
				lines.push("      t.references :" + assoc.rubyName + railsMigrationOptionSuffix(options));
			} else {
				lines.push("      t." + info.railsType + " :" + info.rubyName + railsMigrationOptionSuffix(railsMigrationColumnOptions(info)));
			}
		}
		if (hasMeta(model.meta, ":railsTimestamps")) {
			lines.push("");
			lines.push("      t.timestamps");
		}
		var indexed = railsMigrationIndexes(model, belongsTo);
		if (indexed.length > 0) {
			lines.push("");
			for (indexLine in indexed) {
				lines.push("      " + indexLine);
			}
		}
		lines.push("    end");
	}

	static function railsMigrationOperations(varFields:Array<ClassVarData>, classType:ClassType,
			validation:Null<RailsMigrationValidationContext>):Array<RailsMigrationOperationInfo> {
		var operationField:Null<ClassVarData> = null;
		for (field in varFields) {
			if (field.isStatic && field.field.name == "operations") {
				operationField = field;
				break;
			}
		}
		if (operationField == null) {
			return [];
		}
		var expr = operationField.field.expr();
		if (expr == null) {
			Context.error("@:railsMigration operations must be a static final Array<MigrationOperation> literal.", operationField.field.pos);
			return [];
		}
		return railsMigrationOperationArray(expr, "@:railsMigration operations", false, validation);
	}

	static function railsMigrationOperationArray(expr:TypedExpr, label:String, allowIrreversible:Bool,
			validation:Null<RailsMigrationValidationContext>):Array<RailsMigrationOperationInfo> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TArrayDecl(values):
				var operations:Array<RailsMigrationOperationInfo> = [];
				for (value in values) {
					operations.push(railsMigrationOperationInfo(value, allowIrreversible, validation));
				}
				operations;
			case _:
				Context.error(label + " must be an Array<MigrationOperation> literal.", expr.pos);
				[];
		}
	}

	static function railsMigrationOperationInfo(expr:TypedExpr, allowIrreversible:Bool,
			validation:Null<RailsMigrationValidationContext>):RailsMigrationOperationInfo {
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall({expr: TField(_, FEnum(_, field))}, args):
				switch (field.name) {
					case "CreateTable" if (args.length == 2):
						var table = railsMigrationSymbolArg(args[0], "CreateTable table");
						railsMigrationCreateTableOperation(table, args[1], validation);
					case "AddColumn" if (args.length == 3):
						var table = railsMigrationSymbolArg(args[0], "AddColumn table");
						var name = railsMigrationSymbolArg(args[1], "AddColumn name");
						railsMigrationValidateTable(validation, table, "AddColumn table", args[0]);
						railsMigrationValidateNewColumn(validation, table, name, "AddColumn name", args[1]);
						var column = railsMigrationColumnDsl(args[2]);
						railsMigrationRegisterColumn(validation, table, name);
						railsMigrationOperation([
							"add_column :" + table + ", :" + name + ", :" + column.type + railsMigrationOptionSuffix(column.options)
						]);
					case "RemoveColumn" if (args.length == 2):
						railsMigrationRequireReversibleContext("RemoveColumn", allowIrreversible, expr);
						var table = railsMigrationSymbolArg(args[0], "RemoveColumn table");
						var name = railsMigrationSymbolArg(args[1], "RemoveColumn name");
						railsMigrationValidateTable(validation, table, "RemoveColumn table", args[0]);
						railsMigrationValidateColumn(validation, table, name, "RemoveColumn name", args[1]);
						railsMigrationOperation(["remove_column :" + table + ", :" + name]);
					case "ChangeColumn" if (args.length == 3):
						railsMigrationRequireReversibleContext("ChangeColumn", allowIrreversible, expr);
						var table = railsMigrationSymbolArg(args[0], "ChangeColumn table");
						var name = railsMigrationSymbolArg(args[1], "ChangeColumn name");
						railsMigrationValidateTable(validation, table, "ChangeColumn table", args[0]);
						railsMigrationValidateColumn(validation, table, name, "ChangeColumn name", args[1]);
						var column = railsMigrationColumnDsl(args[2]);
						railsMigrationOperation([
							"change_column :" + table + ", :" + name + ", :" + column.type + railsMigrationOptionSuffix(column.options)
						]);
					case "AddIndex" if (args.length == 3):
						var table = railsMigrationSymbolArg(args[0], "AddIndex table");
						var columnName = railsMigrationSymbolArg(args[1], "AddIndex column");
						railsMigrationValidateTable(validation, table, "AddIndex table", args[0]);
						railsMigrationValidateColumn(validation, table, columnName, "AddIndex column", args[1]);
						var options = railsMigrationIndexDslOptions(args[2]);
						railsMigrationOperation(["add_index :" + table + ", :" + columnName + railsMigrationOptionSuffix(options)]);
					case "AddCompositeIndex" if (args.length == 3):
						var table = railsMigrationSymbolArg(args[0], "AddCompositeIndex table");
						var columns = railsMigrationSymbolArrayArg(args[1], "AddCompositeIndex columns");
						railsMigrationValidateTable(validation, table, "AddCompositeIndex table", args[0]);
						for (columnName in columns) {
							railsMigrationValidateColumn(validation, table, columnName, "AddCompositeIndex column", args[1]);
						}
						var options = railsMigrationIndexDslOptions(args[2]);
						railsMigrationOperation(["add_index :"
							+ table
							+ ", ["
							+ [for (column in columns) ":" + column].join(", ") + "]" + railsMigrationOptionSuffix(options)]);
					case "RemoveIndex" if (args.length == 2):
						var table = railsMigrationSymbolArg(args[0], "RemoveIndex table");
						var columnName = railsMigrationSymbolArg(args[1], "RemoveIndex column");
						railsMigrationValidateTable(validation, table, "RemoveIndex table", args[0]);
						railsMigrationValidateColumn(validation, table, columnName, "RemoveIndex column", args[1]);
						railsMigrationOperation(["remove_index :" + table + ", :" + columnName]);
					case "RemoveIndexByName" if (args.length == 2):
						var table = railsMigrationSymbolArg(args[0], "RemoveIndexByName table");
						var name = railsMigrationSafeIdentifier(args[1], "RemoveIndexByName name");
						railsMigrationValidateTable(validation, table, "RemoveIndexByName table", args[0]);
						railsMigrationOperation(["remove_index :" + table + ", name: " + quoteRubyStringForCode(name)]);
					case "RemoveCompositeIndex" if (args.length == 2):
						var table = railsMigrationSymbolArg(args[0], "RemoveCompositeIndex table");
						var columns = railsMigrationSymbolArrayArg(args[1], "RemoveCompositeIndex columns");
						railsMigrationValidateTable(validation, table, "RemoveCompositeIndex table", args[0]);
						for (columnName in columns) {
							railsMigrationValidateColumn(validation, table, columnName, "RemoveCompositeIndex column", args[1]);
						}
						railsMigrationOperation(["remove_index :"
							+ table
							+ ", column: ["
							+ [for (column in columns) ":" + column].join(", ") + "]"]);
					case "AddReference" if (args.length == 3):
						var table = railsMigrationSymbolArg(args[0], "AddReference table");
						var name = railsMigrationSymbolArg(args[1], "AddReference name");
						railsMigrationValidateTable(validation, table, "AddReference table", args[0]);
						var options = railsMigrationReferenceDslOptions(args[2]);
						var columnName = name + "_id";
						railsMigrationRegisterColumn(validation, table, columnName);
						railsMigrationOperation(["add_reference :" + table + ", :" + name + railsMigrationOptionSuffix(options)]);
					case "RemoveReference" if (args.length == 3):
						railsMigrationRequireReversibleContext("RemoveReference", allowIrreversible, expr);
						var table = railsMigrationSymbolArg(args[0], "RemoveReference table");
						var name = railsMigrationSymbolArg(args[1], "RemoveReference name");
						railsMigrationValidateTable(validation, table, "RemoveReference table", args[0]);
						railsMigrationValidateColumn(validation, table, name + "_id", "RemoveReference column", args[1]);
						var options = railsMigrationReferenceDslOptions(args[2]);
						railsMigrationOperation([
							"remove_reference :" + table + ", :" + name + railsMigrationOptionSuffix(options)
						]);
					case "AddForeignKey" if (args.length == 3):
						var fromTable = railsMigrationSymbolArg(args[0], "AddForeignKey fromTable");
						var toTable = railsMigrationSymbolArg(args[1], "AddForeignKey toTable");
						railsMigrationValidateTable(validation, fromTable, "AddForeignKey fromTable", args[0]);
						railsMigrationValidateTable(validation, toTable, "AddForeignKey toTable", args[1]);
						var options = railsMigrationForeignKeyDslOptions(args[2], validation, fromTable);
						railsMigrationOperation([
							"add_foreign_key :" + fromTable + ", :" + toTable + railsMigrationOptionSuffix(options)
						], [{fromTable: fromTable, toTable: toTable}]);
					case "RemoveForeignKey" if (args.length == 2):
						var fromTable = railsMigrationSymbolArg(args[0], "RemoveForeignKey fromTable");
						var toTable = railsMigrationSymbolArg(args[1], "RemoveForeignKey toTable");
						railsMigrationValidateTable(validation, fromTable, "RemoveForeignKey fromTable", args[0]);
						railsMigrationValidateTable(validation, toTable, "RemoveForeignKey toTable", args[1]);
						railsMigrationOperation(["remove_foreign_key :" + fromTable + ", :" + toTable]);
					case "RemoveForeignKeyByName" if (args.length == 2):
						var fromTable = railsMigrationSymbolArg(args[0], "RemoveForeignKeyByName fromTable");
						var name = railsMigrationSafeIdentifier(args[1], "RemoveForeignKeyByName name");
						railsMigrationValidateTable(validation, fromTable, "RemoveForeignKeyByName fromTable", args[0]);
						railsMigrationOperation(["remove_foreign_key :" + fromTable + ", name: " + quoteRubyStringForCode(name)]);
					case "RenameColumn" if (args.length == 3):
						railsMigrationRequireReversibleContext("RenameColumn", allowIrreversible, expr);
						var table = railsMigrationSymbolArg(args[0], "RenameColumn table");
						var from = railsMigrationSymbolArg(args[1], "RenameColumn from");
						var to = railsMigrationSymbolArg(args[2], "RenameColumn to");
						railsMigrationValidateTable(validation, table, "RenameColumn table", args[0]);
						railsMigrationValidateColumn(validation, table, from, "RenameColumn from", args[1]);
						railsMigrationRegisterColumn(validation, table, to);
						railsMigrationOperation(["rename_column :" + table + ", :" + from + ", :" + to]);
					case "RenameTable" if (args.length == 2):
						railsMigrationRequireReversibleContext("RenameTable", allowIrreversible, expr);
						var from = railsMigrationSymbolArg(args[0], "RenameTable from");
						var to = railsMigrationSymbolArg(args[1], "RenameTable to");
						railsMigrationValidateTable(validation, from, "RenameTable from", args[0]);
						railsMigrationOperation(["rename_table :" + from + ", :" + to]);
					case "ChangeNull" if (args.length == 3):
						var table = railsMigrationSymbolArg(args[0], "ChangeNull table");
						var name = railsMigrationSymbolArg(args[1], "ChangeNull name");
						var nullable = typedBoolLiteral(args[2], "ChangeNull nullable");
						railsMigrationValidateTable(validation, table, "ChangeNull table", args[0]);
						railsMigrationValidateColumn(validation, table, name, "ChangeNull name", args[1]);
						railsMigrationOperation([
							"change_column_null :" + table + ", :" + name + ", " + (nullable ? "true" : "false")
						]);
					case "AddCheckConstraint" if (args.length == 3):
						var table = railsMigrationSymbolArg(args[0], "AddCheckConstraint table");
						var expression = typedStringLiteral(args[1]);
						if (expression == null || expression == "") {
							Context.error("@:railsMigration AddCheckConstraint expression must be a non-empty literal string.", args[1].pos);
						}
						var options = railsMigrationCheckConstraintDslOptions(args[2]);
						railsMigrationValidateTable(validation, table, "AddCheckConstraint table", args[0]);
						railsMigrationOperation(["add_check_constraint :"
							+ table
							+ ", "
							+ quoteRubyStringForCode(expression == null ? "" : expression)
							+ railsMigrationOptionSuffix(options)]);
					case "RemoveCheckConstraint" if (args.length == 2):
						railsMigrationRequireReversibleContext("RemoveCheckConstraint", allowIrreversible, expr);
						var table = railsMigrationSymbolArg(args[0], "RemoveCheckConstraint table");
						var name = railsMigrationSafeIdentifier(args[1], "RemoveCheckConstraint name");
						railsMigrationValidateTable(validation, table, "RemoveCheckConstraint table", args[0]);
						railsMigrationOperation(["remove_check_constraint :" + table + ", name: " + quoteRubyStringForCode(name)]);
					case "DropTable" if (args.length == 1):
						railsMigrationRequireReversibleContext("DropTable", allowIrreversible, expr);
						var table = railsMigrationSymbolArg(args[0], "DropTable table");
						railsMigrationValidateTable(validation, table, "DropTable table", args[0]);
						railsMigrationOperation(["drop_table :" + table]);
					case "ExecuteSql" if (args.length == 2):
						railsMigrationUnsafeSqlOperation("ExecuteSql", args[0], args[1], expr);
					case "DataMigration" if (args.length == 2):
						railsMigrationUnsafeSqlOperation("DataMigration", args[0], args[1], expr);
					case "Reversible" if (args.length == 2):
						railsMigrationReversibleOperation(args[0], args[1], validation);
					case _:
						Context.error('@:railsMigration unsupported MigrationOperation ${field.name}.', expr.pos);
						railsMigrationOperation(["# unsupported RailsHx migration operation"]);
				}
			case _:
				Context.error("@:railsMigration operations must contain MigrationOperation enum values.", expr.pos);
				railsMigrationOperation(["# invalid RailsHx migration operation"]);
		}
	}

	static function railsMigrationRequireReversibleContext(operation:String, allowIrreversible:Bool, expr:TypedExpr):Void {
		if (!allowIrreversible) {
			Context.error('@:railsMigration ${operation} must be wrapped in Reversible(up, down) so RailsHx has an explicit rollback shape.', expr.pos);
		}
	}

	static function railsMigrationCreateTableOperation(table:String, optionsExpr:TypedExpr,
			validation:Null<RailsMigrationValidationContext>):RailsMigrationOperationInfo {
		var lines = ["create_table :" + table + " do |t|"];
		var timestamps = false;
		switch (unwrapTypedExpr(optionsExpr).expr) {
			case TObjectDecl(fields):
				for (field in fields) {
					switch (field.name) {
						case "columns":
							for (item in railsMigrationCreateTableItems(field.expr, table, validation)) {
								lines.push("  " + item);
							}
						case "timestamps":
							timestamps = typedBoolLiteral(field.expr, "CreateTable timestamps");
						case _:
							Context.error('@:railsMigration unknown CreateTable option ${field.name}.', field.expr.pos);
					}
				}
			case _:
				Context.error("@:railsMigration CreateTable options must be an object literal.", optionsExpr.pos);
		}
		if (timestamps) {
			lines.push("");
			lines.push("  t.timestamps");
		}
		lines.push("end");
		return railsMigrationOperation(lines);
	}

	static function railsMigrationCreateTableItems(expr:TypedExpr, table:String, validation:Null<RailsMigrationValidationContext>):Array<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TArrayDecl(values):
				var out:Array<String> = [];
				for (value in values) {
					out = out.concat(railsMigrationCreateTableItem(value, table, validation));
				}
				out;
			case _:
				Context.error("@:railsMigration CreateTable columns must be an Array<CreateTableItem> literal.", expr.pos);
				[];
		}
	}

	static function railsMigrationCreateTableItem(expr:TypedExpr, table:String, validation:Null<RailsMigrationValidationContext>):Array<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall({expr: TField(_, FEnum(_, field))}, args):
				switch (field.name) {
					case "Column" if (args.length == 2):
						var name = railsMigrationSymbolArg(args[0], "CreateTable Column name");
						var column = railsMigrationColumnDsl(args[1]);
						railsMigrationRegisterColumn(validation, table, name);
						["t." + column.type + " :" + name + railsMigrationOptionSuffix(column.options)];
					case "Reference" if (args.length == 2):
						var name = railsMigrationSymbolArg(args[0], "CreateTable Reference name");
						railsMigrationRegisterColumn(validation, table, name + "_id");
						[
							"t.references :" + name + railsMigrationOptionSuffix(railsMigrationReferenceDslOptions(args[1]))
						];
					case "Index" if (args.length == 2):
						var columns = railsMigrationSymbolArrayArg(args[0], "CreateTable Index columns");
						var options = railsMigrationIndexDslOptions(args[1]);
						[
							"t.index [" + [for (column in columns) ":" + column].join(", ") + "]" + railsMigrationOptionSuffix(options)
						];
					case _:
						Context.error('@:railsMigration unsupported CreateTableItem ${field.name}.', expr.pos);
						["# unsupported RailsHx create table item"];
				}
			case _:
				Context.error("@:railsMigration CreateTable columns must contain CreateTableItem enum values.", expr.pos);
				["# invalid RailsHx create table item"];
		}
	}

	static function railsMigrationUnsafeSqlOperation(label:String, upExpr:TypedExpr, downExpr:TypedExpr, callExpr:TypedExpr):RailsMigrationOperationInfo {
		var up = typedStringLiteral(upExpr);
		var down = typedStringLiteral(downExpr);
		if (up == null || up == "" || down == null || down == "") {
			Context.error('@:railsMigration $label expects non-empty literal up and rollback SQL strings.', callExpr.pos);
		}
		return railsMigrationOperation([
			"reversible do |dir|",
			"  dir.up do",
			"    execute " + quoteRubyStringForCode(up == null ? "" : up),
			"  end",
			"  dir.down do",
			"    execute " + quoteRubyStringForCode(down == null ? "" : down),
			"  end",
			"end"
		]);
	}

	static function railsMigrationValidateTable(validation:Null<RailsMigrationValidationContext>, table:String, label:String, expr:TypedExpr):Bool {
		if (validation == null || validation.columnsByTable.exists(table) || validation.externalTables.exists(table)) {
			return true;
		}
		if (validation.strictTables) {
			Context.error('@:railsMigration ${label} references unknown table "$table". Add the model to knownModels/models or list the Rails-owned table in externalTables.',
				expr.pos);
		}
		return false;
	}

	static function railsMigrationValidateColumn(validation:Null<RailsMigrationValidationContext>, table:String, column:String, label:String,
			expr:TypedExpr):Void {
		if (validation == null || validation.externalTables.exists(table)) {
			return;
		}
		var columns = validation.columnsByTable.get(table);
		if (columns != null && !columns.exists(column)) {
			Context.error('@:railsMigration ${label} references unknown column "$column" on table "$table". Add/update known model metadata or list the table in externalTables if Rails owns it.',
				expr.pos);
		}
	}

	static function railsMigrationValidateNewColumn(validation:Null<RailsMigrationValidationContext>, table:String, column:String, label:String,
			expr:TypedExpr):Void {
		if (validation == null || validation.externalTables.exists(table)) {
			return;
		}
		var snapshotColumns = validation.snapshotColumnsByTable.get(table);
		if (snapshotColumns != null && snapshotColumns.exists(column)) {
			Context.error('@:railsMigration ${label} references column "$column" already emitted by this migration snapshot on table "$table". Use ChangeColumn for existing same-snapshot columns.',
				expr.pos);
		}
	}

	static function railsMigrationRegisterColumn(validation:Null<RailsMigrationValidationContext>, table:String, column:String):Void {
		if (validation == null || validation.externalTables.exists(table)) {
			return;
		}
		var columns = validation.columnsByTable.get(table);
		if (columns == null) {
			columns = [];
			validation.columnsByTable.set(table, columns);
		}
		if (columns != null) {
			columns.set(column, true);
		}
		var snapshotColumns = validation.snapshotColumnsByTable.get(table);
		if (snapshotColumns == null) {
			snapshotColumns = [];
			validation.snapshotColumnsByTable.set(table, snapshotColumns);
		}
		if (snapshotColumns != null) {
			snapshotColumns.set(column, true);
		}
	}

	static function railsMigrationOperation(lines:Array<String>, ?foreignKeys:Array<RailsMigrationForeignKeyRef>):RailsMigrationOperationInfo {
		return {lines: lines, foreignKeys: foreignKeys == null ? [] : foreignKeys};
	}

	static function railsMigrationReversibleOperation(upExpr:TypedExpr, downExpr:TypedExpr,
			validation:Null<RailsMigrationValidationContext>):RailsMigrationOperationInfo {
		var lines = ["reversible do |dir|", "  dir.up do"];
		var foreignKeys:Array<RailsMigrationForeignKeyRef> = [];
		for (operation in railsMigrationOperationArray(upExpr, "@:railsMigration Reversible up", true, validation)) {
			foreignKeys = foreignKeys.concat(operation.foreignKeys);
			for (line in operation.lines) {
				lines.push("    " + line);
			}
		}
		lines.push("  end");
		lines.push("  dir.down do");
		for (operation in railsMigrationOperationArray(downExpr, "@:railsMigration Reversible down", true, validation)) {
			for (line in operation.lines) {
				lines.push("    " + line);
			}
		}
		lines.push("  end");
		lines.push("end");
		return railsMigrationOperation(lines, foreignKeys);
	}

	static function railsMigrationColumnDsl(expr:TypedExpr):{type:String, options:Array<String>} {
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall({expr: TField(_, FEnum(_, field))}, args) if (args.length == 1):
				var type = switch (field.name) {
					case "StringColumn": "string";
					case "TextColumn": "text";
					case "IntegerColumn": "integer";
					case "BooleanColumn": "boolean";
					case "FloatColumn": "float";
					case "DecimalColumn": "decimal";
					case _:
						Context.error('@:railsMigration unsupported MigrationColumn ${field.name}.', expr.pos);
						"string";
				}
				{type: type, options: railsMigrationColumnDslOptions(args[0])};
			case _:
				Context.error("@:railsMigration AddColumn expects a MigrationColumn enum value.", expr.pos);
				{type: "string", options: []};
		}
	}

	static function railsMigrationColumnDslOptions(expr:TypedExpr):Array<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TObjectDecl(fields):
				var options:Array<String> = [];
				for (field in fields) {
					switch (field.name) {
						case "nullable":
							var value = typedBoolLiteral(field.expr, "MigrationColumn nullable");
							if (!value) {
								options.push("null: false");
							}
						case "defaultValue":
							options.push("default: " + typedMigrationLiteralCode(field.expr));
						case "limit":
							options.push("limit: " + typedPositiveIntLiteral(field.expr, "MigrationColumn limit"));
						case "precision":
							options.push("precision: " + typedPositiveIntLiteral(field.expr, "MigrationColumn precision"));
						case "scale":
							options.push("scale: " + typedNonNegativeIntLiteral(field.expr, "MigrationColumn scale"));
						case _:
							Context.error('@:railsMigration unknown MigrationColumn option ${field.name}.', field.expr.pos);
					}
				}
				options;
			case _:
				Context.error("@:railsMigration MigrationColumn options must be an object literal.", expr.pos);
				[];
		}
	}

	static function railsMigrationIndexDslOptions(expr:TypedExpr):Array<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TObjectDecl(fields):
				var options:Array<String> = [];
				for (field in fields) {
					switch (field.name) {
						case "unique":
							if (typedBoolLiteral(field.expr, "MigrationIndex unique")) {
								options.push("unique: true");
							}
						case "name":
							options.push("name: " + quoteRubyStringForCode(railsMigrationSafeIdentifier(field.expr, "MigrationIndex name")));
						case "ifNotExists":
							if (typedBoolLiteral(field.expr, "MigrationIndex ifNotExists")) {
								options.push("if_not_exists: true");
							}
						case _:
							Context.error('@:railsMigration unknown MigrationIndex option ${field.name}.', field.expr.pos);
					}
				}
				options;
			case _:
				Context.error("@:railsMigration AddIndex options must be an object literal.", expr.pos);
				[];
		}
	}

	static function railsMigrationReferenceDslOptions(expr:TypedExpr):Array<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TObjectDecl(fields):
				var options:Array<String> = [];
				var foreignKey = false;
				var foreignKeyName:Null<String> = null;
				for (field in fields) {
					switch (field.name) {
						case "nullable":
							if (!typedBoolLiteral(field.expr, "Reference nullable")) {
								options.push("null: false");
							}
						case "foreignKey":
							foreignKey = typedBoolLiteral(field.expr, "Reference foreignKey");
						case "foreignKeyName":
							foreignKeyName = railsMigrationSafeIdentifier(field.expr, "Reference foreignKeyName");
						case "index":
							if (!typedBoolLiteral(field.expr, "Reference index")) {
								options.push("index: false");
							}
						case "polymorphic":
							if (typedBoolLiteral(field.expr, "Reference polymorphic")) {
								options.push("polymorphic: true");
							}
						case _:
							Context.error('@:railsMigration unknown Reference option ${field.name}.', field.expr.pos);
					}
				}
				if (foreignKeyName != null) {
					options.push("foreign_key: { name: " + quoteRubyStringForCode(foreignKeyName) + " }");
				} else if (foreignKey) {
					options.push("foreign_key: true");
				}
				options;
			case _:
				Context.error("@:railsMigration Reference options must be an object literal.", expr.pos);
				[];
		}
	}

	static function railsMigrationCheckConstraintDslOptions(expr:TypedExpr):Array<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TObjectDecl(fields):
				var options:Array<String> = [];
				var hasName = false;
				for (field in fields) {
					switch (field.name) {
						case "name":
							var name = railsMigrationSafeIdentifier(field.expr, "CheckConstraint name");
							hasName = true;
							options.push("name: " + quoteRubyStringForCode(name));
						case _:
							Context.error('@:railsMigration unknown CheckConstraint option ${field.name}.', field.expr.pos);
					}
				}
				if (!hasName) {
					Context.error("@:railsMigration CheckConstraint options must include a literal name.", expr.pos);
				}
				options;
			case _:
				Context.error("@:railsMigration CheckConstraint options must be an object literal.", expr.pos);
				[];
		}
	}

	static function railsMigrationForeignKeyDslOptions(expr:TypedExpr, validation:Null<RailsMigrationValidationContext>, fromTable:String):Array<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TObjectDecl(fields):
				var options:Array<String> = [];
				for (field in fields) {
					switch (field.name) {
						case "column":
							var column = railsMigrationSymbolArg(field.expr, "ForeignKey column");
							railsMigrationValidateColumn(validation, fromTable, column, "ForeignKey column", field.expr);
							options.push("column: :" + column);
						case "name":
							options.push("name: " + quoteRubyStringForCode(railsMigrationSafeIdentifier(field.expr, "ForeignKey name")));
						case "primaryKey":
							options.push("primary_key: :" + railsMigrationSymbolArg(field.expr, "ForeignKey primaryKey"));
						case "onDelete":
							options.push("on_delete: :" + railsMigrationForeignKeyAction(field.expr, "ForeignKey onDelete"));
						case "onUpdate":
							options.push("on_update: :" + railsMigrationForeignKeyAction(field.expr, "ForeignKey onUpdate"));
						case _:
							Context.error('@:railsMigration unknown ForeignKey option ${field.name}.', field.expr.pos);
					}
				}
				options;
			case _:
				Context.error("@:railsMigration AddForeignKey options must be an object literal.", expr.pos);
				[];
		}
	}

	static function railsMigrationForeignKeyAction(expr:TypedExpr, label:String):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall({expr: TField(_, FEnum(_, field))}, args) if (args.length == 0):
				railsMigrationForeignKeyActionName(field.name, label, expr);
			case TField(_, FEnum(_, field)):
				railsMigrationForeignKeyActionName(field.name, label, expr);
			case _:
				Context.error('@:railsMigration ${label} must be a ForeignKeyAction enum value.', expr.pos);
				"restrict";
		}
	}

	static function railsMigrationForeignKeyActionName(name:String, label:String, expr:TypedExpr):String {
		return switch (name) {
			case "Cascade": "cascade";
			case "Nullify": "nullify";
			case "Restrict": "restrict";
			case _:
				Context.error('@:railsMigration unsupported ${label} action ${name}.', expr.pos);
				"restrict";
		}
	}

	static function railsMigrationSymbolArg(expr:TypedExpr, label:String):String {
		var value = typedStringLiteral(expr);
		if (value == null || value == "") {
			Context.error('@:railsMigration ${label} must be a non-empty String literal.', expr.pos);
			return "invalid";
		}
		return RubyNaming.toMethodName(value);
	}

	// Rails index names become generated Ruby identifiers, so keep the Haxe
	// authoring surface literal-only and path-safe before emitting migration code.
	static function railsMigrationSafeIdentifier(expr:TypedExpr, label:String):String {
		var value = typedStringLiteral(expr);
		if (value == null || value == "" || value.indexOf("/") != -1 || value.indexOf("\\") != -1 || value.indexOf(".") != -1
			|| !~/^[a-z][a-z0-9_]*$/.match(value)) {
			Context.error('@:railsMigration ${label} must be a safe Rails identifier such as "index_todos_on_title".', expr.pos);
			return "invalid";
		}
		return value;
	}

	static function railsMigrationSymbolArrayArg(expr:TypedExpr, label:String):Array<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TArrayDecl(values):
				var out:Array<String> = [];
				for (value in values) {
					out.push(railsMigrationSymbolArg(value, label));
				}
				if (out.length == 0) {
					Context.error('@:railsMigration ${label} must not be empty.', expr.pos);
				}
				out;
			case _:
				Context.error('@:railsMigration ${label} must be an Array<String> literal.', expr.pos);
				[];
		}
	}

	static function typedMigrationLiteralCode(expr:TypedExpr):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)): quoteRubyStringForCode(value);
			case TConst(TInt(value)): Std.string(value);
			case TConst(TFloat(value)): value;
			case TConst(TBool(value)): value ? "true" : "false";
			case _:
				Context.error("@:railsMigration literal option value must be a String, Int, Float, or Bool literal.", expr.pos);
				"nil";
		}
	}

	static function typedStringLiteral(expr:TypedExpr):Null<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)): value;
			case _: null;
		}
	}

	static function typedBoolLiteral(expr:TypedExpr, label:String):Bool {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TBool(value)): value;
			case _:
				Context.error('@:railsMigration ${label} must be a Bool literal.', expr.pos);
				false;
		}
	}

	static function typedIntLiteral(expr:TypedExpr, label:String):Int {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TInt(value)): value;
			case _:
				Context.error('@:railsMigration ${label} must be an Int literal.', expr.pos);
				0;
		}
	}

	static function typedPositiveIntLiteral(expr:TypedExpr, label:String):Int {
		var value = typedIntLiteral(expr, label);
		if (value <= 0) {
			Context.error('@:railsMigration ${label} must be a positive Int literal.', expr.pos);
			return 1;
		}
		return value;
	}

	static function typedNonNegativeIntLiteral(expr:TypedExpr, label:String):Int {
		var value = typedIntLiteral(expr, label);
		if (value < 0) {
			Context.error('@:railsMigration ${label} must be a non-negative Int literal.', expr.pos);
			return 0;
		}
		return value;
	}

	static function unwrapTypedExpr(expr:TypedExpr):TypedExpr {
		return switch (expr.expr) {
			case TCast(inner, _) | TParenthesis(inner) | TMeta(_, inner): unwrapTypedExpr(inner);
			case _: expr;
		}
	}

	static function railsMigrationColumnOptions(info:RailsColumnInfo):Array<String> {
		var options:Array<String> = [];
		if (!info.nullable) {
			options.push("null: false");
		}
		if (info.defaultValue != null) {
			options.push("default: " + info.defaultValue);
		}
		return options;
	}

	static function railsMigrationOptionSuffix(options:Array<String>):String {
		return options.length == 0 ? "" : ", " + options.join(", ");
	}

	static function railsMigrationIndexes(model:ClassType, belongsTo:Map<String, RailsBelongsToInfo>):Array<String> {
		var lines:Array<String> = [];
		for (field in model.fields.get()) {
			if (!hasMeta(field.meta, ":railsColumn")) {
				continue;
			}
			var info = railsColumnInfoFromField(field);
			if (info.primaryKey || !info.index || belongsTo.exists(info.rubyName)) {
				continue;
			}
			lines.push("t.index :" + info.rubyName + (info.unique ? ", unique: true" : ""));
		}
		return lines;
	}

	static function railsBelongsToInfo(model:ClassType):Map<String, RailsBelongsToInfo> {
		var out:Map<String, RailsBelongsToInfo> = [];
		for (field in model.fields.get()) {
			if (!hasMeta(field.meta, ":belongsTo")) {
				continue;
			}
			var rubyName = RubyNaming.toMethodName(field.name);
			out.set(RubyNaming.toMethodName(field.name + "Id"), {
				rubyName: rubyName,
				columnName: RubyNaming.toMethodName(field.name + "Id"),
				referencedTable: railsBelongsToReferencedTable(field.type, rubyName + "s")
			});
		}
		return out;
	}

	static function railsBelongsToReferencedTable(type:haxe.macro.Type, fallback:String):String {
		return switch (type) {
			case TInst(ref, [TInst(modelRef, _)]):
				railsModelTableName(modelRef.get());
			case TType(_, [inner]) | TAbstract(_, [inner]):
				railsBelongsToReferencedTable(inner, fallback);
			case TLazy(lazy):
				railsBelongsToReferencedTable(lazy(), fallback);
			case _:
				fallback;
		}
	}

	static function metadataStringLiteral(expr:haxe.macro.Expr):Null<String> {
		return switch (expr.expr) {
			case EConst(CString(value, _)) if (value.length > 0): value;
			case _: null;
		}
	}

	static function metadataStringArray(expr:haxe.macro.Expr, label:String):Array<String> {
		return switch (expr.expr) {
			case EArrayDecl(values):
				var out:Array<String> = [];
				for (value in values) {
					var parsed = metadataStringLiteral(value);
					if (parsed == null) {
						Context.error('@:railsMigration $label must be an array of string literals.', value.pos);
					} else {
						out.push(parsed);
					}
				}
				out;
			case _:
				Context.error('@:railsMigration $label must be an array of string literals.', expr.pos);
				[];
		}
	}

	function emitRailsTemplateArtifact(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>):Void {
		if (!buildContext.railsMode) {
			Context.error("@:railsTemplate requires -D reflaxe_ruby_rails.", classType.pos);
			return;
		}
		var templatePath = metaStringParam(classType.meta, ":railsTemplate", 0);
		if (templatePath == null) {
			Context.error("@:railsTemplate expects a Rails template path string.", classType.pos);
			return;
		}
		validateRailsTemplatePath(templatePath, classType.pos, "@:railsTemplate");
		var usesTypedTemplateAst = metaStringParam(classType.meta, ":railsTemplateAst", 0) != null;
		var body = railsTemplateSourceBody(classType, varFields, funcFields);
		if (body == null) {
			Context.error("@:railsTemplate expects a source path argument, @:railsTemplateAst method, or static string field named body/erb/template.",
				classType.pos);
			return;
		}
		if (!usesTypedTemplateAst && containsRawErb(body) && !hasMeta(classType.meta, ":railsAllowRawErb")) {
			Context.error("@:railsTemplate raw ERB blocks require @:railsAllowRawErb. Prefer typed RailsHx template helpers when available.", classType.pos);
			return;
		}
		setExtraFile(OutputPath.fromStr(railsTemplateOutputPath(templatePath)), normalizeGeneratedText(body));
	}

	function emitRailsRoutesArtifact(classType:ClassType, varFields:Array<ClassVarData>):Void {
		if (!buildContext.railsMode) {
			Context.error("@:railsRoutes requires -D reflaxe_ruby_rails.", classType.pos);
			return;
		}
		var outputPath = "config/routes.rb";
		if (emittedRailsRoutePaths.exists(outputPath)) {
			Context.error('@:railsRoutes emits duplicate route file ${outputPath}; first emitted by ${emittedRailsRoutePaths.get(outputPath)}.', classType.pos);
			return;
		}
		emittedRailsRoutePaths.set(outputPath, fullTypeName(classType.pack, classType.name));

		var routes = railsRoutesField(classType, varFields);
		if (routes == null) {
			return;
		}
		var decls = railsRouteDecls(routes);
		RailsRoutesExtractor.validateAliases(decls);
		var body = RailsRoutesEmitter.renderBody(decls);
		if (body.length == 0) {
			Context.error("@:railsRoutes routes block must declare at least one route.", routes.field.pos);
			return;
		}
		var lines = [
			"# Generated by RailsHx from @:railsRoutes.",
			"# Source: " + fullTypeName(classType.pack, classType.name),
			"# Do not edit directly unless you intend to take RailsHx ownership.",
			"",
			"Rails.application.routes.draw do"
		];
		for (line in body) {
			lines.push("  " + line);
		}
		lines.push("end");
		var routeContent = normalizeGeneratedText(lines.join("\n"));
		var manifestPath = ".railshx/routes.haxe.json";
		var routeManifest = RailsRouteManifest.render(fullTypeName(classType.pack, classType.name), outputPath, fullTypeName(classType.pack, classType.name),
			decls);
		setRailsExtraFile(outputPath, routeContent, classType.pos);
		setRailsExtraFile(manifestPath, routeManifest, classType.pos);
		recordRailsCompilerManifestEntries([
			{
				output: outputPath,
				kind: "rails_config",
				source: "@:railsRoutes " + fullTypeName(classType.pack, classType.name),
				content: routeContent
			},
			{
				output: manifestPath,
				kind: "route_manifest",
				source: "@:railsRoutes " + fullTypeName(classType.pack, classType.name),
				content: routeManifest
			}
		], classType.pos);
	}

	static function railsRoutesField(classType:ClassType, varFields:Array<ClassVarData>):Null<ClassVarData> {
		var found:Null<ClassVarData> = null;
		for (field in varFields) {
			if (field.field.name == "routes") {
				found = field;
			}
		}
		if (found == null) {
			Context.error("@:railsRoutes classes must declare `static final routes = { ... };`.", classType.pos);
			return null;
		}
		if (!found.isStatic) {
			Context.error("@:railsRoutes routes field must be static: `static final routes = { ... };`.", found.field.pos);
			return null;
		}
		if (found.field.expr() == null) {
			Context.error("@:railsRoutes routes field must have a block initializer.", found.field.pos);
			return null;
		}
		return found;
	}

	static function railsRouteDecls(field:ClassVarData):Array<RailsRouteDecl> {
		var expr = field.field.expr();
		if (expr == null) {
			return [];
		}
		var entries = switch (unwrapTypedExpr(expr).expr) {
			case TBlock(values): values;
			case TArrayDecl(values): values;
			// Haxe may type a one-expression `{ root(...); }` initializer as the
			// call itself instead of a TBlock. Accept that optimized AST shape so
			// minimal route files stay ergonomic without changing the DSL contract.
			case TCall(_, _): [expr];
			case _:
				Context.error("@:railsRoutes routes must be a Haxe block: `static final routes = { root(...); resources(...); };`.", expr.pos);
				[];
		}
		var decls:Array<RailsRouteDecl> = [];
		for (entry in entries) {
			decls.push(railsRouteDecl(entry));
		}
		RailsRoutesExtractor.validateTopLevel(decls);
		return decls;
	}

	static function railsRouteDecl(expr:TypedExpr):RailsRouteDecl {
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall(callee, params):
				var info = staticCallInfo(callee);
				if (info != null && info.owner == "rails.routing.RouteDecl") {
					switch (info.name) {
						case "root" if (params.length == 1):
							{
								kind: "root",
								target: railsRouteTarget(params[0]),
								devise: null,
								verb: "",
								verbs: [],
								path: "",
								name: "",
								controller: "",
								moduleName: "",
								only: [],
								except: [],
								param: "",
								options: [],
								children: [],
								pos: expr.pos
							};
						case "verb" if (params.length == 4):
							{
								kind: "verb",
								target: railsRouteTarget(params[2]),
								devise: null,
								verb: railsRouteString(params[0], "route verb"),
								verbs: [],
								path: railsRouteString(params[1], "route path"),
								name: railsRouteStringAllowEmpty(params[3], "route name"),
								controller: "",
								moduleName: "",
								only: [],
								except: [],
								param: "",
								options: [],
								children: [],
								pos: expr.pos
							};
						case "match" if (params.length == 4):
							{
								kind: "match",
								target: railsRouteTarget(params[1]),
								devise: null,
								verb: "",
								verbs: railsRouteStringArray(params[2], "match verbs"),
								path: railsRouteString(params[0], "match path"),
								name: railsRouteStringAllowEmpty(params[3], "match name"),
								controller: "",
								moduleName: "",
								only: [],
								except: [],
								param: "",
								options: [],
								children: [],
								pos: expr.pos
							};
						case "resources" if (params.length == 6):
							{
								kind: "resources",
								target: null,
								devise: null,
								verb: "",
								verbs: [],
								path: "",
								name: railsRouteString(params[0], "resources name"),
								controller: railsRouteString(params[1], "resources controller"),
								moduleName: "",
								only: railsRouteStringArray(params[2], "resources only"),
								except: railsRouteStringArray(params[3], "resources except"),
								param: railsRouteStringAllowEmpty(params[4], "resources param"),
								options: [],
								children: railsRouteChildren(params[5], "resources children"),
								pos: expr.pos
							};
						case "resource" if (params.length == 6):
							{
								kind: "resource",
								target: null,
								devise: null,
								verb: "",
								verbs: [],
								path: "",
								name: railsRouteString(params[0], "resource name"),
								controller: railsRouteString(params[1], "resource controller"),
								moduleName: "",
								only: railsRouteStringArray(params[2], "resource only"),
								except: railsRouteStringArray(params[3], "resource except"),
								param: railsRouteStringAllowEmpty(params[4], "resource param"),
								options: [],
								children: railsRouteChildren(params[5], "resource children"),
								pos: expr.pos
							};
						case "collection" if (params.length == 1):
							{
								kind: "collection",
								target: null,
								devise: null,
								verb: "",
								verbs: [],
								path: "",
								name: "",
								controller: "",
								moduleName: "",
								only: [],
								except: [],
								param: "",
								options: [],
								children: railsRouteChildren(params[0], "collection children"),
								pos: expr.pos
							};
						case "member" if (params.length == 1):
							{
								kind: "member",
								target: null,
								devise: null,
								verb: "",
								verbs: [],
								path: "",
								name: "",
								controller: "",
								moduleName: "",
								only: [],
								except: [],
								param: "",
								options: [],
								children: railsRouteChildren(params[0], "member children"),
								pos: expr.pos
							};
						case "namespace" if (params.length == 2):
							{
								kind: "namespace",
								target: null,
								devise: null,
								verb: "",
								verbs: [],
								path: "",
								name: railsRouteString(params[0], "namespace name"),
								controller: "",
								moduleName: "",
								only: [],
								except: [],
								param: "",
								options: [],
								children: railsRouteChildren(params[1], "namespace children"),
								pos: expr.pos
							};
						case "scope" if (params.length == 4):
							{
								kind: "scope",
								target: null,
								devise: null,
								verb: "",
								verbs: [],
								path: railsRouteString(params[0], "scope path"),
								name: railsRouteStringAllowEmpty(params[2], "scope name"),
								controller: "",
								moduleName: railsRouteStringAllowEmpty(params[1], "scope moduleName"),
								only: [],
								except: [],
								param: "",
								options: [],
								children: railsRouteChildren(params[3], "scope children"),
								pos: expr.pos
							};
						case "controller" if (params.length == 2):
							{
								kind: "controller",
								target: null,
								devise: null,
								verb: "",
								verbs: [],
								path: "",
								name: "",
								controller: railsRouteString(params[0], "controller name"),
								moduleName: "",
								only: [],
								except: [],
								param: "",
								options: [],
								children: railsRouteChildren(params[1], "controller children"),
								pos: expr.pos
							};
						case "defaults" if (params.length == 2):
							{
								kind: "defaults",
								target: null,
								devise: null,
								verb: "",
								verbs: [],
								path: "",
								name: "",
								controller: "",
								moduleName: "",
								only: [],
								except: [],
								param: "",
								options: railsRouteStringArray(params[0], "defaults options"),
								children: railsRouteChildren(params[1], "defaults children"),
								pos: expr.pos
							};
						case "constraints" if (params.length == 2):
							{
								kind: "constraints",
								target: null,
								devise: null,
								verb: "",
								verbs: [],
								path: "",
								name: "",
								controller: "",
								moduleName: "",
								only: [],
								except: [],
								param: "",
								options: railsRouteStringArray(params[0], "constraints options"),
								children: railsRouteChildren(params[1], "constraints children"),
								pos: expr.pos
							};
						case "mount" if (params.length == 3):
							{
								kind: "mount",
								target: null,
								devise: null,
								verb: "",
								verbs: [],
								path: railsRouteString(params[1], "mount path"),
								name: railsRouteStringAllowEmpty(params[2], "mount name"),
								controller: railsRouteString(params[0], "mount app"),
								moduleName: "",
								only: [],
								except: [],
								param: "",
								options: [],
								children: [],
								pos: expr.pos
							};
						case "deviseFor" if (params.length == 8):
							{
								kind: "deviseFor",
								target: null,
								devise: {
									resource: railsRouteString(params[0], "Devise resource"),
									mappingScope: railsRouteString(params[1], "Devise mapping scope"),
									rubyClass: railsRouteString(params[2], "Devise Ruby class"),
									contractType: railsRouteString(params[3], "Devise contract type"),
									contractField: railsRouteString(params[4], "Devise contract field"),
									contractSchema: railsRouteInt(params[5], "Devise contract schema"),
									only: railsRouteStringArray(params[6], "Devise only route groups"),
									skip: railsRouteStringArray(params[7], "Devise skip route groups")
								},
								verb: "",
								verbs: [],
								path: "",
								name: "",
								controller: "",
								moduleName: "",
								only: [],
								except: [],
								param: "",
								options: [],
								children: [],
								pos: expr.pos
							};
						case "rawRuby" if (params.length == 1):
							{
								kind: "rawRuby",
								target: null,
								devise: null,
								verb: "",
								verbs: [],
								path: "",
								name: "",
								controller: railsRouteString(params[0], "raw Ruby route line"),
								moduleName: "",
								only: [],
								except: [],
								param: "",
								options: [],
								children: [],
								pos: expr.pos
							};
						case other:
							Context.error('@:railsRoutes unsupported RouteDecl.${other} declaration in this implementation slice.', expr.pos);
							invalidRailsRouteDecl(expr.pos);
					}
				} else {
					Context.error("@:railsRoutes entries must be produced by rails.macros.RoutesDsl declarations.", expr.pos);
					invalidRailsRouteDecl(expr.pos);
				}
			case _:
				Context.error("@:railsRoutes entries must be route declaration calls.", expr.pos);
				invalidRailsRouteDecl(expr.pos);
		}
	}

	static function invalidRailsRouteDecl(pos:Position):RailsRouteDecl {
		return {
			kind: "",
			target: null,
			devise: null,
			verb: "",
			verbs: [],
			path: "",
			name: "",
			controller: "",
			moduleName: "",
			only: [],
			except: [],
			param: "",
			options: [],
			children: [],
			pos: pos
		};
	}

	static function railsRouteTarget(expr:TypedExpr):RailsRouteTarget {
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall(callee, params):
				var info = staticCallInfo(callee);
				if (info != null && info.owner == "rails.routing.RouteTarget" && info.name == "to" && params.length == 2) {
					{
						controller: railsRouteString(params[0], "route target controller"),
						action: railsRouteString(params[1], "route target action")
					};
				} else {
					Context.error("@:railsRoutes target must be produced by to(Controller, action).", expr.pos);
					{controller: "", action: ""};
				}
			case _:
				Context.error("@:railsRoutes target must be produced by to(Controller, action).", expr.pos);
				{controller: "", action: ""};
		}
	}

	static function railsRouteChildren(expr:TypedExpr, label:String):Array<RailsRouteDecl> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TArrayDecl(values):
				[for (value in values) railsRouteDecl(value)];
			case _:
				Context.error('@:railsRoutes $label must be an Array<RouteDecl> marker value.', expr.pos);
				[];
		}
	}

	static function railsRouteString(expr:TypedExpr, label:String):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)) if (value.length > 0):
				value;
			case _:
				Context.error('@:railsRoutes $label must be a non-empty String literal marker value.', expr.pos);
				"";
		}
	}

	static function railsRouteStringAllowEmpty(expr:TypedExpr, label:String):String {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)):
				value;
			case _:
				Context.error('@:railsRoutes $label must be a String literal marker value.', expr.pos);
				"";
		}
	}

	static function railsRouteInt(expr:TypedExpr, label:String):Int {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TInt(value)):
				value;
			case _:
				Context.error('@:railsRoutes $label must be an Int literal marker value.', expr.pos);
				0;
		}
	}

	static function railsRouteStringArray(expr:TypedExpr, label:String):Array<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TArrayDecl(values):
				[for (value in values) railsRouteString(value, label)];
			case _:
				Context.error('@:railsRoutes $label must be an Array<String> literal marker value.', expr.pos);
				[];
		}
	}

	function emitRailsTestArtifact(classType:ClassType, funcFields:Array<ClassFuncData>):Void {
		if (!buildContext.railsMode) {
			Context.error("@:railsTest requires -D reflaxe_ruby_rails.", classType.pos);
			return;
		}
		var testPath = metaStringParam(classType.meta, ":railsTest", 0);
		if (testPath == null) {
			Context.error("@:railsTest expects a Rails test path string such as \"models/todo_haxe_test\".", classType.pos);
			return;
		}
		validateRailsTestPath(testPath, classType.pos, "@:railsTest");
		var outputPath = railsTestOutputPath(testPath);
		if (emittedRailsTestPaths.exists(outputPath)) {
			Context.error('@:railsTest emits duplicate test file ${outputPath}; first emitted by ${emittedRailsTestPaths.get(outputPath)}.', classType.pos);
			return;
		}
		emittedRailsTestPaths.set(outputPath, fullTypeName(classType.pack, classType.name));

		var body:Array<String> = [];
		var testDescriptions = new Map<String, Position>();
		var defineFields = [for (field in funcFields) if (hasMeta(field.field.meta, ":railsTests")) field];
		if (defineFields.length > 1) {
			Context.error("@:railsTest classes may define at most one @:railsTests declaration function.", defineFields[1].field.pos);
			return;
		}
		if (defineFields.length == 1) {
			for (decl in railsTestDeclsFromDefine(defineFields[0])) {
				if (decl.kind == "test") {
					validateRailsTestDescription(decl.description, decl.pos, testDescriptions);
				}
				body = body.concat(renderStatements([compileRailsTestDecl(decl)]));
			}
		}
		for (field in funcFields) {
			if (field.expr == null
				|| field.isStatic
				|| hasMeta(field.field.meta, ":rubyExternStub")
				|| hasMeta(field.field.meta, ":railsTests")) {
				continue;
			}
			if (!hasMeta(field.field.meta, ":test")) {
				continue;
			}
			validateRailsTestMethod(field);
			validateRailsTestDescription(railsTestDescription(field), field.field.pos, testDescriptions);
			body = body.concat(renderStatements([compileRailsTestMethod(field)]));
		}
		if (body.length == 0) {
			Context.error("@:railsTest classes must define at least one @:railsTests declaration function or @:test method.", classType.pos);
			return;
		}

		var renderedBody = body.join("\n");
		var lines = ["# Generated by RailsHx from @:railsTest.",
			"require \"test_helper\"",
			"",
			"class "
			+ RubyNaming.toConstantName(classType.name)
			+ " < "
			+ railsTestSuperclass(classType)];
		if (railsTestUsesDeviseIntegrationHelpers(renderedBody)) {
			lines.push("  include Devise::Test::IntegrationHelpers");
		}
		for (line in body) {
			lines.push("  " + line);
		}
		lines.push("end");
		setRailsExtraFile(outputPath, normalizeGeneratedText(lines.join("\n")), classType.pos);
	}

	function emitRailsMailerPreviewArtifact(classType:ClassType, funcFields:Array<ClassFuncData>):Void {
		if (!buildContext.railsMode) {
			Context.error("@:railsMailerPreview requires -D reflaxe_ruby_rails.", classType.pos);
			return;
		}
		var previewPath = metaStringParam(classType.meta, ":railsMailerPreview", 0);
		if (previewPath == null) {
			previewPath = RubyNaming.fileName(classType.name);
		}
		validateRailsMailerPreviewPath(previewPath, classType.pos, "@:railsMailerPreview");
		var outputPath = railsMailerPreviewOutputPath(previewPath);
		if (emittedRailsMailerPreviewPaths.exists(outputPath)) {
			Context.error('@:railsMailerPreview emits duplicate preview file ${outputPath}; first emitted by ${emittedRailsMailerPreviewPaths.get(outputPath)}.',
				classType.pos);
			return;
		}
		emittedRailsMailerPreviewPaths.set(outputPath, fullTypeName(classType.pack, classType.name));

		var body:Array<String> = [];
		for (field in funcFields) {
			if (field.expr == null || hasMeta(field.field.meta, ":rubyExternStub")) {
				continue;
			}
			validateRailsMailerPreviewMethod(field);
			body = body.concat(renderStatements([compileMethodAs(field, false)]));
		}
		if (body.length == 0) {
			Context.error("@:railsMailerPreview classes must define at least one instance preview method.", classType.pos);
			return;
		}

		var lines = [
			"# Generated by RailsHx from @:railsMailerPreview.",
			"# Rails preview output; Rails discovers this under test/mailers/previews.",
			"require \"action_mailer/railtie\"",
			"",
			"class " + RubyNaming.toConstantName(classType.name) + " < ActionMailer::Preview"
		];
		for (line in body) {
			lines.push("  " + line);
		}
		lines.push("end");
		setRailsExtraFile(outputPath, normalizeGeneratedText(lines.join("\n")), classType.pos);
	}

	static function validateRailsMailerPreviewMethod(field:ClassFuncData):Void {
		if (field.isStatic) {
			Context.error("@:railsMailerPreview methods must be instance methods so Rails can expose them as previews.", field.field.pos);
		}
		if (field.args.length > 0) {
			Context.error("@:railsMailerPreview methods must not declare parameters; build preview inputs inside the method body.", field.field.pos);
		}
	}

	static function railsTestSuperclass(classType:ClassType):String {
		return classExtends(classType, "rails.test.RequestTestCase") ? "ActionDispatch::IntegrationTest" : "ActiveSupport::TestCase";
	}

	static function classExtends(classType:ClassType, expectedFullName:String):Bool {
		var cursor = classType.superClass;
		while (cursor != null) {
			var superClass = cursor.t.get();
			if (fullTypeName(superClass.pack, superClass.name) == expectedFullName) {
				return true;
			}
			cursor = superClass.superClass;
		}
		return false;
	}

	static function railsTestUsesDeviseIntegrationHelpers(renderedBody:String):Bool {
		return renderedBody.indexOf("sign_in(") != -1 || renderedBody.indexOf("sign_out(") != -1;
	}

	function setRailsExtraFile(outputPath:String, content:String, pos:Position):Void {
		validateRailsExtraFileWrite(outputPath, pos);
		setExtraFile(OutputPath.fromStr(outputPath), content);
	}

	function validateRailsExtraFileWrite(outputPath:String, pos:Position):Void {
		var outputRoot = Context.definedValue(buildContext.outputDirDefineName);
		if (outputRoot == null || outputRoot == "") {
			return;
		}
		var fullPath = Path.normalize(Path.join([outputRoot, outputPath]));
		if (!FileSystem.exists(fullPath) || railsGeneratedFile(fullPath) || railsHxManifestOwns(outputRoot, outputPath)) {
			return;
		}
		Context.error('RailsHx refuses to overwrite non-owned Rails artifact ${outputPath}. Delete the file, add a RailsHx generated header, or use an explicit generator force/repair path if taking ownership is intended.',
			pos);
	}

	static function railsGeneratedFile(path:String):Bool {
		try {
			var content = File.getContent(path);
			return StringTools.startsWith(content, "# Generated by RailsHx")
				|| StringTools.startsWith(content, "# Generated by reflaxe.ruby");
		} catch (_:Dynamic) {
			return false;
		}
	}

	static function railsHxManifestOwns(outputRoot:String, outputPath:String):Bool {
		var manifestPath = Path.normalize(Path.join([outputRoot, ".railshx", "manifest.json"]));
		if (!FileSystem.exists(manifestPath)) {
			return false;
		}
		try {
			var manifest = File.getContent(manifestPath);
			return manifest.indexOf('"output": ' + haxe.Json.stringify(outputPath)) != -1;
		} catch (_:Dynamic) {
			return false;
		}
	}

	function recordRailsCompilerManifestEntries(entries:Array<RailsManifestEntry>, pos:Position):Void {
		var outputRoot = Context.definedValue(buildContext.outputDirDefineName);
		if (outputRoot == null || outputRoot == "") {
			return;
		}
		var manifestPath = Path.normalize(Path.join([outputRoot, ".railshx", "manifest.json"]));
		var outputs:Array<Dynamic> = [];
		if (FileSystem.exists(manifestPath)) {
			try {
				var parsed:Dynamic = haxe.Json.parse(File.getContent(manifestPath));
				var parsedOutputs:Dynamic = Reflect.field(parsed, "outputs");
				if (Std.isOfType(parsedOutputs, Array)) {
					outputs = cast parsedOutputs;
				}
			} catch (e:Dynamic) {
				Context.error('Invalid RailsHx manifest ${manifestPath}: ${Std.string(e)}', pos);
				return;
			}
		}
		var replacing = new Map<String, Bool>();
		for (entry in entries) {
			replacing.set(entry.output, true);
		}
		outputs = [
			for (existing in outputs)
				if (!replacing.exists(Std.string(Reflect.field(existing, "output")))) existing
		];
		for (entry in entries) {
			var item:Dynamic = {};
			Reflect.setField(item, "output", entry.output);
			Reflect.setField(item, "kind", entry.kind);
			Reflect.setField(item, "source", entry.source);
			Reflect.setField(item, "sha256", haxe.crypto.Sha256.encode(entry.content));
			outputs.push(item);
		}
		outputs.sort((a, b) -> Reflect.compare(Std.string(Reflect.field(a, "output")), Std.string(Reflect.field(b, "output"))));
		var manifest:Dynamic = {};
		Reflect.setField(manifest, "version", 1);
		Reflect.setField(manifest, "outputs", outputs);
		setExtraFile(OutputPath.fromStr(".railshx/manifest.json"), haxe.Json.stringify(manifest, null, "  ") + "\n");
	}

	static function validateRailsTestMethod(field:ClassFuncData):Void {
		if (field.isStatic) {
			Context.error("@:test methods inside @:railsTest must be instance methods. Use @:railsTests static function define():Void for the canonical DSL.",
				field.field.pos);
		}
		if (field.args.length > 0) {
			Context.error("@:test methods inside @:railsTest must not declare parameters.", field.field.pos);
		}
	}

	static function railsTestDeclsFromDefine(field:ClassFuncData):Array<RailsTestDecl> {
		if (field.field.name != "define") {
			Context.error("@:railsTests must annotate `static function define():Void`. Use the canonical `define` host so RailsHx test declarations are easy to recognize.",
				field.field.pos);
			return [];
		}
		if (!field.isStatic) {
			Context.error("@:railsTests must annotate a static declaration function.", field.field.pos);
			return [];
		}
		if (field.args.length > 0) {
			Context.error("@:railsTests declaration functions must not declare parameters.", field.field.pos);
			return [];
		}
		if (field.expr == null) {
			Context.error("@:railsTests declaration functions must have a body.", field.field.pos);
			return [];
		}
		var entries = switch (unwrapTypedExpr(field.expr).expr) {
			case TBlock(exprs): exprs;
			case _: [field.expr];
		}
		var out:Array<RailsTestDecl> = [];
		for (entry in entries) {
			var decl = railsTestDeclFromExpr(entry);
			if (decl == null) {
				Context.error("@:railsTests functions may only contain top-level rails.test.Dsl.test/setup/teardown declarations. Move shared code into helpers or test bodies.",
					entry.pos);
			} else {
				out.push(decl);
			}
		}
		return out;
	}

	static function railsTestDeclFromExpr(expr:TypedExpr):Null<RailsTestDecl> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TCall(callee, params):
				var info = staticCallInfo(callee);
				if (info == null || info.owner != "rails.test.Dsl") {
					null;
				} else switch (info.name) {
					case "test" if (params.length == 2):
						var body = railsTestBodyParam(params[1], "test");
						body == null ? null : {
							kind: "test",
							description: railsTestDescriptionParam(params[0], "test"),
							body: body,
							pos: expr.pos
						};
					case "setup" | "teardown" if (params.length == 1):
						var body = railsTestBodyParam(params[0], info.name);
						body == null ? null : {
							kind: info.name,
							description: null,
							body: body,
							pos: expr.pos
						};
					case _:
						Context.error('rails.test.Dsl.${info.name} has an invalid argument shape for @:railsTests.', expr.pos);
						null;
				}
			case _:
				null;
		}
	}

	static function railsTestDescriptionParam(expr:TypedExpr, name:String):Null<String> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TConst(TString(value)): value;
			case _:
				Context.error('rails.test.Dsl.$name description must be a literal string so RailsHx can generate deterministic Rails tests.', expr.pos);
				null;
		}
	}

	static function railsTestBodyParam(expr:TypedExpr, name:String):Null<TypedExpr> {
		return switch (unwrapTypedExpr(expr).expr) {
			case TFunction(fn):
				if (fn.args.length != 0) {
					Context.error('rails.test.Dsl.$name body must be a zero-argument lambda.', expr.pos);
					null;
				} else {
					fn.expr;
				}
			case _:
				Context.error('rails.test.Dsl.$name body must be an inline zero-argument lambda, for example () -> { ... }.', expr.pos);
				null;
		}
	}

	static function validateRailsTestDescription(description:Null<String>, pos:Position, seen:Map<String, Position>):Void {
		if (description == null) {
			return;
		}
		if (description.length == 0 || StringTools.trim(description) != description) {
			Context.error("RailsHx test descriptions must be non-empty strings without leading or trailing whitespace.", pos);
			return;
		}
		if (description.indexOf("\n") != -1 || description.indexOf("\r") != -1 || description.indexOf("\t") != -1) {
			Context.error("RailsHx test descriptions must stay on one line.", pos);
			return;
		}
		if (seen.exists(description)) {
			Context.error('Duplicate RailsHx test description "$description" in the same @:railsTest class.', pos);
			return;
		}
		seen.set(description, pos);
	}

	static function compileRailsTestDecl(decl:RailsTestDecl):RubyStatement {
		return withLocalNameScope([], () -> {
			return RubyRawStatement(renderRailsTestBlock(decl.kind, decl.description, decl.body));
		});
	}

	static function renderRailsTestBlock(kind:String, description:Null<String>, bodyExpr:TypedExpr):String {
		var body = renderStatements(compileRubyBlockBody(bodyExpr));
		var lines = switch (kind) {
			case "test":
				[
					"test " + quoteRubyStringForCode(description == null ? "unnamed test" : description) + " do"
				];
			case "setup" | "teardown":
				[kind + " do"];
			case _:
				[kind + " do"];
		}
		appendIndentedLines(lines, body, 1);
		lines.push("end");
		return lines.join("\n");
	}

	function railsTemplateSourceBody(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>):Null<String> {
		var source = metaStringParam(classType.meta, ":railsTemplate", 1);
		if (source != null) {
			var path = Path.normalize(Path.join([Path.directory(Context.getPosInfos(classType.pos).file), source]));
			if (!FileSystem.exists(path)) {
				Context.error("@:railsTemplate source file not found: " + path, classType.pos);
				return null;
			}
			return File.getContent(path);
		}
		var astMethod = metaStringParam(classType.meta, ":railsTemplateAst", 0);
		if (astMethod != null) {
			return railsTemplateAstBody(classType, funcFields, astMethod);
		}
		for (field in varFields) {
			if (!field.isStatic || ["body", "erb", "template"].indexOf(field.field.name) == -1) {
				continue;
			}
			var expr = field.getDefaultUntypedExpr();
			if (expr == null) {
				continue;
			}
			return switch (expr.expr) {
				case EConst(CString(value, _)): value;
				case _:
					Context.error("@:railsTemplate static body/erb/template field must be a string literal.", expr.pos);
					null;
			}
		}
		return null;
	}

	function railsTemplateAstBody(classType:ClassType, funcFields:Array<ClassFuncData>, methodName:String):Null<String> {
		for (field in funcFields) {
			if (!field.isStatic || field.field.name != methodName) {
				continue;
			}
			if (field.expr == null) {
				Context.error("@:railsTemplateAst method must have a body.", field.field.pos);
				return null;
			}
			var scope = templateScopeFor(field);
			var node = extractTemplateAstReturn(field.expr);
			if (node == null) {
				Context.error("@:railsTemplateAst method must return a rails.action_view.HtmlNode expression.", field.field.pos);
				return null;
			}
			return lowerTemplateNode(node, scope);
		}
		Context.error('@:railsTemplateAst could not find static method "$methodName".', classType.pos);
		return null;
	}

	static function templateScopeFor(field:ClassFuncData):RailsTemplateScope {
		var localNames:Map<Int, String> = [];
		var localObjectNames:Map<Int, String> = [];
		for (arg in field.args) {
			if (arg.tvar != null) {
				var argName = arg.getName();
				localNames.set(arg.tvar.id, RubyNaming.toLocalName(argName));
				if (argName == "locals") {
					localObjectNames.set(arg.tvar.id, argName);
				}
			}
		}
		return {localNames: localNames, localObjectNames: localObjectNames};
	}

	static function extractTemplateAstReturn(expr:TypedExpr):Null<TypedExpr> {
		var unwrapped = unwrapTemplateExpr(expr);
		return switch (unwrapped.expr) {
			case TReturn(value): value == null ? null : unwrapTemplateExpr(value);
			case TBlock(exprs):
				if (exprs == null || exprs.length == 0) {
					null;
				} else {
					extractTemplateAstReturn(exprs[exprs.length - 1]);
				}
			case _: unwrapped;
		}
	}

	static function unwrapTemplateExpr(expr:TypedExpr):TypedExpr {
		return switch (expr.expr) {
			case TMeta(_, inner) | TParenthesis(inner) | TCast(inner, _): unwrapTemplateExpr(inner);
			case _: expr;
		}
	}

	static function lowerTemplateNode(expr:TypedExpr, scope:RailsTemplateScope):String {
		var node = unwrapTemplateExpr(expr);
		return switch (node.expr) {
			case TCall(fn, params):
				switch (templateCtorName(fn, "HtmlNode")) {
					case "Text":
						if (params.length != 1) {
							Context.error("HtmlNode.Text expects one argument.", node.pos);
							"";
						} else {
							expectTemplateString(params[0], "HtmlNode.Text expects a string literal.");
						}
					case "ExprText":
						if (params.length != 1) {
							Context.error("HtmlNode.ExprText expects one argument.", node.pos);
							"";
						} else {
							"<%= " + printTemplateExpr(params[0], scope) + " %>";
						}
					case "Fragment":
						if (params.length != 1) {
							Context.error("HtmlNode.Fragment expects one children array.", node.pos);
							"";
						} else {
							var out = "";
							for (child in expectTemplateArray(params[0], "HtmlNode.Fragment expects an array literal.")) {
								out += lowerTemplateNode(child, scope);
							}
							out;
						}
					case "DoctypeHtml":
						if (params.length != 0) {
							Context.error("HtmlNode.DoctypeHtml expects no arguments.", node.pos);
							"";
						} else {
							"<!DOCTYPE html>";
						}
					case "Element":
						if (params.length != 3) {
							Context.error("HtmlNode.Element expects name, attrs, and children arguments.", node.pos);
							"";
						} else {
							var name = expectTemplateString(params[0], "HtmlNode.Element name must be a string literal.");
							var attrs = expectTemplateArray(params[1], "HtmlNode.Element attrs must be an array literal.");
							var children = expectTemplateArray(params[2], "HtmlNode.Element children must be an array literal.");
							lowerTemplateElement(name, attrs, children, scope);
						}
					case "If":
						if (params.length != 3) {
							Context.error("HtmlNode.If expects cond, thenBranch, and elseBranch arguments.", node.pos);
							"";
						} else {
							lowerTemplateIf(params[0], params[1], params[2], scope);
						}
					case "For":
						if (params.length != 2) {
							Context.error("HtmlNode.For expects items and render arguments.", node.pos);
							"";
						} else {
							lowerTemplateFor(params[0], params[1], scope);
						}
					case "Partial":
						if (params.length != 2) {
							Context.error("HtmlNode.Partial expects template and locals arguments.", node.pos);
							"";
						} else {
							lowerTemplatePartial(params[0], params[1], scope);
						}
					case "Component":
						if (params.length != 4) {
							Context.error("HtmlNode.Component expects template, locals, slotName, and children arguments.", node.pos);
							"";
						} else {
							lowerTemplateComponent(params[0], params[1], params[2], params[3], scope);
						}
					case "ComponentRef":
						if (params.length != 3) {
							Context.error("HtmlNode.ComponentRef expects component, locals, and children arguments.", node.pos);
							"";
						} else {
							lowerTemplateComponentRef(params[0], params[1], params[2], scope);
						}
					case "LinkTo":
						if (params.length != 3) {
							Context.error("HtmlNode.LinkTo expects label, url, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateLinkTo(params[0], params[1], params[2], scope);
						}
					case "LinkToBlock":
						if (params.length != 3) {
							Context.error("HtmlNode.LinkToBlock expects url, attrs, and children arguments.", node.pos);
							"";
						} else {
							lowerTemplateLinkToBlock(params[0], params[1], params[2], scope);
						}
					case "ImageTag":
						if (params.length != 2) {
							Context.error("HtmlNode.ImageTag expects source and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateImageTag(params[0], params[1], scope);
						}
					case "PictureTag":
						if (params.length != 2) {
							Context.error("HtmlNode.PictureTag expects source and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplatePictureTag(params[0], params[1], scope);
						}
					case "FaviconLinkTag":
						if (params.length != 2) {
							Context.error("HtmlNode.FaviconLinkTag expects source and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFaviconLinkTag(params[0], params[1], scope);
						}
					case "PreloadLinkTag":
						if (params.length != 2) {
							Context.error("HtmlNode.PreloadLinkTag expects source and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplatePreloadLinkTag(params[0], params[1], scope);
						}
					case "JavascriptIncludeTag":
						if (params.length != 2) {
							Context.error("HtmlNode.JavascriptIncludeTag expects source and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateJavascriptIncludeTag(params[0], params[1], scope);
						}
					case "JavascriptTag":
						if (params.length != 2) {
							Context.error("HtmlNode.JavascriptTag expects content and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateJavascriptTag(params[0], params[1], scope);
						}
					case "AutoDiscoveryLinkTag":
						if (params.length != 3) {
							Context.error("HtmlNode.AutoDiscoveryLinkTag expects feed type, url, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateAutoDiscoveryLinkTag(params[0], params[1], params[2], scope);
						}
					case "AudioTag":
						if (params.length != 2) {
							Context.error("HtmlNode.AudioTag expects source and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateAudioTag(params[0], params[1], scope);
						}
					case "VideoTag":
						if (params.length != 2) {
							Context.error("HtmlNode.VideoTag expects source and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateVideoTag(params[0], params[1], scope);
						}
					case "MailTo":
						if (params.length != 3) {
							Context.error("HtmlNode.MailTo expects email, label, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateMailTo(params[0], params[1], params[2], scope);
						}
					case "PhoneTo":
						if (params.length != 3) {
							Context.error("HtmlNode.PhoneTo expects phone, label, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplatePhoneTo(params[0], params[1], params[2], scope);
						}
					case "SmsTo":
						if (params.length != 3) {
							Context.error("HtmlNode.SmsTo expects phone, label, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateSmsTo(params[0], params[1], params[2], scope);
						}
					case "Pluralize":
						if (params.length != 3) {
							Context.error("HtmlNode.Pluralize expects count, singular, and plural arguments.", node.pos);
							"";
						} else {
							lowerTemplatePluralize(params[0], params[1], params[2], scope);
						}
					case "SimpleFormat":
						if (params.length != 2) {
							Context.error("HtmlNode.SimpleFormat expects text and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateSimpleFormat(params[0], params[1], scope);
						}
					case "Truncate":
						if (params.length != 3) {
							Context.error("HtmlNode.Truncate expects text, length, and omission arguments.", node.pos);
							"";
						} else {
							lowerTemplateTruncate(params[0], params[1], params[2], scope);
						}
					case "Excerpt":
						if (params.length != 4) {
							Context.error("HtmlNode.Excerpt expects text, phrase, radius, and omission arguments.", node.pos);
							"";
						} else {
							lowerTemplateExcerpt(params[0], params[1], params[2], params[3], scope);
						}
					case "Highlight":
						if (params.length != 4) {
							Context.error("HtmlNode.Highlight expects text, phrase, highlighter, and sanitize arguments.", node.pos);
							"";
						} else {
							lowerTemplateHighlight(params[0], params[1], params[2], params[3], scope);
						}
					case "WordWrap":
						if (params.length != 3) {
							Context.error("HtmlNode.WordWrap expects text, lineWidth, and breakSequence arguments.", node.pos);
							"";
						} else {
							lowerTemplateWordWrap(params[0], params[1], params[2], scope);
						}
					case "Sanitize":
						if (params.length != 3) {
							Context.error("HtmlNode.Sanitize expects html, tags, and attributes arguments.", node.pos);
							"";
						} else {
							lowerTemplateSanitize(params[0], params[1], params[2], scope);
						}
					case "SanitizeCss":
						if (params.length != 1) {
							Context.error("HtmlNode.SanitizeCss expects one style argument.", node.pos);
							"";
						} else {
							"<%= sanitize_css " + printTemplateExpr(params[0], scope) + " %>";
						}
					case "StripTags":
						if (params.length != 1) {
							Context.error("HtmlNode.StripTags expects one html argument.", node.pos);
							"";
						} else {
							"<%= strip_tags " + printTemplateExpr(params[0], scope) + " %>";
						}
					case "StripLinks":
						if (params.length != 1) {
							Context.error("HtmlNode.StripLinks expects one html argument.", node.pos);
							"";
						} else {
							"<%= strip_links " + printTemplateExpr(params[0], scope) + " %>";
						}
					case "ToSentence":
						if (params.length != 4) {
							Context.error("HtmlNode.ToSentence expects items, wordsConnector, twoWordsConnector, and lastWordConnector arguments.", node.pos);
							"";
						} else {
							lowerTemplateToSentence(params[0], params[1], params[2], params[3], scope);
						}
					case "EscapeOnce":
						if (params.length != 1) {
							Context.error("HtmlNode.EscapeOnce expects one html argument.", node.pos);
							"";
						} else {
							"<%= escape_once " + printTemplateExpr(params[0], scope) + " %>";
						}
					case "CdataSection":
						if (params.length != 1) {
							Context.error("HtmlNode.CdataSection expects one content argument.", node.pos);
							"";
						} else {
							"<%= cdata_section " + printTemplateExpr(params[0], scope) + " %>";
						}
					case "SafeJoin":
						if (params.length != 2) {
							Context.error("HtmlNode.SafeJoin expects items and separator arguments.", node.pos);
							"";
						} else {
							lowerTemplateSafeJoin(params[0], params[1], scope);
						}
					case "TokenList":
						if (params.length != 1) {
							Context.error("HtmlNode.TokenList expects one tokens argument.", node.pos);
							"";
						} else {
							"<%= token_list " + printTemplateExpr(params[0], scope) + " %>";
						}
					case "ClassNames":
						if (params.length != 1) {
							Context.error("HtmlNode.ClassNames expects one tokens argument.", node.pos);
							"";
						} else {
							"<%= class_names " + printTemplateExpr(params[0], scope) + " %>";
						}
					case "Cycle":
						if (params.length != 2) {
							Context.error("HtmlNode.Cycle expects values and name arguments.", node.pos);
							"";
						} else {
							lowerTemplateCycle(params[0], params[1], scope);
						}
					case "CurrentCycle":
						if (params.length != 1) {
							Context.error("HtmlNode.CurrentCycle expects one name argument.", node.pos);
							"";
						} else {
							lowerTemplateCurrentCycle(params[0]);
						}
					case "ResetCycle":
						if (params.length != 1) {
							Context.error("HtmlNode.ResetCycle expects one name argument.", node.pos);
							"";
						} else {
							lowerTemplateResetCycle(params[0]);
						}
					case "TimeAgoInWords":
						if (params.length != 2) {
							Context.error("HtmlNode.TimeAgoInWords expects fromTime and includeSeconds arguments.", node.pos);
							"";
						} else {
							lowerTemplateTimeAgoInWords(params[0], params[1], scope);
						}
					case "DistanceOfTimeInWords":
						if (params.length != 3) {
							Context.error("HtmlNode.DistanceOfTimeInWords expects fromTime, toTime, and includeSeconds arguments.", node.pos);
							"";
						} else {
							lowerTemplateDistanceOfTimeInWords(params[0], params[1], params[2], scope);
						}
					case "TimeTag":
						if (params.length != 3) {
							Context.error("HtmlNode.TimeTag expects time, label, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateTimeTag(params[0], params[1], params[2], scope);
						}
					case "NumberToCurrency":
						if (params.length != 3) {
							Context.error("HtmlNode.NumberToCurrency expects number, unit, and precision arguments.", node.pos);
							"";
						} else {
							lowerTemplateNumberToCurrency(params[0], params[1], params[2], scope);
						}
					case "NumberToPercentage":
						if (params.length != 2) {
							Context.error("HtmlNode.NumberToPercentage expects number and precision arguments.", node.pos);
							"";
						} else {
							lowerTemplateNumberToPercentage(params[0], params[1], scope);
						}
					case "NumberToHuman":
						if (params.length != 2) {
							Context.error("HtmlNode.NumberToHuman expects number and precision arguments.", node.pos);
							"";
						} else {
							lowerTemplateNumberToHuman(params[0], params[1], scope);
						}
					case "NumberToHumanSize":
						if (params.length != 2) {
							Context.error("HtmlNode.NumberToHumanSize expects number and precision arguments.", node.pos);
							"";
						} else {
							lowerTemplateNumberToHumanSize(params[0], params[1], scope);
						}
					case "NumberWithPrecision":
						if (params.length != 6) {
							Context.error("HtmlNode.NumberWithPrecision expects number, precision, significant, delimiter, separator, and stripInsignificantZeros arguments.",
								node.pos);
							"";
						} else {
							lowerTemplateNumberWithPrecision(params[0], params[1], params[2], params[3], params[4], params[5], scope);
						}
					case "NumberWithDelimiter":
						if (params.length != 3) {
							Context.error("HtmlNode.NumberWithDelimiter expects number, delimiter, and separator arguments.", node.pos);
							"";
						} else {
							lowerTemplateNumberWithDelimiter(params[0], params[1], params[2], scope);
						}
					case "NumberToDelimited":
						if (params.length != 3) {
							Context.error("HtmlNode.NumberToDelimited expects number, delimiter, and separator arguments.", node.pos);
							"";
						} else {
							lowerTemplateNumberToDelimited(params[0], params[1], params[2], scope);
						}
					case "NumberToPhone":
						if (params.length != 5) {
							Context.error("HtmlNode.NumberToPhone expects number, areaCode, delimiter, extension, and countryCode arguments.", node.pos);
							"";
						} else {
							lowerTemplateNumberToPhone(params[0], params[1], params[2], params[3], params[4], scope);
						}
					case "ButtonTag":
						if (params.length != 2) {
							Context.error("HtmlNode.ButtonTag expects content and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateButtonTag(params[0], params[1], scope);
						}
					case "SubmitTag":
						if (params.length != 2) {
							Context.error("HtmlNode.SubmitTag expects value and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateSubmitTag(params[0], params[1], scope);
						}
					case "TextFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.TextFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateTextFieldTag(params[0], params[1], params[2], scope);
						}
					case "SearchFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.SearchFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateSearchFieldTag(params[0], params[1], params[2], scope);
						}
					case "EmailFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.EmailFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateEmailFieldTag(params[0], params[1], params[2], scope);
						}
					case "TelephoneFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.TelephoneFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateTelephoneFieldTag(params[0], params[1], params[2], scope);
						}
					case "UrlFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.UrlFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateUrlFieldTag(params[0], params[1], params[2], scope);
						}
					case "NumberFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.NumberFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateNumberFieldTag(params[0], params[1], params[2], scope);
						}
					case "RangeFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.RangeFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateRangeFieldTag(params[0], params[1], params[2], scope);
						}
					case "ColorFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.ColorFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateColorFieldTag(params[0], params[1], params[2], scope);
						}
					case "DateFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.DateFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateDateFieldTag(params[0], params[1], params[2], scope);
						}
					case "TimeFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.TimeFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateTimeFieldTag(params[0], params[1], params[2], scope);
						}
					case "DatetimeFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.DatetimeFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateDatetimeFieldTag(params[0], params[1], params[2], scope);
						}
					case "MonthFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.MonthFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateMonthFieldTag(params[0], params[1], params[2], scope);
						}
					case "WeekFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.WeekFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateWeekFieldTag(params[0], params[1], params[2], scope);
						}
					case "PasswordFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.PasswordFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplatePasswordFieldTag(params[0], params[1], params[2], scope);
						}
					case "HiddenFieldTag":
						if (params.length != 3) {
							Context.error("HtmlNode.HiddenFieldTag expects name, value, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateHiddenFieldTag(params[0], params[1], params[2], scope);
						}
					case "FileFieldTag":
						if (params.length != 2) {
							Context.error("HtmlNode.FileFieldTag expects name and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFileFieldTag(params[0], params[1], scope);
						}
					case "TextAreaTag":
						if (params.length != 3) {
							Context.error("HtmlNode.TextAreaTag expects name, content, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateTextAreaTag(params[0], params[1], params[2], scope);
						}
					case "CheckBoxTag":
						if (params.length != 4) {
							Context.error("HtmlNode.CheckBoxTag expects name, value, checked, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateCheckBoxTag(params[0], params[1], params[2], params[3], scope);
						}
					case "RadioButtonTag":
						if (params.length != 4) {
							Context.error("HtmlNode.RadioButtonTag expects name, value, checked, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateRadioButtonTag(params[0], params[1], params[2], params[3], scope);
						}
					case "ButtonTo":
						if (params.length != 3) {
							Context.error("HtmlNode.ButtonTo expects label, url, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateButtonTo(params[0], params[1], params[2], scope);
						}
					case "ButtonToBlock":
						if (params.length != 3) {
							Context.error("HtmlNode.ButtonToBlock expects url, attrs, and children arguments.", node.pos);
							"";
						} else {
							lowerTemplateButtonToBlock(params[0], params[1], params[2], scope);
						}
					case "CsrfMetaTags":
						if (params.length != 0) {
							Context.error("HtmlNode.CsrfMetaTags expects no arguments.", node.pos);
							"";
						} else {
							"<%= csrf_meta_tags %>";
						}
					case "CspMetaTag":
						if (params.length != 0) {
							Context.error("HtmlNode.CspMetaTag expects no arguments.", node.pos);
							"";
						} else {
							"<%= csp_meta_tag %>";
						}
					case "StylesheetLinkTag":
						if (params.length != 2) {
							Context.error("HtmlNode.StylesheetLinkTag expects name and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateStylesheetLinkTag(params[0], params[1], scope);
						}
					case "JavascriptImportmapTags":
						if (params.length != 0) {
							Context.error("HtmlNode.JavascriptImportmapTags expects no arguments.", node.pos);
							"";
						} else {
							"<%= javascript_importmap_tags %>";
						}
					case "TurboStreamFrom":
						if (params.length != 1) {
							Context.error("HtmlNode.TurboStreamFrom expects one stream argument.", node.pos);
							"";
						} else {
							lowerTemplateTurboStreamFrom(params[0]);
						}
					case "TurboFrame":
						if (params.length != 3) {
							Context.error("HtmlNode.TurboFrame expects id, attrs, and children arguments.", node.pos);
							"";
						} else {
							lowerTemplateTurboFrame(params[0], params[1], params[2], scope);
						}
					case "Yield":
						if (params.length != 0) {
							Context.error("HtmlNode.Yield expects no arguments.", node.pos);
							"";
						} else {
							"<%= yield %>";
						}
					case "ContentFor":
						if (params.length != 2) {
							Context.error("HtmlNode.ContentFor expects name and children arguments.", node.pos);
							"";
						} else {
							lowerTemplateContentFor(params[0], params[1], scope);
						}
					case "YieldContent":
						if (params.length != 1) {
							Context.error("HtmlNode.YieldContent expects one name argument.", node.pos);
							"";
						} else {
							"<%= yield " + rubySymbolLiteral(expectTemplateString(params[0], "HtmlNode.YieldContent name must be a string literal.")) + " %>";
						}
					case "FormWith":
						if (params.length != 4) {
							Context.error("HtmlNode.FormWith expects url, scope, attrs, and children arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormWith(params[0], params[1], params[2], params[3], scope);
						}
					case "FormHiddenField":
						if (params.length != 2) {
							Context.error("HtmlNode.FormHiddenField expects name and value arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormHiddenField(params[0], params[1], scope);
						}
					case "FormLabel":
						if (params.length != 3) {
							Context.error("HtmlNode.FormLabel expects name, text, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormLabel(params[0], params[1], params[2], scope);
						}
					case "FormTextField":
						if (params.length != 2) {
							Context.error("HtmlNode.FormTextField expects name and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormTextField(params[0], params[1], scope);
						}
					case "FormSearchField":
						if (params.length != 2) {
							Context.error("HtmlNode.FormSearchField expects name and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormSearchField(params[0], params[1], scope);
						}
					case "FormEmailField":
						if (params.length != 2) {
							Context.error("HtmlNode.FormEmailField expects name and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormEmailField(params[0], params[1], scope);
						}
					case "FormPasswordField":
						if (params.length != 2) {
							Context.error("HtmlNode.FormPasswordField expects name and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormPasswordField(params[0], params[1], scope);
						}
					case "FormFileField":
						if (params.length != 2) {
							Context.error("HtmlNode.FormFileField expects name and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormFileField(params[0], params[1], scope);
						}
					case "FormTextArea":
						if (params.length != 2) {
							Context.error("HtmlNode.FormTextArea expects name and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormTextArea(params[0], params[1], scope);
						}
					case "FormCheckBox":
						if (params.length != 2) {
							Context.error("HtmlNode.FormCheckBox expects name and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormCheckBox(params[0], params[1], scope);
						}
					case "FormSelect":
						if (params.length != 3) {
							Context.error("HtmlNode.FormSelect expects name, options, and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormSelect(params[0], params[1], params[2], scope);
						}
					case "FormFieldErrors":
						if (params.length != 2) {
							Context.error("HtmlNode.FormFieldErrors expects name and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormFieldErrors(params[0], params[1], scope);
						}
					case "FormSubmit":
						if (params.length != 2) {
							Context.error("HtmlNode.FormSubmit expects text and attrs arguments.", node.pos);
							"";
						} else {
							lowerTemplateFormSubmit(params[0], params[1], scope);
						}
					case other:
						Context.error('Unsupported HtmlNode constructor "$other" in @:railsTemplateAst.', node.pos);
						"";
				}
			case TField(_, FEnum(_, _)):
				switch (templateCtorName(node, "HtmlNode")) {
					case "DoctypeHtml":
						"<!DOCTYPE html>";
					case "CsrfMetaTags":
						"<%= csrf_meta_tags %>";
					case "CspMetaTag":
						"<%= csp_meta_tag %>";
					case "JavascriptImportmapTags":
						"<%= javascript_importmap_tags %>";
					case "Yield":
						"<%= yield %>";
					case other:
						Context.error('Unsupported zero-argument HtmlNode constructor "$other" in @:railsTemplateAst.', node.pos);
						"";
				}
			case TBlock(exprs):
				if (exprs == null || exprs.length == 0) {
					Context.error("@:railsTemplateAst node block is empty.", node.pos);
					"";
				} else {
					lowerTemplateNode(exprs[exprs.length - 1], scope);
				}
			case _:
				Context.error("@:railsTemplateAst expected a rails.action_view.HtmlNode constructor expression.", node.pos);
				"";
		}
	}

	static function lowerTemplateElement(name:String, attrs:Array<TypedExpr>, children:Array<TypedExpr>, scope:RailsTemplateScope):String {
		var out = "<" + name;
		for (attr in attrs) {
			out += lowerTemplateAttr(attr, scope);
		}
		if (children.length == 0 && isVoidHtmlElement(name)) {
			return out + ">";
		}
		out += ">";
		for (child in children) {
			out += lowerTemplateNode(child, scope);
		}
		return out + "</" + name + ">";
	}

	static function lowerTemplateAttr(expr:TypedExpr, scope:RailsTemplateScope):String {
		var attr = unwrapTemplateExpr(expr);
		return switch (attr.expr) {
			case TCall(fn, params):
				switch (templateCtorName(fn, "HtmlAttr")) {
					case "Static":
						if (params.length != 2) {
							Context.error("HtmlAttr.Static expects name and value arguments.", attr.pos);
							"";
						} else {" "
							+ expectTemplateString(params[0], "HtmlAttr.Static name must be a string literal.")
							+ "="
							+ quoteHtmlAttr(expectTemplateString(params[1], "HtmlAttr.Static value must be a string literal."));
						}
					case "Bool":
						if (params.length != 1) {
							Context.error("HtmlAttr.Bool expects one name argument.", attr.pos);
							"";
						} else {
							" " + expectTemplateString(params[0], "HtmlAttr.Bool name must be a string literal.");
						}
					case "Expr":
						if (params.length != 2) {
							Context.error("HtmlAttr.Expr expects name and value arguments.", attr.pos);
							"";
						} else {
							var name = expectTemplateString(params[0], "HtmlAttr.Expr name must be a string literal.");
							var staticValue = templateStaticString(params[1]);
							if (staticValue != null) {
								" " + name + "=" + quoteHtmlAttr(staticValue);
							} else {
								" " + name + "=\"<%= " + printTemplateExpr(params[1], scope) + " %>\"";
							}
						}
					case other:
						Context.error('Unsupported HtmlAttr constructor "$other" in @:railsTemplateAst.', attr.pos);
						"";
				}
			case _:
				Context.error("@:railsTemplateAst expected a rails.action_view.HtmlAttr constructor expression.", attr.pos);
				"";
		}
	}

	static function lowerTemplateIf(cond:TypedExpr, thenBranch:TypedExpr, elseBranch:TypedExpr, scope:RailsTemplateScope):String {
		var out = "<% if " + printTemplateExpr(cond, scope) + " %>" + lowerTemplateNode(thenBranch, scope);
		var unwrappedElse = unwrapTemplateExpr(elseBranch);
		switch (unwrappedElse.expr) {
			case TConst(TNull):
			case _:
				out += "<% else %>" + lowerTemplateNode(unwrappedElse, scope);
		}
		return out + "<% end %>";
	}

	static function lowerTemplateFor(items:TypedExpr, render:TypedExpr, scope:RailsTemplateScope):String {
		var fn = unwrapTemplateExpr(render);
		return switch (fn.expr) {
			case TFunction(func):
				if (func.args.length != 1) {
					Context.error("HtmlNode.For render function must take exactly one argument.", fn.pos);
					"";
				} else {
					var binder = func.args[0].v;
					var nextScope = cloneTemplateScope(scope);
					var binderName = RubyNaming.toLocalName(haxeSourceLocalName(binder.name));
					nextScope.localNames.set(binder.id, binderName);
					var body = extractTemplateAstReturn(func.expr);
					if (body == null) {
						Context.error("HtmlNode.For render function must return a HtmlNode.", fn.pos);
						"";
					} else {"<% "
						+ printTemplateExpr(items, scope)
						+ ".each do |"
						+ binderName
						+ "| %>"
						+ lowerTemplateNode(body, nextScope)
						+ "<% end %>";
					}
				}
			case _:
				Context.error("HtmlNode.For render argument must be an inline function.", fn.pos);
				"";
		}
	}

	static function lowerTemplateFormWith(url:TypedExpr, scopeExpr:TypedExpr, attrs:TypedExpr, childrenExpr:TypedExpr, scope:RailsTemplateScope):String {
		var formVar = "form";
		var helperArgs = [
			"url: " + printTemplateExpr(url, scope),
			"scope: " + rubySymbolLiteral(expectTemplateString(scopeExpr, "HtmlNode.FormWith scope must be a string literal."))
		];
		helperArgs = helperArgs.concat(lowerTemplateHelperAttrs(attrs, scope));
		var formScope = cloneTemplateScope(scope);
		formScope.formBuilderName = formVar;
		var out = "<%= form_with " + helperArgs.join(", ") + " do |" + formVar + "| %>";
		for (child in expectTemplateArray(childrenExpr, "HtmlNode.FormWith children must be an array literal.")) {
			out += lowerTemplateNode(child, formScope);
		}
		return out + "<% end %>";
	}

	static function lowerTemplateFormHiddenField(name:TypedExpr, value:TypedExpr, scope:RailsTemplateScope):String {
		var form = requireFormBuilder(scope, name);
		return "<%= "
			+ form
			+ ".hidden_field "
			+ rubySymbolLiteral(expectTemplateFieldName(name, "H.hiddenField name must be a string literal or RailsHx model field ref."))
			+ ", value: "
			+ printTemplateExpr(value, scope)
			+ " %>";
	}

	static function lowerTemplateFormLabel(name:TypedExpr, text:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var form = requireFormBuilder(scope, name);
		var args = [
			rubySymbolLiteral(expectTemplateFieldName(name, "H.label name must be a string literal or RailsHx model field ref.")),
			printTemplateExpr(text, scope)
		].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= " + form + ".label " + args.join(", ") + " %>";
	}

	static function lowerTemplateFormTextField(name:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var form = requireFormBuilder(scope, name);
		var args = [
			rubySymbolLiteral(expectTemplateFieldName(name, "H.textField name must be a string literal or RailsHx model field ref."))
		].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= " + form + ".text_field " + args.join(", ") + " %>";
	}

	static function lowerTemplateFormSearchField(name:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var form = requireFormBuilder(scope, name);
		var args = [
			rubySymbolLiteral(expectTemplateFieldName(name, "H.searchField name must be a string literal or RailsHx model field ref."))
		].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= " + form + ".search_field " + args.join(", ") + " %>";
	}

	static function lowerTemplateFormEmailField(name:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var form = requireFormBuilder(scope, name);
		var args = [
			rubySymbolLiteral(expectTemplateFieldName(name, "H.emailField name must be a string literal or RailsHx model field ref."))
		].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= " + form + ".email_field " + args.join(", ") + " %>";
	}

	static function lowerTemplateFormPasswordField(name:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var form = requireFormBuilder(scope, name);
		var args = [
			rubySymbolLiteral(expectTemplateFieldName(name, "H.passwordField name must be a string literal or RailsHx model field ref."))
		].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= " + form + ".password_field " + args.join(", ") + " %>";
	}

	static function lowerTemplateFormFileField(name:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var form = requireFormBuilder(scope, name);
		var args = [
			rubySymbolLiteral(expectTemplateFieldName(name, "H.fileField name must be a string literal, RailsHx model field ref, or RailsHx attachment ref."))
		].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= " + form + ".file_field " + args.join(", ") + " %>";
	}

	static function lowerTemplateFormTextArea(name:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var form = requireFormBuilder(scope, name);
		var args = [
			rubySymbolLiteral(expectTemplateFieldName(name, "H.textArea name must be a string literal or RailsHx model field ref."))
		].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= " + form + ".text_area " + args.join(", ") + " %>";
	}

	static function lowerTemplateFormCheckBox(name:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var form = requireFormBuilder(scope, name);
		var args = [
			rubySymbolLiteral(expectTemplateFieldName(name, "H.checkBox name must be a string literal or RailsHx model field ref."))
		].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= " + form + ".check_box " + args.join(", ") + " %>";
	}

	static function lowerTemplateFormSelect(name:TypedExpr, options:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var form = requireFormBuilder(scope, name);
		var selectAttrs = lowerTemplateSelectAttrs(attrs, scope);
		var args = [
			rubySymbolLiteral(expectTemplateFieldName(name, "H.select name must be a string literal or RailsHx model field ref.")),
			lowerTemplateSelectOptions(options, scope)
		];
		if (selectAttrs.options.length > 0 || selectAttrs.html.length > 0) {
			args.push("{" + selectAttrs.options.join(", ") + "}");
		}
		if (selectAttrs.html.length > 0) {
			args.push("{" + selectAttrs.html.join(", ") + "}");
		}
		return "<%= " + form + ".select " + args.join(", ") + " %>";
	}

	static function lowerTemplateSelectOptions(options:TypedExpr, scope:RailsTemplateScope):String {
		var pairs = [
			for (option in expectTemplateArray(options, "HtmlNode.FormSelect options must be an array literal."))
				lowerTemplateSelectOption(option, scope)
		];
		return "[" + pairs.join(", ") + "]";
	}

	static function lowerTemplateSelectOption(option:TypedExpr, scope:RailsTemplateScope):String {
		var label:Null<TypedExpr> = null;
		var value:Null<TypedExpr> = null;
		switch (unwrapTemplateExpr(option).expr) {
			case TObjectDecl(fields):
				for (field in fields) {
					switch (field.name) {
						case "label":
							label = field.expr;
						case "value":
							value = field.expr;
						case other:
							Context.error('HtmlNode.FormSelect option field "$other" is not supported; use label and value.', field.expr.pos);
					}
				}
			case _:
				Context.error("HtmlNode.FormSelect options must contain object literals with label and value fields.", option.pos);
		}
		var labelExpr = switch (label) {
			case null:
				Context.error("HtmlNode.FormSelect option literals must include label and value fields.", option.pos);
				option;
			case expr:
				expr;
		}
		var valueExpr = switch (value) {
			case null:
				Context.error("HtmlNode.FormSelect option literals must include label and value fields.", option.pos);
				option;
			case expr:
				expr;
		}
		return "[" + printTemplateExpr(labelExpr, scope) + ", " + printTemplateExpr(valueExpr, scope) + "]";
	}

	static function lowerTemplateSelectAttrs(attrs:TypedExpr, scope:RailsTemplateScope):{options:Array<String>, html:Array<String>} {
		var optionAttrs:Array<String> = [];
		var htmlAttrs:Array<String> = [];
		var dataAttrs:Array<String> = [];
		var ariaAttrs:Array<String> = [];
		for (attr in expectTemplateArray(attrs, "HtmlNode.FormSelect attrs must be an array literal.")) {
			var unwrapped = unwrapTemplateExpr(attr);
			switch (unwrapped.expr) {
				case TCall(fn, params):
					switch (templateCtorName(fn, "HtmlAttr")) {
						case "Static":
							if (params.length != 2) {
								Context.error("HtmlAttr.Static expects name and value arguments.", unwrapped.pos);
							} else {
								addTemplateSelectAttr(optionAttrs, htmlAttrs, dataAttrs, ariaAttrs,
									expectTemplateString(params[0], "HtmlAttr.Static name must be a string literal."),
									quoteRubyStringForCode(expectTemplateString(params[1], "HtmlAttr.Static value must be a string literal.")));
							}
						case "Bool":
							if (params.length != 1) {
								Context.error("HtmlAttr.Bool expects one name argument.", unwrapped.pos);
							} else {
								addTemplateSelectAttr(optionAttrs, htmlAttrs, dataAttrs, ariaAttrs,
									expectTemplateString(params[0], "HtmlAttr.Bool name must be a string literal."), "true");
							}
						case "Expr":
							if (params.length != 2) {
								Context.error("HtmlAttr.Expr expects name and value arguments.", unwrapped.pos);
							} else {
								addTemplateSelectAttr(optionAttrs, htmlAttrs, dataAttrs, ariaAttrs,
									expectTemplateString(params[0], "HtmlAttr.Expr name must be a string literal."), printTemplateExpr(params[1], scope));
							}
						case other:
							Context.error('Unsupported HtmlAttr constructor "$other" for HtmlNode.FormSelect.', unwrapped.pos);
					}
				case _:
					Context.error("HtmlNode.FormSelect attrs must contain HtmlAttr constructor expressions.", unwrapped.pos);
			}
		}
		if (dataAttrs.length > 0) {
			htmlAttrs.push("data: {" + dataAttrs.join(", ") + "}");
		}
		if (ariaAttrs.length > 0) {
			htmlAttrs.push("aria: {" + ariaAttrs.join(", ") + "}");
		}
		return {options: optionAttrs, html: htmlAttrs};
	}

	static function addTemplateSelectAttr(optionAttrs:Array<String>, htmlAttrs:Array<String>, dataAttrs:Array<String>, ariaAttrs:Array<String>,
			name:String, value:String):Void {
		switch (name) {
			case "selected" | "prompt" | "include_blank" | "include-blank":
				optionAttrs.push(helperKwargName(name) + ": " + value);
			case _:
				addTemplateHelperAttr(htmlAttrs, dataAttrs, ariaAttrs, name, value);
		}
	}

	static function lowerTemplateFormFieldErrors(name:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var form = requireFormBuilder(scope, name);
		var fieldName = rubySymbolLiteral(expectTemplateFieldName(name, "H.fieldErrors name must be a string literal or RailsHx model field ref."));
		var attrText = [
			for (attr in expectTemplateArray(attrs, "HtmlNode.FormFieldErrors attrs must be an array literal."))
				lowerTemplateAttr(attr, scope)
		].join("");
		return "<% "
			+ form
			+ ".object.errors["
			+ fieldName
			+ "].each do |message| %><p"
			+ attrText
			+ "><%= message %></p><% end %>";
	}

	static function lowerTemplateFormSubmit(text:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var form = requireFormBuilder(scope, text);
		var args = [printTemplateExpr(text, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= " + form + ".submit " + args.join(", ") + " %>";
	}

	static function requireFormBuilder(scope:RailsTemplateScope, expr:TypedExpr):String {
		if (scope.formBuilderName == null) {
			Context.error("Rails form field helpers must be used inside <form_with> or H.formWith(...).", expr.pos);
			return "form";
		}
		return scope.formBuilderName;
	}

	static function lowerTemplateLinkTo(label:TypedExpr, url:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(label, scope), printTemplateExpr(url, scope)];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (kwargs.length > 0) {
			args = args.concat(kwargs);
		}
		return "<%= link_to " + args.join(", ") + " %>";
	}

	static function lowerTemplateLinkToBlock(url:TypedExpr, attrs:TypedExpr, childrenExpr:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(url, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		var out = "<%= link_to " + args.join(", ") + " do %>";
		for (child in expectTemplateArray(childrenExpr, "HtmlNode.LinkToBlock children must be an array literal.")) {
			out += lowerTemplateNode(child, scope);
		}
		return out + "<% end %>";
	}

	static function lowerTemplateImageTag(source:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(source, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= image_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplatePictureTag(source:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(source, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= picture_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplateFaviconLinkTag(source:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(source, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= favicon_link_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplatePreloadLinkTag(source:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(source, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= preload_link_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplateJavascriptIncludeTag(source:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(source, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= javascript_include_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplateJavascriptTag(content:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(content, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= javascript_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplateAutoDiscoveryLinkTag(feedType:TypedExpr, url:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(feedType, "HtmlNode.AutoDiscoveryLinkTag feed type must be a string literal.")),
			printTemplateExpr(url, scope)
		].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= auto_discovery_link_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplateAudioTag(source:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(source, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= audio_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplateVideoTag(source:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(source, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= video_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplateMailTo(email:TypedExpr, label:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		var args = [printTemplateExpr(email, scope)];
		if (isTemplateNull(label)) {
			if (kwargs.length > 0) {
				args.push("nil");
			}
		} else {
			args.push(printTemplateExpr(label, scope));
		}
		args = args.concat(kwargs);
		return "<%= mail_to " + args.join(", ") + " %>";
	}

	static function lowerTemplatePhoneTo(phone:TypedExpr, label:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		var args = [printTemplateExpr(phone, scope)];
		if (isTemplateNull(label)) {
			if (kwargs.length > 0) {
				args.push("nil");
			}
		} else {
			args.push(printTemplateExpr(label, scope));
		}
		args = args.concat(kwargs);
		return "<%= phone_to " + args.join(", ") + " %>";
	}

	static function lowerTemplateSmsTo(phone:TypedExpr, label:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		var args = [printTemplateExpr(phone, scope)];
		if (isTemplateNull(label)) {
			if (kwargs.length > 0) {
				args.push("nil");
			}
		} else {
			args.push(printTemplateExpr(label, scope));
		}
		args = args.concat(kwargs);
		return "<%= sms_to " + args.join(", ") + " %>";
	}

	static function lowerTemplatePluralize(count:TypedExpr, singular:TypedExpr, plural:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			printTemplateExpr(count, scope),
			quoteRubyStringForCode(expectTemplateString(singular, "HtmlNode.Pluralize singular must be a string literal."))
		];
		if (!isTemplateNull(plural)) {
			args.push(quoteRubyStringForCode(expectTemplateString(plural, "HtmlNode.Pluralize plural must be a string literal.")));
		}
		return "<%= pluralize " + args.join(", ") + " %>";
	}

	static function lowerTemplateSimpleFormat(text:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(text, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= simple_format " + args.join(", ") + " %>";
	}

	static function lowerTemplateTruncate(text:TypedExpr, length:TypedExpr, omission:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(text, scope)];
		if (!isTemplateNull(length)) {
			args.push("length: " + printTemplateExpr(length, scope));
		}
		if (!isTemplateNull(omission)) {
			args.push("omission: " + quoteRubyStringForCode(expectTemplateString(omission, "HtmlNode.Truncate omission must be a string literal.")));
		}
		return "<%= truncate " + args.join(", ") + " %>";
	}

	static function lowerTemplateExcerpt(text:TypedExpr, phrase:TypedExpr, radius:TypedExpr, omission:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(text, scope), printTemplateExpr(phrase, scope)];
		if (!isTemplateNull(radius)) {
			args.push("radius: " + printTemplateExpr(radius, scope));
		}
		if (!isTemplateNull(omission)) {
			args.push("omission: " + quoteRubyStringForCode(expectTemplateString(omission, "HtmlNode.Excerpt omission must be a string literal.")));
		}
		return "<%= excerpt " + args.join(", ") + " %>";
	}

	static function lowerTemplateHighlight(text:TypedExpr, phrase:TypedExpr, highlighter:TypedExpr, sanitize:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(text, scope), printTemplateExpr(phrase, scope)];
		if (!isTemplateNull(highlighter)) {
			args.push("highlighter: " + quoteRubyStringForCode(expectTemplateString(highlighter, "HtmlNode.Highlight highlighter must be a string literal.")));
		}
		if (!isTemplateNull(sanitize)) {
			args.push("sanitize: " + printTemplateExpr(sanitize, scope));
		}
		return "<%= highlight " + args.join(", ") + " %>";
	}

	static function lowerTemplateWordWrap(text:TypedExpr, lineWidth:TypedExpr, breakSequence:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(text, scope)];
		if (!isTemplateNull(lineWidth)) {
			args.push("line_width: " + printTemplateExpr(lineWidth, scope));
		}
		if (!isTemplateNull(breakSequence)) {
			args.push("break_sequence: " + quoteRubyStringForCode(expectTemplateString(breakSequence, "HtmlNode.WordWrap breakSequence must be a string literal.")));
		}
		return "<%= word_wrap " + args.join(", ") + " %>";
	}

	static function lowerTemplateSanitize(html:TypedExpr, tags:TypedExpr, attributes:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(html, scope)];
		if (!isTemplateNull(tags)) {
			args.push("tags: " + printTemplateExpr(tags, scope));
		}
		if (!isTemplateNull(attributes)) {
			args.push("attributes: " + printTemplateExpr(attributes, scope));
		}
		return "<%= sanitize " + args.join(", ") + " %>";
	}

	static function lowerTemplateToSentence(items:TypedExpr, wordsConnector:TypedExpr, twoWordsConnector:TypedExpr, lastWordConnector:TypedExpr,
			scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(items, scope)];
		if (!isTemplateNull(wordsConnector)) {
			args.push("words_connector: "
				+ quoteRubyStringForCode(expectTemplateString(wordsConnector, "HtmlNode.ToSentence wordsConnector must be a string literal.")));
		}
		if (!isTemplateNull(twoWordsConnector)) {
			args.push("two_words_connector: "
				+ quoteRubyStringForCode(expectTemplateString(twoWordsConnector, "HtmlNode.ToSentence twoWordsConnector must be a string literal.")));
		}
		if (!isTemplateNull(lastWordConnector)) {
			args.push("last_word_connector: "
				+ quoteRubyStringForCode(expectTemplateString(lastWordConnector, "HtmlNode.ToSentence lastWordConnector must be a string literal.")));
		}
		return "<%= to_sentence " + args.join(", ") + " %>";
	}

	static function lowerTemplateSafeJoin(items:TypedExpr, separator:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(items, scope)];
		if (!isTemplateNull(separator)) {
			args.push(quoteRubyStringForCode(expectTemplateString(separator, "HtmlNode.SafeJoin separator must be a string literal.")));
		}
		return "<%= safe_join " + args.join(", ") + " %>";
	}

	static function lowerTemplateCycle(values:TypedExpr, name:TypedExpr, scope:RailsTemplateScope):String {
		var args = switch (unwrapTemplateExpr(values).expr) {
			case TArrayDecl(items):
				if (items.length == 0) {
					Context.error("HtmlNode.Cycle values must include at least one string.", values.pos);
				}
				[for (item in items) printTemplateExpr(item, scope)];
			case _:
				["*" + printTemplateExpr(values, scope)];
		}
		if (!isTemplateNull(name)) {
			args.push("name: " + quoteRubyStringForCode(expectTemplateString(name, "HtmlNode.Cycle name must be a string literal.")));
		}
		return "<%= cycle " + args.join(", ") + " %>";
	}

	static function lowerTemplateCurrentCycle(name:TypedExpr):String {
		var args:Array<String> = [];
		if (!isTemplateNull(name)) {
			args.push(quoteRubyStringForCode(expectTemplateString(name, "HtmlNode.CurrentCycle name must be a string literal.")));
		}
		return "<%= current_cycle" + (args.length == 0 ? "" : " " + args.join(", ")) + " %>";
	}

	static function lowerTemplateResetCycle(name:TypedExpr):String {
		var args:Array<String> = [];
		if (!isTemplateNull(name)) {
			args.push(quoteRubyStringForCode(expectTemplateString(name, "HtmlNode.ResetCycle name must be a string literal.")));
		}
		return "<% reset_cycle" + (args.length == 0 ? "" : " " + args.join(", ")) + " %>";
	}

	static function lowerTemplateTimeAgoInWords(fromTime:TypedExpr, includeSeconds:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(fromTime, scope)];
		if (!isTemplateNull(includeSeconds)) {
			args.push("include_seconds: " + printTemplateExpr(includeSeconds, scope));
		}
		return "<%= time_ago_in_words " + args.join(", ") + " %>";
	}

	static function lowerTemplateDistanceOfTimeInWords(fromTime:TypedExpr, toTime:TypedExpr, includeSeconds:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(fromTime, scope), printTemplateExpr(toTime, scope)];
		if (!isTemplateNull(includeSeconds)) {
			args.push("include_seconds: " + printTemplateExpr(includeSeconds, scope));
		}
		return "<%= distance_of_time_in_words " + args.join(", ") + " %>";
	}

	static function lowerTemplateTimeTag(time:TypedExpr, label:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(time, scope)];
		if (!isTemplateNull(label)) {
			args.push(printTemplateExpr(label, scope));
		}
		args = args.concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= time_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplateNumberToCurrency(number:TypedExpr, unit:TypedExpr, precision:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(number, scope)];
		if (!isTemplateNull(unit)) {
			args.push("unit: " + quoteRubyStringForCode(expectTemplateString(unit, "HtmlNode.NumberToCurrency unit must be a string literal.")));
		}
		if (!isTemplateNull(precision)) {
			args.push("precision: " + printTemplateExpr(precision, scope));
		}
		return "<%= number_to_currency " + args.join(", ") + " %>";
	}

	static function lowerTemplateNumberToPercentage(number:TypedExpr, precision:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(number, scope)];
		if (!isTemplateNull(precision)) {
			args.push("precision: " + printTemplateExpr(precision, scope));
		}
		return "<%= number_to_percentage " + args.join(", ") + " %>";
	}

	static function lowerTemplateNumberToHuman(number:TypedExpr, precision:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(number, scope)];
		if (!isTemplateNull(precision)) {
			args.push("precision: " + printTemplateExpr(precision, scope));
		}
		return "<%= number_to_human " + args.join(", ") + " %>";
	}

	static function lowerTemplateNumberToHumanSize(number:TypedExpr, precision:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(number, scope)];
		if (!isTemplateNull(precision)) {
			args.push("precision: " + printTemplateExpr(precision, scope));
		}
		return "<%= number_to_human_size " + args.join(", ") + " %>";
	}

	static function lowerTemplateNumberWithPrecision(number:TypedExpr, precision:TypedExpr, significant:TypedExpr, delimiter:TypedExpr, separator:TypedExpr,
			stripInsignificantZeros:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(number, scope)];
		if (!isTemplateNull(precision)) {
			args.push("precision: " + printTemplateExpr(precision, scope));
		}
		if (!isTemplateNull(significant)) {
			args.push("significant: " + printTemplateExpr(significant, scope));
		}
		if (!isTemplateNull(delimiter)) {
			args.push("delimiter: "
				+ quoteRubyStringForCode(expectTemplateString(delimiter, "HtmlNode.NumberWithPrecision delimiter must be a string literal.")));
		}
		if (!isTemplateNull(separator)) {
			args.push("separator: "
				+ quoteRubyStringForCode(expectTemplateString(separator, "HtmlNode.NumberWithPrecision separator must be a string literal.")));
		}
		if (!isTemplateNull(stripInsignificantZeros)) {
			args.push("strip_insignificant_zeros: " + printTemplateExpr(stripInsignificantZeros, scope));
		}
		return "<%= number_with_precision " + args.join(", ") + " %>";
	}

	static function lowerTemplateNumberWithDelimiter(number:TypedExpr, delimiter:TypedExpr, separator:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(number, scope)];
		if (!isTemplateNull(delimiter)) {
			args.push("delimiter: "
				+ quoteRubyStringForCode(expectTemplateString(delimiter, "HtmlNode.NumberWithDelimiter delimiter must be a string literal.")));
		}
		if (!isTemplateNull(separator)) {
			args.push("separator: "
				+ quoteRubyStringForCode(expectTemplateString(separator, "HtmlNode.NumberWithDelimiter separator must be a string literal.")));
		}
		return "<%= number_with_delimiter " + args.join(", ") + " %>";
	}

	static function lowerTemplateNumberToDelimited(number:TypedExpr, delimiter:TypedExpr, separator:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(number, scope)];
		if (!isTemplateNull(delimiter)) {
			args.push("delimiter: "
				+ quoteRubyStringForCode(expectTemplateString(delimiter, "HtmlNode.NumberToDelimited delimiter must be a string literal.")));
		}
		if (!isTemplateNull(separator)) {
			args.push("separator: "
				+ quoteRubyStringForCode(expectTemplateString(separator, "HtmlNode.NumberToDelimited separator must be a string literal.")));
		}
		return "<%= number_to_delimited " + args.join(", ") + " %>";
	}

	static function lowerTemplateNumberToPhone(number:TypedExpr, areaCode:TypedExpr, delimiter:TypedExpr, extension:TypedExpr, countryCode:TypedExpr,
			scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(number, scope)];
		if (!isTemplateNull(areaCode)) {
			args.push("area_code: " + printTemplateExpr(areaCode, scope));
		}
		if (!isTemplateNull(delimiter)) {
			args.push("delimiter: "
				+ quoteRubyStringForCode(expectTemplateString(delimiter, "HtmlNode.NumberToPhone delimiter must be a string literal.")));
		}
		if (!isTemplateNull(extension)) {
			args.push("extension: "
				+ quoteRubyStringForCode(expectTemplateString(extension, "HtmlNode.NumberToPhone extension must be a string literal.")));
		}
		if (!isTemplateNull(countryCode)) {
			args.push("country_code: " + printTemplateExpr(countryCode, scope));
		}
		return "<%= number_to_phone " + args.join(", ") + " %>";
	}

	static function lowerTemplateButtonTo(label:TypedExpr, url:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(label, scope), printTemplateExpr(url, scope)];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (kwargs.length > 0) {
			args = args.concat(kwargs);
		}
		return "<%= button_to " + args.join(", ") + " %>";
	}

	static function lowerTemplateButtonTag(content:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(content, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= button_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplateSubmitTag(value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(value, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= submit_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplateTextFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.TextFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= text_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateSearchFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.SearchFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= search_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateEmailFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.EmailFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= email_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateTelephoneFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.TelephoneFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= telephone_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateUrlFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.UrlFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= url_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateNumberFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.NumberFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= number_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateRangeFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.RangeFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= range_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateColorFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.ColorFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= color_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateDateFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.DateFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= date_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateTimeFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.TimeFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= time_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateDatetimeFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.DatetimeFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= datetime_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateMonthFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.MonthFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= month_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateWeekFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.WeekFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= week_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplatePasswordFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.PasswordFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= password_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateHiddenFieldTag(name:TypedExpr, value:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.HiddenFieldTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		return "<%= hidden_field_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateFileFieldTag(name:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.FileFieldTag name must be a string literal."))
		].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= file_field_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplateTextAreaTag(name:TypedExpr, content:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.TextAreaTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(content) || kwargs.length > 0) {
			args.push(isTemplateNull(content) ? "nil" : printTemplateExpr(content, scope));
		}
		return "<%= text_area_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateCheckBoxTag(name:TypedExpr, value:TypedExpr, checked:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.CheckBoxTag name must be a string literal."))
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(value) || !isTemplateNull(checked) || kwargs.length > 0) {
			args.push(isTemplateNull(value) ? "nil" : printTemplateExpr(value, scope));
		}
		if (!isTemplateNull(checked) || kwargs.length > 0) {
			args.push(isTemplateNull(checked) ? "false" : printTemplateExpr(checked, scope));
		}
		return "<%= check_box_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateRadioButtonTag(name:TypedExpr, value:TypedExpr, checked:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			rubySymbolLiteral(expectTemplateString(name, "HtmlNode.RadioButtonTag name must be a string literal.")),
			printTemplateExpr(value, scope)
		];
		var kwargs = lowerTemplateHelperAttrs(attrs, scope);
		if (!isTemplateNull(checked) || kwargs.length > 0) {
			args.push(isTemplateNull(checked) ? "false" : printTemplateExpr(checked, scope));
		}
		return "<%= radio_button_tag " + args.concat(kwargs).join(", ") + " %>";
	}

	static function lowerTemplateButtonToBlock(url:TypedExpr, attrs:TypedExpr, childrenExpr:TypedExpr, scope:RailsTemplateScope):String {
		var args = [printTemplateExpr(url, scope)].concat(lowerTemplateHelperAttrs(attrs, scope));
		var out = "<%= button_to " + args.join(", ") + " do %>";
		for (child in expectTemplateArray(childrenExpr, "HtmlNode.ButtonToBlock children must be an array literal.")) {
			out += lowerTemplateNode(child, scope);
		}
		return out + "<% end %>";
	}

	static function lowerTemplateContentFor(nameExpr:TypedExpr, childrenExpr:TypedExpr, scope:RailsTemplateScope):String {
		var name = rubySymbolLiteral(expectTemplateString(nameExpr, "HtmlNode.ContentFor name must be a string literal."));
		var out = "<% content_for " + name + " do %>";
		for (child in expectTemplateArray(childrenExpr, "HtmlNode.ContentFor children must be an array literal.")) {
			out += lowerTemplateNode(child, scope);
		}
		return out + "<% end %>";
	}

	static function lowerTemplateStylesheetLinkTag(name:TypedExpr, attrs:TypedExpr, scope:RailsTemplateScope):String {
		var args = [
			quoteRubyStringForCode(expectTemplateString(name, "HtmlNode.StylesheetLinkTag name must be a string literal."))
		].concat(lowerTemplateHelperAttrs(attrs, scope));
		return "<%= stylesheet_link_tag " + args.join(", ") + " %>";
	}

	static function lowerTemplateTurboStreamFrom(stream:TypedExpr):String {
		return "<%= turbo_stream_from " + printParam([stream], 0) + " %>";
	}

	static function lowerTemplateTurboFrame(id:TypedExpr, attrs:TypedExpr, childrenExpr:TypedExpr, scope:RailsTemplateScope):String {
		var children = expectTemplateArray(childrenExpr, "HtmlNode.TurboFrame children must be an array literal.");
		var staticId = templateStaticString(id);
		var out = "<turbo-frame id=" + (staticId == null ? "\"<%= " + printTemplateExpr(id, scope) + " %>\"" : quoteHtmlAttr(staticId));
		for (attr in expectTemplateArray(attrs, "HtmlNode.TurboFrame attrs must be an array literal.")) {
			out += lowerTemplateAttr(attr, scope);
		}
		out += ">";
		for (child in children) {
			out += lowerTemplateNode(child, scope);
		}
		return out + "</turbo-frame>";
	}

	static function lowerTemplateHelperAttrs(attrs:TypedExpr, scope:RailsTemplateScope):Array<String> {
		var out:Array<String> = [];
		var dataAttrs:Array<String> = [];
		var ariaAttrs:Array<String> = [];
		for (attr in expectTemplateArray(attrs, "HtmlNode.LinkTo attrs must be an array literal.")) {
			var unwrapped = unwrapTemplateExpr(attr);
			switch (unwrapped.expr) {
				case TCall(fn, params):
					switch (templateCtorName(fn, "HtmlAttr")) {
						case "Static":
							if (params.length != 2) {
								Context.error("HtmlAttr.Static expects name and value arguments.", unwrapped.pos);
							} else {
								addTemplateHelperAttr(out, dataAttrs, ariaAttrs,
									expectTemplateString(params[0], "HtmlAttr.Static name must be a string literal."),
									quoteRubyStringForCode(expectTemplateString(params[1], "HtmlAttr.Static value must be a string literal.")));
							}
						case "Bool":
							if (params.length != 1) {
								Context.error("HtmlAttr.Bool expects one name argument.", unwrapped.pos);
							} else {
								addTemplateHelperAttr(out, dataAttrs, ariaAttrs,
									expectTemplateString(params[0], "HtmlAttr.Bool name must be a string literal."), "true");
							}
						case "Expr":
							if (params.length != 2) {
								Context.error("HtmlAttr.Expr expects name and value arguments.", unwrapped.pos);
							} else {
								addTemplateHelperAttr(out, dataAttrs, ariaAttrs,
									expectTemplateString(params[0], "HtmlAttr.Expr name must be a string literal."), printTemplateExpr(params[1], scope));
							}
						case other:
							Context.error('Unsupported HtmlAttr constructor "$other" for HtmlNode.LinkTo.', unwrapped.pos);
					}
				case _:
					Context.error("HtmlNode.LinkTo attrs must contain HtmlAttr constructor expressions.", unwrapped.pos);
			}
		}
		if (dataAttrs.length > 0) {
			out.push("data: {" + dataAttrs.join(", ") + "}");
		}
		if (ariaAttrs.length > 0) {
			out.push("aria: {" + ariaAttrs.join(", ") + "}");
		}
		return out;
	}

	static function isTemplateNull(expr:TypedExpr):Bool {
		return switch (unwrapTemplateExpr(expr).expr) {
			case TConst(TNull):
				true;
			case _:
				false;
		}
	}

	static function addTemplateHelperAttr(out:Array<String>, dataAttrs:Array<String>, ariaAttrs:Array<String>, name:String, value:String):Void {
		if (StringTools.startsWith(name, "data-")) {
			var dataName = RubyNaming.toLocalName(name.substr("data-".length));
			dataAttrs.push(dataName + ": " + dataAttrValue(name, value));
			return;
		}
		if (StringTools.startsWith(name, "aria-")) {
			var ariaName = RubyNaming.toLocalName(name.substr("aria-".length));
			ariaAttrs.push(ariaName + ": " + value);
			return;
		}
		out.push(helperKwargName(name) + ": " + value);
	}

	static function dataAttrValue(name:String, value:String):String {
		if (name == "data-turbo" && value == quoteRubyStringForCode("false")) {
			return "false";
		}
		if (name == "data-turbo" && value == quoteRubyStringForCode("true")) {
			return "true";
		}
		return value;
	}

	static function lowerTemplatePartial(template:TypedExpr, locals:TypedExpr, scope:RailsTemplateScope):String {
		var path = extractTypedTemplatePath(template);
		if (path == null) {
			Context.error("HtmlNode.Partial expects Template.of(ViewClass), Template.existing(\"path\"), Template.named(\"path\"), or Template.external(\"path\") as the template argument.",
				template.pos);
			return "";
		}
		var localsHash = lowerTemplateLocalsHash(locals, scope, null, null);
		return "<%= render partial: " + quoteRubyStringForCode(path) + ", locals: " + localsHash + " %>";
	}

	static function lowerTemplateComponent(template:TypedExpr, locals:TypedExpr, slotNameExpr:TypedExpr, childrenExpr:TypedExpr,
			scope:RailsTemplateScope):String {
		var path = extractTypedTemplatePath(template);
		if (path == null) {
			Context.error("HtmlNode.Component expects Template.of(ViewClass), Template.existing(\"path\"), Template.named(\"path\"), or Template.external(\"path\") as the template argument.",
				template.pos);
			return "";
		}
		var slotName = expectTemplateString(slotNameExpr, "HtmlNode.Component slotName must be a string literal.");
		validateTemplateComponentSlotName(slotName, slotNameExpr.pos, "HtmlNode.Component");
		return lowerTemplateComponentRender(path, slotName, locals, childrenExpr, scope);
	}

	static function lowerTemplateComponentRef(component:TypedExpr, locals:TypedExpr, childrenExpr:TypedExpr, scope:RailsTemplateScope):String {
		var ref = extractTypedComponentRef(component);
		if (ref == null) {
			Context.error("HtmlNode.ComponentRef expects Component.of(ViewClass, \"slot\"), Component.existing(\"path\", \"slot\"), Component.named(\"path\", \"slot\"), or Component.external(\"path\", \"slot\") as the component argument.",
				component.pos);
			return "";
		}
		return lowerTemplateComponentRender(ref.path, ref.slotName, locals, childrenExpr, scope);
	}

	static function lowerTemplateComponentRender(path:String, slotName:String, locals:TypedExpr, childrenExpr:TypedExpr, scope:RailsTemplateScope):String {
		var slotLocalName = "railshx_component_" + RubyNaming.toLocalName(slotName);
		var out = "<% " + slotLocalName + " = capture do %>";
		for (child in expectTemplateArray(childrenExpr, "HtmlNode.Component children must be an array literal.")) {
			out += lowerTemplateNode(child, scope);
		}
		out += "<% end %>";
		var localsHash = lowerTemplateLocalsHash(locals, scope, slotName, slotLocalName);
		return out + "<%= render partial: " + quoteRubyStringForCode(path) + ", locals: " + localsHash + " %>";
	}

	static function lowerTemplateLocalsHash(locals:TypedExpr, scope:RailsTemplateScope, slotName:Null<String>, slotBuffer:Null<String>):String {
		return switch (unwrapTemplateExpr(locals).expr) {
			case TObjectDecl(fields):
				if (fields.length == 0) {
					Context.error("HtmlNode.Partial locals must include at least one named local.", locals.pos);
					"{}";
				} else {
					var foundSlot = slotName == null;
					var out = [
						for (field in fields) {
							var value = if (slotName != null && field.name == slotName) {
								foundSlot = true;
								slotBuffer == null ? "nil" : slotBuffer;
							} else {
								printTemplateExpr(field.expr, scope);
							}
							RubyNaming.toLocalName(field.name) + ": " + value;
						}
					];
					if (!foundSlot) {
						Context.error('HtmlNode.Component locals must include a "$slotName" slot local.', locals.pos);
					}
					"{" + out.join(", ") + "}";
				}
			case _:
				Context.error("HtmlNode.Partial locals must be an object literal so Rails local names are explicit.", locals.pos);
				"{}";
		}
	}

	static function extractTypedTemplatePath(template:TypedExpr):Null<String> {
		var unwrapped = unwrapTemplateExpr(template);
		return switch (unwrapped.expr) {
			case TCall(callee, [path]) if (isTemplatePathCall(callee)):
				var value = expectTemplateString(path, "Template.named/external expects a string literal path.");
				validateRailsTemplatePath(value, path.pos, "Template.named/external");
				normalizeRailsRenderPath(value);
			case _:
				null;
		}
	}

	static function extractTypedComponentRef(component:TypedExpr):Null<RailsComponentRef> {
		var unwrapped = unwrapTemplateExpr(component);
		return switch (unwrapped.expr) {
			case TCall(callee, [path, slot]) if (isComponentPathCall(callee)):
				var value = expectTemplateString(path, "Component.named/external expects a string literal path.");
				var slotName = expectTemplateString(slot, "Component.named/external expects a string literal slot name.");
				validateRailsTemplatePath(value, path.pos, "Component.named/external");
				validateTemplateComponentSlotName(slotName, slot.pos, "Component.named/external");
				{path: normalizeRailsRenderPath(value), slotName: slotName};
			case _:
				null;
		}
	}

	static function isTemplatePathCall(callee:TypedExpr):Bool {
		return switch (unwrapTemplateExpr(callee).expr) {
			case TField(_, access): var name = fieldAccessName(access); name == "named" || name == "external";
			case _:
				false;
		}
	}

	static function isComponentPathCall(callee:TypedExpr):Bool {
		return switch (unwrapTemplateExpr(callee).expr) {
			case TField(_, FStatic(classRef, fieldRef)): var classType = classRef.get(); fullTypeName(classType.pack,
					classType.name) == "rails.action_view.Component" && ["named", "external"].indexOf(fieldRef.get().name) != -1;
			case _:
				false;
		}
	}

	static function cloneTemplateScope(scope:RailsTemplateScope):RailsTemplateScope {
		var localNames:Map<Int, String> = [];
		for (key in scope.localNames.keys()) {
			localNames.set(key, scope.localNames.get(key));
		}
		var localObjectNames:Map<Int, String> = [];
		for (key in scope.localObjectNames.keys()) {
			localObjectNames.set(key, scope.localObjectNames.get(key));
		}
		return {localNames: localNames, localObjectNames: localObjectNames, formBuilderName: scope.formBuilderName};
	}

	static function templateCtorName(fn:TypedExpr, enumName:String):Null<String> {
		var unwrapped = unwrapTemplateExpr(fn);
		return switch (unwrapped.expr) {
			case TField(_, FEnum(enumRef, fieldRef)):
				var enumType = enumRef.get();
				if (enumType.name == enumName && enumType.pack.join(".") == "rails.action_view") {
					fieldRef.name;
				} else {
					null;
				}
			case _:
				null;
		}
	}

	static function expectTemplateArray(expr:TypedExpr, message:String):Array<TypedExpr> {
		return switch (unwrapTemplateExpr(expr).expr) {
			case TArrayDecl(values): values;
			case _:
				Context.error(message, expr.pos);
				[];
		}
	}

	static function expectTemplateString(expr:TypedExpr, message:String):String {
		var value = templateStaticString(expr);
		if (value == null) {
			Context.error(message, expr.pos);
			return "";
		}
		return value;
	}

	static function templateStaticString(expr:TypedExpr):Null<String> {
		var unwrapped = unwrapTemplateExpr(expr);
		return switch (unwrapped.expr) {
			case TConst(TString(value)):
				value;
			case TField(_, FStatic(_, fieldRef)):
				templateStaticFieldString(fieldRef.get());
			case _:
				null;
		}
	}

	static function templateStaticFieldString(field:ClassField):Null<String> {
		var expr = field.expr();
		if (expr != null) {
			var value = templateStaticString(expr);
			if (value != null) {
				return value;
			}
		}
		return null;
	}

	static function expectTemplateFieldName(expr:TypedExpr, message:String):String {
		var unwrapped = unwrapTemplateExpr(expr);
		return switch (unwrapped.expr) {
			case TConst(TString(value)):
				RubyNaming.toMethodName(value);
			case TField(_, access):
				var value = fieldAccessRailsFieldName(access);
				if (value == null) {
					value = fieldAccessRailsAttachmentName(access);
				}
				if (value == null) {
					Context.error(message, expr.pos);
					"";
				} else {
					RubyNaming.toMethodName(value);
				}
			case _:
				Context.error(message, expr.pos);
				"";
		}
	}

	static function fieldAccessRailsFieldName(access:haxe.macro.Type.FieldAccess):Null<String> {
		var meta = switch (access) {
			case FInstance(_, _, field) | FStatic(_, field): field.get().meta;
			case FAnon(fieldRef) | FClosure(_, fieldRef): fieldRef.get().meta;
			case FEnum(_, field): field.meta;
			case FDynamic(_): null;
		}
		return metaStringParam(meta, ":railsField", 0);
	}

	static function fieldAccessRailsAssociationName(access:haxe.macro.Type.FieldAccess):Null<String> {
		var meta = switch (access) {
			case FInstance(_, _, field) | FStatic(_, field): field.get().meta;
			case FAnon(fieldRef) | FClosure(_, fieldRef): fieldRef.get().meta;
			case FEnum(_, field): field.meta;
			case FDynamic(_): null;
		}
		return metaStringParam(meta, ":railsAssociation", 0);
	}

	static function fieldAccessRailsAttachmentName(access:haxe.macro.Type.FieldAccess):Null<String> {
		var meta = switch (access) {
			case FInstance(_, _, field) | FStatic(_, field): field.get().meta;
			case FAnon(fieldRef) | FClosure(_, fieldRef): fieldRef.get().meta;
			case FEnum(_, field): field.meta;
			case FDynamic(_): null;
		}
		return metaStringParam(meta, ":railsAttachment", 0);
	}

	static function printTemplateExpr(expr:TypedExpr, scope:RailsTemplateScope):String {
		var unwrapped = unwrapTemplateExpr(expr);
		var abstractValue = abstractIdentityBlockValue(unwrapped);
		if (abstractValue != null) {
			return printTemplateExpr(abstractValue, scope);
		}
		return switch (unwrapped.expr) {
			case TLocal(v) if (scope.localNames.exists(v.id)):
				scope.localNames.get(v.id);
			case TLocal(v):
				haxeSourceLocalName(v.name);
			case TCall({expr: TField(_, FStatic(classRef, fieldRef))}, []) if (isSlotContentCall(classRef.get(), fieldRef.get())):
				Context.error("Slot.content() may only be used as the matching slot local for HtmlNode.Component.", unwrapped.pos);
				"nil";
			case TConst(TNull): "nil";
			case TConst(TBool(value)): value ? "true" : "false";
			case TConst(TInt(value)): Std.string(value);
			case TConst(TFloat(value)): value;
			case TConst(TString(value)): quoteRubyStringForCode(value);
			case TCall({expr: TField(_, FStatic(classRef, fieldRef))}, []) if (isDateNowCall(classRef.get(), fieldRef.get())):
				"Time.now";
			case TCall({expr: TField(_, FStatic(classRef, fieldRef))}, [value]) if (isStdStringCall(classRef.get(), fieldRef.get())):
				printTemplateExpr(value, scope) + ".to_s";
			case TCall({expr: TField(_, FStatic(classRef, fieldRef))}, []) if (actionViewFlashExpr(classRef.get(), fieldRef.get()) != null):
				actionViewFlashExpr(classRef.get(), fieldRef.get());
			case TCall({expr: TField(_, FStatic(classRef, fieldRef))}, params) if (deviseAuthLinkPathExpr(classRef.get(), fieldRef.get(), params) != null):
				deviseAuthLinkPathExpr(classRef.get(), fieldRef.get(), params);
			case TCall({expr: TField(_, FStatic(classRef, fieldRef))}, params) if (deviseErrorsExpr(classRef.get(), fieldRef.get(), params, scope) != null):
				deviseErrorsExpr(classRef.get(), fieldRef.get(), params, scope);
			case TField(_, FStatic(_, fieldRef)):
				var staticValue = templateStaticFieldString(fieldRef.get());
				if (staticValue != null) {
					quoteRubyStringForCode(staticValue);
				} else {
					simplifyTemplateRubyIdentityBegin(reflaxe.ruby.ast.RubyASTPrinter.printExpr(compileExpr(unwrapped)));
				}
			case TArray(target, index): printTemplateExpr(target, scope) + "[" + printTemplateExpr(index, scope) + "]";
			case TArrayDecl(values): "[" + [for (value in values) printTemplateExpr(value, scope)].join(", ") + "]";
			case TBinop(op, lhs, rhs): printTemplateExpr(lhs, scope) + " " + binopToRuby(op) + " " + printTemplateExpr(rhs, scope);
			case TUnop(op, _, inner): unopToRuby(op) + printTemplateExpr(inner, scope);
			case TField({expr: TLocal(v)}, access) if (scope.localObjectNames.exists(v.id)):
				fieldAccessName(access);
			case TField(target, access): printTemplateExpr(target, scope) + "." + fieldAccessName(access);
			case TCall({expr: TField(_, FStatic(classRef, fieldRef))}, params):
				var classType = classRef.get();
				var receiver = rubyNativeName(classType.meta) ?? rubyConstantPath(classType.pack, classType.name);
				var method = rubyFieldName(fieldRef.get().name, fieldRef.get().meta);
				var args = [for (param in params) printTemplateExpr(param, scope)].join(", ");
				(receiver == "self" ? method : receiver + "." + method) + "(" + args + ")";
			case TCall({expr: TField(target, access)}, params):
				printTemplateExpr(target, scope)
				+ "."
				+ fieldAccessName(access)
				+ "("
				+ [for (param in params) printTemplateExpr(param, scope)].join(", ") + ")";
			case TCall(callee, params):
				printTemplateExpr(callee, scope) + ".call(" + [for (param in params) printTemplateExpr(param, scope)].join(", ") + ")";
			case TIf(cond, eThen, eElse):
				"(if "
				+ printTemplateExpr(cond, scope)
				+ " then "
				+ printTemplateExpr(eThen, scope)
				+ " else "
				+ (eElse == null ? "nil" : printTemplateExpr(eElse, scope))
				+ " end)";
			case _:
				simplifyTemplateRubyIdentityBegin(reflaxe.ruby.ast.RubyASTPrinter.printExpr(compileExpr(unwrapped)));
		}
	}

	static function simplifyTemplateRubyIdentityBegin(code:String):String {
		return simplifyRubyCompilerLocalNames(simplifyRubyIdentityBegin(code));
	}

	static function simplifyRubyCompilerLocalNames(code:String):String {
		return ~/\b([a-z][A-Za-z0-9_]*)__hx[0-9]+\b/g.replace(code, "$1");
	}

	static function isStdStringCall(classType:ClassType, field:haxe.macro.Type.ClassField):Bool {
		return classType.pack.length == 0 && classType.name == "Std" && field.name == "string";
	}

	static function isDateNowCall(classType:ClassType, field:haxe.macro.Type.ClassField):Bool {
		// Rails DateHelper methods want Time-like Ruby values; template lowering
		// keeps Haxe Date.now() typed while emitting the Rails-native Time.now.
		return classType.pack.length == 0 && classType.name == "Date" && field.name == "now";
	}

	static function actionViewFlashExpr(classType:ClassType, field:haxe.macro.Type.ClassField):Null<String> {
		// `rails.action_view.FlashMessages` is an extern authoring facade, not a
		// runtime Ruby class. Lowering it here keeps app HHX typed while emitting
		// the same `flash[:alert]` / `flash[:notice]` reads a Rails view would use.
		if (classType.pack.join(".") != "rails.action_view" || classType.name != "FlashMessages") {
			return null;
		}
		return switch (field.name) {
			case "alert": "flash[:alert]";
			case "notice": "flash[:notice]";
			case "message": "flash[:alert] || flash[:notice]";
			case "hasMessage": "flash[:alert].present? || flash[:notice].present?";
			case "kind": "(flash[:alert].present? ? \"alert\" : \"notice\")";
			case _: null;
		}
	}

	static function deviseAuthLinkPathExpr(classType:ClassType, field:haxe.macro.Type.ClassField, params:Array<TypedExpr>):Null<String> {
		if (classType.pack.join(".") != "devisehx.hhx" || classType.name != "AuthLinks") {
			return null;
		}
		if (params.length != 1) {
			Context.error("DeviseHx HHX auth route helpers expect one generated Devise scope argument, such as UserAuth.scope.", field.pos);
			return "nil";
		}
		var scope = deviseMappingScopeFromArg(params[0]);
		return switch (field.name) {
			case "newSessionPath" | "signInPath":
				"new_" + scope + "_session_path()";
			case "sessionPath":
				scope + "_session_path()";
			case "destroySessionPath" | "signOutPath":
				"destroy_" + scope + "_session_path()";
			case "newRegistrationPath" | "signUpPath":
				"new_" + scope + "_registration_path()";
			case "editRegistrationPath":
				"edit_" + scope + "_registration_path()";
			case "registrationPath":
				scope + "_registration_path()";
			case "cancelRegistrationPath":
				"cancel_" + scope + "_registration_path()";
			case "newPasswordPath":
				"new_" + scope + "_password_path()";
			case "editPasswordPath":
				"edit_" + scope + "_password_path()";
			case "passwordPath":
				scope + "_password_path()";
			case "newConfirmationPath":
				"new_" + scope + "_confirmation_path()";
			case "confirmationPath":
				scope + "_confirmation_path()";
			case "newUnlockPath":
				"new_" + scope + "_unlock_path()";
			case "unlockPath":
				scope + "_unlock_path()";
			case _:
				null;
		}
	}

	static function deviseErrorsExpr(classType:ClassType, field:haxe.macro.Type.ClassField, params:Array<TypedExpr>, scope:RailsTemplateScope):Null<String> {
		if (classType.pack.join(".") != "devisehx.hhx" || classType.name != "DeviseErrors") {
			return null;
		}
		if (params.length != 1) {
			Context.error("DeviseErrors helpers expect one typed Devise resource argument.", field.pos);
			return "nil";
		}
		var target = printTemplateExpr(params[0], scope) + ".errors";
		return switch (field.name) {
			case "hasAny":
				target + ".any?";
			case "count":
				target + ".count";
			case "fullMessages":
				target + ".full_messages";
			case _:
				null;
		}
	}

	static function haxeSourceLocalName(name:String):String {
		var marker = name.lastIndexOf("__hx");
		if (marker <= 0) {
			return name;
		}
		var suffix = name.substr(marker + "__hx".length);
		return ~/^[0-9]+$/.match(suffix) ? name.substr(0, marker) : name;
	}

	static function isSlotContentCall(classType:ClassType, field:haxe.macro.Type.ClassField):Bool {
		return field.name == "content"
			&& ((classType.pack.join(".") == "rails.action_view" && classType.name == "Slot")
				|| (classType.pack.join(".") == "rails.action_view._Slot" && classType.name == "Slot_Impl_"));
	}

	static function quoteHtmlAttr(value:String):String {
		return quoteRubyStringForCode(value);
	}

	static function helperKwargName(value:String):String {
		return ~/^[A-Za-z_][A-Za-z0-9_]*$/.match(value) ? value : quoteRubyStringForCode(value);
	}

	static function isVoidHtmlElement(name:String):Bool {
		return [
			"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"
		].indexOf(name) != -1;
	}

	static function railsTemplateOutputPath(path:String):String {
		var normalized = normalizeRailsTemplatePath(path);
		while (StringTools.startsWith(normalized, "/")) {
			normalized = normalized.substr(1);
		}
		if (!StringTools.endsWith(normalized, ".erb")) {
			normalized += ".html.erb";
		}
		return "app/views/" + normalized;
	}

	static function railsTestOutputPath(path:String):String {
		var normalized = normalizeRailsTestPath(path);
		while (StringTools.startsWith(normalized, "/")) {
			normalized = normalized.substr(1);
		}
		if (!StringTools.endsWith(normalized, ".rb")) {
			normalized += ".rb";
		}
		return "test/generated/" + normalized;
	}

	static function railsMailerPreviewOutputPath(path:String):String {
		var normalized = normalizeRailsMailerPreviewPath(path);
		while (StringTools.startsWith(normalized, "/")) {
			normalized = normalized.substr(1);
		}
		if (!StringTools.endsWith(normalized, ".rb")) {
			normalized += ".rb";
		}
		return "test/mailers/previews/" + normalized;
	}

	static function normalizeRailsRenderPath(path:String):String {
		var normalized = normalizeRailsTemplatePath(path);
		if (StringTools.endsWith(normalized, ".html.erb")) {
			normalized = normalized.substr(0, normalized.length - ".html.erb".length);
		} else if (StringTools.endsWith(normalized, ".erb")) {
			normalized = normalized.substr(0, normalized.length - ".erb".length);
		}
		var segments = normalized.split("/");
		var last = segments.pop();
		if (last != null && StringTools.startsWith(last, "_")) {
			last = last.substr(1);
		}
		if (last != null) {
			segments.push(last);
		}
		return segments.join("/");
	}

	static function validateRailsTemplatePath(path:String, pos:haxe.macro.Expr.Position, context:String):Void {
		var normalized = normalizeRailsTemplatePath(path);
		if (normalized == ""
			|| StringTools.startsWith(normalized, "/")
			|| normalized.indexOf("..") != -1
			|| normalized.indexOf("//") != -1
			|| path.indexOf("\\") != -1) {
			Context.error(context + " path must be a safe Rails template path relative to app/views.", pos);
			return;
		}
		for (segment in normalized.split("/")) {
			if (segment == "" || segment == "." || segment == "..") {
				Context.error(context + " path must not contain empty, '.', or '..' segments.", pos);
				return;
			}
		}
	}

	static function validateRailsTestPath(path:String, pos:haxe.macro.Expr.Position, context:String):Void {
		var normalized = normalizeRailsTestPath(path);
		if (normalized == ""
			|| StringTools.startsWith(normalized, "/")
			|| normalized.indexOf("..") != -1
			|| normalized.indexOf("//") != -1
			|| path.indexOf("\\") != -1) {
			Context.error(context + " path must be a safe Rails test path relative to test/generated.", pos);
			return;
		}
		if (!StringTools.endsWith(normalized, "_test") && !StringTools.endsWith(normalized, "_test.rb")) {
			Context.error(context + " path must end with _test or _test.rb so Rails/Minitest discovers it.", pos);
			return;
		}
		for (segment in normalized.split("/")) {
			if (segment == "" || segment == "." || segment == "..") {
				Context.error(context + " path must not contain empty, '.', or '..' segments.", pos);
				return;
			}
		}
	}

	static function validateRailsMailerPreviewPath(path:String, pos:haxe.macro.Expr.Position, context:String):Void {
		var normalized = normalizeRailsMailerPreviewPath(path);
		if (normalized == ""
			|| StringTools.startsWith(normalized, "/")
			|| normalized.indexOf("..") != -1
			|| normalized.indexOf("//") != -1
			|| path.indexOf("\\") != -1) {
			Context.error(context + " path must be a safe Rails preview path relative to test/mailers/previews.", pos);
			return;
		}
		if (!StringTools.endsWith(normalized, "_preview") && !StringTools.endsWith(normalized, "_preview.rb")) {
			Context.error(context + " path must end with _preview or _preview.rb so Rails discovers it as a mailer preview.", pos);
			return;
		}
		for (segment in normalized.split("/")) {
			if (segment == "" || segment == "." || segment == "..") {
				Context.error(context + " path must not contain empty, '.', or '..' segments.", pos);
				return;
			}
		}
	}

	static function validateTemplateComponentSlotName(slotName:String, pos:haxe.macro.Expr.Position, context:String):Void {
		if (!~/^[A-Za-z_][A-Za-z0-9_]*$/.match(slotName)) {
			Context.error(context + " slot name must be a safe Haxe/Ruby local identifier.", pos);
		}
	}

	static function normalizeRailsTemplatePath(path:String):String {
		return StringTools.replace(path == null ? "" : StringTools.trim(path), "\\", "/");
	}

	static function normalizeRailsTestPath(path:String):String {
		return StringTools.replace(path == null ? "" : StringTools.trim(path), "\\", "/");
	}

	static function normalizeRailsMailerPreviewPath(path:String):String {
		var normalized = StringTools.replace(path == null ? "" : StringTools.trim(path), "\\", "/");
		while (StringTools.startsWith(normalized, "test/mailers/previews/")) {
			normalized = normalized.substr("test/mailers/previews/".length);
		}
		return normalized;
	}

	static function normalizeGeneratedText(value:String):String {
		var normalized = StringTools.replace(value == null ? "" : value, "\r\n", "\n").split("\r").join("\n");
		return StringTools.endsWith(normalized, "\n") ? normalized : normalized + "\n";
	}

	static function containsRawErb(value:String):Bool {
		return value != null && value.indexOf("<%") != -1;
	}

	function outputRelativeDir(dir:Null<String>, appOwned:Bool):Null<String> {
		var normalized = dir == null ? "" : dir;
		if (buildContext.railsMode && appOwned) {
			return normalized == "" ? buildContext.railsOutputRoot : buildContext.railsOutputRoot + "/" + normalized;
		}
		return normalized == "" ? null : normalized;
	}

	function outputRelativePath(path:String, runtimeOwned:Bool):String {
		if (buildContext.railsMode && runtimeOwned) {
			return buildContext.railsOutputRoot + "/" + path;
		}
		return path;
	}

	static function runtimeFileContent(name:String):String {
		var path = Path.join([findLibraryRoot(), "runtime", "hxruby", name]);
		if (!FileSystem.exists(path)) {
			Context.fatalError("Missing hxruby runtime file: " + path, Context.currentPos());
		}
		return File.getContent(path);
	}

	static function findLibraryRoot():String {
		var compilerPath = Context.resolvePath("reflaxe/ruby/RubyCompiler.hx");
		return Path.normalize(Path.join([Path.directory(compilerPath), "..", "..", ".."]));
	}

	static function isSysPrintCall(callee:TypedExpr):Bool {
		return switch (callee.expr) {
			case TField(_, FStatic(_, field)) | TField(_, FInstance(_, _, field)): var name = field.get().name; name == "print" || name == "println";
			case TField(_, FAnon(fieldRef)) | TField(_, FClosure(_, fieldRef)): var field = fieldRef.get(); field.name == "print" || field.name == "println";
			case _:
				false;
		}
	}

	static function fieldAccessName(access:haxe.macro.Type.FieldAccess):String {
		return switch (access) {
			case FInstance(_, _, field) | FStatic(_, field): rubyFieldName(field.get().name, field.get().meta);
			case FAnon(fieldRef) | FClosure(_, fieldRef): rubyFieldName(fieldRef.get().name, fieldRef.get().meta);
			case FDynamic(name): RubyNaming.toMethodName(name);
			case FEnum(_, field): rubyFieldName(field.name, field.meta);
		}
	}

	static function fieldAccessRawName(access:haxe.macro.Type.FieldAccess):String {
		return switch (access) {
			case FInstance(_, _, field) | FStatic(_, field): field.get().name;
			case FAnon(fieldRef) | FClosure(_, fieldRef): fieldRef.get().name;
			case FDynamic(name): name;
			case FEnum(_, field): field.name;
		}
	}

	static function isArrayFieldAccess(access:haxe.macro.Type.FieldAccess):Bool {
		return switch (access) {
			case FInstance(classRef, _, _):
				var classType = classRef.get();
				fullTypeName(classType.pack, classType.name) == "Array";
			case _:
				false;
		}
	}

	static function hasFieldAccessMeta(access:haxe.macro.Type.FieldAccess, name:String):Bool {
		var meta = switch (access) {
			case FInstance(_, _, field) | FStatic(_, field): field.get().meta;
			case FAnon(fieldRef) | FClosure(_, fieldRef): fieldRef.get().meta;
			case FEnum(_, field): field.meta;
			case FDynamic(_): null;
		}
		return hasMeta(meta, name);
	}

	static function moduleTypeName(moduleType:ModuleType):String {
		return switch (moduleType) {
			case TClassDecl(classRef):
				var classType = classRef.get();
				coreRubyTypeName(classType.pack, classType.name) ?? rubyNativeName(classType.meta) ?? rubyConstantPath(classType.pack, classType.name);
			case TEnumDecl(enumRef):
				var enumType = enumRef.get();
				rubyNativeName(enumType.meta) ?? rubyConstantPath(enumType.pack, enumType.name);
			case TTypeDecl(typeRef):
				var defType = typeRef.get();
				rubyNativeName(defType.meta) ?? rubyConstantPath(defType.pack, defType.name);
			case TAbstract(abstractRef):
				var abstractType = abstractRef.get();
				rubyNativeName(abstractType.meta) ?? rubyConstantPath(abstractType.pack, abstractType.name);
		}
	}

	static function coreRubyTypeName(pack:Array<String>, name:String):Null<String> {
		return switch (fullTypeName(pack, name)) {
			case "String": "String";
			case "Array": "Array";
			case _: null;
		}
	}

	static function rubyConstantPath(pack:Array<String>, name:String):String {
		var parts = RubyNaming.modulePath(pack);
		parts.push(RubyNaming.toConstantName(name));
		return parts.join("::");
	}

	static function rubyFieldName(name:String, meta:Null<haxe.macro.Type.MetaAccess>):String {
		return rubyNativeName(meta) ?? RubyNaming.toMethodName(name);
	}

	static function rubyNativeName(meta:Null<haxe.macro.Type.MetaAccess>):Null<String> {
		if (meta == null || meta.extract == null) {
			return null;
		}
		var entries = meta.extract(":native");
		if (entries.length == 0) {
			return null;
		}
		var entry = entries[0];
		if (entry.params == null || entry.params.length == 0) {
			return null;
		}
		return switch (entry.params[0].expr) {
			case EConst(CString(value, _)) if (value.length > 0): value;
			case EConst(CIdent(value)) if (value.length > 0): value;
			case _: null;
		}
	}

	static function hasMeta(meta:Null<haxe.macro.Type.MetaAccess>, name:String):Bool {
		return meta != null && meta.has != null && meta.has(name);
	}

	static function railsModelTableName(classType:ClassType):Null<String> {
		var explicit = metaStringValue(classType.meta, ":railsModel");
		if (explicit != null) {
			return explicit;
		}
		return RubyNaming.fileName(classType.name) + "s";
	}

	static function railsModelHasAttachments(classType:ClassType):Bool {
		for (field in classType.fields.get()) {
			if (hasMeta(field.meta, ":hasOneAttached") || hasMeta(field.meta, ":hasManyAttached")) {
				return true;
			}
		}
		return false;
	}

	static function metaStringValue(meta:Null<haxe.macro.Type.MetaAccess>, name:String):Null<String> {
		return metaStringParam(meta, name, 0);
	}

	static function metaStringParam(meta:Null<haxe.macro.Type.MetaAccess>, name:String, index:Int):Null<String> {
		if (meta == null || meta.extract == null) {
			return null;
		}
		var entries = meta.extract(name);
		if (entries.length == 0 || entries[0].params == null || entries[0].params.length <= index) {
			return null;
		}
		return switch (entries[0].params[index].expr) {
			case EConst(CString(value, _)) if (value.length > 0): value;
			case _: null;
		}
	}

	static function metadataObject(meta:Null<haxe.macro.Type.MetaAccess>, name:String):Null<Array<RubyMetadataField>> {
		if (meta == null || meta.extract == null) {
			return null;
		}
		var entries = meta.extract(name);
		if (entries.length == 0 || entries[0].params == null || entries[0].params.length != 1) {
			return null;
		}
		return switch (entries[0].params[0].expr) {
			case EObjectDecl(fields):
				[for (field in fields) {field: field.field, expr: field.expr}];
			case _:
				null;
		}
	}

	static function metadataObjectString(fields:Array<RubyMetadataField>, key:String, pos:Position):String {
		for (field in fields) {
			if (field.field != key) {
				continue;
			}
			return switch (field.expr.expr) {
				case EConst(CString(value, _)): value;
				case _:
					Context.error('DeviseHx metadata field "$key" must be a string literal.', field.expr.pos);
					"";
			}
		}
		Context.error('DeviseHx metadata is missing required field "$key".', pos);
		return "";
	}

	static function metadataObjectInt(fields:Array<RubyMetadataField>, key:String, pos:Position):Int {
		for (field in fields) {
			if (field.field != key) {
				continue;
			}
			return switch (field.expr.expr) {
				case EConst(CInt(value, _)): Std.parseInt(value);
				case _:
					Context.error('DeviseHx metadata field "$key" must be an integer literal.', field.expr.pos);
					0;
			}
		}
		Context.error('DeviseHx metadata is missing required field "$key".', pos);
		return 0;
	}

	static function validateDeviseMappingScope(scope:String, pos:Position):Void {
		if (!~/^[a-z][a-z0-9_]*$/.match(scope)) {
			Context.error("DeviseHx mappingScope must be a safe snake_case Devise scope.", pos);
		}
	}

	static function validationTargetName(field:ClassVarData):String {
		var explicit = metaStringValue(field.field.meta, ":validates");
		if (explicit != null) {
			return RubyNaming.toMethodName(explicit);
		}
		var name = field.field.name;
		var suffix = "Validation";
		if (StringTools.endsWith(name, suffix) && name.length > suffix.length) {
			name = name.substr(0, name.length - suffix.length);
		}
		return RubyNaming.toMethodName(name);
	}

	static function validationOptions(meta:Null<haxe.macro.Type.MetaAccess>):Array<String> {
		if (meta == null || meta.extract == null) {
			return [];
		}
		var entries = meta.extract(":validates");
		if (entries.length == 0 || entries[0].params == null || entries[0].params.length == 0) {
			return [];
		}
		var params = entries[0].params;
		var options = switch (params[0].expr) {
			case EObjectDecl(_): params[0];
			case _ if (params.length > 1): params[1];
			case _: null;
		}
		return options == null ? [] : metadataObjectOptions(options);
	}

	static function railsEnumOptions(meta:Null<haxe.macro.Type.MetaAccess>):String {
		if (meta == null || meta.extract == null) {
			return "{}";
		}
		var entries = meta.extract(":railsEnum");
		if (entries.length == 0 || entries[0].params == null || entries[0].params.length == 0) {
			return "{}";
		}
		return metadataValueCode(entries[0].params[0]);
	}

	static function railsAssociationOptionsSuffix(meta:Null<haxe.macro.Type.MetaAccess>, name:String):String {
		if (meta == null || meta.extract == null) {
			return "";
		}
		var entries = meta.extract(name);
		if (entries.length == 0 || entries[0].params == null || entries[0].params.length == 0) {
			return "";
		}
		var options = railsAssociationOptions(entries[0].params[0]);
		return options.length == 0 ? "" : ", " + options.join(", ");
	}

	static function railsAssociationOptions(expr:haxe.macro.Expr):Array<String> {
		return switch (expr.expr) {
			case EObjectDecl(fields):
				[for (field in fields) railsAssociationOption(field.field, field.expr)];
			case _:
				[];
		}
	}

	static function railsAssociationOption(name:String, expr:haxe.macro.Expr):String {
		var rubyName = RubyNaming.toMethodName(name);
		var value = switch (name) {
			case "dependent" | "inverseOf" | "through" | "source":
				railsSymbolOptionValue(expr);
			case "foreignKey":
				railsStringMethodOptionValue(expr);
			case "className":
				metadataValueCode(expr);
			case _:
				metadataValueCode(expr);
		}
		return rubyName + ": " + value;
	}

	static function railsSymbolOptionValue(expr:haxe.macro.Expr):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)):
				":" + RubyNaming.toMethodName(value);
			case _:
				metadataValueCode(expr);
		}
	}

	static function railsStringMethodOptionValue(expr:haxe.macro.Expr):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)):
				quoteRubyStringForCode(RubyNaming.toMethodName(value));
			case _:
				metadataValueCode(expr);
		}
	}

	static function railsCallbackNames(meta:Null<haxe.macro.Type.MetaAccess>):Array<String> {
		if (meta == null || meta.extract == null) {
			return [];
		}
		var names:Array<String> = [];
		var callbackPairs:Array<{metaName:String, rubyName:String}> = [
			{metaName: ":beforeValidation", rubyName: "before_validation"},
			{metaName: ":afterValidation", rubyName: "after_validation"},
			{metaName: ":beforeSave", rubyName: "before_save"},
			{metaName: ":afterSave", rubyName: "after_save"},
			{metaName: ":beforeCreate", rubyName: "before_create"},
			{metaName: ":afterCreate", rubyName: "after_create"},
			{metaName: ":beforeUpdate", rubyName: "before_update"},
			{metaName: ":afterUpdate", rubyName: "after_update"},
			{metaName: ":beforeDestroy", rubyName: "before_destroy"},
			{metaName: ":afterDestroy", rubyName: "after_destroy"},
			{metaName: ":afterCommit", rubyName: "after_commit"},
			{metaName: ":afterRollback", rubyName: "after_rollback"}
		];
		for (callback in callbackPairs) {
			if (meta.extract(callback.metaName).length > 0) {
				names.push(callback.rubyName);
			}
		}
		for (entry in meta.extract(":railsCallback")) {
			if (entry.params != null && entry.params.length > 0) {
				switch (entry.params[0].expr) {
					case EConst(CString(value, _)):
						names.push(RubyNaming.toMethodName(value));
					case _:
				}
			}
		}
		return names;
	}

	static function metadataObjectOptions(expr:haxe.macro.Expr):Array<String> {
		return switch (expr.expr) {
			case EObjectDecl(fields):
				[
					for (field in fields)
						RubyNaming.toMethodName(field.field) + ": " + metadataValueCode(field.expr)
				];
			case _:
				[];
		}
	}

	static function metadataValueCode(expr:haxe.macro.Expr):String {
		return switch (expr.expr) {
			case EConst(CIdent("true")): "true";
			case EConst(CIdent("false")): "false";
			case EConst(CIdent("null")): "nil";
			case EConst(CString(value, _)): quoteRubyStringForCode(value);
			case EConst(CInt(value, _)): value;
			case EConst(CFloat(value, _)): value;
			case EConst(CRegexp(pattern, options)): rubyRegexLiteral(pattern, options);
			case EArrayDecl(values): "[" + [for (value in values) metadataValueCode(value)].join(", ") + "]";
			case EObjectDecl(fields): "{" + [
					for (field in fields)
						RubyNaming.toMethodName(field.field) + ": " + metadataValueCode(field.expr)
				].join(", ") + "}";
			case _: "nil";
		}
	}

	static function rubyRegexLiteral(pattern:String, options:String):String {
		var flags = options == "i" ? "i" : "";
		return "/" + pattern + "/" + flags;
	}

	static function railsColumnBoolOption(meta:Null<haxe.macro.Type.MetaAccess>, name:String, fallback:Bool):Bool {
		var expr = railsColumnOption(meta, name);
		if (expr == null) {
			return fallback;
		}
		return switch (expr.expr) {
			case EConst(CIdent("true")): true;
			case EConst(CIdent("false")): false;
			case _: fallback;
		}
	}

	static function railsColumnStringOption(meta:Null<haxe.macro.Type.MetaAccess>, name:String):Null<String> {
		var expr = railsColumnOption(meta, name);
		if (expr == null) {
			return null;
		}
		return switch (expr.expr) {
			case EConst(CString(value, _)) if (value.length > 0): RubyNaming.toMethodName(value);
			case _: null;
		}
	}

	static function railsColumnValueOption(meta:Null<haxe.macro.Type.MetaAccess>, name:String):Null<String> {
		var expr = railsColumnOption(meta, name);
		return expr == null ? null : metadataValueCode(expr);
	}

	static function railsColumnOption(meta:Null<haxe.macro.Type.MetaAccess>, name:String):Null<haxe.macro.Expr> {
		if (meta == null || meta.extract == null) {
			return null;
		}
		var entries = meta.extract(":railsColumn");
		if (entries.length == 0 || entries[0].params == null || entries[0].params.length == 0) {
			return null;
		}
		return switch (entries[0].params[0].expr) {
			case EObjectDecl(fields):
				var found:Null<haxe.macro.Expr> = null;
				for (field in (fields : Array<RubyMetadataField>)) {
					if (field.field == name) {
						found = field.expr;
						break;
					}
				}
				found;
			case _:
				null;
		}
	}

	static function railsColumnTypeLabel(type:haxe.macro.Type):String {
		return switch (type) {
			case TType(ref, params) if (ref.get().name == "Null" && params.length == 1):
				railsColumnTypeLabel(params[0]);
			case TAbstract(ref, params) if (ref.get().name == "Null" && params.length == 1):
				railsColumnTypeLabel(params[0]);
			case TLazy(lazy):
				railsColumnTypeLabel(lazy());
			case _:
				typeLabel(type);
		}
	}

	static function isNullableType(type:haxe.macro.Type):Bool {
		return switch (type) {
			case TType(ref, _) if (ref.get().name == "Null"): true;
			case TAbstract(ref, _) if (ref.get().name == "Null"): true;
			case TLazy(lazy): isNullableType(lazy());
			case _: false;
		}
	}

	static function railsTypeName(haxeType:String):String {
		return switch (haxeType) {
			case "String": "string";
			case "Bool": "boolean";
			case "Int": "integer";
			case "Float": "float";
			case "Date": "date";
			case "Dynamic": "json";
			case _: RubyNaming.toMethodName(haxeType);
		}
	}

	static function typeLabel(type:haxe.macro.Type):String {
		return switch (type) {
			case TAbstract(ref, _): ref.get().name;
			case TInst(ref, _): ref.get().name;
			case TEnum(ref, _): ref.get().name;
			case TType(ref, _): ref.get().name;
			case TDynamic(_): "Dynamic";
			case TFun(_, _): "Function";
			case TAnonymous(_): "Anonymous";
			case TLazy(lazy): typeLabel(lazy());
			case TMono(_): "Unknown";
		}
	}

	static function rubySymbolLiteral(value:String):String {
		if (isSimpleRubySymbol(value)) {
			return ":" + value;
		}
		var escaped = value == null ? "" : value;
		escaped = StringTools.replace(escaped, "\\", "\\\\");
		escaped = StringTools.replace(escaped, "\"", "\\\"");
		return ":\"" + escaped + "\"";
	}

	static function isRubyBangOrPredicateMethodName(value:String):Bool {
		return value != null && ~/^[a-z_][a-z0-9_]*[!?]$/.match(value);
	}

	static function isSimpleRubySymbol(value:String):Bool {
		if (value == null || value.length == 0) {
			return false;
		}
		var first = value.charCodeAt(0);
		if (!isRubyIdentStart(first)) {
			return false;
		}
		var limit = value.length;
		var last = value.charAt(value.length - 1);
		if (last == "!" || last == "?" || last == "=") {
			limit--;
		}
		for (i in 1...limit) {
			if (!isRubyIdentPart(value.charCodeAt(i))) {
				return false;
			}
		}
		return true;
	}

	static function isRubyIdentStart(code:Int):Bool {
		return code == 95 || (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
	}

	static function isRubyIdentPart(code:Int):Bool {
		return isRubyIdentStart(code) || (code >= 48 && code <= 57);
	}

	static function withLocalNameScope<T>(args:Array<TVar>, build:Void->T):T {
		var previous = localNameScope;
		localNameScope = {names: [], nextByBase: []};
		for (arg in args) {
			localName(arg);
		}
		try {
			var result = build();
			localNameScope = previous;
			return result;
		} catch (e:Dynamic) {
			localNameScope = previous;
			throw e;
		}
	}

	static function localName(v:TVar):String {
		if (localNameScope == null) {
			localNameScope = {names: [], nextByBase: []};
		}
		var existing = localNameScope.names.get(v.id);
		if (existing != null) {
			return existing;
		}
		var base = RubyNaming.toLocalName(v.name);
		var next = localNameScope.nextByBase.exists(base) ? localNameScope.nextByBase.get(base) : 0;
		localNameScope.nextByBase.set(base, next + 1);
		var name = base + "__hx" + Std.string(next);
		localNameScope.names.set(v.id, name);
		return name;
	}

	static function loopIteratorName(v:TVar, iterable:TypedExpr):String {
		var pos = Context.getPosInfos(iterable.pos);
		return "__hx_iter_" + localName(v) + "_" + pos.min;
	}

	static function binopToRuby(op:haxe.macro.Expr.Binop):String {
		return switch (op) {
			case OpAdd: "+";
			case OpSub: "-";
			case OpMult: "*";
			case OpDiv: "/";
			case OpMod: "%";
			case OpEq: "==";
			case OpNotEq: "!=";
			case OpGt: ">";
			case OpGte: ">=";
			case OpLt: "<";
			case OpLte: "<=";
			case OpBoolAnd: "&&";
			case OpBoolOr: "||";
			case OpAnd: "&";
			case OpOr: "|";
			case OpXor: "^";
			case OpShl: "<<";
			case OpShr | OpUShr: ">>";
			case OpAssign: "=";
			case OpAssignOp(inner): binopToRuby(inner);
			case _: "+";
		}
	}

	static function unopToRuby(op:haxe.macro.Expr.Unop):String {
		return switch (op) {
			case OpNot: "!";
			case OpNeg | OpNegBits: "-";
			case OpIncrement | OpDecrement: "";
			case _: "";
		}
	}

	static function printInlineExpr(expr:TypedExpr):String {
		return reflaxe.ruby.ast.RubyASTPrinter.printExpr(compileExpr(expr));
	}

	static function lambdaBody(expr:TypedExpr):String {
		return switch (expr.expr) {
			case TReturn(value):
				value == null ? "nil" : printInlineExpr(value);
			case TBlock(exprs) if (exprs.length > 0):
				lambdaBody(exprs[exprs.length - 1]);
			case _:
				printInlineExpr(expr);
		}
	}

	static function quoteRubyStringForCode(value:String):String {
		var escaped = value == null ? "" : value;
		escaped = StringTools.replace(escaped, "\\", "\\\\");
		escaped = StringTools.replace(escaped, "\"", "\\\"");
		return "\"" + escaped + "\"";
	}

	static function statementToInlineRuby(statement:RubyStatement):String {
		return switch (statement) {
			case RubyExprStatement(expr): reflaxe.ruby.ast.RubyASTPrinter.printExpr(expr);
			case RubyAssign(target, value): reflaxe.ruby.ast.RubyASTPrinter.printExpr(target) + " = " + reflaxe.ruby.ast.RubyASTPrinter.printExpr(value);
			case RubyReturn(value): value == null ? "return" : "return " + reflaxe.ruby.ast.RubyASTPrinter.printExpr(value);
			case RubyIfStmt(cond, thenBody, elseBody):
				var lines = ["if " + reflaxe.ruby.ast.RubyASTPrinter.printExpr(cond)];
				appendIndentedLines(lines, renderStatements(thenBody), 1);
				if (elseBody != null && elseBody.length > 0) {
					lines.push("else");
					appendIndentedLines(lines, renderStatements(elseBody), 1);
				}
				lines.push("end");
				lines.join("\n");
			case RubyWhileStmt(cond, body):
				var lines = ["while " + reflaxe.ruby.ast.RubyASTPrinter.printExpr(cond)];
				appendIndentedLines(lines, renderStatements(body), 1);
				lines.push("end");
				lines.join("\n");
			case RubyRawStatement(code): code;
			case RubyComment(text): "# " + text;
			case _: "# TODO: inline statement";
		}
	}

	static function RubyNilStatement():RubyStatement {
		return RubyExprStatement(RubyNil);
	}
}
#else
class RubyCompiler {
	public function new() {}
}
#end
