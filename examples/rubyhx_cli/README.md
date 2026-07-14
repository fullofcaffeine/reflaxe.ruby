# RubyHx Text Report CLI

This is the maintained framework-independent Haxe-first reference project. Its
owned library and CLI implementation are split across typed Haxe modules; Ruby
remains the runtime and a normal handwritten Ruby program consumes the same
generated `TextAnalyzer` and `TextReportJson` API.

The CLI reads a file and writes a typed JSON report containing its path, line,
word, and character counts. It also owns explicit usage and missing-file exit
codes. The example deliberately needs no third-party runtime gem: installed-gem
interop is covered by the existing RubyHx interop fixtures, while this project
keeps the day-to-day library/CLI lifecycle focused.

Run the complete source-checkout contract:

```bash
npm run test:rubyhx-cli
```

With a verified release ZIP installed through the public package path, the
normal project loop is:

```bash
cd examples/rubyhx_cli
haxe build.hxml
ruby out/ruby/run.rb ../../test/fixtures/rubyhx_cli/sample.txt
```

The smoke test compiles the current source, runs successful and failing CLI
paths, calls the generated library from handwritten Ruby, and proves an invalid
typed call fails during Haxe compilation. The Haxelib package gate separately
installs the exact current candidate ZIP into an isolated repository, copies
this project as external source, compiles it with `-lib reflaxe.ruby`, and runs
the resulting CLI. Public old-release upgrades and rollback are a separate
release-migration contract rather than hidden inside this example.
