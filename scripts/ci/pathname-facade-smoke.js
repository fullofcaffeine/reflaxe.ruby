#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "pathname_facade");
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

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  console.error("Unable to find vendored Reflaxe source for pathname_facade.");
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
  join(root, "test", "pathname_facade", "src_haxe"),
  "-cp",
  reflaxeSrc,
  "--macro",
  "reflaxe.ruby.CompilerBootstrap.Start()",
  "--macro",
  "reflaxe.ruby.CompilerInit.Start()",
  "-main",
  "Main",
]);

for (const file of ["hxruby/core.rb", "main.rb", "run.rb"]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    console.error(`Expected generated Ruby file missing: ${fullPath}`);
    process.exit(1);
  }
}

const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
if (!runRuby.includes('require "pathname"')) {
  console.error('Expected require "pathname" missing from run.rb.');
  process.exit(1);
}

const mainRuby = readFileSync(join(outputDir, "main.rb"), "utf8");
for (const expected of [
  /Pathname\.new\("tmp\/\.\.\/typed"\)/,
  /relative(?:__hx\d+)?\.cleanpath\(\)/,
  /clean(?:__hx\d+)?\.join\("file.txt"\)/,
  /joined(?:__hx\d+)?\.basename\(\)/,
  /joined(?:__hx\d+)?\.basename\("\.txt"\)/,
  /joined(?:__hx\d+)?\.extname\(\)/,
  /Pathname\.new\("typed"\)\.expand_path\("\/tmp"\)/,
  /Pathname\.new\("\."\)\.realpath\(\)\.absolute\?\(\)/,
  /destination(?:__hx\d+)?\.relative_path_from\(base(?:__hx\d+)?\)/,
  /package_file(?:__hx\d+)?\.exist\?\(\)/,
  /package_file(?:__hx\d+)?\.readable\?\(\)/,
  /package_file(?:__hx\d+)?\.writable\?\(\)/,
  /package_file(?:__hx\d+)?\.executable\?\(\)/,
  /package_file(?:__hx\d+)?\.symlink\?\(\)/,
  /package_file(?:__hx\d+)?\.empty\?\(\)/,
  /Pathname\.new\("std\/ruby"\)\.children\(false\)/,
  /package_file(?:__hx\d+)?\.read\(1\)/,
]) {
  if (!expected.test(mainRuby)) {
    console.error(`Expected direct Pathname shape missing from main.rb: ${expected}`);
    console.error(mainRuby);
    process.exit(1);
  }
}

if (mainRuby.includes("Ruby::Pathname") || mainRuby.includes("HXRuby.pathname")) {
  console.error("Pathname facade should dispatch directly without a generated wrapper or runtime helper.");
  process.exit(1);
}

const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
const expected = [
  "typed",
  "typed/file.txt",
  "file.txt",
  "file",
  ".txt",
  "typed",
  "typed",
  "/tmp/typed",
  "true",
  "lib/entry.rb",
  "true",
  "true",
  "true",
  "true",
  "true",
  "true",
  "true",
  "false",
  "false",
  "false",
  "true",
  "true",
  "{",
  "",
].join("\n");

if (actual !== expected) {
  console.error("pathname_facade stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}
