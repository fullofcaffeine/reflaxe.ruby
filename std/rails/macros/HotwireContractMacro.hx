package rails.macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

/**
	Builds the declarative RailsHx Hotwire contract and browser-hook surfaces.

	The declaration-only `stream`, `target`, and `row` fields keep the source of
	each fact visible and type-checkable in ordinary Haxe. This macro consumes
	those fields and generates inline typed accessors, so application code cannot
	accidentally mix a row template's locals type with another stream while the
	emitted Ruby remains ordinary Turbo calls with no contract wrapper at runtime.

	This macro intentionally does not infer domain-to-locals mappings or inspect
	rendered HTML itself. Mappings remain explicit application code; target
	existence is proven at the owning view boundary with `@:railsDomTargets(...)`
	for HHX or `StreamTarget.existing(...)` for Rails-owned ERB.

	`@:hotwireHooks` is deliberately separate from the server contract. Its
	stream, target, and explicit readiness selector are safe to import from Haxe
	JavaScript and export to Playwright without pulling server-only models or
	ActionView templates into the browser dependency graph.
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
		var contractMetadata = classType.meta.extract(":hotwireContract");
		var hooksMetadata = classType.meta.extract(":hotwireHooks");
		if (contractMetadata.length == 0 && hooksMetadata.length == 0) {
			return fields;
		}
		if (contractMetadata.length > 0 && hooksMetadata.length > 0) {
			Context.error("@:hotwireContract and @:hotwireHooks own different server/browser declarations and cannot annotate the same class.", classType.pos);
		}
		if (hooksMetadata.length > 0) {
			return buildHooks(fields, classType, hooksMetadata);
		}
		if (contractMetadata.length != 1 || (contractMetadata[0].params != null && contractMetadata[0].params.length != 0)) {
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

	/**
		Consumes the browser-safe declarations and emits typed inline accessors.

		Readiness is explicit because neither a Turbo stream name nor a DOM target
		can prove which browser element represents a connected subscription.
		`targetSelector()` is the only derived fact and retains the declared
		selector type, keeping Haxe-authored and exported Playwright tests aligned.
	**/
	static function buildHooks(fields:Array<Field>, classType:ClassType, metadata:Array<MetadataEntry>):Array<Field> {
		if (metadata.length != 1 || (metadata[0].params != null && metadata[0].params.length != 0)) {
			Context.error("@:hotwireHooks does not accept arguments; declare static final stream, target, and ready fields.", classType.pos);
		}
		if (classType.isExtern || classType.isInterface) {
			Context.error("@:hotwireHooks must annotate a concrete declaration class.", classType.pos);
		}

		var stream = requiredHooksDeclaration(fields, "stream");
		var target = requiredHooksDeclaration(fields, "target");
		var ready = requiredHooksDeclaration(fields, "ready");
		var streamSource = fieldInitializer(stream);
		var targetSource = fieldInitializer(target);
		var readySource = fieldInitializer(ready);
		var streamType = declaredFieldType(stream, "@:hotwireHooks");
		var targetType = declaredFieldType(target, "@:hotwireHooks");
		var selectorType = declaredFieldType(ready, "@:hotwireHooks");

		rejectStringCompatibleSource(stream, "stream", "@:hotwireHooks");
		rejectStringCompatibleSource(target, "target", "@:hotwireHooks");
		rejectStringCompatibleSource(ready, "ready", "@:hotwireHooks");
		requiredHookToken(stream, "stream");
		var targetValue = requiredHookToken(target, "target");
		requiredHookToken(ready, "ready");
		if (!~/^[A-Za-z_][A-Za-z0-9_-]*$/.match(targetValue)) {
			Context.error("@:hotwireHooks `target` must be a selector-safe DOM id containing only letters, digits, `_`, or `-` and starting with a letter or `_`.",
				target.pos);
		}
		reserveHooksGeneratedNames(fields);

		var retained = [
			for (field in fields)
				if (field != stream && field != target && field != ready) field
		];
		retained.push(generatedAccessor("streamName", streamSource, streamType, macro return $e{streamSource}));
		retained.push(generatedAccessor("targetId", targetSource, targetType, macro return $e{targetSource}));
		retained.push(generatedAccessor("targetSelector", targetSource, selectorType, macro return "#" + $e{targetSource}));
		retained.push(generatedAccessor("readySelector", readySource, selectorType, macro return $e{readySource}));
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

	static function requiredHooksDeclaration(fields:Array<Field>, name:String):Field {
		var found:Null<Field> = null;
		for (field in fields) {
			if (field.name == name) {
				if (found != null) {
					Context.error("@:hotwireHooks declares `" + name + "` more than once.", field.pos);
				}
				found = field;
			}
		}
		if (found == null) {
			return Context.error("@:hotwireHooks requires a private static final `" + name + "` declaration.", Context.currentPos());
		}
		if (!hasAccess(found, AStatic) || !hasAccess(found, AFinal) || hasAccess(found, APublic)) {
			Context.error("@:hotwireHooks `" + name + "` must be private static final because the macro replaces it with a typed accessor.", found.pos);
		}
		switch (found.kind) {
			case FVar(type, initializer) if (type != null && initializer != null):
			case _:
				Context.error("@:hotwireHooks `" + name + "` must have an explicit type and value initializer.", found.pos);
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

	static function rejectStringCompatibleSource(field:Field, role:String, owner:String):Void {
		var sourceType = TypeTools.follow(Context.typeof(fieldInitializer(field)));
		switch (sourceType) {
			case TDynamic(_):
				Context.error(owner + " `" + role + "` must be a checked String-compatible token, not Dynamic.", field.pos);
			case _:
		}
		if (!Context.unify(sourceType, Context.getType("String"))) {
			Context.error(owner + " `" + role + "` must be String-compatible.", field.pos);
		}
	}

	static function requiredHookToken(field:Field, role:String):String {
		var value = staticString(fieldInitializer(field));
		if (value == null) {
			return Context.error("@:hotwireHooks `" + role + "` must be a compile-time String token.", field.pos);
		}
		if (value.length == 0) {
			Context.error("@:hotwireHooks `" + role + "` must not be empty.", field.pos);
		}
		return value;
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

	static function reserveHooksGeneratedNames(fields:Array<Field>):Void {
		for (name in ["streamName", "targetId", "targetSelector", "readySelector"]) {
			for (field in fields) {
				if (field.name == name) {
					Context.error("@:hotwireHooks reserves `" + name + "` for its generated typed accessor.", field.pos);
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

	static function declaredFieldType(field:Field, owner:String):ComplexType {
		return switch (field.kind) {
			case FVar(type, _) if (type != null): type;
			case _: Context.error(owner + " declaration is missing its required explicit type.", field.pos);
		}
	}

	static function fieldInitializer(field:Field):Expr {
		return switch (field.kind) {
			case FVar(_, initializer) if (initializer != null): initializer;
			case _: Context.error("@:hotwireContract declaration is missing its required initializer.", field.pos);
		}
	}

	static function staticString(expr:Expr):Null<String> {
		return switch (expr.expr) {
			case EConst(CString(value, _)): value;
			case _:
				typedStaticString(Context.typeExpr(expr));
		}
	}

	static function typedStaticString(expr:TypedExpr):Null<String> {
		return switch (expr.expr) {
			case TConst(TString(value)):
				value;
			case TField(_, FStatic(_, fieldRef)):
				var fieldExpr = fieldRef.get().expr();
				fieldExpr == null ? null : typedStaticString(fieldExpr);
			case TMeta(_, inner) | TParenthesis(inner) | TCast(inner, _):
				typedStaticString(inner);
			case _:
				null;
		}
	}

	static function hasAccess(field:Field, access:Access):Bool {
		return field.access != null && field.access.indexOf(access) != -1;
	}
}
#end
