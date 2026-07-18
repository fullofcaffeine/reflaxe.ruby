package ruby;

/**
	Composable, closed option bits for native Ruby `Regexp` construction.

	A Haxe abstract keeps arbitrary integers out of the public constructor while
	erasing to the exact option bit mask Ruby accepts. The exposed values are the
	stable cross-version `IGNORECASE`, `EXTENDED`, and `MULTILINE` bits; encoding
	flags and Ruby-internal option bits remain outside this bounded contract.
	`@:rubyNoEmit` prevents an empty Ruby module after the inline values erase.
**/
@:rubyNoEmit
extern abstract RegexpOptions(Int) {
	public static inline final none:RegexpOptions = new RegexpOptions(0);
	public static inline final ignoreCase:RegexpOptions = new RegexpOptions(1);
	public static inline final extended:RegexpOptions = new RegexpOptions(2);
	public static inline final multiline:RegexpOptions = new RegexpOptions(4);

	private inline function new(bits:Int) {
		this = bits;
	}

	/** Combines two supported option sets without exposing an open integer. **/
	@:op(A | B)
	public inline function combine(other:RegexpOptions):RegexpOptions {
		return new RegexpOptions(this | other.bits());
	}

	private inline function bits():Int {
		return this;
	}
}
