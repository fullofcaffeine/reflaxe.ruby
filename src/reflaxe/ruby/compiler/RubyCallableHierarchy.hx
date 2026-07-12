package reflaxe.ruby.compiler;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.FieldAccess;
import reflaxe.ruby.compiler.RubyCallableShape.RubyCallableContract;

/** The declaration that owns one method's effective Ruby callable ABI. **/
typedef EffectiveRubyCallableContract = {
	var field:ClassField;
	var contract:RubyCallableContract;
	var rubyName:String;
	var ownerName:String;
}

private typedef HierarchyCandidate = {
	var effective:EffectiveRubyCallableContract;
}

/**
	Resolves keyword/block/rest metadata as an inherited method contract.

	Haxe does not automatically copy custom metadata onto overrides. Ruby cannot
	afford that loss: a base-typed call and a child-typed call must agree about
	keywords, blocks, splats, and the native method name. This resolver walks the
	class/interface declaration graph once for each use, inherits a single agreed
	shape through unannotated overrides, and fails closed when a declaration tries
	to change an ABI that an ancestor's callers can already observe.
**/
class RubyCallableHierarchy {
	/** Resolves the effective contract visible through a typed field access. **/
	public static function resolveAccess(access:FieldAccess, pos:Position, ?callArgumentTypes:Array<Type>):Null<EffectiveRubyCallableContract> {
		return switch (access) {
			case FInstance(classRef, _, fieldRef):
				resolveInstance(classRef.get(), fieldRef.get().name, pos, callArgumentTypes);
			case FClosure(owner, fieldRef) if (owner != null):
				resolveInstance(owner.c.get(), fieldRef.get().name, pos, callArgumentTypes);
			case FStatic(classRef, fieldRef):
				direct(classRef.get(), fieldRef.get(), pos, callArgumentTypes);
			case FAnon(fieldRef) | FClosure(_, fieldRef):
				var field = fieldRef.get();
				{
					field: field,
					contract: RubyCallableShape.resolve(field, pos, callArgumentTypes),
					rubyName: RubyCallableShape.rubyMethodName(field, pos),
					ownerName: "anonymous callable"
				};
			case FDynamic(_) | FEnum(_, _):
				null;
		}
	}

	/** Resolves an owned definition, including metadata inherited from ancestors. **/
	public static function resolveDefinition(owner:ClassType, field:ClassField, ?diagnosticPos:Position):EffectiveRubyCallableContract {
		var pos = diagnosticPos == null ? field.pos : diagnosticPos;
		var resolved = resolveInstance(owner, field.name, pos, null);
		return resolved == null ? direct(owner, field, pos, null) : resolved;
	}

	/** Resolves a named instance method as seen from `owner`. **/
	public static function resolveInstance(owner:ClassType, fieldName:String, pos:Position,
			?callArgumentTypes:Array<Type>):Null<EffectiveRubyCallableContract> {
		var candidate = resolveCandidate(owner, fieldName, pos, []);
		if (candidate == null) {
			return null;
		}
		var source = candidate.effective;
		return {
			field: source.field,
			contract: RubyCallableShape.resolve(source.field, pos, callArgumentTypes),
			rubyName: source.rubyName,
			ownerName: source.ownerName
		};
	}

	static function resolveCandidate(owner:ClassType, fieldName:String, pos:Position, visiting:Map<String, Bool>):Null<HierarchyCandidate> {
		var key = typeName(owner) + "#" + fieldName;
		if (visiting.exists(key)) {
			return null;
		}
		visiting.set(key, true);

		var inherited:Array<EffectiveRubyCallableContract> = [];
		if (owner.superClass != null) {
			var parent = resolveCandidate(owner.superClass.t.get(), fieldName, pos, visiting);
			if (parent != null) {
				inherited.push(parent.effective);
			}
		}
		if (owner.interfaces != null) {
			for (implemented in owner.interfaces) {
				var parent = resolveCandidate(implemented.t.get(), fieldName, pos, visiting);
				if (parent != null) {
					inherited.push(parent.effective);
				}
			}
		}
		visiting.remove(key);

		var inheritedShape = reconcileInherited(owner, fieldName, inherited, pos);
		var own = ownInstanceField(owner, fieldName);
		if (own == null) {
			return inheritedShape == null ? null : {effective: inheritedShape};
		}

		var ownEffective = direct(owner, own, pos, null);
		if (inheritedShape == null) {
			return {effective: ownEffective};
		}
		// Haxe propagates an ancestor's @:native spelling onto an otherwise
		// unannotated override. That copied name must not make the override look like
		// it deliberately replaced the keyword/block contract.
		var ownsShape = RubyCallableShape.hasRubyCallableShape(own);
		if (!ownsShape) {
			// An ordinary override inherits the already-public Ruby ABI. This is the
			// common ergonomic path: Haxe authors do not repeat compiler metadata.
			return {effective: inheritedShape};
		}
		if (!sameEffectiveShape(ownEffective, inheritedShape)) {
			conflict(owner, fieldName, ownEffective, inheritedShape, pos);
		}
		return {effective: ownEffective};
	}

	static function reconcileInherited(owner:ClassType, fieldName:String, inherited:Array<EffectiveRubyCallableContract>,
			pos:Position):Null<EffectiveRubyCallableContract> {
		if (inherited.length == 0) {
			return null;
		}
		var first = inherited[0];
		for (candidate in inherited.slice(1)) {
			if (!sameEffectiveShape(first, candidate)) {
				conflict(owner, fieldName, first, candidate, pos);
			}
		}
		return first;
	}

	static function direct(owner:ClassType, field:ClassField, pos:Position, callArgumentTypes:Null<Array<Type>>):EffectiveRubyCallableContract {
		return {
			field: field,
			contract: RubyCallableShape.resolve(field, pos, callArgumentTypes),
			rubyName: RubyCallableShape.rubyMethodName(field, pos),
			ownerName: typeName(owner)
		};
	}

	static function ownInstanceField(owner:ClassType, fieldName:String):Null<ClassField> {
		for (field in owner.fields.get()) {
			if (field.name == fieldName) {
				return field;
			}
		}
		return null;
	}

	static function sameEffectiveShape(left:EffectiveRubyCallableContract, right:EffectiveRubyCallableContract):Bool {
		if (left.rubyName != right.rubyName) {
			return false;
		}
		var a = left.contract;
		var b = right.contract;
		if (a.hasKwargs != b.hasKwargs
			|| a.kwargsIndex != b.kwargsIndex
			|| a.hasBlockArg != b.hasBlockArg
			|| a.blockIndex != b.blockIndex
			|| a.blockOptional != b.blockOptional
			|| a.hasRest != b.hasRest
			|| a.restIndex != b.restIndex
			|| a.keywordFields.length != b.keywordFields.length) {
			return false;
		}
		for (leftField in a.keywordFields) {
			var rightField = null;
			for (candidate in b.keywordFields) {
				if (candidate.haxeName == leftField.haxeName) {
					rightField = candidate;
					break;
				}
			}
			// Keyword order is not part of Ruby's ABI. Labels, native mapping, and
			// presence semantics are, so compare those by Haxe field identity.
			if (rightField == null || leftField.rubyName != rightField.rubyName || leftField.optional != rightField.optional) {
				return false;
			}
		}
		return true;
	}

	static function conflict(owner:ClassType, fieldName:String, left:EffectiveRubyCallableContract, right:EffectiveRubyCallableContract, pos:Position):Void {
		Context.error("Ruby callable ABI conflict for `"
			+ typeName(owner)
			+ "."
			+ fieldName
			+ "`: declarations from `"
			+ left.ownerName
			+ "` and `"
			+ right.ownerName
			+ "` disagree about keyword/block/rest shape or native Ruby method name. All static types must expose one identical Ruby call ABI.",
			pos);
	}

	static function typeName(type:ClassType):String {
		return type.pack == null || type.pack.length == 0 ? type.name : type.pack.concat([type.name]).join(".");
	}
}
#end
