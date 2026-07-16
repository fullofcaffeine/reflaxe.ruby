#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "csv_facade");
const invalidOutputRoot = join(root, "test", ".generated", "csv_facade_invalid");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function fail(message) {
  console.error(`[csv-facade] ERROR: ${message}`);
  process.exit(1);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0 && !options.allowFailure) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

const facadePaths = [
  "std/ruby/CSV.hx",
  "std/ruby/CSVRow.hx",
  "std/ruby/CSVParseOptions.hx",
  "std/ruby/CSVGenerateOptions.hx",
];
for (const path of facadePaths) {
  const source = readFileSync(join(root, path), "utf8");
  for (const forbidden of [/\bDynamic\b/, /\bAny\b/, /\buntyped\b/, /\bcast\b/, /__ruby__/, /#if\s+ruby/]) {
    if (forbidden.test(source)) fail(`${path} widens the typed native boundary with ${forbidden}`);
  }
}

rmSync(outputDir, { force: true, recursive: true });
rmSync(invalidOutputRoot, { force: true, recursive: true });
const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) fail("unable to find vendored Reflaxe source");

const baseHaxeArgs = [
  "-D",
  "reflaxe_runtime",
  "-cp",
  join(root, "src"),
  "-cp",
  reflaxeSrc,
  "--macro",
  "reflaxe.ruby.CompilerBootstrap.Start()",
  "--macro",
  "reflaxe.ruby.CompilerInit.Start()",
];

run("haxe", [
  "-D",
  `ruby_output=${outputDir}`,
  "-cp",
  join(root, "test", "csv_facade", "src_haxe"),
  ...baseHaxeArgs,
  "-main",
  "Main",
]);

for (const file of ["hxruby/core.rb", "main.rb", "run.rb"]) {
  if (!existsSync(join(outputDir, file))) fail(`expected generated Ruby file missing: ${file}`);
}

for (const file of ["main.rb", "run.rb"]) {
  const generated = readFileSync(join(outputDir, file), "utf8");
  if ((generated.match(/require "csv"/g) ?? []).length !== 1) {
    fail(`${file} must contain exactly one deduplicated require "csv"`);
  }
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /CSV\.parse_line\(""\)/,
  /CSV\.parse_line\("alpha,,\\"\\""\)/,
  /CSV\.parse\("alpha,1\\nbeta,\\n"\)/,
  /CSV\.parse\(" alpha ; 1 \\n\\n beta ; \\n",/,
  /col_sep:/,
  /max_field_size:/,
  /skip_blanks:/,
  /strip:/,
  /CSV\.read\(fixture_path(?:__hx\d+)?\)/,
  /CSV\.foreach\(fixture_path(?:__hx\d+)?\) do \|row\|/,
  /CSV\.foreach\(fixture_path(?:__hx\d+)?, max_field_size: 64\) do \|row(?:__hx\d+)?\|/,
  /CSV\.generate_line\(generated_row(?:__hx\d+)?\)/,
  /CSV\.generate_line\(generated_row(?:__hx\d+)?, col_sep: ";"\)/,
  /CSV\.generate_lines\(generated_rows(?:__hx\d+)?\)/,
  /CSV\.generate_lines\(generated_rows(?:__hx\d+)?,/,
  /row_sep:/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(mainRuby);
    fail(`expected direct CSV shape missing from main.rb: ${expected}`);
  }
}
if (/Ruby::CSV|HXRuby\.(?:csv|CSV)|class CSV(?:\s|$)/.test(mainRuby)) {
  fail("CSV facade must dispatch directly without a generated wrapper or runtime helper");
}

assertCompileFailure("InvalidOptions", "has extra field headers");
assertCompileFailure("InvalidFields", "Int should be Null<String>");

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = [
  "true",
  "3:alpha|<null>|",
  "2",
  "2:alpha|1",
  "2:beta|<null>",
  "2",
  "2:alpha|1",
  "2:beta|<null>",
  "2",
  "2:name|value",
  "2:alpha|1",
  "visit:name",
  "visit:alpha",
  "visited:2",
  "visited-fields:4",
  'alpha,,""',
  'alpha;;""',
  "alpha,1",
  "beta,",
  "alpha;1|beta;|",
  "",
].join("\n");
if (actual !== expected) {
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  fail("runtime stdout mismatch");
}

const csvVersion = run("ruby", ["-rcsv", "-e", "print CSV::VERSION"]).stdout;
console.log(`[csv-facade] OK: typed facade compiles to direct CSV calls and passes MRI csv ${csvVersion} runtime behavior`);

function assertCompileFailure(mainClass, expectedDiagnostic) {
  const result = run(
    "haxe",
    [
      "-D",
      `ruby_output=${join(invalidOutputRoot, mainClass)}`,
      "-cp",
      join(root, "test", "csv_facade", "invalid"),
      ...baseHaxeArgs,
      "-main",
      mainClass,
    ],
    { allowFailure: true },
  );
  if (result.status === 0) fail(`${mainClass} unexpectedly compiled`);
  const diagnostic = `${result.stdout}\n${result.stderr}`;
  if (!diagnostic.includes(expectedDiagnostic)) {
    console.error(diagnostic);
    fail(`${mainClass} did not produce expected diagnostic: ${expectedDiagnostic}`);
  }
}
