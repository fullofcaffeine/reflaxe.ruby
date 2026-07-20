/** Counts the two effectful evaluations exercised by the callable ABI fixture. **/
class WorkerFactory {
	public static var created(default, null):Int = 0;
	public static var positionalEvaluations(default, null):Int = 0;

	public static function make():BlockChild {
		created += 1;
		return new BlockChild();
	}

	public static function positionalValue():Int {
		positionalEvaluations += 1;
		return 9;
	}
}
