#!/usr/bin/env node

const { existsSync, readFileSync, rmSync, writeFileSync, mkdirSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "controller_generator");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "controller.rb"),
  "Todos",
  "index",
  "show",
  "--templates",
  "--output",
  outputDir,
]);

for (const file of [
  "src_haxe/controllers/TodosController.hx",
  "src_haxe/views/todos/IndexView.hx",
  "src_haxe/views/todos/ShowView.hx",
]) {
  if (!existsSync(join(outputDir, file))) {
    fail(`controller generator output missing ${file}`);
  }
}

assertIncludes("src_haxe/controllers/TodosController.hx", [
  "typedef IndexLocals = {",
  "typedef ShowLocals = {",
  "class TodosController extends rails.action_controller.Base",
  "ViewMacro.renderTemplate(this, (Template.of(IndexView) : Template<IndexLocals>), {title: \"TodosController#index\"})",
  "ViewMacro.renderTemplate(this, (Template.of(ShowView) : Template<ShowLocals>), {title: \"TodosController#show\"})",
]);
assertIncludes("src_haxe/views/todos/IndexView.hx", [
  "import controllers.TodosController.IndexLocals;",
  '@:railsTemplate("controllers/todos/index")',
  '@:railsTemplateAst("render")',
  "public static function render(locals:IndexLocals):HtmlNode",
  "<h1>${locals.title}</h1>",
]);
writeFileSync(join(outputDir, "src_haxe", "Main.hx"), [
  "import controllers.TodosController;",
  "import views.todos.IndexView;",
  "import views.todos.ShowView;",
  "",
  "class Main {",
  "\tstatic function main() {",
  "\t\tvar controller:TodosController = null;",
  "\t\tvar index:Class<IndexView> = IndexView;",
  "\t\tvar show:Class<ShowView> = ShowView;",
  "\t\tSys.println(controller == null);",
  "\t\tSys.println(index != null);",
  "\t\tSys.println(show != null);",
  "\t}",
  "}",
  "",
].join("\n"));
if (!compileWithFirstAvailableReflaxe(join(outputDir, "ruby"))) {
  fail("generated controller/HHX view graph did not compile through reflaxe.ruby");
}

const modelDir = join(root, "test", ".generated", "controller_generator_model");
rmSync(modelDir, { force: true, recursive: true });
run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "controller.rb"),
  "Todos",
  "index",
  "create",
  "--model",
  "Todo",
  "--fields",
  "title,isCompleted",
  "--routes",
  "rails",
  "--output",
  modelDir,
]);
const modelController = readFileSync(join(modelDir, "src_haxe", "controllers", "TodosController.hx"), "utf8");
for (const expected of [
  "import models.Todo;",
  "import rails.macros.ParamsMacro;",
  "import routes.Routes;",
  "var todos = Todo.where({});",
  'ParamsMacro.requirePermit(this.params(), "todo", ["title", "isCompleted"])',
  "redirectTo(Routes.todosPath());",
]) {
  if (!modelController.includes(expected)) {
    fail(`model-backed controller missing ${expected}`);
  }
}

const collisionDir = join(root, "test", ".generated", "controller_generator_collision");
rmSync(collisionDir, { force: true, recursive: true });
mkdirSync(join(collisionDir, "src_haxe", "controllers"), { recursive: true });
writeFileSync(join(collisionDir, "src_haxe", "controllers", "TodosController.hx"), "// hand-written\n");
const collision = run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "controller.rb"),
  "Todos",
  "index",
  "--output",
  collisionDir,
], { allowFailure: true });
if (collision.status === 0 || !collision.stderr.includes("Refusing to overwrite non-RailsHx-owned file")) {
  process.stdout.write(collision.stdout);
  process.stderr.write(collision.stderr);
  fail("controller generator did not protect a non-owned controller file");
}

const manifest = JSON.parse(readFileSync(join(outputDir, ".railshx", "manifest.json"), "utf8"));
for (const [output, kind] of [
  ["src_haxe/controllers/TodosController.hx", "haxe_controller_source"],
  ["src_haxe/views/todos/IndexView.hx", "haxe_view_source"],
]) {
  const entry = manifest.outputs.find((candidate) => candidate.output === output);
  if (!entry || entry.kind !== kind || entry.source !== "hxruby:controller" || !entry.sha256) {
    fail(`controller manifest missing expected ${output} ${kind} entry`);
  }
}

console.log("[controller-generator] OK");

function assertIncludes(relativeFile, expectedLines) {
  const content = readFileSync(join(outputDir, relativeFile), "utf8");
  for (const expected of expectedLines) {
    if (!content.includes(expected)) {
      fail(`${relativeFile} missing expected line: ${expected}`);
    }
  }
}

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

function compileWithFirstAvailableReflaxe(rubyOutput) {
  for (const reflaxeSrc of reflaxeCandidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D",
      `ruby_output=${rubyOutput}`,
      "-D",
      "reflaxe_runtime",
      "-D",
      "reflaxe_ruby_rails",
      "-cp",
      join(root, "src"),
      "-cp",
      join(outputDir, "src_haxe"),
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
      return true;
    }
  }
  return false;
}

function fail(message) {
  console.error(`[controller-generator] ERROR: ${message}`);
  process.exit(1);
}
