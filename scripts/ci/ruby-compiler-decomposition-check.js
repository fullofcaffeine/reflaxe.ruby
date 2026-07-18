#!/usr/bin/env node

const { existsSync, readFileSync, readdirSync } = require("node:fs");
const { join, relative, resolve } = require("node:path");

const root = resolve(__dirname, "..", "..");
const compilerPath = join(root, "src", "reflaxe", "ruby", "RubyCompiler.hx");
const railsRoot = join(root, "src", "reflaxe", "ruby", "rails");
const planPath = join(root, "docs", "ruby-compiler-rails-module-extraction.md");
const packagePath = join(root, "package.json");
const workflowPath = join(root, ".github", "workflows", "ci.yml");

// These ceilings move downward after extractions. Raising either one requires a
// reviewed explanation because RubyCompiler is an orchestration boundary, not a
// default home for new Rails or target-lowering responsibilities.
const MAX_ROOT_LINES = 14575;
const MAX_ROOT_FUNCTIONS = 789;

const requiredServices = [
  "RailsArtifactPaths.hx",
  "RailsMailerPreviewArtifacts.hx",
  "RailsRoutesEmitter.hx",
  "RailsRoutesExtractor.hx",
  "RailsTestAdapter.hx",
  "RailsTestArtifacts.hx",
];

const forbiddenMovedFunctions = [
  "normalizeRailsMailerPreviewPath",
  "normalizeRailsTestPath",
  "railsMailerPreviewOutputPath",
  "railsSpecOutputPath",
  "railsTestAdapter",
  "railsTestArtifactLines",
  "railsTestOutputPath",
  "railsTestRSpecType",
  "railsTestSuperclass",
  "validateRailsMailerPreviewMethod",
  "validateRailsMailerPreviewPath",
  "validateRailsSpecPath",
  "validateRailsTestPath",
];

function fail(message) {
  console.error(`[ruby-compiler-decomposition] ERROR: ${message}`);
  process.exit(1);
}

function read(relativePath) {
  return readFileSync(join(root, relativePath), "utf8");
}

function haxeFiles(directory) {
  const files = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) files.push(...haxeFiles(path));
    else if (entry.isFile() && entry.name.endsWith(".hx")) files.push(path);
  }
  return files;
}

const compiler = readFileSync(compilerPath, "utf8");
const compilerLines = compiler.split(/\r?\n/).length - (compiler.endsWith("\n") ? 1 : 0);
const functionNames = [...compiler.matchAll(/^\s*(?:(?:public|private|static|inline|override)\s+)*function\s+([A-Za-z0-9_]+)/gm)].map((match) => match[1]);
const functionSet = new Set(functionNames);

if (compilerLines > MAX_ROOT_LINES) {
  fail(`RubyCompiler grew to ${compilerLines} lines; orchestration ceiling is ${MAX_ROOT_LINES}`);
}
if (functionNames.length > MAX_ROOT_FUNCTIONS) {
  fail(`RubyCompiler grew to ${functionNames.length} functions; orchestration ceiling is ${MAX_ROOT_FUNCTIONS}`);
}
for (const name of forbiddenMovedFunctions) {
  if (functionSet.has(name)) fail(`moved helper ${name} was reintroduced in RubyCompiler`);
}

for (const service of requiredServices) {
  const path = join(railsRoot, service);
  if (!existsSync(path)) fail(`required Rails compiler service is missing: ${relative(root, path)}`);
}

for (const path of haxeFiles(railsRoot)) {
  const source = readFileSync(path, "utf8");
  if (/^\s*import\s+reflaxe\.ruby\.RubyCompiler\b/m.test(source) || source.includes("reflaxe.ruby.RubyCompiler")) {
    fail(`${relative(root, path)} depends back on RubyCompiler; Rails services must remain one-way dependencies`);
  }
}

for (const expected of [
  "import reflaxe.ruby.rails.RailsMailerPreviewArtifacts;",
  "import reflaxe.ruby.rails.RailsTestArtifacts;",
  "railsMailerPreviewArtifacts.prepare(classType, buildContext.railsMode)",
  "RailsMailerPreviewArtifacts.render(plan, body)",
  "railsTestArtifacts.prepare(classType, buildContext.railsMode)",
  "RailsTestArtifacts.render(plan, body, railsTestIncludes(funcFields))",
]) {
  if (!compiler.includes(expected)) fail(`RubyCompiler is missing typed service delegation: ${expected}`);
}

for (const service of ["RailsMailerPreviewArtifacts.hx", "RailsTestArtifacts.hx"]) {
  const source = readFileSync(join(railsRoot, service), "utf8");
  if (/\b(?:Dynamic|Any|Reflect|cast)\b/.test(source)) {
    fail(`${service} introduced an unsafe broad type or reflection escape`);
  }
}

const plan = readFileSync(planPath, "utf8");
for (const expected of [
  "RailsArtifactPaths",
  "RailsMailerPreviewArtifacts",
  "RailsRoutesEmitter",
  "RailsRoutesExtractor",
  "RailsTestArtifacts",
  "Dependency And Root-Growth Guard",
  "Per-Step Regression Contract",
]) {
  if (!plan.includes(expected)) fail(`responsibility map is missing ${expected}`);
}

const packageJson = JSON.parse(readFileSync(packagePath, "utf8"));
if (packageJson.scripts["test:ruby-compiler-decomposition"] !== "node scripts/ci/ruby-compiler-decomposition-check.js") {
  fail("package.json must expose the decomposition guard");
}
if (!packageJson.scripts.test.includes("npm run test:ruby-compiler-decomposition")) {
  fail("the full npm test gate must run the decomposition guard");
}
if (!readFileSync(workflowPath, "utf8").includes("run: npm test")) {
  fail("canonical CI must run the full npm test gate");
}

console.log(`[ruby-compiler-decomposition] OK: ${compilerLines}/${MAX_ROOT_LINES} lines, ${functionNames.length}/${MAX_ROOT_FUNCTIONS} functions, one-way typed Rails services`);
