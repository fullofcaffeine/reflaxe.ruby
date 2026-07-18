import ruby.RegexpOptions;

class InvalidOptionBits {
	static function main():Void {
		RegexpOptions.fromBits(8);
	}
}
