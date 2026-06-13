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
		addModelAttachmentRefs(fields, selfType, pos);
		addStub(fields, "where", criteriaType, relationComplexType(selfType, criteriaType, pos), pos);
		addStub(fields, "rewhere", criteriaType, relationComplexType(selfType, criteriaType, pos), pos);
		addPlainStub(fields, "reorder", orderComplexType(selfType), relationComplexType(selfType, criteriaType, pos), "order", pos);
		addPlainStub(fields, "includes", associationComplexType(selfType, macro : Dynamic), relationComplexType(selfType, criteriaType, pos), "association", pos);
		addPlainStub(fields, "joins", associationComplexType(selfType, macro : Dynamic), relationComplexType(selfType, criteriaType, pos), "association", pos);
		addPlainStub(fields, "offset", macro : Int, relationComplexType(selfType, criteriaType, pos), "count", pos);
		addNoArgStub(fields, "all", relationComplexType(selfType, criteriaType, pos), pos);
		addNoArgStub(fields, "distinct", relationComplexType(selfType, criteriaType, pos), pos);
		addStub(fields, "find", primaryKeyComplexType(fields), selfType, pos);
		addStub(fields, "findBy", criteriaType, nullableSelf, pos);
		addOptionalStub(fields, "exists", criteriaType, macro : Bool, "criteria", "exists?", pos);
		addNoArgStub(fields, "count", macro : Int, pos);
		addStub(fields, "create", macro : Dynamic, selfType, pos);
		addNoArgStub(fields, "first", nullableSelf, pos);
		addNoArgStub(fields, "last", nullableSelf, pos);
		addPluckStub(fields, selfType, pos);
		addFieldProjectionStub(fields, "minimum", selfType, nullableGenericComplexType("TValue"), pos);
		addFieldProjectionStub(fields, "maximum", selfType, nullableGenericComplexType("TValue"), pos);
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

	static function addModelAttachmentRefs(fields:Array<Field>, selfType:ComplexType, pos:Position):Void {
		var attachmentFields = [for (field in fields.copy()) if (isRailsAttachment(field)) field];
		if (attachmentFields.length == 0) {
			return;
		}
		addAttachmentsObject(fields, "attachments", attachmentFields, selfType, pos);
	}

	static function addAttachmentsObject(fields:Array<Field>, name:String, attachmentFields:Array<Field>, selfType:ComplexType, pos:Position):Void {
		if (hasFieldNamed(fields, name)) {
			return;
		}
		var objectFields:Array<Field> = [];
		var values:Array<ObjectField> = [];
		for (field in attachmentFields) {
			var refType = attachmentComplexType(field, selfType);
			objectFields.push({
				name: field.name,
				access: [],
				kind: FVar(refType, null),
				meta: [
					{name: ":railsAttachment", params: [macro $v{field.name}], pos: pos},
					{name: ":railsAttachmentKind", params: [macro $v{attachmentKind(field)}], pos: pos}
				],
				pos: pos
			});
			values.push({
				field: field.name,
				expr: attachmentConstructorExpr(field)
			});
		}
		fields.push({
			name: name,
			access: [APublic, AStatic, AFinal],
			kind: FVar(TAnonymous(objectFields), {expr: EObjectDecl(values), pos: pos}),
			pos: pos
		});
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
						validateAssociationOptions(field, meta, fields);
					case ":hasOneAttached" | ":hasManyAttached":
						if (!isVarField(field)) {
							throw meta.name + " can only be used on model fields.";
						}
						validateAttachmentType(field, meta.name);
					case ":railsEnum":
						if (!isVarField(field)) {
							throw "@:railsEnum can only be used on model fields.";
						}
						if (!isRailsColumn(field)) {
							throw "@:railsEnum requires the same field to be marked @:railsColumn.";
						}
						validateEnumMetadata(field, meta);
					case ":validates":
						if (!isVarField(field)) {
							throw "@:validates can only be used on model fields.";
						}
						if (!hasValidValidationArgs(meta.params)) {
							throw "@:validates expects an options object, or a field name followed by an options object.";
						}
						validateValidationMetadata(field, fields, meta);
					case ":beforeValidation" | ":afterValidation" | ":beforeSave" | ":afterSave" | ":beforeCreate" | ":afterCreate" | ":beforeUpdate" | ":afterUpdate" | ":beforeDestroy" | ":afterDestroy" | ":afterCommit" | ":afterRollback" | ":railsCallback":
						validateCallbackMetadata(field, meta);
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

	static function associationMeta(field:Field):Null<MetadataEntry> {
		if (field.meta == null) {
			return null;
		}
		for (meta in field.meta) {
			switch (meta.name) {
				case ":belongsTo" | ":hasMany" | ":hasOne":
					return meta;
				case _:
			}
		}
		return null;
	}

	static function associationStringOption(meta:Null<MetadataEntry>, name:String):Null<String> {
		if (meta == null || meta.params == null || meta.params.length == 0) {
			return null;
		}
		return switch (meta.params[0].expr) {
			case EObjectDecl(options):
				for (option in options) {
					if (option.field == name && isStringExpr(option.expr)) {
						return stringExprValue(option.expr);
					}
				}
				null;
			case _:
				null;
		}
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
		var foreignKeyName = belongsToForeignKeyName(field);
		var foreignKey = findFieldNamed(fields, foreignKeyName);
		if (foreignKey == null || !isRailsColumn(foreignKey)) {
			throw '@:belongsTo field ${field.name} requires a @:railsColumn foreign key named ${foreignKeyName}.';
		}
		if (complexTypeName(fieldValueType(foreignKey)) != "Int") {
			throw '@:belongsTo foreign key ${foreignKeyName} must be Int for the current RailsHx association validator.';
		}
	}

	static function validateAssociationOptions(field:Field, meta:MetadataEntry, fields:Array<Field>):Void {
		if (meta.params == null || meta.params.length == 0) {
			return;
		}
		if (meta.params.length != 1) {
			throw meta.name + " expects zero arguments or one options object.";
		}
		switch (meta.params[0].expr) {
			case EObjectDecl(options):
				for (option in options) {
					switch (option.field) {
						case "dependent":
							validateDependentOption(meta.name, option.expr);
						case "optional":
							if (meta.name != ":belongsTo") {
								throw '@:association option optional is only valid for @:belongsTo.';
							}
							if (!isBoolExpr(option.expr)) {
								throw '@:association option optional must be a Bool literal.';
							}
						case "foreignKey":
							if (!isStringExpr(option.expr)) {
								throw '@:association option foreignKey must be a String literal.';
							}
							validateForeignKeyOption(field, meta.name, fields, stringExprValue(option.expr));
						case "inverseOf":
							if (!isStringExpr(option.expr)) {
								throw '@:association option inverseOf must be a String literal.';
							}
						case "className":
							if (!isStringExpr(option.expr)) {
								throw '@:association option className must be a String literal.';
							}
						case "through":
							if (meta.name == ":belongsTo") {
								throw '@:association option through is not valid for @:belongsTo.';
							}
							if (!isStringExpr(option.expr)) {
								throw '@:association option through must be a String literal.';
							}
							validateThroughOption(field, fields, stringExprValue(option.expr));
						case "source":
							if (meta.name == ":belongsTo") {
								throw '@:association option source is not valid for @:belongsTo.';
							}
							if (!isStringExpr(option.expr)) {
								throw '@:association option source must be a String literal.';
							}
						case _:
							throw '@:association unknown option ${option.field}.';
					}
				}
			case _:
				throw meta.name + " expects an options object.";
		}
	}

	static function validateDependentOption(associationMeta:String, expr:Expr):Void {
		if (associationMeta == ":belongsTo") {
			throw '@:association option dependent is not valid for @:belongsTo.';
		}
		if (!isStringExpr(expr)) {
			throw '@:association option dependent must be a String literal.';
		}
		var value = stringExprValue(expr);
		switch (value) {
			case "destroy" | "deleteAll" | "nullify" | "restrictWithError" | "restrictWithException":
			case _:
				throw '@:association option dependent has unsupported value ${value}.';
		}
	}

	static function validateThroughOption(field:Field, fields:Array<Field>, throughName:String):Void {
		var through = findFieldNamed(fields, throughName);
		if (through == null || !isRailsAssociation(through)) {
			throw '@:association through option on ${field.name} must reference a model association named ${throughName}.';
		}
		if (through.name == field.name) {
			throw '@:association through option on ${field.name} cannot reference itself.';
		}
	}

	static function validateForeignKeyOption(field:Field, associationMeta:String, fields:Array<Field>, foreignKeyName:String):Void {
		if (associationMeta != ":belongsTo") {
			return;
		}
		var foreignKey = findFieldNamed(fields, foreignKeyName);
		if (foreignKey == null || !isRailsColumn(foreignKey)) {
			throw '@:belongsTo field ${field.name} requires a @:railsColumn foreign key named ${foreignKeyName}.';
		}
	}

	static function belongsToForeignKeyName(field:Field):String {
		var explicit = associationStringOption(associationMeta(field), "foreignKey");
		return explicit == null ? field.name + "Id" : explicit;
	}

	static function validateValidationMetadata(field:Field, fields:Array<Field>, meta:MetadataEntry):Void {
		var targetName = validationTargetName(field, meta);
		var targetField = findRailsColumnByHaxeOrRubyName(fields, targetName);
		if (targetField == null) {
			throw '@:validates target ${targetName} must match a @:railsColumn field.';
		}
		var validationType = validationValueType(field);
		var targetType = fieldValueType(targetField);
		if (complexTypeName(validationType) != "Dynamic" && complexTypeName(validationType) != complexTypeName(targetType)) {
			throw '@:validates field ${field.name} must use Validation<${complexTypeName(targetType)}> for target ${targetField.name}.';
		}
		validateValidationOptions(validationOptionsExpr(meta.params));
	}

	static function validateCallbackMetadata(field:Field, meta:MetadataEntry):Void {
		if (!isFuncField(field)) {
			throw meta.name + " can only be used on model methods.";
		}
		switch (field.kind) {
			case FFun(fn):
				if (fn.args != null && fn.args.length > 0) {
					throw meta.name + " callback methods must not declare arguments.";
				}
			case _:
		}
		if (field.name == "new") {
			throw meta.name + " cannot be used on model constructors.";
		}
		if (hasAccess(field, AStatic)) {
			throw meta.name + " callback methods must be instance methods.";
		}
		var callbackName = callbackRubyName(meta);
		if (!isAllowedCallbackName(callbackName)) {
			throw '@:railsCallback unknown callback ${callbackName}.';
		}
	}

	static function callbackRubyName(meta:MetadataEntry):String {
		return switch (meta.name) {
			case ":beforeValidation": "before_validation";
			case ":afterValidation": "after_validation";
			case ":beforeSave": "before_save";
			case ":afterSave": "after_save";
			case ":beforeCreate": "before_create";
			case ":afterCreate": "after_create";
			case ":beforeUpdate": "before_update";
			case ":afterUpdate": "after_update";
			case ":beforeDestroy": "before_destroy";
			case ":afterDestroy": "after_destroy";
			case ":afterCommit": "after_commit";
			case ":afterRollback": "after_rollback";
			case ":railsCallback":
				if (meta.params == null || meta.params.length != 1 || !isStringExpr(meta.params[0])) {
					throw '@:railsCallback expects one Rails callback name string.';
				}
				stringExprValue(meta.params[0]);
			case _:
				"";
		}
	}

	static function isAllowedCallbackName(name:String):Bool {
		return switch (name) {
			case "before_validation" | "after_validation" | "before_save" | "after_save" | "before_create" | "after_create" | "before_update" | "after_update" | "before_destroy" | "after_destroy" | "after_commit" | "after_rollback":
				true;
			case _:
				false;
		}
	}

	static function validateEnumMetadata(field:Field, meta:MetadataEntry):Void {
		var params = meta.params;
		if (params == null || params.length != 1) {
			throw "@:railsEnum expects one options object.";
		}
		var enumValueKind = "";
		switch (params[0].expr) {
			case EObjectDecl(options):
				if (options.length == 0) {
					throw "@:railsEnum expects at least one enum value.";
				}
				for (option in options) {
					var currentKind = switch (option.expr.expr) {
						case EConst(CString(_, _)): "String";
						case EConst(CInt(_, _)): "Int";
						case _:
							throw '@:railsEnum value ${option.field} must be a String or Int literal.';
					}
					if (enumValueKind == "") {
						enumValueKind = currentKind;
					} else if (enumValueKind != currentKind) {
						throw "@:railsEnum values must all use the same literal type.";
					}
				}
			case _:
				throw "@:railsEnum expects one options object.";
		}
		var fieldType = fieldTypeName(field);
		if (fieldType != enumValueKind) {
			throw '@:railsEnum ${field.name} values are ${enumValueKind} literals, so the field must be ${enumValueKind}.';
		}
	}

	static function validationTargetName(field:Field, meta:MetadataEntry):String {
		if (meta.params != null && meta.params.length > 1) {
			return stringExprValue(meta.params[0]);
		}
		var suffix = "Validation";
		if (StringTools.endsWith(field.name, suffix) && field.name.length > suffix.length) {
			return field.name.substr(0, field.name.length - suffix.length);
		}
		return field.name;
	}

	static function validateValidationOptions(expr:Expr):Void {
		switch (expr.expr) {
			case EObjectDecl(options):
				for (option in options) {
					switch (option.field) {
						case "presence" | "uniqueness" | "absence" | "acceptance" | "confirmation":
							if (!isBoolExpr(option.expr) && !isObjectExpr(option.expr)) {
								throw '@:validates option ${option.field} must be a Bool literal or an options object.';
							}
							validateMetadataLiteralValue(option.expr, '@:validates option ${option.field}');
						case "length" | "format" | "inclusion" | "exclusion" | "numericality":
							if (!isObjectExpr(option.expr)) {
								throw '@:validates option ${option.field} must be an options object.';
							}
							validateMetadataLiteralValue(option.expr, '@:validates option ${option.field}');
						case "allowBlank" | "allowNil":
							if (!isBoolExpr(option.expr)) {
								throw '@:validates option ${option.field} must be a Bool literal.';
							}
						case "message" | "on" | "if" | "unless":
							if (!isStringExpr(option.expr)) {
								throw '@:validates option ${option.field} must be a String literal.';
							}
						case "strict":
							if (!isBoolExpr(option.expr) && !isStringExpr(option.expr)) {
								throw "@:validates option strict must be a Bool or String literal.";
							}
						case _:
							throw '@:validates unknown option ${option.field}.';
					}
				}
			case _:
				throw "@:validates expects an options object.";
		}
	}

	static function validateMetadataLiteralValue(expr:Expr, label:String):Void {
		switch (expr.expr) {
			case EConst(CIdent("true" | "false" | "null")):
			case EConst(CString(_, _)) | EConst(CInt(_, _)) | EConst(CFloat(_, _)):
			case EArrayDecl(values):
				for (value in values) {
					validateMetadataLiteralValue(value, label);
				}
			case EObjectDecl(options):
				for (option in options) {
					validateMetadataLiteralValue(option.expr, label + "." + option.field);
				}
			case _:
				throw label + " must contain only literal metadata values.";
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

	static function isFuncField(field:Field):Bool {
		return switch (field.kind) {
			case FFun(_): true;
			case _: false;
		}
	}

	static function hasAccess(field:Field, access:Access):Bool {
		return field.access != null && field.access.indexOf(access) >= 0;
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

	static function isRailsAttachment(field:Field):Bool {
		if (field.meta == null) {
			return false;
		}
		for (meta in field.meta) {
			switch (meta.name) {
				case ":hasOneAttached" | ":hasManyAttached":
					return true;
				case _:
			}
		}
		return false;
	}

	static function attachmentKind(field:Field):String {
		if (field.meta == null) {
			return "one";
		}
		for (meta in field.meta) {
			switch (meta.name) {
				case ":hasOneAttached":
					return "one";
				case ":hasManyAttached":
					return "many";
				case _:
			}
		}
		return "one";
	}

	static function attachmentComplexType(field:Field, selfType:ComplexType):ComplexType {
		return TPath({
			pack: ["rails", "active_storage"],
			name: attachmentKind(field) == "many" ? "Many" : "One",
			params: [TPType(selfType)]
		});
	}

	static function attachmentConstructorExpr(field:Field):Expr {
		return attachmentKind(field) == "many" ? macro rails.active_storage.Many.named($v{field.name}) : macro rails.active_storage.One.named($v{field.name});
	}

	static function validateAttachmentType(field:Field, metaName:String):Void {
		var expected = metaName == ":hasManyAttached" ? "Many" : "One";
		switch (fieldValueType(field)) {
			case TPath(path) if (attachmentTypePathName(path) == "rails.active_storage." + expected
				|| attachmentTypePathName(path) == "rails.ActiveStorage." + expected):
			case TPath(path):
				throw metaName + ' field ${field.name} must be typed as rails.ActiveStorage.$expected<ThisModel>.';
			case _:
				throw metaName + ' field ${field.name} must be typed as rails.ActiveStorage.$expected<ThisModel>.';
		}
	}

	static function attachmentTypePathName(path:TypePath):String {
		var parts = path.pack.copy();
		parts.push(path.name);
		if (path.sub != null) {
			parts.push(path.sub);
		}
		return parts.join(".");
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

	static function findRailsColumnByHaxeOrRubyName(fields:Array<Field>, name:String):Null<Field> {
		for (field in fields) {
			if (!isRailsColumn(field)) {
				continue;
			}
			if (field.name == name || RubyNaming.toMethodName(field.name) == RubyNaming.toMethodName(name)) {
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

	static function validationValueType(field:Field):ComplexType {
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

	static function orderComplexType(selfType:ComplexType):ComplexType {
		return TPath({
			pack: ["rails", "active_record"],
			name: "Order",
			params: [TPType(selfType)]
		});
	}

	static function arrayComplexType(itemType:ComplexType):ComplexType {
		return TPath({
			pack: [],
			name: "Array",
			params: [TPType(itemType)]
		});
	}

	static function nullableGenericComplexType(name:String):ComplexType {
		return TPath({
			pack: [],
			name: "Null",
			params: [TPType(TPath({pack: [], name: name}))]
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

	static function validationOptionsExpr(params:Null<Array<Expr>>):Expr {
		if (params == null || params.length == 0) {
			return macro {};
		}
		if (params.length > 1) {
			return params[1];
		}
		return params[0];
	}

	static function stringExprValue(expr:Expr):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)): value;
			case _: "";
		}
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

	static function addPluckStub(fields:Array<Field>, selfType:ComplexType, pos:Position):Void {
		var valueType:ComplexType = TPath({pack: [], name: "TValue"});
		addFieldProjectionStub(fields, "pluck", selfType, arrayComplexType(valueType), pos);
	}

	static function addFieldProjectionStub(fields:Array<Field>, name:String, selfType:ComplexType, ret:ComplexType, pos:Position):Void {
		if (hasFieldNamed(fields, name)) {
			return;
		}
		var valueType:ComplexType = TPath({pack: [], name: "TValue"});
		fields.push({
			name: name,
			access: [APublic, AStatic],
			kind: FFun({
				params: [{name: "TValue", constraints: [], params: [], meta: []}],
				args: [{name: "field", type: typedFieldComplexType(selfType, valueType)}],
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

	static function addOptionalStub(fields:Array<Field>, name:String, argType:ComplexType, ret:ComplexType, argName:String, nativeName:String, pos:Position):Void {
		for (field in fields) {
			if (field.name == name) {
				return;
			}
		}
		fields.push({
			name: name,
			access: [APublic, AStatic],
			kind: FFun({
				args: [{name: argName, type: argType, opt: true}],
				ret: ret,
				expr: macro return cast null
			}),
			meta: [
				{name: ":native", params: [macro $v{nativeName}], pos: pos},
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
