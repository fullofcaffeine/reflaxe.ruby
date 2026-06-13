#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "ruby_extensions");
const failureFixtureDir = join(root, "test", ".generated", "ruby_extensions_failure_src");
const failureOutputDir = join(root, "test", ".generated", "ruby_extensions_failure");
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
rmSync(failureFixtureDir, { force: true, recursive: true });
rmSync(failureOutputDir, { force: true, recursive: true });

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for ruby_extensions.");
  process.exit(1);
}

compile(join(root, "examples", "ruby_extensions"), outputDir);

const supportDir = join(outputDir, "support");
mkdirSync(supportDir, { recursive: true });
writeFileSync(join(supportDir, "extensions.rb"), [
  "module Sluggable",
  "  def slug",
  "    @title.downcase.gsub(' ', '-')",
  "  end",
  "end",
  "",
  "module SlugSearch",
  "  def find_by_slug(slug)",
  "    new(slug.tr('-', ' '))",
  "  end",
  "end",
  "",
  "class LegacyPost",
  "  include Sluggable",
  "  extend SlugSearch",
  "",
  "  def initialize(title)",
  "    @title = title",
  "  end",
  "end",
  "",
  "module Decorated",
  "  def decorated",
  "    \"decorated:#{@title}\"",
  "  end",
  "",
  "  def build_label(value)",
  "    \"label:#{value}\"",
  "  end",
  "end",
  "",
  "module RawDecorated",
  "  def raw_decorated",
  "    \"raw:#{@title}\"",
  "  end",
  "end",
  "",
].join("\n"));

for (const file of ["hxruby/core.rb", "haxe_only_library.rb", "haxe_owned_post.rb", "haxe_raw_backed_post.rb", "main.rb", "run.rb"]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
}

for (const file of ["legacy_post.rb", "sluggable_instance.rb", "slug_search_class_methods.rb"]) {
  if (existsSync(join(outputDir, file))) {
    console.error(`Extern extension contract should not be emitted: ${file}`);
    process.exit(1);
  }
}

const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
assertOrdered(runRuby, [
  'require_relative "./support/extensions"',
  'require_relative "hxruby/core"',
  'require_relative "haxe_only_library"',
  'require_relative "haxe_owned_post"',
  'require_relative "haxe_raw_backed_post"',
  'require_relative "main"',
]);

const ownedRuby = readFileSync(join(outputDir, "haxe_owned_post.rb"), "utf8");
for (const expected of [
  "include Decorated",
  "extend Decorated",
  "attr_accessor :title",
  "def display_title()",
]) {
  if (!ownedRuby.includes(expected)) {
    console.error(`Expected Haxe-owned extension output missing: ${expected}`);
    process.exit(1);
  }
}
for (const unexpected of ["def decorated()", "def self.build_label()"]) {
  if (ownedRuby.includes(unexpected)) {
    console.error(`Injected extension stub leaked into generated Ruby: ${unexpected}`);
    process.exit(1);
  }
}

const rawBackedRuby = readFileSync(join(outputDir, "haxe_raw_backed_post.rb"), "utf8");
for (const expected of [
  "include RawDecorated",
  "def ruby_class_name()",
  "self.class.name",
]) {
  if (!rawBackedRuby.includes(expected)) {
    console.error(`Expected raw-backed extension output missing: ${expected}`);
    process.exit(1);
  }
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /LegacyPost\.new/,
  /legacy__hx\d+\.slug\(\)/,
  /LegacyPost\.find_by_slug/,
  /owned__hx\d+\.decorated\(\)/,
  /HaxeOwnedPost\.build_label/,
  /raw_backed__hx\d+\.raw_decorated\(\)/,
  /HaxeOnlyLibrary\.headline/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`Expected extension call shape missing from main.rb: ${expected}`);
    process.exit(1);
  }
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = [
  "ship-typed-mixins",
  "ship-typed-mixins",
  "decorated:Owned Type",
  "label:abc",
  "title:Owned Type",
  "raw:Raw Island",
  "HaxeRawBackedPost",
  "haxe:library",
  "",
].join("\n");

if (actual !== expected) {
  console.error("ruby_extensions stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

expectConflictFailure();

function compile(sourceDir, targetDir, options = {}) {
  return run("haxe", [
    "-D",
    `ruby_output=${targetDir}`,
    "-D",
    "reflaxe_runtime",
    ...(options.strictExamples ? ["-D", "reflaxe_ruby_strict_examples"] : []),
    "-cp",
    join(root, "src"),
    "-cp",
    sourceDir,
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    "Main",
  ], options);
}

function expectConflictFailure() {
  mkdirSync(failureFixtureDir, { recursive: true });
  writeFileSync(join(failureFixtureDir, "Main.hx"), [
    "@:rubyMixin({module: \"Sluggable\"})",
    "extern interface SluggableInstance {",
    "\tpublic function slug():String;",
    "}",
    "",
    "@:rubyInclude(SluggableInstance)",
    "class DuplicateSlug {",
    "\tpublic function new() {}",
    "\tpublic function slug():String {",
    "\t\treturn \"owned\";",
    "\t}",
    "}",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tSys.println(new DuplicateSlug().slug());",
    "\t}",
    "}",
    "",
  ].join("\n"));

  const result = compile(failureFixtureDir, failureOutputDir, { allowFailure: true });
  if (result.status === 0) {
    console.error("Expected duplicate injected extension method to fail.");
    process.exit(1);
  }
  const output = `${result.stdout}\n${result.stderr}`;
  const expectedDiagnostic = ":rubyInclude cannot inject slug because the target already defines it";
  if (!output.includes(expectedDiagnostic)) {
    console.error(`Missing expected duplicate extension diagnostic: ${expectedDiagnostic}`);
    console.error(output);
    process.exit(1);
  }
}

function assertOrdered(haystack, needles) {
  let lastIndex = -1;
  for (const needle of needles) {
    const index = haystack.indexOf(needle);
    if (index === -1) {
      console.error(`Missing expected line: ${needle}`);
      process.exit(1);
    }
    if (index <= lastIndex) {
      console.error(`Line out of order: ${needle}`);
      process.exit(1);
    }
    lastIndex = index;
  }
}
