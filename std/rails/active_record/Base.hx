package rails.active_record;

@:autoBuild(rails.macros.ModelMacro.build())
class Base<T> {
	public function new() {}

	@:native("persisted?")
	@:rubyExternStub
	public function persisted():Bool {
		return false;
	}

	@:native("valid?")
	@:rubyExternStub
	public function valid():Bool {
		return false;
	}

	@:rubyExternStub
	public function save():Bool {
		return false;
	}
}
