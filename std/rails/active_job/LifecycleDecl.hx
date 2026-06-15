package rails.active_job;

/**
	Compiler-owned marker calls for ActiveJob lifecycle declarations.

	`rails.macros.JobDsl` expands contextual Haxe calls such as
	`queueAs("mailers")` and `retryOn(StandardError)` into these typed marker
	calls. The Ruby compiler recognizes them only inside an `@:railsJob`
	`lifecycle` field and erases them into normal Rails class macros, so RailsHx
	gets type-checking without introducing a runtime job DSL.
**/
extern class LifecycleDecl {
	public static function queue(name:String):LifecycleDecl;

	public static function retry(exception:String, waitSeconds:Int, attempts:Int, queue:String):LifecycleDecl;

	public static function discard(exception:String):LifecycleDecl;
}
