#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "filesystem_parity");
const probeDir = join(root, "test", ".generated", "filesystem_parity_probe");
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
rmSync(probeDir, { force: true, recursive: true });

if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile broader-suite filesystem parity through Reflaxe.");
  process.exit(1);
}

for (const file of [
  "hxruby/hx_exception.rb",
  "main.rb",
  "run.rb",
  "sys/io/file_input.rb",
  "sys/io/file_output.rb",
  "sys/io/file_seek.rb",
]) {
  if (!existsSync(join(outputDir, file))) {
    console.error(`Expected generated filesystem parity file missing: ${file}`);
    process.exit(1);
  }
}
for (const erasedFacade of ["sys/file_system.rb", "sys/io/file.rb"]) {
  if (existsSync(join(outputDir, erasedFacade))) {
    console.error(`Stateless filesystem facade should remain compiler-erased: ${erasedFacade}`);
    process.exit(1);
  }
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
if (actual !== "filesystem-parity ok\n") {
  console.error("Filesystem broader-suite parity stdout mismatch");
  console.error(`expected: ${JSON.stringify("filesystem-parity ok\n")}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
const inputRuby = readFileSync(join(outputDir, "sys", "io", "file_input.rb"), "utf8");
const outputRuby = readFileSync(join(outputDir, "sys", "io", "file_output.rb"), "utf8");
for (const expectedShape of [
  "::File.join(::Dir.pwd,",
  "::File.realpath(",
  "::FileUtils.mkdir_p(",
  "::Dir.children(",
  "::File.binread(",
  "::File.binwrite(",
]) {
  if (!mainRuby.includes(expectedShape)) {
    console.error(`Expected direct Ruby filesystem shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const expectedShape of [
  "class Sys",
  "module Io",
  "class FileInput < Haxe::Io::Input",
  "self.handle.getbyte()",
  "rescue StandardError => __hx_ex",
  "__hx_ex.is_a?(HxException) ? __hx_ex.value : __hx_ex",
]) {
  if (!inputRuby.includes(expectedShape)) {
    console.error(`Expected FileInput carrier shape missing: ${expectedShape}`);
    process.exit(1);
  }
}
for (const expectedShape of [
  "class FileOutput < Haxe::Io::Output",
  "self.handle.write([value & 255].pack('C'))",
  "self.handle.write(bytes.get_data().slice(pos, len).pack('C*'))",
]) {
  if (!outputRuby.includes(expectedShape)) {
    console.error(`Expected FileOutput carrier shape missing: ${expectedShape}`);
    process.exit(1);
  }
}

rmSync(probeDir, { force: true, recursive: true });

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
      join(root, "test", "filesystem_parity", "src_haxe"),
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
