package ruby;

abstract Symbol(String) from String to String {
	public static function of(value:String):Symbol {
		return cast value;
	}

	public function toString():String {
		return this;
	}
}
