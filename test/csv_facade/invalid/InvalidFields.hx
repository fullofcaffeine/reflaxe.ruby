import ruby.CSV;
import ruby.CSVRow;

/** Compile-fail contract: arbitrary Ruby field objects are outside the string-row surface. **/
class InvalidFields {
	static function main():Void {
		var row:CSVRow = ["typed", 42];
		CSV.generateLine(row);
	}
}
