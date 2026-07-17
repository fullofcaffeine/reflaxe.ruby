#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "time_date_facade");
const timeOnlyOutputDir = join(root, "test", ".generated", "time_date_facade_time_only");
const invalidOutputRoot = join(root, "test", ".generated", "time_date_facade_invalid");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function fail(message) {
  console.error(`[time-date-facade] ERROR: ${message}`);
  process.exit(1);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    env: { ...process.env, ...(options.env ?? {}) },
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0 && !options.allowFailure) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

for (const facadePath of ["std/ruby/Time.hx", "std/ruby/Date.hx"]) {
  const facadeSource = readFileSync(join(root, facadePath), "utf8");
  const facadeCode = facadeSource.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/.*$/gm, "");
  for (const forbidden of [/\bDynamic\b/, /\bAny\b/, /\buntyped\b/, /\bcast\b/, /__ruby__/, /#if\s+ruby/]) {
    if (forbidden.test(facadeCode)) fail(`${facadePath} widens the typed native boundary with ${forbidden}`);
  }
}

const timeSource = readFileSync(join(root, "std", "ruby", "Time.hx"), "utf8");
const dateSource = readFileSync(join(root, "std", "ruby", "Date.hx"), "utf8");
if (!timeSource.includes('@:native("Time")') || !timeSource.includes("extern class Time")) {
  fail("ruby.Time must remain a direct core native extern");
}
if (timeSource.includes("@:rubyRequire")) fail("core ruby.Time must remain require-free");
if (!dateSource.includes('@:rubyRequire("date")') || !dateSource.includes("extern class Date")) {
  fail('ruby.Date must remain a direct native extern behind require "date"');
}
if (existsSync(join(root, "std", "ruby", "DateTime.hx"))) fail("DateTime must remain outside this bounded slice");

rmSync(outputDir, { force: true, recursive: true });
rmSync(timeOnlyOutputDir, { force: true, recursive: true });
rmSync(invalidOutputRoot, { force: true, recursive: true });
const reflaxeSrc = reflaxeCandidates.find((candidate) => existsSync(join(candidate, "reflaxe", "ReflectCompiler.hx")));
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
  join(root, "test", "time_date_facade", "src_haxe"),
  ...baseHaxeArgs,
  "-main",
  "Main",
]);
run("haxe", [
  "-D",
  `ruby_output=${timeOnlyOutputDir}`,
  "-cp",
  join(root, "test", "time_date_facade", "time_only"),
  ...baseHaxeArgs,
  "-main",
  "TimeOnly",
]);

for (const [generatedDir, generatedFiles] of [
  [outputDir, ["hxruby/core.rb", "hx_date.rb", "main.rb", "run.rb"]],
  [timeOnlyOutputDir, ["hxruby/core.rb", "time_only.rb"]],
]) {
  for (const generatedFile of generatedFiles) {
    if (!existsSync(join(generatedDir, generatedFile))) fail(`expected generated Ruby file missing: ${generatedFile}`);
  }
}
if (existsSync(join(outputDir, "date.rb"))) fail("portable Haxe Date output must not shadow Ruby's date feature");

for (const generatedFile of ["main.rb", "run.rb"]) {
  const generated = readFileSync(join(outputDir, generatedFile), "utf8");
  if ((generated.match(/require "date"/g) ?? []).length !== 1) {
    fail(`${generatedFile} must contain exactly one deduplicated require "date"`);
  }
  if (/require "time"/.test(generated)) fail(`${generatedFile} must not widen core Time into the default-gem time parser`);
}

const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
if (runRuby.indexOf('require "date"') > runRuby.indexOf("$LOAD_PATH.unshift(__dir__)")) {
  fail('run.rb must load Ruby\'s date feature before adding generated files to $LOAD_PATH');
}
for (const generatedFile of ["time_only.rb"]) {
  const generated = readFileSync(join(timeOnlyOutputDir, generatedFile), "utf8");
  if (/require "(?:date|time)"/.test(generated)) fail(`Time-only ${generatedFile} must remain require-free`);
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expectedShape of [
  /Time\.utc\(2024, 2, 29, 12, 34, 56\)/,
  /Time\.at\(1709210096\.0\)/,
  /Time\.local\(2024, 2, 29, 12, 34, 56\)/,
  /Time\.now\(\)\.year\(\)/,
  /utc(?:__hx\d+)?\.utc\?\(\)/,
  /utc(?:__hx\d+)?\.dst\?\(\)/,
  /utc(?:__hx\d+)?\.utc_offset\(\)/,
  /utc(?:__hx\d+)?\.getlocal\(7200\)/,
  /utc(?:__hx\d+)?\.getlocal\(\)\.getutc\(\)/,
  /later = \(utc(?:__hx\d+)? \+ 90\.5\)/,
  /\(later(?:__hx\d+)? - utc(?:__hx\d+)?\)/,
  /\(later(?:__hx\d+)? - 90\.5\)\.strftime/,
  /Date\.new\(2024, 2, 29\)/,
  /Date\.iso8601\("2025-12-31"\)/,
  /Date\.strptime\("31\/12\/2025", "%d\/%m\/%Y"\)/,
  /Date\.today\(\)\.year\(\)/,
  /HxDate\.new\(2024, 1, 29, 0, 0, 0\)/,
  /leap(?:__hx\d+)?\.leap\?\(\)/,
  /leap(?:__hx\d+)?\.next_day\(2\)/,
  /leap(?:__hx\d+)?\.prev_month\(\)/,
  /leap(?:__hx\d+)?\.iso8601\(\)/,
]) {
  if (!expectedShape.test(mainRuby)) {
    console.error(mainRuby);
    fail(`expected direct Time/Date shape missing from main.rb: ${expectedShape}`);
  }
}
const haxeDateRuby = readFileSync(join(outputDir, "hx_date.rb"), "utf8");
if (!/class HxDate\b/.test(haxeDateRuby) || /class Date\b/.test(haxeDateRuby)) {
  fail("portable Haxe Date must use its collision-safe HxDate Ruby constant");
}
if (/class (?:Time|Date)\b|Ruby::(?:Time|Date)|HXRuby\.(?:time|date|Time|Date)/.test(mainRuby)) {
  fail("Time/Date facades must dispatch directly without generated wrappers or runtime helpers");
}

assertCompileFailure("InvalidTimeInput", "String should be Int");
assertCompileFailure("InvalidTimeArithmetic", "String should be Float");
assertCompileFailure("InvalidDateInput", "String should be Null<Int>");
assertCompileFailure("InvalidDateFormat", "Int should be String");
assertCompileFailure("InvalidDateTime", "Type not found : ruby.DateTime");

const actual = run("ruby", [join(outputDir, "run.rb")], { env: { TZ: "UTC" } }).stdout;
const expected = [
  "2024",
  "2",
  "29",
  "12",
  "34",
  "56",
  "4",
  "60",
  "true",
  "false",
  "0",
  "UTC",
  "2024-02-29 12:34:56 +0000",
  "true",
  "true",
  "2024-02-29 12:36:26.500",
  "90.5",
  "12:34:56",
  "14:34:56 +0200",
  "12:34:56 +0000",
  "2024-02-29 12:34:56",
  "false",
  "true",
  "2024-02-29",
  "2024",
  "2",
  "29",
  "4",
  "60",
  "2024",
  "9",
  "4",
  "true",
  "2024-03-01",
  "2024-03-02",
  "2024-02-28",
  "2024-03-29",
  "2024-01-29",
  "2025-02-28",
  "2023-02-28",
  "Thursday, 29 February 2024",
  "2025-12-31",
  "2025-12-31",
  "true",
  "1",
].join("\n") + "\n";
if (actual !== expected) {
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  fail("runtime stdout mismatch");
}

const timeOnlyActual = run("ruby", ["-I", timeOnlyOutputDir, "-rtime_only", "-e", "TimeOnly.main"], { env: { TZ: "UTC" } }).stdout;
if (timeOnlyActual !== "2024-W09-4\n") fail("require-free core Time runtime contract mismatch");

const versions = run("ruby", [
  "-rdate",
  "-e",
  'spec = Gem.loaded_specs["date"]; print RUBY_VERSION, " / date ", (spec ? spec.version : "stdlib")',
]).stdout;
console.log(`[time-date-facade] OK: direct core Time and strict Date behavior pass MRI ${versions}`);

function assertCompileFailure(mainClass, expectedDiagnostic) {
  const result = run(
    "haxe",
    [
      "-D",
      `ruby_output=${join(invalidOutputRoot, mainClass)}`,
      "-cp",
      join(root, "test", "time_date_facade", "invalid"),
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
