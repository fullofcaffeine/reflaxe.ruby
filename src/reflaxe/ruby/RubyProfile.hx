package reflaxe.ruby;

enum abstract RubyProfile(String) from String to String {
	// Keep the constructor name for source compatibility; the public profile spelling is ruby_first.
	var Idiomatic = "ruby_first";
	var Portable = "portable";
}
