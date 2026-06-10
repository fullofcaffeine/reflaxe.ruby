#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "ruby_interop");
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
  console.error("Unable to compile ruby_interop through Reflaxe.");
  process.exit(1);
}

const supportDir = join(outputDir, "support");
mkdirSync(supportDir, { recursive: true });
writeFileSync(join(supportDir, "ruby_interop.rb"), [
  "module RubyInterop",
  "  def self.describe(name:, count:)",
  "    \"#{name}:#{count}\"",
  "  end",
  "",
  "  def self.each(values)",
  "    values.each { |value| yield value }",
  "  end",
  "",
  "  def self.describe_details(name:, tags:, count:)",
  "    \"#{name}:#{count}:#{tags.join('|')}\"",
  "  end",
  "",
  "  def self.with_options(values, prefix:, tags:, count:)",
  "    values.each { |value| yield value }",
  "  end",
  "",
  "  def self.accept_symbol(value)",
  "    value.is_a?(Symbol) ? value.to_s : \"not-symbol\"",
  "  end",
  "end",
  "",
].join("\n"));

for (const file of ["hxruby/core.rb", "main.rb", "run.rb"]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
}

const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
assertOrdered(runRuby, [
  'require "json"',
  'require_relative "./support/ruby_interop"',
  'require_relative "hxruby/core"',
  'require_relative "main"',
]);

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /JSON\.generate/,
  /File\.basename/,
  /RubyInterop\.describe\(name: "interop", count: 3\)/,
  /RubyInterop\.describe_details\(name: "interop", tags: \[:safe, :typed\], count: count__hx\d+\)/,
  /RubyInterop\.each\(\[4, 5\]\) \{ \|value__hx\d+\| puts\(HXRuby\.stringify\(value__hx\d+\)\) \}/,
  /RubyInterop\.with_options\(\[6, 7\], prefix: "interop", tags: \[:block\], count: count__hx\d+\) do \|value__hx\d+\|/,
  /Kernel\.print\("interop="\)/,
  /RubyInterop\.accept_symbol\(:ready\)/,
  /Kernel\.puts\("kernel"\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`Expected interop shape missing from main.rb: ${expected}`);
    process.exit(1);
  }
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = readFileSync(join(root, "test", "fixtures", "ruby_interop", "expected.stdout"), "utf8");

if (actual !== expected) {
  console.error("ruby_interop stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

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
      join(root, "examples", "ruby_interop"),
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
  }
  return null;
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
