#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "stdlib_mvp");
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
  console.error("Unable to compile stdlib_mvp through Reflaxe.");
  process.exit(1);
}

for (const file of ["hxruby/core.rb", "main.rb", "run.rb"]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = readFileSync(join(root, "test", "fixtures", "stdlib_mvp", "expected.stdout"), "utf8");

if (actual !== expected) {
  console.error("stdlib_mvp stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
const haxeJsonRuby = readFileSync(join(outputDir, "haxe", "json.rb"), "utf8");
for (const expectedJsonShape of [
  'require "json"',
  "JSON.parse(text)",
  "JSON.generate(value)",
  "JSON.pretty_generate(value, indent: space)",
]) {
  if (!runRuby.includes(expectedJsonShape) && !haxeJsonRuby.includes(expectedJsonShape)) {
    console.error(`Expected haxe.Json Ruby shape missing: ${expectedJsonShape}`);
    console.error(haxeJsonRuby);
    process.exit(1);
  }
}
for (const forbiddenJsonShape of ["HXRuby.json_parse", "HXRuby.json_stringify"]) {
  if (haxeJsonRuby.includes(forbiddenJsonShape)) {
    console.error(`haxe.Json should use Ruby JSON directly, not ${forbiddenJsonShape}.`);
    console.error(haxeJsonRuby);
    process.exit(1);
  }
}

const jsonFailureProbe = run("ruby", ["-e", [
  `$LOAD_PATH.unshift(${JSON.stringify(outputDir)})`,
  `require "json"`,
  `require_relative ${JSON.stringify(join(outputDir, "hxruby", "core"))}`,
  `require_relative ${JSON.stringify(join(outputDir, "hxruby", "hx_exception"))}`,
  `require_relative ${JSON.stringify(join(outputDir, "haxe", "json"))}`,
  `begin`,
  `  Haxe::Json.parse("{")`,
  `  puts "missing parser error"`,
  `rescue JSON::ParserError`,
  `  puts "parser error"`,
  `end`,
  `begin`,
  `  Haxe::Json.stringify({"name" => "ruby"}, ->(_key, value) { value })`,
  `  puts "missing replacer error"`,
  `rescue HxException`,
  `  puts "replacer error"`,
  `end`,
].join("\n")]).stdout;
if (jsonFailureProbe !== "parser error\nreplacer error\n") {
  console.error("haxe.Json failure probe mismatch");
  console.error(`actual: ${JSON.stringify(jsonFailureProbe)}`);
  process.exit(1);
}

for (const erasedSysFile of ["sys/file_system.rb", "sys/io/file.rb"]) {
  if (existsSync(join(outputDir, erasedSysFile))) {
    console.error(`sys.* std facades should inline/direct-lower, not emit ${erasedSysFile}.`);
    process.exit(1);
  }
}
if (existsSync(join(outputDir, "sys"))) {
  console.error("sys.* std facades should not emit a nested sys/ runtime namespace.");
  process.exit(1);
}
for (const expectedFileShape of [
  "::File.write(",
  "::File.read(",
  "::File.stat(",
  "::File.expand_path(",
  "::File.realpath(",
  "::FileUtils.mkdir_p(",
  "::FileUtils.copy_file(",
  "::File.binread(",
  "::File.binwrite(",
  "::Dir.children(",
  "::Dir.rmdir(",
]) {
  if (!mainRuby.includes(expectedFileShape)) {
    console.error(`Expected direct Ruby file-system shape missing: ${expectedFileShape}`);
    console.error(mainRuby);
    process.exit(1);
  }
}
for (const forbiddenSysShape of ["Sys::FileSystem", "Sys::Io::File_", "HXRuby.file_"]) {
  if (mainRuby.includes(forbiddenSysShape) || runRuby.includes(`require_relative "${forbiddenSysShape}"`)) {
    console.error(`sys.* output should not depend on ${forbiddenSysShape}.`);
    console.error(mainRuby);
    process.exit(1);
  }
}

const mathRuby = readFileSync(join(outputDir, "math.rb"), "utf8");
for (const expectedMathShape of [
  /def self\.abs\(v\)\n\s+return v\.abs/,
  /def self\.is_finite\(f\)\n\s+return f\.finite\?/,
]) {
  if (!expectedMathShape.test(mathRuby)) {
    console.error(`Expected idiomatic direct Ruby Math lowering missing: ${expectedMathShape}`);
    console.error(mathRuby);
    process.exit(1);
  }
}
for (const helperCall of ["HXRuby.math_abs", "HXRuby.math_finite?"]) {
  if (mathRuby.includes(helperCall)) {
    console.error(`Math output should not delegate to ${helperCall} when Ruby has matching receiver semantics.`);
    console.error(mathRuby);
    process.exit(1);
  }
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
      join(root, "examples", "stdlib_mvp"),
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
