# Handwritten Ruby consumer of the Haxe-owned text-report library. Keeping this
# outside generated output proves ordinary Ruby can require and call the public
# class methods without a wrapper generated specifically for the test.
require "text_analyzer"
require "text_report_json"

report = TextAnalyzer.analyze("memory.txt", "one two\nthree\n")
parsed = JSON.parse(TextReportJson.encode(report))
expected = {"path" => "memory.txt", "lines" => 2, "words" => 3, "characters" => 14}
abort "Ruby-origin report mismatch: #{parsed.inspect}" unless parsed == expected

puts [parsed.fetch("path"), parsed.fetch("lines"), parsed.fetch("words"), parsed.fetch("characters")].join("|")
