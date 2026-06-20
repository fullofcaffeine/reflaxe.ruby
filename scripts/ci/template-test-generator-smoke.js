#!/usr/bin/env node

const { existsSync, mkdtempSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { tmpdir } = require("node:os");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = mkdtempSync(join(tmpdir(), "railshx-template-test."));
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

try {
  run("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "template.rb"),
    "controllers/todos/_card",
    "--output",
    outputDir,
    "--locals",
    "title:String,count:Int",
  ]);

  run("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "test.rb"),
    "models/todo",
    "--output",
    outputDir,
    "--description",
    "generated model test uses typed assertions",
  ]);

  run("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "test.rb"),
    "controllers/todos_request",
    "--type",
    "request",
    "--output",
    outputDir,
    "--description",
    "generated request test uses typed request helpers",
  ]);

  expectFile("src_haxe/views/controllers/todos/CardView.hx", [
    "package views.controllers.todos;",
    "typedef CardLocals = {",
    "var title:String;",
    "var count:Int;",
    '@:railsTemplate("controllers/todos/_card")',
    '@:railsTemplateAst("render")',
    "(Template.of(CardView)",
    "return <article class=\"railshx-generated-partial\">",
  ]);

  expectFile("test_haxe/models/TodoHaxeTest.hx", [
    "package test_haxe.models;",
    'import rails.test.ModelTestCase;',
    '@:railsTest("models/todo_haxe_test")',
    "class TodoHaxeTest extends ModelTestCase",
    "@:railsTests",
    'test("generated model test uses typed assertions", () -> {',
    "truthy(true);",
  ]);

  expectFile("test_haxe/controllers/TodosRequestHaxeTest.hx", [
    "package test_haxe.controllers;",
    "import rails.test.Request.*;",
    "import rails.test.RequestTestCase;",
    '@:railsTest("controllers/todos_request_haxe_test")',
    "class TodosRequestHaxeTest extends RequestTestCase",
    'test("generated request test uses typed request helpers", () -> {',
    'get("/");',
    "assertResponse(rails.action_controller.Status.ok);",
  ]);

  const manifest = JSON.parse(readFileSync(join(outputDir, ".railshx", "manifest.json"), "utf8"));
  for (const [output, kind, source] of [
    ["src_haxe/views/controllers/todos/CardView.hx", "haxe_view_source", "hxruby:template"],
    ["test_haxe/models/TodoHaxeTest.hx", "haxe_test_source", "hxruby:test"],
    ["test_haxe/controllers/TodosRequestHaxeTest.hx", "haxe_test_source", "hxruby:test"],
  ]) {
    const entry = manifest.outputs.find((candidate) => candidate.output === output);
    if (!entry || entry.kind !== kind || entry.source !== source || !entry.sha256) {
      fail(`manifest missing ${output} ${kind} ${source}`);
    }
  }

  const unsafeTemplate = run("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "template.rb"),
    "../bad",
    "--output",
    outputDir,
  ], { allowFailure: true });
  if (unsafeTemplate.status === 0 || !unsafeTemplate.stderr.includes("template PATH must be a safe relative path")) {
    fail("template generator did not fail closed on unsafe path");
  }

  const unsafeTest = run("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "test.rb"),
    "models/bad.test",
    "--output",
    outputDir,
  ], { allowFailure: true });
  if (unsafeTest.status === 0 || !unsafeTest.stderr.includes("Test name must use safe Rails path characters")) {
    fail("test generator did not fail closed on unsafe test path");
  }

  writeBuildFile();
  compileGeneratedSources();
} finally {
  rmSync(outputDir, { force: true, recursive: true });
}

function writeBuildFile() {
  const reflaxeSrc = reflaxeCandidates.find((candidate) => existsSync(join(candidate, "reflaxe", "ReflectCompiler.hx")));
  if (!reflaxeSrc) {
    fail("Unable to find vendored Reflaxe source for generator smoke compile");
  }
  const content = [
    "-cp .",
    "-cp src_haxe",
    `-cp ${root}/std`,
    `-cp ${root}/src`,
    `-cp ${reflaxeSrc}`,
    "-D reflaxe_runtime",
    "-D reflaxe_ruby_rails",
    `-D ruby_output=${outputDir}/ruby`,
    "--macro reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro reflaxe.ruby.CompilerInit.Start()",
    "-main Main",
    "",
  ].join("\n");
  require("node:fs").writeFileSync(join(outputDir, "build.hxml"), content);
  require("node:fs").writeFileSync(join(outputDir, "src_haxe", "Main.hx"), [
    "import views.controllers.todos.CardView;",
    "import test_haxe.models.TodoHaxeTest;",
    "import test_haxe.controllers.TodosRequestHaxeTest;",
    "",
    "class Main {",
    "\tstatic function main() {",
    "\t\tvar view:Class<CardView> = CardView;",
    "\t\tvar modelTest:Class<TodoHaxeTest> = TodoHaxeTest;",
    "\t\tvar requestTest:Class<TodosRequestHaxeTest> = TodosRequestHaxeTest;",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function compileGeneratedSources() {
  run("haxe", ["build.hxml"], { cwd: outputDir });
}

function expectFile(relative, snippets) {
  const path = join(outputDir, relative);
  if (!existsSync(path)) {
    fail(`missing generated file ${relative}`);
  }
  const content = readFileSync(path, "utf8");
  for (const snippet of snippets) {
    if (!content.includes(snippet)) {
      fail(`${relative} missing expected snippet: ${snippet}`);
    }
  }
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd || root,
    env: options.env || process.env,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0 && !options.allowFailure) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status || 1);
  }
  return result;
}

function fail(message) {
  console.error(`[template-test-generator] ERROR: ${message}`);
  process.exit(1);
}
