package ruby;

/**
	Opt-in Ruby-style helper names for Haxe-authored Ruby code.

	These are deliberately normal static imports instead of compiler-global names:
	`import ruby.Prelude.puts; puts(value);` reads like Ruby, while the import makes
	the choice visible to editors, reviewers, and other Haxe targets. The helpers
	delegate to `Sys` so they keep Haxe/RubyHx stringification semantics; use
	`ruby.Kernel.puts` when you specifically want Ruby Kernel's native conversion.
**/
class Prelude {
	public static inline function puts(value:Dynamic):Void {
		Sys.println(value);
	}

	public static inline function print(value:Dynamic):Void {
		Sys.print(value);
	}
}
