package rails.macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

/**
	Builds the first declarative RailsHx Hotwire contract surface.

	The declaration-only `stream`, `target`, and `row` fields keep the source of
	each fact visible and type-checkable in ordinary Haxe. This macro consumes
	those fields and generates inline typed accessors, so application code cannot
	accidentally mix a row template's locals type with another stream while the
	emitted Ruby remains ordinary Turbo calls with no contract wrapper at runtime.

	This macro intentionally does not infer domain-to-locals mappings or inspect
	rendered HTML itself. Mappings remain explicit application code; target
	existence is proven at the owning view boundary with `@:railsDomTargets(...)`
	for HHX or `StreamTarget.existing(...)` for Rails-owned ERB.
**/
class HotwireContractMacro {
	static var enabled = false;

	/**
		Attach the build macro to reachable types in both Ruby and RailsHx client
		compilations. Non-contract types return unchanged, which lets one annotation
		work in shared source without coupling the Ruby compiler to an app class.
	**/
	public static function enable():Void {
		if (enabled) {
			return;
		}
		enabled = true;
		Compiler.addGlobalMetadata("", "@:build(rails.macros.HotwireContractMacro.build())", true, true, false);
	}

	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var localClass = Context.getLocalClass();
		if (localClass == null) {
			return fields;
		}
		var classType = localClass.get();
		var metadata = classType.meta.extract(":hotwireContract");
		if (metadata.length == 0) {
			return fields;
		}
		if (metadata.length != 1 || (metadata[0].params != null && metadata[0].params.length != 0)) {
			Context.error("@:hotwireContract does not accept arguments; declare static final stream, target, and row fields.", classType.pos);
		}
		if (classType.isExtern || classType.isInterface) {
			Context.error("@:hotwireContract must annotate a concrete declaration class.", classType.pos);
		}

		var stream = requiredDeclaration(fields, "stream");
		var target = requiredDeclaration(fields, "target");
		var row = requiredDeclaration(fields, "row");
		var localsType = templateLocalsType(row);
		var streamSource = fieldInitializer(stream);
		var targetSource = fieldInitializer(target);
		var rowSource = fieldInitializer(row);

		rejectDynamicSource(stream, "stream");
		rejectDynamicSource(target, "target");
		reserveGeneratedNames(fields);

		var retained = [
			for (field in fields)
				if (field != stream && field != target && field != row) field
		];
		retained.push(generatedAccessor("streamName", streamSource, streamNameType(localsType), macro return rails.turbo.StreamName.named($e{streamSource})));
		retained.push(generatedAccessor("streamTarget", targetSource, macro :rails.turbo.StreamTarget,
			macro return rails.turbo.StreamTarget.named($e{targetSource})));
		retained.push(generatedAccessor("rowTemplate", rowSource, templateType(localsType), macro return $e{rowSource}));
		return retained;
	}

	static function requiredDeclaration(fields:Array<Field>, name:String):Field {
		var found:Null<Field> = null;
		for (field in fields) {
			if (field.name == name) {
				if (found != null) {
					Context.error("@:hotwireContract declares `" + name + "` more than once.", field.pos);
				}
				found = field;
			}
		}
		if (found == null) {
			return Context.error("@:hotwireContract requires a private static final `" + name + "` declaration.", Context.currentPos());
		}
		if (!hasAccess(found, AStatic) || !hasAccess(found, AFinal) || hasAccess(found, APublic)) {
			Context.error("@:hotwireContract `" + name + "` must be private static final because the macro replaces it with a typed accessor.", found.pos);
		}
		switch (found.kind) {
			case FVar(_, initializer) if (initializer != null):
			case _:
				Context.error("@:hotwireContract `" + name + "` must have a value initializer.", found.pos);
		}
		return found;
	}

	/**
		The row annotation is the single durable owner of `TLocals`. Requiring an
		explicit `Template<TLocals>` avoids guessing from object literals or keeping
		an untyped expression for later compiler/emitter re-analysis.
	**/
	static function templateLocalsType(row:Field):ComplexType {
		var declaredType = switch (row.kind) {
			case FVar(type, _): type;
			case _: null;
		}
		if (declaredType == null) {
			return Context.error("@:hotwireContract `row` must declare Template<TLocals> explicitly.", row.pos);
		}
		var resolved = TypeTools.follow(Context.resolveType(declaredType, row.pos));
		return switch (resolved) {
			case TInst(ref, [locals]) if (ref.get().pack.join(".") == "rails.action_view" && ref.get().name == "Template"):
				rejectUnsafeLocalsType(locals, row.pos);
				var complex = TypeTools.toComplexType(locals);
				complex == null ? Context.error("@:hotwireContract could not preserve the row Template<TLocals> type.", row.pos) : complex;
			case _:
				Context.error("@:hotwireContract `row` must be declared as rails.action_view.Template<TLocals>.", row.pos);
		}
	}

	static function rejectUnsafeLocalsType(locals:Type, pos:Position):Void {
		switch (TypeTools.follow(locals)) {
			case TDynamic(_):
				Context.error("@:hotwireContract row locals must be a precise type, not Dynamic.", pos);
			case TAbstract(ref, _) if (ref.get().pack.length == 0 && ref.get().name == "Any"):
				Context.error("@:hotwireContract row locals must be a precise type, not Any.", pos);
			case _:
		}
	}

	static function rejectDynamicSource(field:Field, role:String):Void {
		var sourceType = TypeTools.follow(Context.typeof(fieldInitializer(field)));
		switch (sourceType) {
			case TDynamic(_):
				Context.error("@:hotwireContract `" + role + "` must be a checked String-compatible token, not Dynamic.", field.pos);
			case _:
		}
		if (!Context.unify(sourceType, Context.getType("String"))) {
			Context.error("@:hotwireContract `" + role + "` must be String-compatible.", field.pos);
		}
	}

	static function reserveGeneratedNames(fields:Array<Field>):Void {
		for (name in ["streamName", "streamTarget", "rowTemplate"]) {
			for (field in fields) {
				if (field.name == name) {
					Context.error("@:hotwireContract reserves `" + name + "` for its generated typed accessor.", field.pos);
				}
			}
		}
	}

	static function generatedAccessor(name:String, source:Expr, returnType:ComplexType, body:Expr):Field {
		return {
			name: name,
			access: [APublic, AStatic, AInline],
			kind: FFun({
				args: [],
				ret: returnType,
				expr: body
			}),
			meta: [
				{
					name: ":hotwireContractGenerated",
					params: [],
					pos: source.pos
				}
			],
			pos: source.pos
		};
	}

	static function streamNameType(localsType:ComplexType):ComplexType {
		return TPath({
			pack: ["rails", "turbo"],
			name: "StreamName",
			params: [TPType(localsType)]
		});
	}

	static function templateType(localsType:ComplexType):ComplexType {
		return TPath({
			pack: ["rails", "action_view"],
			name: "Template",
			params: [TPType(localsType)]
		});
	}

	static function fieldInitializer(field:Field):Expr {
		return switch (field.kind) {
			case FVar(_, initializer) if (initializer != null): initializer;
			case _: Context.error("@:hotwireContract declaration is missing its required initializer.", field.pos);
		}
	}

	static function hasAccess(field:Field, access:Access):Bool {
		return field.access != null && field.access.indexOf(access) != -1;
	}
}
#end
