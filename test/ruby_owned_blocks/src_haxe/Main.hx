// Symmetric Ruby block ABI executable contract.
//
// Type safety: every block has a precise Haxe argument/result type, including
// optional, generic, zero-argument, and multi-argument forms.
// Generated Ruby: direct required calls use `yield`; optional/escaping values
// use `&block`; forwarding uses `&block`; early callback returns use a strict
// lambda; constructors/modules/concerns/patches expose ordinary Ruby blocks.
using StringBlockPatch;

class Main {
	static function main():Void {
		Sys.println("direct:" + OwnedBlocks.direct(5, value -> value + 1));
		Sys.println("instance:" + new OwnedBlocks().instanceDirect(5, value -> value + 2));
		Sys.println("optional:" + OwnedBlocks.optional(3));
		Sys.println("optional:" + OwnedBlocks.optional(4, value -> "value:" + value));
		var absent:Null<Int->String> = null;
		Sys.println("optional-null:" + OwnedBlocks.optional(4, absent));
		var optionalCallback = (value:Int) -> "stored:" + value;
		Sys.println("optional-stored:" + OwnedBlocks.optional(4, optionalCallback));

		var captured = OwnedBlocks.capture(value -> "captured:" + value);
		Sys.println(captured(5));
		Sys.println(OwnedBlocks.forward(6, value -> "forward:" + value));
		Sys.println(OwnedBlocks.nested(7, value -> "nested:" + value));
		Sys.println("sum:" + OwnedBlocks.sum([1, 2, 3], value -> value * 2));
		Sys.println("zero:" + OwnedBlocks.zero(() -> "zero"));
		Sys.println("pair:" + OwnedBlocks.pair(3, 4, (left, right) -> left + right));

		var constructed = new BlockConstructed(8, value -> "ctor:" + value);
		Sys.println(constructed.rendered);
		Sys.println(new ModuleReceiver().decorateFromModule(9, value -> "module:" + value));
		Sys.println(new ConcernReceiver().decorateFromConcern(10, value -> "concern:" + value));
		Sys.println("patch".decorate(value -> value.toUpperCase()));

		// This non-tail return must stay local to the callback. A plain Ruby block
		// would return from Main.main and incorrectly skip `after-early`.
		var early = OwnedBlocks.direct(11, function(value) {
			if (value > 0) {
				return "early:" + value;
			}
			return "fallback";
		});
		Sys.println(early);
		Sys.println("after-early");

		// The nested function owns its own return. It must not force the outer
		// tail-safe callback away from a normal native block.
		var nestedReturn = OwnedBlocks.direct(12, function(value) {
			var add = function():Int {
				return value + 3;
			};
			return add();
		});
		Sys.println("nested-return:" + nestedReturn);

		try {
			OwnedBlocks.direct(1, function(_):String {
				throw "block-boom";
			});
		} catch (error:String) {
			Sys.println("throw:" + error);
		}
		Sys.println("after-throw");
	}
}
