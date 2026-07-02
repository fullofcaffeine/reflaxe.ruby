package reflaxe.ruby.rails;

import haxe.macro.Context;
import haxe.macro.Expr.Position;

/**
	Owns RailsHx artifact path normalization and fail-closed path validation.

	RubyCompiler remains the compiler entrypoint, but Rails-owned output locations
	are a Rails concern: views live under app/views, generated tests under
	test/generated, and mailer previews under test/mailers/previews. Keeping that
	contract here makes future ActionView/test/mailer extraction less dependent
	on RubyCompiler internals while preserving the same diagnostics.
**/
class RailsArtifactPaths {
	public static function templateOutputPath(path:String):String {
		var normalized = normalizeTemplatePath(path);
		normalized = stripLeadingSlashes(normalized);
		if (!StringTools.endsWith(normalized, ".erb")) {
			normalized += ".html.erb";
		}
		return "app/views/" + normalized;
	}

	public static function testOutputPath(path:String):String {
		var normalized = normalizeTestPath(path);
		normalized = stripLeadingSlashes(normalized);
		if (!StringTools.endsWith(normalized, ".rb")) {
			normalized += ".rb";
		}
		return "test/generated/" + normalized;
	}

	public static function specOutputPath(path:String):String {
		var normalized = normalizeSpecPath(path);
		normalized = stripLeadingSlashes(normalized);
		if (!StringTools.endsWith(normalized, ".rb")) {
			normalized += ".rb";
		}
		return "spec/generated/" + normalized;
	}

	public static function mailerPreviewOutputPath(path:String):String {
		var normalized = normalizeMailerPreviewPath(path);
		normalized = stripLeadingSlashes(normalized);
		if (!StringTools.endsWith(normalized, ".rb")) {
			normalized += ".rb";
		}
		return "test/mailers/previews/" + normalized;
	}

	public static function normalizeRenderPath(path:String):String {
		var normalized = normalizeTemplatePath(path);
		if (StringTools.endsWith(normalized, ".html.erb")) {
			normalized = normalized.substr(0, normalized.length - ".html.erb".length);
		} else if (StringTools.endsWith(normalized, ".erb")) {
			normalized = normalized.substr(0, normalized.length - ".erb".length);
		}
		var segments = normalized.split("/");
		var last = segments.pop();
		if (last != null && StringTools.startsWith(last, "_")) {
			last = last.substr(1);
		}
		if (last != null) {
			segments.push(last);
		}
		return segments.join("/");
	}

	public static function validateTemplatePath(path:String, pos:Position, context:String):Void {
		var normalized = normalizeTemplatePath(path);
		if (isUnsafeRelativePath(path, normalized)) {
			Context.error(context + " path must be a safe Rails template path relative to app/views.", pos);
			return;
		}
		validateSegments(normalized, pos, context);
	}

	public static function validateTestPath(path:String, pos:Position, context:String):Void {
		var normalized = normalizeTestPath(path);
		if (isUnsafeRelativePath(path, normalized)) {
			Context.error(context + " path must be a safe Rails test path relative to test/generated.", pos);
			return;
		}
		if (!StringTools.endsWith(normalized, "_test") && !StringTools.endsWith(normalized, "_test.rb")) {
			Context.error(context + " path must end with _test or _test.rb so Rails/Minitest discovers it.", pos);
			return;
		}
		validateSegments(normalized, pos, context);
	}

	public static function validateSpecPath(path:String, pos:Position, context:String):Void {
		var normalized = normalizeSpecPath(path);
		if (isUnsafeRelativePath(path, normalized)) {
			Context.error(context + " path must be a safe Rails spec path relative to spec/generated.", pos);
			return;
		}
		if (!StringTools.endsWith(normalized, "_spec") && !StringTools.endsWith(normalized, "_spec.rb")) {
			Context.error(context + " path must end with _spec or _spec.rb so RSpec discovers it.", pos);
			return;
		}
		validateSegments(normalized, pos, context);
	}

	public static function validateMailerPreviewPath(path:String, pos:Position, context:String):Void {
		var normalized = normalizeMailerPreviewPath(path);
		if (isUnsafeRelativePath(path, normalized)) {
			Context.error(context + " path must be a safe Rails preview path relative to test/mailers/previews.", pos);
			return;
		}
		if (!StringTools.endsWith(normalized, "_preview") && !StringTools.endsWith(normalized, "_preview.rb")) {
			Context.error(context + " path must end with _preview or _preview.rb so Rails discovers it as a mailer preview.", pos);
			return;
		}
		validateSegments(normalized, pos, context);
	}

	public static function normalizeTemplatePath(path:String):String {
		return StringTools.replace(path == null ? "" : StringTools.trim(path), "\\", "/");
	}

	public static function normalizeTestPath(path:String):String {
		return StringTools.replace(path == null ? "" : StringTools.trim(path), "\\", "/");
	}

	public static function normalizeSpecPath(path:String):String {
		return StringTools.replace(path == null ? "" : StringTools.trim(path), "\\", "/");
	}

	public static function normalizeMailerPreviewPath(path:String):String {
		var normalized = StringTools.replace(path == null ? "" : StringTools.trim(path), "\\", "/");
		while (StringTools.startsWith(normalized, "test/mailers/previews/")) {
			normalized = normalized.substr("test/mailers/previews/".length);
		}
		return normalized;
	}

	static function stripLeadingSlashes(path:String):String {
		var normalized = path;
		while (StringTools.startsWith(normalized, "/")) {
			normalized = normalized.substr(1);
		}
		return normalized;
	}

	static function isUnsafeRelativePath(original:String, normalized:String):Bool {
		return normalized == ""
			|| StringTools.startsWith(normalized, "/")
			|| normalized.indexOf("..") != -1
			|| normalized.indexOf("//") != -1
			|| original.indexOf("\\") != -1;
	}

	static function validateSegments(normalized:String, pos:Position, context:String):Void {
		for (segment in normalized.split("/")) {
			if (segment == "" || segment == "." || segment == "..") {
				Context.error(context + " path must not contain empty, '.', or '..' segments.", pos);
				return;
			}
		}
	}
}
