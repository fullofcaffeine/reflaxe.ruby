import ruby.Open3;
import ruby.Open3Executable;

/**
	Executable contract for the typed `ruby.Open3` capture facade.

	The sample proves shell-free argv handling, exact stdout/stderr capture,
	nullable process status fields, and both inline and stored Haxe rest calls.
	Generated Ruby should contain one `require "open3"` and direct
	`Open3.capture3([path, argv0], *arguments)` dispatch.
**/
class Main {
	static function main():Void {
		var arguments = [
			"-e",
			"STDOUT.write(ARGV.fetch(0)); STDERR.write(ARGV.fetch(1)); exit(Integer(ARGV.fetch(2)))",
			"literal;$(not-run)",
			"problem",
			"7"
		];
		var failed = Open3.capture(Open3Executable.named("ruby", "rubyhx-open3-child"), ...arguments);
		Sys.println(failed.standardOutput);
		Sys.println(failed.standardError);
		var failedStatus = failed.status;
		Sys.println(failedStatus.exitCode());
		Sys.println(failedStatus.succeeded());
		Sys.println(failedStatus.exited());
		Sys.println(failedStatus.signaled());
		Sys.println(failedStatus.terminationSignal() == null);
		Sys.println(failedStatus.processId() > 0);

		var succeeded = Open3.capture(Open3Executable.of("ruby"), "-e", "STDOUT.write('ok')");
		Sys.println(succeeded.standardOutput);
		Sys.println(succeeded.standardError.length);
		Sys.println(succeeded.status.exitCode());
		Sys.println(succeeded.status.succeeded());
	}
}
