/** Ruby process operations used only at the CLI boundary. **/
@:native("Kernel")
extern class ReportCliProcess {
	@:native("warn")
	public static function warn(message:String):Void;

	@:native("exit")
	public static function exit(status:Int):Void;
}

/**
	Framework-independent RubyHx CLI around the typed text-report library.

	Haxe owns argument validation, filesystem access, JSON output, and exit codes.
	The compiler emits ordinary Ruby `File` and `Kernel` calls; there is no CLI
	framework or generated wrapper API for users to learn.
**/
class ReportCli {
	static inline final USAGE_EXIT = 64;
	static inline final INPUT_EXIT = 66;

	public static function execute(args:Array<String>):Void {
		var status = run(args);
		if (status != 0) {
			ReportCliProcess.exit(status);
		}
	}

	public static function run(args:Array<String>):Int {
		if (args.length != 1) {
			ReportCliProcess.warn("Usage: rubyhx-report PATH");
			return USAGE_EXIT;
		}

		var path = args[0];
		if (!sys.FileSystem.exists(path) || sys.FileSystem.isDirectory(path)) {
			ReportCliProcess.warn('rubyhx-report: file not found: $path');
			return INPUT_EXIT;
		}

		var source = sys.io.File.getContent(path);
		var report = TextAnalyzer.analyze(path, source);
		Sys.println(TextReportJson.encode(report));
		return 0;
	}
}
