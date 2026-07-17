#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "active_support_facades");
const extensionsOnlyOutputDir = join(root, "test", ".generated", "active_support_facades_extensions_only");
const invalidOutputRoot = join(root, "test", ".generated", "active_support_facades_invalid");
const requireRails = process.env.REQUIRE_RAILS === "1" || process.env.CI_REQUIRE_RAILS === "1";
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
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

rmSync(outputDir, { force: true, recursive: true });
rmSync(extensionsOnlyOutputDir, { force: true, recursive: true });
rmSync(invalidOutputRoot, { force: true, recursive: true });

for (const facadePath of [
  "std/rails/active_support/RailsTime.hx",
  "std/rails/active_support/TimeZone.hx",
  "std/rails/active_support/TimeWithZone.hx",
]) {
  const facadeSource = readFileSync(join(root, facadePath), "utf8");
  const facadeCode = facadeSource.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/.*$/gm, "");
  for (const forbidden of [/\bDynamic\b/, /\bAny\b/, /\buntyped\b/, /\bcast\b/, /__ruby__/, /#if\s+ruby/]) {
    if (forbidden.test(facadeCode)) {
      console.error(`${facadePath} widens the typed native boundary with ${forbidden}`);
      process.exit(1);
    }
  }
}

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for active_support_facades.");
  process.exit(1);
}

run("haxe", [
  "-D",
  `ruby_output=${outputDir}`,
  "-D",
  "reflaxe_runtime",
  "-cp",
  join(root, "src"),
  "-cp",
  join(root, "examples", "active_support_facades"),
  "-cp",
  reflaxeSrc,
  "--macro",
  "reflaxe.ruby.CompilerBootstrap.Start()",
  "--macro",
  "reflaxe.ruby.CompilerInit.Start()",
  "-main",
  "Main",
]);
run("haxe", [
  "-D",
  `ruby_output=${extensionsOnlyOutputDir}`,
  "-D",
  "reflaxe_runtime",
  "-cp",
  join(root, "src"),
  "-cp",
  join(root, "test", "active_support_facades", "extensions_only"),
  "-cp",
  reflaxeSrc,
  "--macro",
  "reflaxe.ruby.CompilerBootstrap.Start()",
  "--macro",
  "reflaxe.ruby.CompilerInit.Start()",
  "-main",
  "ExtensionsOnly",
]);

for (const [mainClass, expectedDiagnostic] of [
  ["InvalidZoneInput", "Int should be String"],
  ["InvalidTimeWithZoneConstruction", "does not have a constructor"],
  ["InvalidPermissiveTimeParse", "has no field parse"],
]) {
  const result = run("haxe", [
    "-D",
    `ruby_output=${join(invalidOutputRoot, mainClass)}`,
    "-D",
    "reflaxe_runtime",
    "-cp",
    join(root, "src"),
    "-cp",
    join(root, "test", "active_support_facades", "invalid"),
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    mainClass,
  ], { allowFailure: true });
  if (result.status === 0) {
    console.error(`${mainClass} unexpectedly compiled`);
    process.exit(1);
  }
  const diagnostic = `${result.stdout}\n${result.stderr}`;
  if (!diagnostic.includes(expectedDiagnostic)) {
    console.error(diagnostic);
    console.error(`${mainClass} did not produce expected diagnostic: ${expectedDiagnostic}`);
    process.exit(1);
  }
}

for (const file of ["hxruby/core.rb", "main.rb", "run.rb"]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
}

const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
const expectedRequires = [
  'require "active_support/core_ext/object/blank"',
  'require "active_support/core_ext/string/filters"',
  'require "active_support"',
  'require "active_support/time"',
  'require "date"',
];
for (const generatedFile of ["main.rb", "run.rb"]) {
  const generated = readFileSync(join(outputDir, generatedFile), "utf8");
  for (const expected of expectedRequires) {
    const count = generated.split(expected).length - 1;
    if (count !== 1) {
      console.error(`Expected exactly one deduplicated require in ${generatedFile}: ${expected}; got ${count}`);
      console.error(generated);
      process.exit(1);
    }
  }
}
if (runRuby.indexOf('require "active_support"') > runRuby.indexOf('require "active_support/time"')) {
  console.error('run.rb must load base ActiveSupport before its time extensions');
  console.error(runRuby);
  process.exit(1);
}

for (const generatedFile of ["extensions_only.rb"]) {
  const generated = readFileSync(join(extensionsOnlyOutputDir, generatedFile), "utf8");
  for (const unexpected of ['require "active_support"', 'require "active_support/time"', 'require "date"']) {
    if (generated.includes(unexpected)) {
      console.error(`Receiver-only ActiveSupport use unexpectedly loaded a temporal dependency in ${generatedFile}: ${unexpected}`);
      console.error(generated);
      process.exit(1);
    }
  }
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /title(?:__hx\d+)?\.squish\(\)/,
  /normalized(?:__hx\d+)?\.presence\(\)/,
  /""\.blank\?\(\)/,
  /normalized(?:__hx\d+)?\.present\?\(\)/,
  /Time\.find_zone!\("America\/New_York"\)/,
  /zone(?:__hx\d+)?\.local\(2026, 7, 17, 12, 30, 0\)/,
  /zone(?:__hx\d+)?\.at\(/,
  /zone(?:__hx\d+)?\.iso8601\("2026-07-17T12:30:00-04:00"\)/,
  /zone(?:__hx\d+)?\.rfc3339\("2026-07-17T16:30:00Z"\)/,
  /Time\.find_zone\("Not\/A_Real_Zone"\)/,
  /Time\.zone\(\)\.name\(\)/,
  /Time\.current\(\)\.time_zone\(\)\.name\(\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`Expected ActiveSupport receiver call shape missing from main.rb: ${expected}`);
    console.error(mainRuby);
    process.exit(1);
  }
}
if (/class (?:Time|TimeZone|TimeWithZone)\b|class ActiveSupport::Time(?:Zone|WithZone)\b|HXRuby\.(?:time|timeZone|timeWithZone)/.test(mainRuby)) {
  console.error("Rails temporal facades must dispatch directly without generated wrappers or runtime helpers");
  console.error(mainRuby);
  process.exit(1);
}

const activeSupportCheck = run("ruby", [
  "-e",
  'require "active_support/core_ext/object/blank"; require "active_support/core_ext/string/filters"',
], { allowFailure: true });

if (activeSupportCheck.status !== 0) {
  if (requireRails) {
    console.error("[active-support-facades] REQUIRE_RAILS=1 but ActiveSupport could not be loaded.");
    process.exit(1);
  }
  console.log("[active-support-facades] ActiveSupport is unavailable; skipped runtime facade pass.");
  console.log("[active-support-facades] Static compile and generated Ruby shape checks passed.");
  process.exit(0);
}

const actual = run("ruby", [
  "-ractive_support",
  "-ractive_support/time",
  "-e",
  'Time.zone_default = Time.find_zone!("UTC"); load ARGV.fetch(0)',
  join(outputDir, "run.rb"),
]).stdout;
const expected = [
  "true",
  "true",
  "true",
  "Ship typed Rails",
  "America/New_York",
  "America/New_York",
  "-18000",
  "-05:00",
  "2026",
  "7",
  "17",
  "12",
  "30",
  "0",
  "EDT",
  "America/New_York",
  "true",
  "false",
  "-14400",
  "-0400",
  "2026-07-17T12:30:00-04:00",
  "2026-07-17 12:30:00 -04:00",
  "2026-07-17 12:30:00 -0400",
  "2026-07-17T12:30:00-04:00",
  "2026-07-17T12:30:00-04:00",
  "2026-07-17T12:30:00-04:00",
  "2026-07-17T12:31:30.500-04:00",
  "90.5",
  "2026-07-17T12:30:00-04:00",
  "true",
  "true",
  "UTC",
  "UTC",
  "",
].join("\n");

if (actual !== expected) {
  console.error("active_support_facades stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}
