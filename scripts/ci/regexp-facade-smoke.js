#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "regexp_facade");
const invalidOutputRoot = join(root, "test", ".generated", "regexp_facade_invalid");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function fail(message) {
  console.error(`[regexp-facade] ERROR: ${message}`);
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
  "std/ruby/MatchData.hx",
  "std/ruby/MatchOffset.hx",
  "std/ruby/Regexp.hx",
  "std/ruby/RegexpCompileOptions.hx",
  "std/ruby/RegexpOptions.hx",
];
for (const facadePath of facadePaths) {
  const facadeSource = readFileSync(join(root, facadePath), "utf8");
  const facadeCode = facadeSource.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/.*$/gm, "");
  for (const forbidden of [/\bDynamic\b/, /\bAny\b/, /\buntyped\b/, /\bcast\b/, /__ruby__/, /#if\s+ruby/]) {
    if (forbidden.test(facadeCode)) fail(`${facadePath} widens the typed native boundary with ${forbidden}`);
  }
}

const regexpSource = readFileSync(join(root, "std", "ruby", "Regexp.hx"), "utf8");
const matchDataSource = readFileSync(join(root, "std", "ruby", "MatchData.hx"), "utf8");
const matchOffsetSource = readFileSync(join(root, "std", "ruby", "MatchOffset.hx"), "utf8");
const optionsSource = readFileSync(join(root, "std", "ruby", "RegexpOptions.hx"), "utf8");
if (!regexpSource.includes('@:native("Regexp")') || !regexpSource.includes("extern class Regexp")) {
  fail("ruby.Regexp must remain a direct core native extern");
}
if (!matchDataSource.includes('@:native("MatchData")') || !matchDataSource.includes("extern class MatchData")) {
  fail("ruby.MatchData must remain a direct core native extern");
}
if (facadePaths.some((path) => readFileSync(join(root, path), "utf8").includes("@:rubyRequire"))) {
  fail("core Regexp/MatchData facades must remain require-free");
}
if (/public\s+function\s+new\s*\(/.test(matchDataSource)) {
  fail("ruby.MatchData values must only come from native Regexp matching");
}
if (!matchOffsetSource.includes("@:rubyNoEmit") ||
    !matchOffsetSource.includes("extern abstract MatchOffset(Array<Null<Int>>)") ||
    /@:forward|@:from|@:to/.test(matchOffsetSource)) {
  fail("MatchOffset must remain an erased, non-converting view of native character offsets");
}
if (!optionsSource.includes("@:rubyNoEmit") ||
    !optionsSource.includes("extern abstract RegexpOptions(Int)") ||
    /@:from|@:to|fromBits/.test(optionsSource)) {
  fail("RegexpOptions must remain a closed option set without arbitrary integer conversion");
}

const eRegSource = readFileSync(join(root, "std", "ruby", "_std", "EReg.hx"), "utf8");
if (!eRegSource.includes("import ruby.MatchData as RubyMatchData;") ||
    !eRegSource.includes("import ruby.Regexp as RubyRegexp;") ||
    !eRegSource.includes("return RubyRegexp.escape(s);") ||
    !/function expandReplacement\(by:String, match:RubyMatchData\):String/.test(eRegSource)) {
  fail("Haxe EReg must retain only the exact typed Regexp.escape/MatchData reuse seams");
}

rmSync(outputDir, { force: true, recursive: true });
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
  join(root, "test", "regexp_facade", "src_haxe"),
  ...baseHaxeArgs,
  "-main",
  "Main",
]);

for (const file of ["hxruby/core.rb", "main.rb", "run.rb"]) {
  if (!existsSync(join(outputDir, file))) fail(`expected generated Ruby file missing: ${file}`);
}
for (const forbiddenFile of [
  "ruby/match_offset.rb",
  "ruby/match_offset/match_offset_impl.rb",
  "ruby/regexp_options.rb",
  "ruby/regexp_options/regexp_options_impl.rb",
]) {
  if (existsSync(join(outputDir, forbiddenFile))) fail(`erased facade emitted a Ruby shell: ${forbiddenFile}`);
}
for (const file of ["main.rb", "run.rb"]) {
  const generated = readFileSync(join(outputDir, file), "utf8");
  if (/require ["']regexp["']/.test(generated)) fail(`${file} must keep core Regexp require-free`);
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expectedShape of [
  /Regexp\.escape\("a\+b\?"\)/,
  /Regexp\.new\(" r \. b y ", options(?:__hx\d+)?\)/,
  /Regexp\.new\("\(\?<word>r\.\)\(\?<optional>z\)\?"\)/,
  /expression(?:__hx\d+)?\.match\?\("R\\nby"\)/,
  /expression(?:__hx\d+)?\.match\?\("xxR\\nby", 2\)/,
  /named(?:__hx\d+)?\.named_captures\(\)/,
  /match(?:__hx\d+)?\.match\(1\)/,
  /match(?:__hx\d+)?\.match_length\(1\)/,
  /match(?:__hx\d+)?\.offset\(2\)/,
  /match(?:__hx\d+)?\.pre_match\(\)/,
  /match(?:__hx\d+)?\.post_match\(\)/,
  /match(?:__hx\d+)?\.regexp\(\)\.source\(\)/,
  /Regexp\.new\("r\.by", 0, timeout: 0\.25\)/,
  /bounded(?:__hx\d+)?\.timeout\(\)/,
]) {
  if (!expectedShape.test(mainRuby)) {
    console.error(mainRuby);
    fail(`expected direct Regexp/MatchData shape missing from main.rb: ${expectedShape}`);
  }
}
if (/class (?:Regexp|MatchData|MatchOffset)\b|Ruby::(?:Regexp|MatchData)|HXRuby\.(?:regexp|match_data|Regexp|MatchData)/.test(mainRuby)) {
  fail("Regexp/MatchData facades must dispatch directly without generated wrappers or runtime helpers");
}

assertCompileFailure("InvalidPattern", "Int should be String");
assertCompileFailure("InvalidOptions", "Int should be Null<ruby.RegexpOptions>");
assertCompileFailure("InvalidMatchInput", "Int should be String");
assertCompileFailure("InvalidCaptureName", "String should be Int");
assertCompileFailure("InvalidMatchDataConstruction", "ruby.MatchData does not have a constructor");
assertCompileFailure("InvalidOptionBits", "Abstract<ruby.RegexpOptions> has no field fromBits");
assertCompileFailure("InvalidGlobalMatch", "Class<ruby.Regexp> has no field lastMatch");
assertCompileFailure("InvalidByteOffset", "has no field byteOffset");

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = [
  "a\\+b\\?",
  " r . b y ",
  "7",
  "true",
  "false",
  "true",
  "true",
  "true",
  "word,optional",
  "true",
  "ru",
  "3",
  "ru",
  "ru",
  "true",
  "2",
  "true",
  "ru,null",
  "word,optional",
  "true",
  "",
  "by",
  "ruby",
  "(?<word>r.)(?<optional>z)?",
  "ru,ru,null",
  "0",
  "2",
  "true",
  "true",
  "true",
  "false",
  "2",
  "xx",
  "by",
  "0.25",
  "true",
  "(?-mix:r.by)",
].join("\n") + "\n";
if (actual !== expected) {
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  fail("runtime stdout mismatch");
}

const version = run("ruby", ["-e", "print RUBY_VERSION"]).stdout;
console.log(`[regexp-facade] OK: closed options, native matching, nullable captures, offsets, names, and timeout pass MRI ${version}`);

function assertCompileFailure(mainClass, expectedDiagnostic) {
  const result = run(
    "haxe",
    [
      "-D",
      `ruby_output=${join(invalidOutputRoot, mainClass)}`,
      "-cp",
      join(root, "test", "regexp_facade", "invalid"),
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
