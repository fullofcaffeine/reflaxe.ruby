package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class ConnectionMacro {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var localClass = Context.getLocalClass();
		if (localClass == null) {
			return fields;
		}
		var classType = localClass.get();
		if (classType.name == "Connection" && classType.pack.join(".") == "rails.action_cable") {
			return fields;
		}
		if (classType.meta.has(":railsCableConnection")) {
			if (findStaticField(fields, "identifiers") == null) {
				throw "@:railsCableConnection classes must declare `static final identifiers = { identifiedBy(...); }`. Use `[]` when no identifiers are needed.";
			}
			if (findInstanceMethod(fields, "connect") == null) {
				throw "@:railsCableConnection classes must define an instance connect() method.";
			}
		}
		return fields;
	}

	static function findInstanceMethod(fields:Array<Field>, name:String):Null<Function> {
		for (field in fields) {
			if (field.name != name || hasAccess(field, AStatic)) {
				continue;
			}
			return switch (field.kind) {
				case FFun(fn): fn;
				case _: null;
			}
		}
		return null;
	}

	static function findStaticField(fields:Array<Field>, name:String):Null<Field> {
		for (field in fields) {
			if (field.name == name && hasAccess(field, AStatic)) {
				return field;
			}
		}
		return null;
	}

	static function hasAccess(field:Field, access:Access):Bool {
		return field.access != null && field.access.indexOf(access) != -1;
	}
}
#end
