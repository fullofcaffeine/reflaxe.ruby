#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "ruby_owned_blocks");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

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

rmSync(outputDir, { force: true, recursive: true });

if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile the Haxe-owned Ruby block ABI fixture through Reflaxe.");
  process.exit(1);
}

const expectedFiles = [
  "block_concern.rb",
  "block_constructed.rb",
  "block_module.rb",
  "concern_receiver.rb",
  "hxruby/core.rb",
  "hxruby/hx_exception.rb",
  "main.rb",
  "module_receiver.rb",
  "owned_blocks.rb",
  "run.rb",
];
for (const relativeFile of expectedFiles) {
  const fullPath = join(outputDir, relativeFile);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
  if (relativeFile.endsWith(".rb")) {
    run("ruby", ["-c", fullPath]);
  }
}

const supportDir = join(outputDir, "support");
mkdirSync(supportDir, { recursive: true });
writeFileSync(join(supportDir, "string_block_patch.rb"), [
  "class String",
  "  def decorate",
  "    yield self",
  "  end",
  "end",
  "",
].join("\n"));

// The full compiler matrix intentionally does not install Rails gems. This
// tiny load-path fixture supplies only the `extend ActiveSupport::Concern`
// constant needed to execute ordinary module inclusion; the dedicated
// rails-concerns lane owns real ActiveSupport behavior.
const activeSupportDir = join(outputDir, "active_support");
mkdirSync(activeSupportDir, { recursive: true });
writeFileSync(join(activeSupportDir, "concern.rb"), [
  "module ActiveSupport",
  "  module Concern",
  "  end",
  "end",
  "",
].join("\n"));

const ownedRuby = readFileSync(join(outputDir, "owned_blocks.rb"), "utf8");
for (const expected of [
  /def self\.direct\(value\)\n\s+return yield\(value\)/,
  /def instance_direct\(value\)\n\s+return yield\(value\)/,
  /def self\.optional\(value, &block\)/,
  /return block\.call\(value\)/,
  /def self\.capture\(&block\)/,
  /raise\(ArgumentError, "required block missing for self\.capture"\)/,
  /def self\.forward\(value, &block\)/,
  /OwnedBlocks\.direct\(value, &block\)/,
  /def self\.nested\(value, &block\)/,
  /block\.call\(value\)/,
  /def self\.sum\(values\)/,
  /yield\(value\)/,
  /def self\.zero\(\)\n\s+return yield/,
  /def self\.pair\(left, right\)\n\s+return yield\(left, right\)/,
]) {
  if (!expected.test(ownedRuby)) {
    console.error(`Expected owned block definition shape missing: ${expected}`);
    process.exit(1);
  }
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /OwnedBlocks\.direct\(5\) \{ \|value(?:__hx\d+)?\| \(value(?:__hx\d+)? \+ 1\) \}/,
  /OwnedBlocks\.optional\(3\)/,
  /OwnedBlocks\.optional\(4\) \{ \|value(?:__hx\d+)?\|/,
  /OwnedBlocks\.optional\(4, &absent(?:__hx\d+)?\)/,
  /OwnedBlocks\.optional\(4, &optional_callback(?:__hx\d+)?\)/,
  /BlockConstructed\.new\(8\) \{ \|value(?:__hx\d+)?\|/,
  /ModuleReceiver\.new\(\)\.decorate_from_module\(9\) \{/,
  /ConcernReceiver\.new\(\)\.decorate_from_concern\(10\) \{/,
  /"patch"\.decorate \{ \|value(?:__hx\d+)?\|/,
  /OwnedBlocks\.direct\(11, &->\(value(?:__hx\d+)?\) do/,
  /return \("early:" \+ HXRuby\.stringify\(value(?:__hx\d+)?\)\)/,
  /OwnedBlocks\.direct\(12\) do \|value(?:__hx\d+)?\|/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`Expected owned block call shape missing: ${expected}`);
    process.exit(1);
  }
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = readFileSync(join(root, "test", "fixtures", "ruby_owned_blocks", "expected.stdout"), "utf8");
if (actual !== expected) {
  console.error("ruby_owned_blocks stdout mismatch");
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
  "assert_equal('ruby:2', OwnedBlocks.direct(2) { |value| \"ruby:#{value}\" }, 'static yield')",
  "begin",
  "  OwnedBlocks.direct(2)",
  "  raise 'required yielded block did not fail'",
  "rescue LocalJumpError",
  "end",
  "assert_equal('instance:3', OwnedBlocks.new.instance_direct(3) { |value| \"instance:#{value}\" }, 'instance yield')",
  "assert_equal('none', OwnedBlocks.optional(4), 'optional omission')",
  "assert_equal('optional:4', OwnedBlocks.optional(4) { |value| \"optional:#{value}\" }, 'optional block')",
  "captured = OwnedBlocks.capture { |value| \"captured:#{value}\" }",
  "assert_equal('captured:5', captured.call(5), 'captured block')",
  "begin",
  "  OwnedBlocks.capture",
  "  raise 'required captured block did not fail'",
  "rescue ArgumentError => error",
  "  raise error unless error.message.include?('required block missing')",
  "end",
  "assert_equal('forward:6', OwnedBlocks.forward(6) { |value| \"forward:#{value}\" }, 'forwarded block')",
  "assert_equal('nested:7', OwnedBlocks.nested(7) { |value| \"nested:#{value}\" }, 'nested capture')",
  "assert_equal('ctor:8', BlockConstructed.new(8) { |value| \"ctor:#{value}\" }.rendered, 'constructor block')",
  "assert_equal('module:9', ModuleReceiver.new.decorate_from_module(9) { |value| \"module:#{value}\" }, 'module block')",
  "assert_equal('concern:10', ConcernReceiver.new.decorate_from_concern(10) { |value| \"concern:#{value}\" }, 'concern block')",
  "assert_equal('PATCH', 'patch'.decorate { |value| value.upcase }, 'patch block')",
  "puts 'ruby-origin-ok'",
  "",
].join("\n"));
const rubyOrigin = run("ruby", [rubyOriginPath]).stdout;
if (rubyOrigin !== "ruby-origin-ok\n") {
  console.error(`Ruby-origin block ABI output mismatch: ${JSON.stringify(rubyOrigin)}`);
  process.exit(1);
}

console.log("[ruby-owned-blocks] OK");

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
      join(root, "test", "ruby_owned_blocks", "src_haxe"),
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
      return result;
    }
    process.stderr.write(result.stderr);
  }
  return null;
}
