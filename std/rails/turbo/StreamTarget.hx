package rails.turbo;

abstract StreamTarget(String) to String from String {
	public inline function new(value:String) {
		this = value;
	}

	public static inline function named(name:String):StreamTarget {
		return new StreamTarget(name);
	}
}
