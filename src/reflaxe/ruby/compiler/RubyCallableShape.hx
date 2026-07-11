package reflaxe.ruby.compiler;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.MethodKind;
import haxe.macro.TypeTools;

/**
	The validated Ruby call ABI attached to one Haxe method declaration.

	Indices refer to the original Haxe parameter list. Later lowering stages use
	them to remove the carrier parameters and render Ruby keyword/block syntax
	without rediscovering metadata or guessing from an expression's shape.
**/
typedef RubyCallableContract = {
	var hasKwargs:Bool;
	var kwargsIndex:Int;
	var hasBlockArg:Bool;
	var blockIndex:Int;
	var blockOptional:Bool;
}

private typedef RubyCallableParameter = {
	var name:String;
	var opt:Bool;
	var t:Type;
}

/**
	Extracts and validates the metadata that changes a method's Ruby call ABI.

	This validator is deliberately independent from expression rendering. Both
	extern call sites and Haxe-owned method definitions must consult the same
	contract, otherwise a declaration can emit one signature while its callers
	emit another. Diagnostics point at the declaration because that is where the
	invalid ABI promise originates.
**/
class RubyCallableShape {
	static final RUBY_OPERATOR_METHODS = [
		"[]", "[]=", "<=>", "==", "===", "!=", "=~", "!~", "+", "-", "*", "/", "%", "**", "<<", ">>", "&", "|", "^", "~", "~@", "<", "<=", ">", ">=", "+@",
		"-@", "!", "!@", "`"
	];

	public static function hasCallableMetadata(field:ClassField):Bool {
		return hasMeta(field, ":rubyKwargs") || hasMeta(field, ":rubyBlockArg");
	}

	public static function resolve(field:ClassField, ?diagnosticPos:Position, ?callArgumentTypes:Array<Type>):RubyCallableContract {
		var pos = diagnosticPos == null ? field.pos : diagnosticPos;
		var declaredKwargs = validateMarker(field, ":rubyKwargs", pos);
		var hasBlockArg = validateMarker(field, ":rubyBlockArg", pos);
		validateNativeFieldName(field, pos);
		var generatedOverloadCall = callArgumentTypes != null && hasMeta(field, ":rubyExternStub");
		var hasKwargs = declaredKwargs;
		if (generatedOverloadCall && hasKwargs) {
			var callKwargsIndex = callArgumentTypes.length - (hasBlockArg ? 2 : 1);
			// Haxe retains metadata from the generated overload family on the
			// selected field. Activate kwargs only for the overload invocation that
			// actually supplies the typed carrier; positional overloads stay
			// positional. User-authored declarations never receive this exception.
			hasKwargs = callKwargsIndex >= 0 && isKeywordCarrierType(callArgumentTypes[callKwargsIndex]);
		}

		var empty:RubyCallableContract = {
			hasKwargs: false,
			kwargsIndex: -1,
			hasBlockArg: false,
			blockIndex: -1,
			blockOptional: false
		};
		if (!hasKwargs && !hasBlockArg) {
			return empty;
		}

		switch (field.kind) {
			case FMethod(MethDynamic):
				Context.error(callableMetadataNames(hasKwargs, hasBlockArg)
					+ " cannot be used on a Haxe dynamic method because rebinding would lose the declared Ruby call ABI.",
					pos);
			case FMethod(_):
			case _:
				Context.error(callableMetadataNames(hasKwargs, hasBlockArg) + " is valid only on a method declaration.", pos);
		}

		var signatures = functionSignatures(field);
		if (generatedOverloadCall) {
			signatures.unshift([
				for (index in 0...callArgumentTypes.length)
					{name: "arg" + index, opt: false, t: callArgumentTypes[index]}
			]);
		}
		if (signatures.length == 0) {
			Context.error(callableMetadataNames(hasKwargs, hasBlockArg) + " requires a statically typed Haxe function signature.", pos);
		}
		var blockCandidates = hasBlockArg ? [
			for (args in signatures)
				if (args.length > 0 && isFunctionType(args[args.length - 1].t)) args
		] : signatures;
		if (hasBlockArg && blockCandidates.length == 0) {
			Context.error("@:rubyBlockArg on method `"
				+ field.name
				+ "` requires the final Haxe parameter of at least one overload to have a precise function type such as `Value->Result`.",
				pos);
		}
		var compatible = hasKwargs ? [
			for (args in blockCandidates)
				if (keywordCarrierIndex(args, hasBlockArg) >= 0
					&& isKeywordCarrierType(args[keywordCarrierIndex(args, hasBlockArg)].t)) args
		] : blockCandidates;
		if (hasKwargs && compatible.length == 0) {
			var location = hasBlockArg ? "immediately before the final block parameter" : "as the final Haxe parameter";
			Context.error("@:rubyKwargs on method `" + field.name + "` requires a typed anonymous-object/typedef carrier " + location
				+ ". Available overloads: " + signatureLabels(blockCandidates) + ".",
				pos);
		}
		var args = compatible[0];
		var blockIndex = hasBlockArg ? args.length - 1 : -1;
		var kwargsIndex = hasKwargs ? keywordCarrierIndex(args, hasBlockArg) : -1;
		var blockOptional = hasBlockArg && args[blockIndex].opt;

		return {
			hasKwargs: hasKwargs,
			kwargsIndex: kwargsIndex,
			hasBlockArg: hasBlockArg,
			blockIndex: blockIndex,
			blockOptional: blockOptional
		};
	}

	static function validateMarker(field:ClassField, name:String, pos:Position):Bool {
		if (field.meta == null || field.meta.extract == null) {
			return false;
		}
		var entries = field.meta.extract(name);
		if (entries.length == 0) {
			return false;
		}
		if (entries.length != 1) {
			Context.error("@" + name + " may appear only once on method `" + field.name + "`.", pos);
		}
		if (entries[0].params != null && entries[0].params.length != 0) {
			Context.error("@"
				+ name
				+ " on method `"
				+ field.name
				+ "` does not accept arguments; its typed Haxe parameter declares the contract.",
				entries[0].pos);
		}
		return true;
	}

	public static function validateNativeFieldName(field:ClassField, ?diagnosticPos:Position):Void {
		var pos = diagnosticPos == null ? field.pos : diagnosticPos;
		if (field.meta == null || field.meta.extract == null) {
			return;
		}
		var entries = field.meta.extract(":native");
		if (entries.length == 0) {
			return;
		}
		if (entries.length != 1 || entries[0].params == null || entries[0].params.length != 1) {
			Context.error("Field-level @:native requires exactly one non-empty Ruby method-name string.", pos);
		}
		var nativeName = switch (entries[0].params[0].expr) {
			case EConst(CString(value, _)) if (value.length > 0): value;
			case _:
				Context.error("Field-level @:native requires exactly one non-empty Ruby method-name string.", entries[0].pos);
				"";
		};
		if (!isValidRubyMethodName(nativeName)) {
			Context.error('@:native("'
				+ nativeName
				+ '") on Haxe field `'
				+ field.name
				+ '` is not a valid Ruby method name. Use an identifier with an optional `?`, `!`, or `=` suffix, or a supported Ruby operator.',
				entries[0].pos);
		}
	}

	static function isFunctionType(type:haxe.macro.Type):Bool {
		return switch (TypeTools.follow(type)) {
			case TFun(_, _): true;
			case _: false;
		}
	}

	static function functionSignatures(field:ClassField):Array<Array<RubyCallableParameter>> {
		var types = [field.type];
		if (field.overloads != null) {
			var overloadFields = field.overloads.get();
			for (overloadField in overloadFields) {
				types.push(overloadField.type);
			}
		}
		var signatures:Array<Array<RubyCallableParameter>> = [];
		for (type in types) {
			switch (TypeTools.follow(type)) {
				case TFun(args, _):
					signatures.push(args);
				case _:
			}
		}
		return signatures;
	}

	static function keywordCarrierIndex(args:Array<RubyCallableParameter>, hasBlockArg:Bool):Int {
		return args.length - (hasBlockArg ? 2 : 1);
	}

	static function signatureLabels(signatures:Array<Array<RubyCallableParameter>>):String {
		if (signatures.length == 0) {
			return "none";
		}
		return [
			for (args in signatures)
				"(" + [for (arg in args) TypeTools.toString(arg.t)].join(", ") + ")"
		].join(" or ");
	}

	static function isKeywordCarrierType(type:haxe.macro.Type):Bool {
		return switch (TypeTools.follow(type)) {
			case TAnonymous(_): true;
			case _: false;
		}
	}

	static function isValidRubyMethodName(value:String):Bool {
		if (RUBY_OPERATOR_METHODS.indexOf(value) != -1) {
			return true;
		}
		if (value == null || value.length == 0) {
			return false;
		}
		return ~/^[A-Za-z_][A-Za-z0-9_]*[!?=]?$/.match(value);
	}

	static function callableMetadataNames(hasKwargs:Bool, hasBlockArg:Bool):String {
		if (hasKwargs && hasBlockArg) {
			return "@:rubyKwargs and @:rubyBlockArg";
		}
		return hasKwargs ? "@:rubyKwargs" : "@:rubyBlockArg";
	}

	static function hasMeta(field:ClassField, name:String):Bool {
		return field.meta != null && field.meta.has != null && field.meta.has(name);
	}
}
#end
