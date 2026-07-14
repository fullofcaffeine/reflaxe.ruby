package devisehx.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import reflaxe.ruby.naming.RubyNaming;

/** Moves Devise model-token and schema validation into the companion layer. **/
class DeviseModelMacro {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var classType = Context.getLocalClass().get();
		var entries = classType.meta.extract(":devise");
		if (entries.length == 0) {
			return fields;
		}
		if (entries.length > 1) {
			Context.error("@:devise can only be declared once per Rails model.", classType.pos);
		}
		var entry = entries[0];
		if (entry.params.length != 2) {
			Context.error("@:devise expects a generated Devise scope and an array of Devise module tokens.", entry.pos);
		}
		ContractTools.routeContract(entry.params[0], "@:devise");
		var modules = moduleSymbols(entry.params[1]);
		if (modules.length == 0) {
			Context.error("@:devise requires at least one Devise module token.", entry.pos);
		}
		validateSchema(classType.name, fields, modules, entry.pos);
		classType.meta.add(":railsClassMacro", [macro $v{"devise"}, stringArray(modules, entry.pos)], entry.pos);
		return fields;
	}

	static function moduleSymbols(expr:Expr):Array<String> {
		return switch expr.expr {
			case EArrayDecl(items): [for (item in items) moduleSymbol(item)];
			case _:
				Context.error("@:devise module list must be an array literal so DeviseHx can emit deterministic Ruby.", expr.pos);
		}
	}

	static function moduleSymbol(expr:Expr):String {
		return switch expr.expr {
			case EConst(CIdent(name)) | EField(_, name): knownModule(name, expr.pos);
			case ECall(callee, args): calledModule(callee, args, expr.pos);
			case _:
				Context.error("@:devise module entries must be known DeviseHx module tokens imported from devisehx.model.DeviseModule.", expr.pos);
		}
	}

	static function calledModule(callee:Expr, args:Array<Expr>, pos:Position):String {
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
					case EConst(CString(name)) if (~/^[a-z][a-z0-9_]*$/.match(name)): name;
					case _:
						Context.error("@:devise unsafeCustom(...) requires a safe snake_case custom module name literal.", args[0].pos);
				}
			case _:
				Context.error("@:devise module calls must be supported DeviseHx tokens such as omniauthable([...]) or unsafeCustom(\"magic_auth\").", pos);
		}
	}

	static function knownModule(name:String, pos:Position):String {
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
		}
	}

	static function validateSchema(className:String, fields:Array<Field>, modules:Array<String>, pos:Position):Void {
		var columns = new Map<String, Bool>();
		for (field in fields) {
			if (hasMeta(field, ":railsColumn")) {
				columns.set(rubyFieldName(field), true);
			}
		}
		var required:Array<String> = [];
		for (moduleName in modules) {
			for (column in requiredColumns(moduleName)) {
				if (required.indexOf(column) == -1) {
					required.push(column);
				}
			}
		}
		var missing = [for (column in required) if (!columns.exists(column)) column];
		if (missing.length > 0) {
			Context.error("@:devise on "
				+ className
				+ " requires typed @:railsColumn field(s) for Devise module schema: "
				+ missing.join(", ")
				+ ". Add the fields to the Haxe model or keep this model Rails-owned through a generated extern/adoption contract.",
				pos);
		}
	}

	static function requiredColumns(moduleName:String):Array<String> {
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

	static function rubyFieldName(field:Field):String {
		if (field.meta != null) {
			for (meta in field.meta) {
				if (meta.name == ":native" && meta.params.length == 1) {
					switch meta.params[0].expr {
						case EConst(CString(value)):
							return value;
						case _:
					}
				}
			}
		}
		return RubyNaming.toMethodName(field.name);
	}

	static function hasMeta(field:Field, name:String):Bool {
		if (field.meta == null) {
			return false;
		}
		for (meta in field.meta) {
			if (meta.name == name) {
				return true;
			}
		}
		return false;
	}

	static function stringArray(values:Array<String>, pos:Position):Expr {
		return {expr: EArrayDecl([for (value in values) macro $v{value}]), pos: pos};
	}
}
#else
class DeviseModelMacro {}
#end
