#!/usr/bin/env node

const { existsSync, readFileSync, readdirSync, rmSync, statSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const exampleDir = join(root, "examples", "rubyhx_cli");
const fixtureDir = join(root, "test", "fixtures", "rubyhx_cli");
const outputDir = join(root, "test", ".generated", "rubyhx_cli");
const invalidOutputDir = join(root, "test", ".generated", "rubyhx_cli_invalid");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function fail(message) {
  console.error(`[rubyhx-cli] ERROR: ${message}`);
  process.exit(1);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
    env: options.env ?? process.env,
  });
  if (result.error) throw result.error;
  if (result.status !== 0 && !options.allowFailure) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

function rubyFilesUnder(directory) {
  const files = [];
  for (const entry of readdirSync(directory)) {
    const path = join(directory, entry);
    if (statSync(path).isDirectory()) {
      files.push(...rubyFilesUnder(path));
    } else if (path.endsWith(".rb")) {
      files.push(path);
    }
  }
  return files;
}

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) fail("unable to find vendored Reflaxe source");

for (const file of ["Main.hx", "ReportCli.hx", "TextAnalyzer.hx", "TextReport.hx", "TextReportJson.hx"]) {
  const source = readFileSync(join(exampleDir, file), "utf8");
  for (const [label, unsafe] of [
    ["Dynamic", /:Dynamic\b|<Dynamic>|Dynamic->/],
    ["Any", /:Any\b|<Any>|Any->/],
    ["Reflect", /\bReflect\./],
    ["cast", /\bcast\s*\(/],
    ["raw Ruby", /__ruby__/],
  ]) {
    if (unsafe.test(source)) fail(`${file} leaks unsafe app-facing ${label} usage`);
  }
}

rmSync(outputDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });

const compilerArgs = [
  "-D",
  `ruby_output=${outputDir}`,
  "-D",
  "reflaxe_runtime",
  "-cp",
  join(root, "src"),
  "-cp",
  exampleDir,
  "-cp",
  reflaxeSrc,
  "--macro",
  "reflaxe.ruby.CompilerBootstrap.Start()",
  "--macro",
  "reflaxe.ruby.CompilerInit.Start()",
  "--dce",
  "full",
  "-main",
  "Main",
];
run("haxe", compilerArgs);

for (const file of ["main.rb", "report_cli.rb", "run.rb", "text_analyzer.rb", "text_report_json.rb"]) {
  if (!existsSync(join(outputDir, file))) fail(`generated Ruby file missing: ${file}`);
}
for (const file of rubyFilesUnder(outputDir)) {
  const syntax = run("ruby", ["-c", file]);
  if (syntax.stdout !== "Syntax OK\n") fail(`Ruby syntax check failed for ${file}`);
}

const samplePath = "test/fixtures/rubyhx_cli/sample.txt";
const cli = run("ruby", [join(outputDir, "run.rb"), samplePath]);
if (cli.stderr !== "") fail(`successful CLI wrote stderr: ${JSON.stringify(cli.stderr)}`);
let report;
try {
  report = JSON.parse(cli.stdout);
} catch (error) {
  fail(`CLI did not emit JSON: ${error.message}\n${cli.stdout}`);
}
const expected = { path: samplePath, lines: 2, words: 3, characters: 16 };
if (JSON.stringify(report) !== JSON.stringify(expected)) {
  fail(`CLI report mismatch: expected ${JSON.stringify(expected)}, got ${JSON.stringify(report)}`);
}

const usage = run("ruby", [join(outputDir, "run.rb")], { allowFailure: true });
if (usage.status !== 64 || usage.stdout !== "" || usage.stderr !== "Usage: rubyhx-report PATH\n") {
  fail(`usage failure contract drifted: ${JSON.stringify(usage)}`);
}
const missing = run("ruby", [join(outputDir, "run.rb"), "missing-rubyhx-report.txt"], { allowFailure: true });
if (missing.status !== 66 || missing.stdout !== "" || !missing.stderr.includes("file not found")) {
  fail(`missing-file contract drifted: ${JSON.stringify(missing)}`);
}

const rubyOrigin = run("ruby", ["-I", outputDir, join(fixtureDir, "ruby_origin.rb")]);
const rubyOriginExpected = readFileSync(join(fixtureDir, "ruby_origin.expected.stdout"), "utf8");
if (rubyOrigin.stdout !== rubyOriginExpected || rubyOrigin.stderr !== "") {
  fail(`Ruby-origin consumer mismatch: ${JSON.stringify(rubyOrigin)}`);
}

const invalid = run("haxe", [
  "-D",
  `ruby_output=${invalidOutputDir}`,
  "-D",
  "reflaxe_runtime",
  "-cp",
  join(root, "src"),
  "-cp",
  exampleDir,
  "-cp",
  join(fixtureDir, "invalid"),
  "-cp",
  reflaxeSrc,
  "--macro",
  "reflaxe.ruby.CompilerBootstrap.Start()",
  "--macro",
  "reflaxe.ruby.CompilerInit.Start()",
  "-main",
  "InvalidMain",
], { allowFailure: true });
const invalidOutput = `${invalid.stdout}\n${invalid.stderr}`;
if (invalid.status === 0 || !invalidOutput.includes("Int should be String")) {
  fail(`invalid typed analyzer call did not fail clearly:\n${invalidOutput}`);
}

console.log("[rubyhx-cli] OK: Haxe and Ruby callers share a typed filesystem-to-JSON CLI library");
