package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class ModelMacro {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var cls = Context.getLocalClass().get();
		var pos = Context.currentPos();
		var selfType:ComplexType = TPath({pack: cls.pack, name: cls.name});
		var arraySelf:ComplexType = TPath({pack: [], name: "Array", params: [TPType(selfType)]});

		validateModelMetadata(fields);
		addStub(fields, "where", macro : Dynamic, arraySelf, pos);
		addStub(fields, "create", macro : Dynamic, selfType, pos);
		return fields;
	}

	static function validateModelMetadata(fields:Array<Field>):Void {
		for (field in fields) {
			if (field.meta == null) {
				continue;
			}
			for (meta in field.meta) {
				switch (meta.name) {
					case ":belongsTo" | ":hasMany" | ":hasOne":
						if (!isVarField(field)) {
							throw meta.name + " can only be used on model fields.";
						}
					case ":validates":
						if (!isVarField(field)) {
							throw "@:validates can only be used on model fields.";
						}
						if (!hasValidValidationArgs(meta.params)) {
							throw "@:validates expects an options object, or a field name followed by an options object.";
						}
					case _:
				}
			}
		}
	}

	static function isVarField(field:Field):Bool {
		return switch (field.kind) {
			case FVar(_, _): true;
			case _: false;
		}
	}

	static function hasValidValidationArgs(params:Null<Array<Expr>>):Bool {
		if (params == null || params.length == 0) {
			return false;
		}
		if (params.length == 1) {
			return isObjectExpr(params[0]);
		}
		return isStringExpr(params[0]) && isObjectExpr(params[1]);
	}

	static function isObjectExpr(expr:Expr):Bool {
		return switch (expr.expr) {
			case EObjectDecl(_): true;
			case _: false;
		}
	}

	static function isStringExpr(expr:Expr):Bool {
		return switch (expr.expr) {
			case EConst(CString(_, _)): true;
			case _: false;
		}
	}

	static function addStub(fields:Array<Field>, name:String, argType:ComplexType, ret:ComplexType, pos:Position):Void {
		for (field in fields) {
			if (field.name == name) {
				return;
			}
		}
		fields.push({
			name: name,
			access: [APublic, AStatic],
			kind: FFun({
				args: [{name: "attrs", type: argType}],
				ret: ret,
				expr: macro return cast null
			}),
			meta: [
				{name: ":native", params: [macro $v{name}], pos: pos},
				{name: ":rubyKwargs", params: [], pos: pos},
				{name: ":rubyExternStub", params: [], pos: pos}
			],
			pos: pos
		});
	}
}
#else
class ModelMacro {}
#end
