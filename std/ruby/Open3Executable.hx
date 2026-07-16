package ruby;

/**
	A shell-free executable identity for `Open3.capture`.

	Ruby's process APIs interpret `[path, argv0]` as an executable selected
	directly rather than a command line eligible for shell parsing. This abstract
	keeps that two-element representation private while still lowering to the
	native Ruby array form without a wrapper runtime.
**/
abstract Open3Executable(Array<String>) {
	private inline function new(value:Array<String>) {
		this = value;
	}

	/** Runs `path` directly and reports the same value as the child process name. **/
	public static inline function of(path:String):Open3Executable {
		return new Open3Executable([path, path]);
	}

	/** Runs `path` directly while supplying an explicit child `argv[0]` name. **/
	public static inline function named(path:String, processName:String):Open3Executable {
		return new Open3Executable([path, processName]);
	}
}
