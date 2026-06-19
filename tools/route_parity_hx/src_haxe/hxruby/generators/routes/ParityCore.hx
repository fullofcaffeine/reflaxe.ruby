package hxruby.generators.routes;

import ruby.NativeHash;

class ManifestRoute {
	public final name:Null<String>;
	public final verb:Null<String>;
	public final path:String;
	public final target:Null<String>;
	public final position:Null<String>;
	public final opaque:Bool;

	public function new(name:Null<String>, verb:Null<String>, path:String, target:Null<String>, position:Null<String>, opaque:Bool) {
		this.name = name;
		this.verb = verb;
		this.path = path;
		this.target = target;
		this.position = position;
		this.opaque = opaque;
	}
}

class RailsRoute {
	public final prefix:String;
	public final verb:Null<String>;
	public final path:String;
	public final target:Null<String>;

	public function new(prefix:String, verb:Null<String>, path:String, target:Null<String>) {
		this.prefix = prefix;
		this.verb = verb;
		this.path = path;
		this.target = target;
	}
}

class ParityCore {
	public static function main():Void {}

	public static function compareManifest(manifest:Dynamic, railsRoutes:String):Array<String> {
		var manifestErrors = validateManifest(manifest);
		if (manifestErrors.length > 0) {
			return manifestErrors;
		}

		var routes = parseRoutes(railsRoutes);
		var expected = flattenManifest(hashArray(manifest, "declarations"), "");
		var errors:Array<String> = [];
		for (route in expected) {
			errors = errors.concat(compareRoute(route, routes));
		}
		return errors;
	}

	static function validateManifest(manifest:Dynamic):Array<String> {
		var errors:Array<String> = [];
		var version:Dynamic = hashValue(manifest, "version");
		var versionText = version == null ? "" : Std.string(version);
		if (versionText != "1" && versionText != "2") {
			errors.push('unsupported Haxe-owned route manifest version ${versionText == "" ? "(missing)" : versionText}');
		}
		if (!NativeHash.exists(manifest, "declarations")) {
			errors.push("Haxe-owned route manifest is missing declarations");
		}
		return errors.concat(validateDeclarations(hashArray(manifest, "declarations")));
	}

	static function validateDeclarations(declarations:Array<Dynamic>):Array<String> {
		var errors:Array<String> = [];
		for (decl in declarations) {
			var kind = hashString(decl, "kind");
			if (!supportedDeclarationKind(kind)) {
				errors.push('unknown Haxe-owned route manifest declaration kind ${kind == null ? "(missing)" : kind}');
			} else {
				errors = errors.concat(validateDeclarations(childrenOf(decl)));
			}
		}
		return errors;
	}

	static function supportedDeclarationKind(kind:Null<String>):Bool {
		return switch kind {
			case "collection" | "constraints" | "controller" | "defaults" | "deviseFor" | "match" | "member" | "mount" | "namespace" | "rawRuby" | "resource" | "resources" | "root" | "scope" | "verb": true;
			case _: false;
		}
	}

	static function parseRoutes(input:String):Array<RailsRoute> {
		var routes:Array<RailsRoute> = [];
		var previousPrefix:Null<String> = null;
		for (rawLine in input.split("\n")) {
			var parsed = parseRouteLine(rawLine, previousPrefix);
			for (route in parsed) {
				if (route.prefix != "") {
					previousPrefix = route.prefix;
				}
				routes.push(route);
			}
		}
		return routes;
	}

	static function parseRouteLine(rawLine:String, previousPrefix:Null<String>):Array<RailsRoute> {
		var line = StringTools.trim(rawLine);
		if (line == "" || StringTools.startsWith(line, "Prefix ")) {
			return [];
		}

		var tokens = nonEmptyTokens(line);
		var verbIndex = findVerbIndex(tokens);
		if (verbIndex < 0) {
			return parseMountLine(tokens);
		}

		var uri = tokens[verbIndex + 1];
		var target = tokens[verbIndex + 2];
		if (uri == null || target == null || !StringTools.startsWith(uri, "/")) {
			return [];
		}

		var rawPrefix = tokens.slice(0, verbIndex).join("_");
		var prefix = rawPrefix == "" ? previousPrefix : rawPrefix;
		if (prefix == null || prefix == "") {
			return [];
		}

		var routes:Array<RailsRoute> = [];
		for (verb in tokens[verbIndex].split("|")) {
			routes.push(new RailsRoute(prefix, verb.toLowerCase(), normalizeRailsUri(uri), target));
		}
		return routes;
	}

	static function parseMountLine(tokens:Array<String>):Array<RailsRoute> {
		if (tokens.length < 2 || !StringTools.startsWith(tokens[1], "/")) {
			return [];
		}
		return [new RailsRoute(tokens[0], null, normalizeRailsUri(tokens[1]), null)];
	}

	static function nonEmptyTokens(line:String):Array<String> {
		var out:Array<String> = [];
		for (token in line.split(" ")) {
			if (token != "") {
				out.push(token);
			}
		}
		return out;
	}

	static function findVerbIndex(tokens:Array<String>):Int {
		var index = 0;
		while (index < tokens.length) {
			if (routeVerb(tokens[index])) {
				return index;
			}
			index++;
		}
		return -1;
	}

	static function routeVerb(token:String):Bool {
		var parts = token.split("|");
		for (part in parts) {
			if (!isHttpVerb(part)) {
				return false;
			}
		}
		return parts.length > 0;
	}

	static function isHttpVerb(value:String):Bool {
		return switch value {
			case "GET" | "POST" | "PATCH" | "PUT" | "DELETE" | "OPTIONS" | "HEAD": true;
			case _: false;
		}
	}

	static function normalizeRailsUri(uri:String):String {
		return StringTools.replace(uri, "(.:format)", "");
	}

	static function flattenManifest(declarations:Array<Dynamic>, prefix:String):Array<ManifestRoute> {
		var out:Array<ManifestRoute> = [];
		for (decl in declarations) {
			out = out.concat(flattenDecl(decl, prefix));
		}
		return out;
	}

	static function flattenDecl(decl:Dynamic, prefix:String):Array<ManifestRoute> {
		var kind = hashString(decl, "kind");
		return switch kind {
			case "root":
				[expectedRoute(decl, "root", "get", "/", hashString(decl, "target"))];
			case "verb":
				[expectedRoute(decl, nullableName(decl), hashString(decl, "verb"), joinedPath(prefix, hashString(decl, "path")), hashString(decl, "target"))];
			case "match":
				hashArray(decl, "verbs").map(function(verb) {
					return expectedRoute(decl, nullableName(decl), cast verb, joinedPath(prefix, hashString(decl, "path")), hashString(decl, "target"));
				});
			case "mount":
				[expectedRoute(decl, nullableName(decl), null, joinedPath(prefix, hashString(decl, "path")), null)];
			case "rawRuby":
				[new ManifestRoute(null, null, "", null, hashString(decl, "position"), true)];
			case "deviseFor":
				[];
			case "scope":
				flattenManifest(childrenOf(decl), joinedPath(prefix, hashString(decl, "path")));
			case "namespace":
				flattenManifest(childrenOf(decl), joinedPath(prefix, hashString(decl, "name")));
			case "defaults" | "constraints" | "controller":
				flattenManifest(childrenOf(decl), prefix);
			case "resources" | "resource" | "collection" | "member":
				[];
			case _:
				[];
		}
	}

	static function expectedRoute(decl:Dynamic, name:Null<String>, verb:Null<String>, path:String, target:Null<String>):ManifestRoute {
		return new ManifestRoute(name, verb, path, target, hashString(decl, "position"), false);
	}

	static function nullableName(decl:Dynamic):Null<String> {
		var name = hashString(decl, "name");
		return name == null || name == "" ? null : name;
	}

	static function childrenOf(decl:Dynamic):Array<Dynamic> {
		return hashArray(decl, "children");
	}

	static function joinedPath(prefix:String, path:Null<String>):String {
		var joined:Array<String> = [];
		appendPathPiece(joined, prefix);
		appendPathPiece(joined, path == null ? "" : path);
		return joined.length == 0 ? "/" : "/" + joined.join("/");
	}

	static function appendPathPiece(out:Array<String>, value:String):Void {
		if (value == "") {
			return;
		}
		var piece = trimSlashes(value);
		if (piece != "") {
			out.push(piece);
		}
	}

	static function trimSlashes(value:String):String {
		var out = value;
		while (StringTools.startsWith(out, "/")) {
			out = out.substr(1);
		}
		while (StringTools.endsWith(out, "/")) {
			out = out.substr(0, out.length - 1);
		}
		return out;
	}

	static function compareRoute(expected:ManifestRoute, routes:Array<RailsRoute>):Array<String> {
		if (expected.opaque) {
			return ['opaque raw Haxe-owned route at ${expected.position} cannot be parity-checked; replace it with typed route declarations or keep Rails-owned routes'];
		}

		if (any(routes, function(route) return routeMatches(expected, route))) {
			return [];
		}

		var diagnostics:Array<String> = [];
		if (expected.name != null) {
			var named = routes.filter(function(route) return route.prefix == expected.name);
			if (named.length > 0 && !any(named, function(route) return route.verb == expected.verb)) {
				diagnostics.push(wrongVerb(expected, named));
			}
			if (named.length > 0
				&& any(named, function(route) return route.verb == expected.verb)
				&& !any(named, function(route) return route.path == expected.path)) {
				diagnostics.push(wrongPath(expected, named));
			}
		}

		var samePathVerb = routes.filter(function(route) return route.path == expected.path && route.verb == expected.verb);
		if (expected.target != null && samePathVerb.length > 0 && !any(samePathVerb, function(route) return route.target == expected.target)) {
			diagnostics.push(wrongTarget(expected, samePathVerb));
		}
		if (diagnostics.length > 0) {
			return diagnostics;
		}

		return ['missing Haxe-owned route ${formatExpected(expected)}'];
	}

	static function routeMatches(expected:ManifestRoute, route:RailsRoute):Bool {
		return (expected.name == null || route.prefix == expected.name)
			&& route.verb == expected.verb
			&& route.path == expected.path
			&& (expected.target == null || route.target == expected.target);
	}

	static function wrongVerb(expected:ManifestRoute, routes:Array<RailsRoute>):String {
		return 'wrong verb for route ${expected.name}: expected ${upper(expected.verb)}, saw ${unique(routes.map(function(route) return upper(route.verb))).join(", ")}';
	}

	static function wrongPath(expected:ManifestRoute, routes:Array<RailsRoute>):String {
		return 'wrong path for route ${expected.name}: expected ${expected.path}, saw ${unique(routes.map(function(route) return route.path)).join(", ")}';
	}

	static function wrongTarget(expected:ManifestRoute, routes:Array<RailsRoute>):String {
		return 'wrong target for route ${expected.path} ${upper(expected.verb)}: expected ${expected.target}, saw ${unique(routes.map(function(route) return route.target == null ? "" : route.target)).join(", ")}';
	}

	static function formatExpected(expected:ManifestRoute):String {
		return [expected.name, upper(expected.verb), expected.path, expected.target].filter(function(part) return part != null && part != "").join(" ");
	}

	static function upper(value:Null<String>):String {
		return switch value {
			case null: "";
			case "delete": "DELETE";
			case "get": "GET";
			case "head": "HEAD";
			case "options": "OPTIONS";
			case "patch": "PATCH";
			case "post": "POST";
			case "put": "PUT";
			case _: value;
		}
	}

	static function unique(values:Array<String>):Array<String> {
		var out:Array<String> = [];
		for (value in values) {
			if (out.indexOf(value) < 0) {
				out.push(value);
			}
		}
		return out;
	}

	static function any<T>(items:Array<T>, predicate:T->Bool):Bool {
		for (item in items) {
			if (predicate(item)) {
				return true;
			}
		}
		return false;
	}

	static function hashString(hash:Dynamic, key:String):Null<String> {
		return NativeHash.get(hash, key);
	}

	static function hashValue(hash:Dynamic, key:String):Dynamic {
		return NativeHash.get(hash, key);
	}

	static function hashArray(hash:Dynamic, key:String):Array<Dynamic> {
		var value:Array<Dynamic> = NativeHash.get(hash, key);
		return value == null ? [] : value;
	}
}
