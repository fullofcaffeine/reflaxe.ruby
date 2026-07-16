import domain.TodoDraftVectors;

/**
	Ruby entrypoint for the executable two-target domain contract.

	The vectors and behavior remain target-neutral. Only stdout belongs here
	because `Sys.print` is a system-target API rather than a browser API.
**/
class Main {
	static function main():Void {
		Sys.print(TodoDraftVectors.render());
	}
}
