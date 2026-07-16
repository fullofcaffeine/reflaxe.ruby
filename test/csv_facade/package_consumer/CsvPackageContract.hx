import ruby.CSV;

/** Installed-Haxelib contract for all CSV facade support types and direct runtime calls. **/
class CsvPackageContract {
	public static function verify():Void {
		var row = CSV.parseLineWith('packaged;;""', {columnSeparator: ";"});
		if (row == null || row[0] != "packaged" || row[1] != null || row[2] != "") {
			throw "packaged CSV parse mismatch";
		}
		if (CSV.generateLineWith(row, {columnSeparator: ";"}) != 'packaged;;""\n') {
			throw "packaged CSV generation mismatch";
		}
	}
}
