package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class JobMacro {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();
		var perform = findPerform(fields);
		if (perform == null) {
			throw "@:railsJob classes must define an instance perform(...) method.";
		}
		addEnqueueStub(fields, "performLater", "perform_later", perform, pos);
		addEnqueueStub(fields, "performNow", "perform_now", perform, pos);
		return fields;
	}

	static function findPerform(fields:Array<Field>):Null<Function> {
		for (field in fields) {
			if (field.name != "perform" || hasAccess(field, AStatic)) {
				continue;
			}
			return switch (field.kind) {
				case FFun(fn): fn;
				case _: null;
			}
		}
		return null;
	}

	static function addEnqueueStub(fields:Array<Field>, haxeName:String, rubyName:String, perform:Function, pos:Position):Void {
		if (hasFieldNamed(fields, haxeName)) {
			return;
		}
		fields.push({
			name: haxeName,
			access: [APublic, AStatic],
			kind: FFun({
				args: [for (arg in perform.args) {
					name: arg.name,
					opt: arg.opt,
					type: arg.type,
					value: null,
					meta: arg.meta
				}],
				ret: macro : Dynamic,
				expr: macro return null
			}),
			meta: [
				{name: ":native", params: [macro $v{rubyName}], pos: pos},
				{name: ":rubyExternStub", params: [], pos: pos}
			],
			pos: pos
		});
	}

	static function hasFieldNamed(fields:Array<Field>, name:String):Bool {
		for (field in fields) {
			if (field.name == name) {
				return true;
			}
		}
		return false;
	}

	static function hasAccess(field:Field, access:Access):Bool {
		return field.access != null && field.access.indexOf(access) != -1;
	}
}
#end
