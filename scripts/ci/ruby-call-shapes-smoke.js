#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "ruby_call_shapes");
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
  console.error("Unable to compile ruby_call_shapes through Reflaxe.");
  process.exit(1);
}

for (const file of ["hxruby/core.rb", "main.rb", "run.rb"]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
}

const supportDir = join(outputDir, "support");
mkdirSync(supportDir, { recursive: true });
writeFileSync(join(supportDir, "native_interop.rb"), [
  "module NativeInterop",
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

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /NativeInterop\.describe\(name: "ruby", count: 2\)/,
  /NativeInterop\.describe_details\(name: "ruby", tags: \[:fast, :typed\], count: count(?:__hx\d+)?\)/,
  /NativeInterop\.each\(\[1, 2\]\) \{ \|value(?:__hx\d+)?\| puts\(HXRuby\.stringify\(value(?:__hx\d+)?\)\) \}/,
  /NativeInterop\.with_options\(\[3, 4\], prefix: "item", tags: \[:safe\], count: count(?:__hx\d+)?\) do \|value(?:__hx\d+)?\|/,
  /Kernel\.print\("item="\)/,
  /NativeInterop\.accept_symbol\(:ready\)/,
  /Kernel\.puts\("kernel"\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`Expected call shape missing from main.rb: ${expected}`);
    process.exit(1);
  }
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = readFileSync(join(root, "test", "fixtures", "ruby_call_shapes", "expected.stdout"), "utf8");

if (actual !== expected) {
  console.error("ruby_call_shapes stdout mismatch");
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
      join(root, "examples", "ruby_call_shapes"),
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
