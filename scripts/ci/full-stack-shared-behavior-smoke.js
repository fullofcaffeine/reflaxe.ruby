#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const exampleDir = join(root, "examples", "shared_domain");
const outputRoot = join(root, "test", ".generated", "full_stack_shared_behavior");
const rubyOutputDir = join(outputRoot, "ruby");
const javascriptOutput = join(outputRoot, "javascript", "main.js");
const expectedOutput = readFileSync(join(exampleDir, "expected.jsonl"), "utf8");
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

function fail(message) {
  console.error(`[full-stack-shared-behavior] ${message}`);
  process.exit(1);
}

function compileRuby() {
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${rubyOutputDir}`,
      "-D",
      "reflaxe_ruby_profile=portable",
      "-D",
      "reflaxe_runtime",
      "-D",
      "no-utf16",
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
      "-main",
      "Main",
    ], { allowFailure: true });
    if (result.status === 0) {
      return;
    }
  }
  fail("Unable to compile the Ruby vector runner through Reflaxe.");
}

function compileJavaScript() {
  run("haxe", [
    "-cp",
    exampleDir,
    "-main",
    "JavaScriptMain",
    "-js",
    javascriptOutput,
    "-D",
    "js-es=6",
    "--dce=full",
  ]);
}

function assertPortableSource() {
  const files = [join("domain", "TodoDraftContract.hx"), join("domain", "TodoDraftVectors.hx")];
  const forbidden = [
    [/(^|\W)Dynamic(\W|$)/m, "Dynamic"],
    [/(^|\W)Any(\W|$)/m, "Any"],
    [/Reflect\./, "Reflect"],
    [/(^|\W)cast(\W|$)/m, "cast"],
    [/(^|\W)untyped(\W|$)/m, "untyped"],
    [/__ruby__/, "raw Ruby"],
    [/#if\s+(ruby|js)\b/, "target conditional"],
    [/import\s+(ruby|rails|js)\./, "target-specific import"],
  ];

  for (const relative of files) {
    const source = readFileSync(join(exampleDir, relative), "utf8");
    for (const [pattern, label] of forbidden) {
      if (pattern.test(source)) {
        fail(`${relative} leaks ${label} into the shared contract.`);
      }
    }
  }
}

function assertOutput(label, actual) {
  if (actual !== expectedOutput) {
    console.error(`[full-stack-shared-behavior] ${label} output drifted from expected.jsonl.`);
    console.error(`expected: ${JSON.stringify(expectedOutput)}`);
    console.error(`actual:   ${JSON.stringify(actual)}`);
    process.exit(1);
  }
}

rmSync(outputRoot, { force: true, recursive: true });
assertPortableSource();
compileRuby();
compileJavaScript();

for (const file of ["run.rb", "main.rb", "domain/todo_draft_contract.rb", "haxe/json.rb"]) {
  if (!existsSync(join(rubyOutputDir, file))) {
    fail(`Generated Ruby output is missing ${file}.`);
  }
}
if (!existsSync(javascriptOutput)) {
  fail("Generated JavaScript output is missing main.js.");
}

const rubyOutput = run("ruby", [join(rubyOutputDir, "run.rb")]).stdout;
const javascriptOutputText = run("node", [javascriptOutput]).stdout;
assertOutput("Ruby", rubyOutput);
assertOutput("JavaScript", javascriptOutputText);

if (rubyOutput !== javascriptOutputText) {
  fail("Ruby and JavaScript outputs are not byte-identical.");
}

const vectors = expectedOutput.trimEnd().split("\n").map((line) => JSON.parse(line));
if (vectors.length !== 7) {
  fail(`Expected seven common vectors, found ${vectors.length}.`);
}
const statuses = new Set(vectors.map((vector) => vector.result.status));
if (!statuses.has("accepted") || !statuses.has("rejected")) {
  fail("Common vectors must exercise both accepted and rejected results.");
}

console.log(`[full-stack-shared-behavior] OK: ${vectors.length} common vectors matched generated Ruby and JavaScript byte-for-byte`);
