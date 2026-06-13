package blog_engine.services;

// Demonstrates: Haxe-authored code intended to ship from a Rails engine/plugin
// under an engine-local Rails output root.
// Type safety: host apps consume the generated Ruby constant normally, while
// engine authors keep Haxe compile-time checks for method arity and argument
// types.
// Rails output: with `-D reflaxe_ruby_rails_output_root=engines/blog/app/haxe_gen`,
// this emits `engines/blog/app/haxe_gen/blog_engine/services/engine_greeting.rb`
// and the autoload initializer points Rails at that generated root.
class EngineGreeting {
	public static function message(name:String):String {
		return "RailsHx engine says hello to " + name;
	}
}
