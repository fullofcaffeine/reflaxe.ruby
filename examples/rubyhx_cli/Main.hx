// Haxe-first RubyHx library and CLI reference entrypoint.
//
// Demonstrates: a multi-file typed domain library, filesystem input, JSON
// output, Ruby-native process behavior, and a callable API for handwritten Ruby.
// Type safety: report fields, analyzer inputs, and JSON encoding are checked in
// Haxe; no Dynamic, Any, Reflect, cast, or raw Ruby escape crosses the app API.
// IntelliSense: editors expose TextAnalyzer, TextReport, TextReportJson, and the
// explicit ReportCli result contract.
// Ruby output: ordinary classes plus File, JSON, Kernel.warn, and Kernel.exit.
class Main {
	static function main():Void {
		ReportCli.execute(Sys.args());
	}
}
