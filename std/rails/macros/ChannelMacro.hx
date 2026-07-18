package rails.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

/**
	Owns compile-time validation and derived client contracts for
	`@:railsChannel` classes. Ruby compilation consumes the server class directly;
	JavaScript compilation additionally receives a zero-runtime typed channel
	reference so browser code cannot drift its name or generic shapes.
**/
class ChannelMacro {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var localClass = Context.getLocalClass();
		if (localClass == null) {
			return fields;
		}
		var classType = localClass.get();
		if (classType.name == "Channel" && classType.pack.join(".") == "rails.action_cable") {
			return fields;
		}
		if (classType.meta.has(":railsChannel") && findInstanceMethod(fields, "subscribed") == null) {
			throw "@:railsChannel classes must define an instance subscribed() method.";
		}
		// The reference is a browser authoring surface. Keeping it out of the Ruby
		// compiler context avoids making a JS-only ActionCable handle part of the
		// server class while the same source still supplies its types to `-js`.
		if (classType.meta.has(":railsChannel") && Context.defined("js")) {
			addClientRef(fields, classType);
		}
		return fields;
	}

	/**
		Generate the browser-only typed channel reference from the same generic base
		contract the server class owns. The target guard prevents this authoring helper
		from entering Ruby compilation, and `inline final` leaves only the Rails
		channel-name string in JavaScript.
	**/
	static function addClientRef(fields:Array<Field>, classType:ClassType):Void {
		for (field in fields) {
			if (field.name == "client") {
				Context.error("@:railsChannel reserves the static field `client` for its typed browser subscription reference.", field.pos);
			}
		}
		var contract = channelContract(classType, classType.pos);
		var paramsType = TypeTools.toComplexType(contract.params);
		var payloadType = TypeTools.toComplexType(contract.payload);
		if (paramsType == null || payloadType == null) {
			Context.error("@:railsChannel could not preserve its Channel<TParams, TPayload> client contract.", classType.pos);
			return;
		}
		var refType:ComplexType = TPath({
			pack: ["rails", "action_cable"],
			name: "ChannelRef",
			params: [TPType(paramsType), TPType(payloadType)]
		});
		var channelName = railsChannelConstant(classType.name);
		fields.push({
			name: "client",
			access: [APublic, AStatic, AInline, AFinal],
			kind: FVar(refType, macro @:privateAccess new rails.action_cable.ChannelRef($v{channelName})),
			pos: classType.pos
		});
	}

	/**
		Walk intermediate generic base classes and substitute their concrete type
		arguments until reaching `Channel<TParams, TPayload>`. Reading only the direct
		superclass would silently lose client types for reusable app channel bases.
	**/
	static function channelContract(classType:ClassType, pos:Position):{params:Type, payload:Type} {
		var cursor = classType.superClass;
		while (cursor != null) {
			var superClass = cursor.t.get();
			var actualParams = cursor.params;
			if (superClass.pack.join(".") == "rails.action_cable" && superClass.name == "Channel") {
				if (actualParams.length != 2) {
					Context.error("@:railsChannel must preserve Channel<TParams, TPayload>.", pos);
				}
				return {params: actualParams[0], payload: actualParams[1]};
			}
			if (superClass.superClass == null) {
				break;
			}
			var parent = superClass.superClass;
			cursor = {
				t: parent.t,
				params: [
					for (parentParam in parent.params)
						TypeTools.applyTypeParameters(parentParam, superClass.params, actualParams)
				]
			};
		}
		return Context.error("@:railsChannel must extend rails.action_cable.Channel<TParams, TPayload>.", pos);
	}

	/** Mirror the Ruby compiler's Rails-native top-level constant mapping for a
		valid Haxe type identifier. Haxe has already excluded unsafe identifier
		characters; underscore-separated segments are the only spelling that needs
		folding here. */
	static function railsChannelConstant(name:String):String {
		var out = new StringBuf();
		for (part in name.split("_")) {
			if (part == "") {
				continue;
			}
			out.add(part.charAt(0).toUpperCase());
			out.add(part.substr(1));
		}
		return out.toString();
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

	static function hasAccess(field:Field, access:Access):Bool {
		return field.access != null && field.access.indexOf(access) != -1;
	}
}
#end
