#!/usr/bin/env node

const { existsSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "ruby_keyword_rest");
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
    process.stdout.write(result.stdout ?? "");
    process.stderr.write(result.stderr ?? "");
    process.exit(result.status ?? 1);
  }
  return result;
}

rmSync(outputDir, { force: true, recursive: true });
if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile the Ruby keyword/rest ABI fixture through Reflaxe.");
  process.exit(1);
}

const expectedFiles = [
  "hxruby/core.rb",
  "hxruby/data_define.rb",
  "keyword_constructed.rb",
  "keyword_shapes.rb",
  "main.rb",
  "rest_shapes.rb",
  "run.rb",
];
for (const relativeFile of expectedFiles) {
  const fullPath = join(outputDir, relativeFile);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
  run("ruby", ["-c", fullPath]);
}

const keywordRuby = readFileSync(join(outputDir, "keyword_shapes.rb"), "utf8");
for (const expected of [
  /def self\.describe\(prefix, required_label:, retry_count:, \*\*optional_keywords\)/,
  /unknown_keywords = \(optional_keywords\.keys\(\) - \[:active, :note_text\]\)/,
  /note = \(optional_keywords\.key\?\(:note_text\) \? HXRuby\.stringify\(optional_keywords\[:note_text\]\) : "missing"\)/,
  /def self\.passthrough\(required_label:, retry_count:, \*\*optional_keywords\)/,
  /# Rebuild the typed Haxe keyword carrier because this method uses it as a value\./,
  /options = \{"requiredLabel" => required_label, "retries" => retry_count\}/,
  /options\["note"\] = optional_keywords\[:note_text\]/,
  /def self\.mutate\(required_label:, retry_count:, \*\*optional_keywords\)(?:.|\n)*options\["requiredLabel"\] = \(options\["requiredLabel"\] \+ "!"\)/,
  /def self\.transform\(required_label:, retry_count:, \*\*optional_keywords\)\n(?:.|\n)*return yield\(required_label\)/,
  /def self\.ready\?\(\)/,
  /def self\.save!\(value\)/,
  /def self\.value=\(value\)/,
]) {
  if (!expected.test(keywordRuby)) {
    console.error(`Expected owned keyword/native-name shape missing: ${expected}`);
    process.exit(1);
  }
}

const restRuby = readFileSync(join(outputDir, "rest_shapes.rb"), "utf8");
for (const expected of [
  /def initialize\(\*values\)/,
  /def self\.join\(prefix, \*values\)/,
  /def join_instance\(prefix, \*values\)/,
  /def self\.forward\(prefix, \*values\)/,
  /RestShapes\.join\(prefix, \*values\)/,
]) {
  if (!expected.test(restRuby)) {
    console.error(`Expected owned rest shape missing: ${expected}`);
    process.exit(1);
  }
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /KeywordShapes\.describe\("inline", required_label: "ruby", retry_count: 1\)/,
  /KeywordShapes\.describe\("stored", required_label: stored\["requiredLabel"\], retry_count: stored\["retries"\], \*\*\(stored\.key\?\("active"\)/,
  /# Evaluate the typed keyword carrier once and preserve optional-key presence\./,
  /keyword_options = Main\.make_options\(\)/,
  /projected_keywords = \{required_label: keyword_options\["requiredLabel"\], retry_count: keyword_options\["retries"\]\}/,
  /KeywordShapes\.transform\(required_label: "block", retry_count: 8\) \{ \|value\| value\.upcase\(\) \}/,
  /KeywordConstructed\.new\(required_label: "ctor", retry_count: 9\)/,
  /KeywordShapes\.ready\?\(\)/,
  /KeywordShapes\.save!\("record"\)/,
  /KeywordShapes\.value = 10/,
  /RestShapes\.join\("inline", 1, 2\)/,
  /RestShapes\.join\("stored", \*stored(?:__hx\d+)?\)/,
  /RestShapes\.new\(7, 8\)/,
  /RestShapes\.new\(\)\.join_instance\("instance-rest", 9, 10\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`Expected keyword/rest call shape missing from main.rb: ${expected}`);
    process.exit(1);
  }
}
if (/KeywordShapes\.describe\("narrowed"[^\n]*extra:/.test(mainRuby)) {
  console.error("A structurally wider stored carrier leaked its extra Haxe field as a Ruby keyword.");
  process.exit(1);
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = readFileSync(join(root, "test", "fixtures", "ruby_keyword_rest", "expected.stdout"), "utf8");
if (actual !== expected) {
  console.error("ruby_keyword_rest stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

const runPrelude = readFileSync(join(outputDir, "run.rb"), "utf8")
  .split("\n")
  .filter((line) => line !== "Main.main")
  .join("\n");
const rubyOriginPath = join(outputDir, "ruby_origin.rb");
writeFileSync(rubyOriginPath, [
  runPrelude,
  "def assert_equal(expected, actual, label)",
  "  raise \"#{label}: expected #{expected.inspect}, got #{actual.inspect}\" unless expected == actual",
  "end",
  "assert_equal('ruby-origin:ruby:11:missing:missing', KeywordShapes.describe('ruby-origin', required_label: 'ruby', retry_count: 11), 'required keywords')",
  "assert_equal('ruby-origin:ruby:12:null:missing', KeywordShapes.describe('ruby-origin', required_label: 'ruby', retry_count: 12, note_text: nil), 'explicit nil')",
  "assert_equal('RUBY', KeywordShapes.transform(required_label: 'ruby', retry_count: 13) { |value| value.upcase }, 'keyword plus block')",
  "assert_equal('ruby!', KeywordShapes.mutate(required_label: 'ruby', retry_count: 13), 'materialized mutation')",
  "assert_equal('instance:ruby:14:missing:missing', KeywordShapes.new.describe_instance(required_label: 'ruby', retry_count: 14), 'instance keywords')",
  "assert_equal('ctor:15', KeywordConstructed.new(required_label: 'ctor', retry_count: 15).rendered, 'constructor keywords')",
  "assert_equal(true, KeywordShapes.ready?, 'predicate native name')",
  "assert_equal('saved:ruby', KeywordShapes.save!('ruby'), 'bang native name')",
  "KeywordShapes.value = 16",
  "assert_equal(16, KeywordShapes.assigned, 'writer native name')",
  "assert_equal('ruby:1,2,3', RestShapes.join('ruby', 1, 2, 3), 'rest method')",
  "assert_equal('forward:4,5', RestShapes.forward('forward', 4, 5), 'rest forwarding')",
  "assert_equal([6, 7], RestShapes.new(6, 7).values, 'rest constructor')",
  "assert_equal('instance:8,9', RestShapes.new.join_instance('instance', 8, 9), 'instance rest method')",
  "begin",
  "  KeywordShapes.describe('bad', required_label: 'ruby', retry_count: 17, unknown: true)",
  "  raise 'unknown keyword was accepted'",
  "rescue ArgumentError => error",
  "  raise error unless error.message.include?('unknown keyword')",
  "end",
  "puts 'ruby-origin-ok'",
  "",
].join("\n"));
const rubyOrigin = run("ruby", [rubyOriginPath]).stdout;
if (rubyOrigin !== "ruby-origin-ok\n") {
  console.error(`Ruby-origin keyword/rest ABI output mismatch: ${JSON.stringify(rubyOrigin)}`);
  process.exit(1);
}

console.log("[ruby-keyword-rest] OK");

function compileWithFirstAvailableReflaxe() {
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${outputDir}`,
      "-D",
      "reflaxe_runtime",
      "-cp",
      join(root, "src"),
      "-cp",
      join(root, "test", "ruby_keyword_rest", "src_haxe"),
      "-cp",
      reflaxeSrc,
      "--macro",
      "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro",
      "reflaxe.ruby.CompilerInit.Start()",
      "-main",
      "Main",
    ], { allowFailure: true });
    if (result.status === 0) {
      return true;
    }
    process.stderr.write(result.stderr ?? "");
  }
  return false;
}
