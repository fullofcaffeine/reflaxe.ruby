package ruby;

/**
	Typed keyword configuration for bounded native `Regexp` construction.

	The optional field preserves omission separately from an explicit `null`.
	Callers compiling a pattern that is not fully trusted should set a small,
	workload-appropriate timeout and still bound the input size.
**/
typedef RegexpCompileOptions = {
	/** Per-match timeout in seconds; `null` falls back to Ruby's class default. **/
	@:optional
	@:native("timeout")
	var timeoutSeconds:Null<Float>;
}
