package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import reflaxe.ruby.naming.RubyNaming;

class ModelMacro {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var cls = Context.getLocalClass().get();
		var pos = Context.currentPos();
		var selfType:ComplexType = TPath({pack: cls.pack, name: cls.name});
		var nullableSelf:ComplexType = TPath({pack: [], name: "Null", params: [TPType(selfType)]});
		var criteriaType = criteriaComplexType(fields);

		validateModelMetadata(fields);
		addModelFieldRefs(fields, selfType, cls.name, pos);
		addModelAssociationRefs(fields, selfType, pos);
		addStub(fields, "where", criteriaType, relationComplexType(selfType, criteriaType, pos), pos);
		addPlainStub(fields, "includes", associationComplexType(selfType, macro : Dynamic), relationComplexType(selfType, criteriaType, pos), "association", pos);
		addPlainStub(fields, "joins", associationComplexType(selfType, macro : Dynamic), relationComplexType(selfType, criteriaType, pos), "association", pos);
		addStub(fields, "find", primaryKeyComplexType(fields), selfType, pos);
		addStub(fields, "findBy", criteriaType, nullableSelf, pos);
		addStub(fields, "create", macro : Dynamic, selfType, pos);
		addNoArgStub(fields, "first", nullableSelf, pos);
		addNoArgStub(fields, "typedColumnCount", macro : Int, pos);
		return fields;
	}

	static function addModelFieldRefs(fields:Array<Field>, selfType:ComplexType, className:String, pos:Position):Void {
		var paramKey = "railsParamKey";
		if (!hasFieldNamed(fields, paramKey)) {
			var paramKeyType:ComplexType = TPath({
				pack: ["rails", "active_record"],
				name: "ModelKey",
				params: [TPType(selfType)]
			});
			fields.push({
				name: paramKey,
				access: [APublic, AStatic, AInline, AFinal],
				kind: FVar(paramKeyType, macro rails.active_record.ModelKey.named($v{RubyNaming.toLocalName(className)})),
				pos: pos
			});
		}
		var columnFields = [for (field in fields.copy()) if (isRailsColumn(field)) field];
		if (columnFields.length > 0) {
			addFieldsObject(fields, "fields", columnFields, selfType, pos);
			addFieldsObject(fields, "f", columnFields, selfType, pos);
		}
		for (field in columnFields) {
			if (!isRailsColumn(field)) {
				continue;
			}
			var refName = field.name + "Field";
			if (hasFieldNamed(fields, refName)) {
				continue;
			}
			var fieldType = fieldValueType(field);
			var refType:ComplexType = TPath({
				pack: ["rails", "active_record"],
				name: "Field",
				params: [TPType(selfType), TPType(fieldType)]
			});
			fields.push({
				name: refName,
				access: [APublic, AStatic, AInline, AFinal],
				kind: FVar(refType, macro rails.active_record.Field.named($v{field.name})),
				meta: [{name: ":railsField", params: [macro $v{field.name}], pos: pos}],
				pos: pos
			});
		}
	}

	static function addModelAssociationRefs(fields:Array<Field>, selfType:ComplexType, pos:Position):Void {
		var associationFields = [for (field in fields.copy()) if (isRailsAssociation(field)) field];
		if (associationFields.length == 0) {
			return;
		}
		addAssociationsObject(fields, "associations", associationFields, selfType, pos);
		addAssociationsObject(fields, "a", associationFields, selfType, pos);
	}

	static function addAssociationsObject(fields:Array<Field>, name:String, associationFields:Array<Field>, selfType:ComplexType, pos:Position):Void {
		if (hasFieldNamed(fields, name)) {
			return;
		}
		var objectFields:Array<Field> = [];
		var values:Array<ObjectField> = [];
		for (field in associationFields) {
			var targetType = associationTargetType(field);
			var assocType = associationComplexType(selfType, targetType);
			objectFields.push({
				name: field.name,
				access: [],
				kind: FVar(assocType, null),
				meta: [{name: ":railsAssociation", params: [macro $v{field.name}], pos: pos}],
				pos: pos
			});
			values.push({
				field: field.name,
				expr: macro rails.active_record.Association.named($v{field.name})
			});
		}
		fields.push({
			name: name,
			access: [APublic, AStatic, AFinal],
			kind: FVar(TAnonymous(objectFields), {expr: EObjectDecl(values), pos: pos}),
			pos: pos
		});
	}

	static function addFieldsObject(fields:Array<Field>, name:String, columnFields:Array<Field>, selfType:ComplexType, pos:Position):Void {
		if (hasFieldNamed(fields, name)) {
			return;
		}
		var objectFields:Array<Field> = [];
		var values:Array<ObjectField> = [];
		for (field in columnFields) {
			var fieldType = typedFieldComplexType(selfType, fieldValueType(field));
			objectFields.push({
				name: field.name,
				access: [],
				kind: FVar(fieldType, null),
				meta: [{name: ":railsField", params: [macro $v{field.name}], pos: pos}],
				pos: pos
			});
			values.push({
				field: field.name,
				expr: macro rails.active_record.Field.named($v{field.name})
			});
		}
		fields.push({
			name: name,
			access: [APublic, AStatic, AFinal],
			kind: FVar(TAnonymous(objectFields), {expr: EObjectDecl(values), pos: pos}),
			pos: pos
		});
	}

	static function typedFieldComplexType(selfType:ComplexType, fieldType:ComplexType):ComplexType {
		return TPath({
			pack: ["rails", "active_record"],
			name: "Field",
			params: [TPType(selfType), TPType(fieldType)]
		});
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
		validateAssociationMetadata(fields);
	}

	static function validateAssociationMetadata(fields:Array<Field>):Void {
		for (field in fields) {
			if (!isRailsAssociation(field)) {
				continue;
			}
			var associationMeta = associationMetaName(field);
			var target = associationTargetType(field);
			validateAssociationTarget(field, target, associationMeta);
			if (associationMeta == ":belongsTo") {
				validateBelongsToForeignKey(field, fields);
			}
		}
	}

	static function associationMetaName(field:Field):String {
		if (field.meta == null) {
			return "";
		}
		for (meta in field.meta) {
			switch (meta.name) {
				case ":belongsTo" | ":hasMany" | ":hasOne":
					return meta.name;
				case _:
			}
		}
		return "";
	}

	static function validateAssociationTarget(field:Field, target:ComplexType, associationMeta:String):Void {
		switch (target) {
			case TPath(path) if (path.name != "Dynamic"):
				var fullName = path.pack.concat([path.name]).join(".");
				switch (Context.getType(fullName)) {
					case TInst(ref, _):
						var cls = ref.get();
						var resolvedName = cls.pack.concat([cls.name]).join(".");
						if (cls.meta == null || !cls.meta.has(":railsModel")) {
							throw associationMeta + " target " + resolvedName + " must be a @:railsModel class.";
						}
					case _:
						throw associationMeta + " target " + fullName + " must resolve to a class.";
				}
			case _:
				throw associationMeta + " must specify a concrete @:railsModel target type.";
		}
	}

	static function validateBelongsToForeignKey(field:Field, fields:Array<Field>):Void {
		var foreignKeyName = field.name + "Id";
		var foreignKey = findFieldNamed(fields, foreignKeyName);
		if (foreignKey == null || !isRailsColumn(foreignKey)) {
			throw '@:belongsTo field ${field.name} requires a @:railsColumn foreign key named ${foreignKeyName}.';
		}
		if (complexTypeName(fieldValueType(foreignKey)) != "Int") {
			throw '@:belongsTo foreign key ${foreignKeyName} must be Int for the current RailsHx association validator.';
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

	static function isRailsColumn(field:Field):Bool {
		if (field.meta == null) {
			return false;
		}
		for (meta in field.meta) {
			if (meta.name == ":railsColumn") {
				return true;
			}
		}
		return false;
	}

	static function isRailsAssociation(field:Field):Bool {
		if (field.meta == null) {
			return false;
		}
		for (meta in field.meta) {
			switch (meta.name) {
				case ":belongsTo" | ":hasMany" | ":hasOne":
					return true;
				case _:
			}
		}
		return false;
	}

	static function hasFieldNamed(fields:Array<Field>, name:String):Bool {
		for (field in fields) {
			if (field.name == name) {
				return true;
			}
		}
		return false;
	}

	static function findFieldNamed(fields:Array<Field>, name:String):Null<Field> {
		for (field in fields) {
			if (field.name == name) {
				return field;
			}
		}
		return null;
	}

	static function fieldValueType(field:Field):ComplexType {
		return switch (field.kind) {
			case FVar(t, _) | FProp(_, _, t, _):
				t == null ? macro : Dynamic : t;
			case _:
				macro : Dynamic;
		}
	}

	static function associationTargetType(field:Field):ComplexType {
		return switch (fieldValueType(field)) {
			case TPath(path) if (path.params != null && path.params.length == 1):
				switch (path.params[0]) {
					case TPType(inner): inner;
					case _: macro : Dynamic;
				}
			case _:
				macro : Dynamic;
		}
	}

	static function associationComplexType(selfType:ComplexType, targetType:ComplexType):ComplexType {
		return TPath({
			pack: ["rails", "active_record"],
			name: "Association",
			params: [TPType(selfType), TPType(targetType)]
		});
	}

	static function criteriaComplexType(fields:Array<Field>):ComplexType {
		var criteriaFields:Array<Field> = [];
		for (field in fields) {
			if (!isRailsColumn(field)) {
				continue;
			}
			criteriaFields.push({
				name: field.name,
				access: [],
				kind: FVar(fieldValueType(field), null),
				meta: [{name: ":optional", pos: field.pos}],
				pos: field.pos
			});
		}
		return criteriaFields.length == 0 ? macro : Dynamic : TAnonymous(criteriaFields);
	}

	static function primaryKeyComplexType(fields:Array<Field>):ComplexType {
		for (field in fields) {
			if (isRailsColumn(field) && isPrimaryKeyField(field)) {
				return fieldValueType(field);
			}
		}
		for (field in fields) {
			if (isRailsColumn(field) && field.name == "id") {
				return fieldValueType(field);
			}
		}
		return macro : Int;
	}

	static function relationComplexType(selfType:ComplexType, criteriaType:ComplexType, pos:Position):ComplexType {
		return TPath({
			pack: ["rails", "active_record"],
			name: "Relation",
			params: [TPType(selfType), TPType(criteriaType)]
		});
	}

	static function isPrimaryKeyField(field:Field):Bool {
		if (field.meta == null) {
			return false;
		}
		for (meta in field.meta) {
			if (meta.name != ":railsColumn" || meta.params == null || meta.params.length == 0) {
				continue;
			}
			switch (meta.params[0].expr) {
				case EObjectDecl(options):
					for (option in options) {
						if (option.field == "primaryKey" && isBoolExpr(option.expr)) {
							return switch (option.expr.expr) {
								case EConst(CIdent("true")): true;
								case _: false;
							}
						}
					}
				case _:
			}
		}
		return false;
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

	static function addPlainStub(fields:Array<Field>, name:String, argType:ComplexType, ret:ComplexType, argName:String, pos:Position):Void {
		for (field in fields) {
			if (field.name == name) {
				return;
			}
		}
		fields.push({
			name: name,
			access: [APublic, AStatic],
			kind: FFun({
				args: [{name: argName, type: argType}],
				ret: ret,
				expr: macro return cast null
			}),
			meta: [
				{name: ":native", params: [macro $v{name}], pos: pos},
				{name: ":rubyExternStub", params: [], pos: pos}
			],
			pos: pos
		});
	}
}
#else
class ModelMacro {}
#end
