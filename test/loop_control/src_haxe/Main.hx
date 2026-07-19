/**
	Executable control-flow contract for RubyHx loops.

	The typed fixture exercises one-time iterable evaluation, nested-loop ownership,
	and Haxe `continue`/`break` behavior. The build macro separately covers the
	residual structural `TFor` path that normal Haxe lowering may otherwise erase.
**/
@:build(LoopStructuralContract.build())
class Main {
	static var iterableBuilds = 0;

	static function buildValues():Array<Int> {
		iterableBuilds++;
		return [1, 2, 3, 4, 5];
	}

	static function main():Void {
		var visited:Array<Int> = [];
		var nested:Array<Int> = [];
		for (value in buildValues()) {
			if (value == 2) {
				continue;
			}
			visited.push(value);
			for (inner in [10, 20, 30]) {
				if (inner == 20) {
					break;
				}
				nested.push(value + inner);
			}
			if (value == 4) {
				break;
			}
		}

		var index = 0;
		var whileVisited:Array<Int> = [];
		while (true) {
			index++;
			if (index == 2) {
				continue;
			}
			whileVisited.push(index);
			if (index == 3) {
				break;
			}
		}

		Sys.println(iterableBuilds);
		Sys.println(visited.join(","));
		Sys.println(nested.join(","));
		Sys.println(whileVisited.join(","));
	}
}
