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
		var nullableSelf:ComplexType = TPath({pack: [], name: "Null", params: [TPType(selfType)]});
		var arraySelf:ComplexType = TPath({pack: [], name: "Array", params: [TPType(selfType)]});

		validateModelMetadata(fields);
		addStub(fields, "where", macro : Dynamic, arraySelf, pos);
		addStub(fields, "create", macro : Dynamic, selfType, pos);
		addNoArgStub(fields, "first", nullableSelf, pos);
		addNoArgStub(fields, "typedColumnCount", macro : Int, pos);
		return fields;
	}

	static function validateModelMetadata(fields:Array<Field>):Void {
		for (field in fields) {
			if (field.meta == null) {
				continue;
			}
			for (meta in field.meta) {
				switch (meta.name) {
					case ":railsColumn":
						if (!isVarField(field)) {
							throw "@:railsColumn can only be used on model fields.";
						}
						validateColumnOptions(field, meta);
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

	static function validateColumnOptions(field:Field, meta:MetadataEntry):Void {
		var params = meta.params;
		if (params == null || params.length == 0) {
			return;
		}
		if (params.length > 1) {
			throw "@:railsColumn expects zero arguments or one options object.";
		}
		switch (params[0].expr) {
			case EObjectDecl(options):
				for (option in options) {
					switch (option.field) {
						case "nullable" | "primaryKey" | "index" | "unique":
							if (!isBoolExpr(option.expr)) {
								throw '@:railsColumn option ${option.field} must be a Bool literal.';
							}
						case "defaultValue":
							validateDefaultValue(field, option.expr);
						case "dbType":
							if (!isStringExpr(option.expr)) {
								throw "@:railsColumn option dbType must be a String literal.";
							}
						case _:
							throw '@:railsColumn unknown option ${option.field}.';
					}
				}
			case _:
				throw "@:railsColumn expects an options object.";
		}
	}

	static function validateDefaultValue(field:Field, expr:Expr):Void {
		var fieldType = fieldTypeName(field);
		switch (fieldType) {
			case "String":
				if (!isStringExpr(expr)) {
					throw "@:railsColumn defaultValue for String fields must be a String literal.";
				}
			case "Bool":
				if (!isBoolExpr(expr)) {
					throw "@:railsColumn defaultValue for Bool fields must be a Bool literal.";
				}
			case "Int":
				if (!isIntExpr(expr)) {
					throw "@:railsColumn defaultValue for Int fields must be an Int literal.";
				}
			case "Float":
				if (!isIntExpr(expr) && !isFloatExpr(expr)) {
					throw "@:railsColumn defaultValue for Float fields must be a numeric literal.";
				}
			case _:
		}
	}

	static function fieldTypeName(field:Field):String {
		return switch (field.kind) {
			case FVar(t, _) | FProp(_, _, t, _):
				complexTypeName(t);
			case _:
				"";
		}
	}

	static function complexTypeName(type:Null<ComplexType>):String {
		return switch (type) {
			case TPath(path):
				if (path.name == "Null" && path.params != null && path.params.length == 1) {
					switch (path.params[0]) {
						case TPType(inner): complexTypeName(inner);
						case _: path.name;
					}
				} else {
					path.name;
				}
			case _:
				"";
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

	static function isBoolExpr(expr:Expr):Bool {
		return switch (expr.expr) {
			case EConst(CIdent("true" | "false")): true;
			case _: false;
		}
	}

	static function isIntExpr(expr:Expr):Bool {
		return switch (expr.expr) {
			case EConst(CInt(_, _)): true;
			case _: false;
		}
	}

	static function isFloatExpr(expr:Expr):Bool {
		return switch (expr.expr) {
			case EConst(CFloat(_, _)): true;
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

	static function addNoArgStub(fields:Array<Field>, name:String, ret:ComplexType, pos:Position):Void {
		for (field in fields) {
			if (field.name == name) {
				return;
			}
		}
		fields.push({
			name: name,
			access: [APublic, AStatic],
			kind: FFun({
				args: [],
				ret: ret,
				expr: macro return cast null
			}),
			meta: [
				{name: ":rubyExternStub", params: [], pos: pos}
			],
			pos: pos
		});
	}
}
#else
class ModelMacro {}
#end
