#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "json_parity");
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
  console.error("Unable to compile broader-suite haxe.Json parity through Reflaxe.");
  process.exit(1);
}

for (const file of ["haxe/json.rb", "hxruby/core.rb", "main.rb", "run.rb"]) {
  if (!existsSync(join(outputDir, file))) {
    console.error(`Expected generated JSON parity file missing: ${file}`);
    process.exit(1);
  }
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
if (actual !== "json-parity ok\n") {
  console.error("haxe.Json broader-suite parity stdout mismatch");
  console.error(`expected: ${JSON.stringify("json-parity ok\n")}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

const jsonRuby = readFileSync(join(outputDir, "haxe", "json.rb"), "utf8");
for (const expectedShape of [
  'require "json"',
  "JSON.parse(text)",
  "HXRuby.json_prepare(value, replacer)",
  "JSON.generate(prepared)",
  "JSON.pretty_generate(prepared, indent: space)",
]) {
  if (!jsonRuby.includes(expectedShape)) {
    console.error(`Expected native Ruby JSON shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
if (existsSync(join(outputDir, "haxe", "format", "json_printer.rb"))) {
  console.error("haxe.Json should preserve native Ruby JSON generation instead of emitting JsonPrinter.");
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
      "reflaxe_ruby_profile=portable",
      "-D",
      "reflaxe_runtime",
      "-D",
      "no-utf16",
      "-cp",
      join(root, "src"),
      "-cp",
      join(root, "test", "json_parity", "src_haxe"),
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
