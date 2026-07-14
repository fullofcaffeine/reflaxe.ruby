/**
	JSON output boundary for the owned `TextReport` shape.

	Encoding accepts only the precise report typedef; callers cannot pass an
	arbitrary dynamic object. The existing Ruby JSON facade lowers this closed
	shape directly to `JSON.generate(report)` without a generated wrapper.
**/
class TextReportJson {
	public static function encode(report:TextReport):String {
		return ruby.Json.generate(report);
	}
}
