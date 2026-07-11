package ruby;

/**
	Checked subset of Ruby `Array#pack`/`String#unpack1` directives used by RubyHx.

	Keeping these directives nominal prevents arbitrary format strings from
	drifting away from the statically declared result type at binary interop
	boundaries. The values still erase to ordinary Ruby format strings.
**/
enum abstract BinaryFormat(String) {
	var BytesUnsigned = "C*";
	var Float32LittleEndian = "e";
	var Float64LittleEndian = "E";
	var Int32LittleEndian = "l<";
	var TwoInt32LittleEndian = "l<l<";
}
