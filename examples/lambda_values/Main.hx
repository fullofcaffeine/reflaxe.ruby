// Lambda/function-value smoke.
//
// Demonstrates: Haxe function literals lowered to Ruby callable values.
// Type safety: the lambda parameter and return are both `Int`; calling it with a
// non-`Int` argument or returning the wrong type fails before Ruby is emitted.
// IntelliSense: editors should show `addOne` as `Int -> Int` after inference.
// Ruby output: a Ruby lambda/proc-shaped value called through the compiler's
// normal call lowering.
class Main {
	static function main():Void {
		var addOne = function(x:Int):Int {
			return x + 1;
		};
		Sys.println(addOne(2));
	}
}
