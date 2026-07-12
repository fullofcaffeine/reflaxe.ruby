package reflaxe.ruby.compiler;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.MethodKind;
import haxe.macro.TypeTools;
import reflaxe.ruby.naming.RubyNaming;

/** One field in the typed anonymous-object carrier used for Ruby keywords. **/
typedef RubyKeywordFieldContract = {
	var haxeName:String;
	var rubyName:String;
	var optional:Bool;
}

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
	var keywordFields:Array<RubyKeywordFieldContract>;
	var hasRest:Bool;
	var restIndex:Int;
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

	/**
		Returns the validated Ruby method spelling for one declaration.

		Hierarchy resolution uses this alongside the keyword/block shape. A native
		name is part of the callable ABI: inheriting block behavior but silently
		changing `visit!` back to `visit` would make base-typed and child-typed calls
		dispatch to different Ruby methods.
	**/
	public static function rubyMethodName(field:ClassField, ?diagnosticPos:Position):String {
		var pos = diagnosticPos == null ? field.pos : diagnosticPos;
		validateNativeFieldName(field, pos);
		if (field.meta == null || field.meta.extract == null) {
			return RubyNaming.toMethodName(field.name);
		}
		var entries = field.meta.extract(":native");
		if (entries.length == 0) {
			return RubyNaming.toMethodName(field.name);
		}
		return switch (entries[0].params[0].expr) {
			case EConst(CString(value, _)): value;
			case _: RubyNaming.toMethodName(field.name);
		}
	}

	/** True when a call needs structured keyword, block, or rest lowering. **/
	public static function hasRubyCallableShape(field:ClassField):Bool {
		if (hasCallableMetadata(field)) {
			return true;
		}
		for (signature in functionSignatures(field)) {
			if (signatureHasRest(signature)) {
				return true;
			}
		}
		return false;
	}

	public static function resolve(field:ClassField, ?diagnosticPos:Position, ?callArgumentTypes:Array<Type>):RubyCallableContract {
		var pos = diagnosticPos == null ? field.pos : diagnosticPos;
		var declaredKwargs = validateMarker(field, ":rubyKwargs", pos);
		var hasBlockArg = validateMarker(field, ":rubyBlockArg", pos);
		validateNativeFieldName(field, pos);
		var signatures = functionSignatures(field);
		var declaresRest = false;
		for (signature in signatures) {
			if (signatureHasRest(signature)) {
				declaresRest = true;
				break;
			}
		}
		if (declaresRest && (declaredKwargs || hasBlockArg)) {
			Context.error(callableMetadataNames(declaredKwargs, hasBlockArg)
				+
				" cannot be combined with a final haxe.Rest parameter. Haxe requires Rest to be final, while Ruby keyword/block carriers occupy the trailing ABI positions; declare a narrower typed facade for that native shape.",
				pos);
		}
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
			blockOptional: false,
			keywordFields: [],
			hasRest: false,
			restIndex: -1
		};
		if (!hasKwargs && !hasBlockArg && !declaresRest) {
			return empty;
		}

		switch (field.kind) {
			case FMethod(MethDynamic):
				Context.error(callableContractNames(hasKwargs, hasBlockArg, declaresRest)
					+ " cannot be used on a Haxe dynamic method because rebinding would lose the declared Ruby call ABI.",
					pos);
			case FMethod(_):
			case _:
				Context.error(callableContractNames(hasKwargs, hasBlockArg, declaresRest) + " is valid only on a method declaration.", pos);
		}

		if (generatedOverloadCall) {
			signatures.unshift([
				for (index in 0...callArgumentTypes.length)
					{name: "arg" + index, opt: false, t: callArgumentTypes[index]}
			]);
		}
		if (signatures.length == 0) {
			Context.error(callableContractNames(hasKwargs, hasBlockArg, declaresRest) + " requires a statically typed Haxe function signature.", pos);
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
		if (hasKwargs && args[kwargsIndex].opt) {
			Context.error("@:rubyKwargs carrier `"
				+ args[kwargsIndex].name
					+ "` on method `"
					+ field.name
					+ "` must be required. Put optionality on individual carrier fields so omission and explicit null remain distinguishable.",
				pos);
		}
		var keywordFields = hasKwargs ? keywordFieldContracts(args[kwargsIndex].t, field.name, pos) : [];
		var hasRest = signatureHasRest(args);
		var restIndex = hasRest ? args.length - 1 : -1;

		return {
			hasKwargs: hasKwargs,
			kwargsIndex: kwargsIndex,
			hasBlockArg: hasBlockArg,
			blockIndex: blockIndex,
			blockOptional: blockOptional,
			keywordFields: keywordFields,
			hasRest: hasRest,
			restIndex: restIndex
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

	/** Recognizes Haxe's native rest contract without following away the abstract. **/
	public static function isRestType(type:haxe.macro.Type):Bool {
		return switch (type) {
			case TAbstract(ref, _): var abstractType = ref.get(); abstractType.pack.join(".") == "haxe" && abstractType.name == "Rest";
			case TType(ref, _): var defType = ref.get(); defType.pack.join(".") == "haxe.extern" && defType.name == "Rest";
			case TMono(ref): var resolved = ref.get(); resolved != null && isRestType(resolved);
			case TLazy(resolve): isRestType(resolve());
			case _: false;
		}
	}

	static function signatureHasRest(args:Array<RubyCallableParameter>):Bool {
		return args.length > 0 && isRestType(args[args.length - 1].t);
	}

	/**
		Extracts the keyword schema once from the declared carrier type.

		Ruby keyword labels are intentionally stricter than method names: predicate,
		bang, writer, and operator spellings are valid methods but cannot bind normal
		keyword locals. Rejecting them here keeps both calls and owned definitions on
		the same ABI instead of quoting one side or falling back to a loose hash.
	**/
	static function keywordFieldContracts(type:haxe.macro.Type, methodName:String, pos:Position):Array<RubyKeywordFieldContract> {
		var anonymous = switch (TypeTools.follow(type)) {
			case TAnonymous(ref): ref.get();
			case _:
				Context.error("@:rubyKwargs on method `" + methodName + "` requires an anonymous-object/typedef carrier.", pos);
				return [];
		}
		var fields:Array<RubyKeywordFieldContract> = [];
		var rubyNames = new Map<String, String>();
		for (field in anonymous.fields) {
			var nativeName = keywordNativeName(field, methodName, pos);
			var rubyName = nativeName == null ? RubyNaming.toMethodName(field.name) : nativeName;
			if (!~/^[A-Za-z_][A-Za-z0-9_]*$/.match(rubyName)) {
				Context.error('@:native("'
					+ rubyName
					+ '") on keyword field `'
					+ field.name
					+ '` for method `'
					+ methodName
					+ '` is not a valid Ruby keyword label. Use a plain Ruby identifier without `?`, `!`, or `=`.',
					field.pos);
			}
			if (rubyNames.exists(rubyName)) {
				Context.error("Keyword fields `" + rubyNames.get(rubyName) + "` and `" + field.name + "` on method `" + methodName
					+ "` both lower to Ruby keyword `" + rubyName + "`.",
					field.pos);
			}
			rubyNames.set(rubyName, field.name);
			fields.push({
				haxeName: field.name,
				rubyName: rubyName,
				optional: hasMeta(field, ":optional")
			});
		}
		return fields;
	}

	static function keywordNativeName(field:ClassField, methodName:String, pos:Position):Null<String> {
		if (field.meta == null || field.meta.extract == null) {
			return null;
		}
		var entries = field.meta.extract(":native");
		if (entries.length == 0) {
			return null;
		}
		if (entries.length != 1 || entries[0].params == null || entries[0].params.length != 1) {
			Context.error("Keyword field `" + field.name + "` on method `" + methodName + "` requires exactly one non-empty @:native string.", pos);
		}
		return switch (entries[0].params[0].expr) {
			case EConst(CString(value, _)) if (value.length > 0): value;
			case _:
				Context.error("Keyword field `" + field.name + "` on method `" + methodName + "` requires exactly one non-empty @:native string.",
					entries[0].pos);
				return null;
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

	static function callableContractNames(hasKwargs:Bool, hasBlockArg:Bool, hasRest:Bool):String {
		return hasKwargs
			|| hasBlockArg ? callableMetadataNames(hasKwargs, hasBlockArg) : hasRest ? "A final haxe.Rest parameter" : "Ruby callable metadata";
	}

	static function hasMeta(field:ClassField, name:String):Bool {
		return field.meta != null && field.meta.has != null && field.meta.has(name);
	}
}
#end
