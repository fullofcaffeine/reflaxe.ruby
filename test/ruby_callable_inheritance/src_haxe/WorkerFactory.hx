/** Counts side-effecting receiver evaluation at method-value capture. **/
class WorkerFactory {
	public static var created(default, null):Int = 0;

	public static function make():BlockChild {
		created += 1;
		return new BlockChild();
	}
}
