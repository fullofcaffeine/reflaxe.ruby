import ruby.CSV;
import ruby.CSVGenerateOptions;
import ruby.CSVParseOptions;
import ruby.CSVRow;

/**
	Executable contract for the typed `ruby.CSV` facade.

	The sample exercises nullable fields, whole-string and file parsing, typed
	keyword completion, native block iteration, and deterministic generation.
	Generated Ruby should contain one `require "csv"` plus direct `CSV.*` calls.
**/
class Main {
	static function main():Void {
		var empty = CSV.parseLine("");
		Sys.println(empty == null);

		var parsed = CSV.parseLine('alpha,,""');
		if (parsed == null) {
			throw "a populated CSV line must produce a row";
		}
		printRow(parsed);

		var rows = CSV.parseRows("alpha,1\nbeta,\n");
		Sys.println(rows.length);
		printRow(rows[0]);
		printRow(rows[1]);

		var parseOptions:CSVParseOptions = {
			columnSeparator: ";",
			maxFieldSize: 64,
			skipBlankRows: true,
			stripFields: true
		};
		var customRows = CSV.parseRowsWith(" alpha ; 1 \n\n beta ; \n", parseOptions);
		Sys.println(customRows.length);
		printRow(customRows[0]);
		printRow(customRows[1]);

		var fixturePath = "test/csv_facade/fixtures/rows.csv";
		var fileRows = CSV.readRows(fixturePath);
		Sys.println(fileRows.length);
		printRow(fileRows[0]);
		printRow(fileRows[1]);

		var visited = 0;
		CSV.forEachRow(fixturePath, function(row) {
			visited++;
			Sys.println("visit:" + row[0]);
		});
		Sys.println("visited:" + visited);

		var visitedWith = 0;
		CSV.forEachRowWith(fixturePath, {maxFieldSize: 64}, function(row) {
			visitedWith += row.length;
		});
		Sys.println("visited-fields:" + visitedWith);

		var generatedRow:CSVRow = ["alpha", null, ""];
		Sys.print(CSV.generateLine(generatedRow));
		Sys.print(CSV.generateLineWith(generatedRow, {columnSeparator: ";"}));

		var generatedRows:Array<CSVRow> = [["alpha", "1"], ["beta", null]];
		Sys.print(CSV.generateRows(generatedRows));
		var generateOptions:CSVGenerateOptions = {columnSeparator: ";", rowSeparator: "|"};
		Sys.println(CSV.generateRowsWith(generatedRows, generateOptions));
	}

	static function printRow(row:CSVRow):Void {
		Sys.println(row.length + ":" + row.map(field -> field == null ? "<null>" : field).join("|"));
	}
}
