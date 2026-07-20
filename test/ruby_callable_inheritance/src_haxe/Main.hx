// Callable inheritance and method-value executable contract.
//
// Type safety: one Haxe function type is used for direct, inherited, interface,
// captured, recursive, module, and concern calls.
// Generated Ruby: direct dispatch stays wrapper-free; only first-class method
// capture emits a documented lambda that restores native keywords/blocks.
class Main {
	static function main():Void {
		var child = new BlockChild();
		Sys.println(child.visit(1, value -> "direct:" + value));
		var base:BlockBase = child;
		Sys.println(base.visit(2, value -> "base:" + value));
		Sys.println(child.recursive(2, value -> "recursive:" + value));

		var worker = new InterfaceWorker();
		var api:BlockApi = worker;
		Sys.println(worker.visit(3, value -> "impl:" + value));
		Sys.println(api.visit(4, value -> "api:" + value));

		var staticBlock = StaticCallables.decorate;
		Sys.println(staticBlock(5, value -> "static-value:" + value));
		var instanceBlock = child.visit;
		Sys.println(instanceBlock(6, value -> "instance-value:" + value));
		var interfaceBlock = api.visit;
		Sys.println(interfaceBlock(7, value -> "interface-value:" + value));
		// A user-authored block is not an abstract identity carrier: its discarded
		// initializer must still run before the final positional value is passed.
		Sys.println(child.visit({
			var positional = WorkerFactory.positionalValue();
			positional = 15;
			positional;
		}, value -> "positional:" + value));
		Sys.println("positional-evaluations:" + WorkerFactory.positionalEvaluations);
		// A side-effecting receiver must be evaluated once when a plain method value
		// is captured; IntelliSense still exposes the precise Int->String type.
		var effectfulPlain = WorkerFactory.make().plain;
		Sys.println(effectfulPlain(8));
		Sys.println("plain-factory-count:" + WorkerFactory.created);
		var effectfulBlock = WorkerFactory.make().visit;
		Sys.println(effectfulBlock(8, value -> "effectful:" + value));
		Sys.println("factory-count:" + WorkerFactory.created);
		var nativeChild = new NativeBlockChild();
		Sys.println(nativeChild.transform(9, value -> "direct-native:" + value));
		var nativeValue = nativeChild.transform;
		Sys.println(nativeValue(10, value -> "captured-native:" + value));

		var staticKeyword = StaticCallables.label;
		Sys.println("static-keyword:" + staticKeyword({prefix: "one"}));
		var optionalBlock = StaticCallables.optional;
		Sys.println(optionalBlock(11));
		Sys.println(optionalBlock(12, value -> "optional-value:" + value));
		var combined = StaticCallables.compose;
		Sys.println(combined({prefix: "combined"}, value -> "combined-value:" + value));
		var restValue = StaticCallables.join;
		Sys.println(restValue("rest:", 1, 2));
		var spread = [3, 4];
		Sys.println(restValue("spread:", ...spread));
		var keyword = new KeywordChild();
		var keywordValue = keyword.configure;
		Sys.println(keywordValue({prefix: "two", suffix: null}));

		var moduleValue = new ModuleCallableReceiver().moduleVisit;
		Sys.println(moduleValue(13, value -> "module:" + value));
		var concernValue = new ConcernCallableReceiver().concernVisit;
		Sys.println(concernValue(14, value -> "concern:" + value));
	}
}
