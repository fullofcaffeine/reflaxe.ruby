import domain.TodoDraftVectors;
import js.Syntax;

/**
	Node entrypoint for the executable two-target domain contract.

	`process.stdout` is intentionally isolated at this JavaScript test seam. The
	shared vectors and todo behavior contain no JavaScript, Ruby, or Rails API.
**/
class JavaScriptMain {
	static function main():Void {
		Syntax.code("process.stdout.write({0})", TodoDraftVectors.render());
	}
}
