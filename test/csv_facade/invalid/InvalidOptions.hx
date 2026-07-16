import ruby.CSV;

/** Compile-fail contract: header mode changes rows to CSV::Row and is not in this facade. **/
class InvalidOptions {
	static function main():Void {
		CSV.parseRowsWith("name,value\n", {headers: true});
	}
}
