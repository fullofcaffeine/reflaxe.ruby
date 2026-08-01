/** Proves that an uncaught target-runtime failure remains nonzero. **/
class RuntimeFailureMain {
	static function main():Void {
		throw "intentional-public-install-runtime-failure";
	}
}
