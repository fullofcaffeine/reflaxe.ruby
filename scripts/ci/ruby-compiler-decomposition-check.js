#!/usr/bin/env node

const { existsSync, readFileSync, readdirSync } = require("node:fs");
const { join, relative, resolve } = require("node:path");

const root = resolve(__dirname, "..", "..");
const compilerPath = join(root, "src", "reflaxe", "ruby", "RubyCompiler.hx");
const exceptionLoweringPath = join(root, "src", "reflaxe", "ruby", "compiler", "RubyExceptionLowering.hx");
const int32LoweringPath = join(root, "src", "reflaxe", "ruby", "compiler", "RubyInt32Lowering.hx");
const loopLoweringPath = join(root, "src", "reflaxe", "ruby", "compiler", "RubyLoopLowering.hx");
const referenceLoweringPath = join(root, "src", "reflaxe", "ruby", "compiler", "RubyReferenceLowering.hx");
const railsCallArgumentPlanPath = join(root, "src", "reflaxe", "ruby", "rails", "RailsCallArgumentPlan.hx");
const railsActiveRecordResultLoweringPath = join(root, "src", "reflaxe", "ruby", "rails", "RailsActiveRecordResultLowering.hx");
const railsStaticReferenceLoweringPath = join(root, "src", "reflaxe", "ruby", "rails", "RailsStaticReferenceLowering.hx");
const railsRoot = join(root, "src", "reflaxe", "ruby", "rails");
const planPath = join(root, "docs", "ruby-compiler-rails-module-extraction.md");
const packagePath = join(root, "package.json");
const workflowPath = join(root, ".github", "workflows", "ci.yml");

// These ceilings move downward after extractions. Raising either one requires a
// reviewed explanation because RubyCompiler is an orchestration boundary, not a
// default home for new Rails or target-lowering responsibilities.
const MAX_ROOT_LINES = 14485;
const MAX_ROOT_FUNCTIONS = 779;

const requiredServices = [
  "RailsArtifactPaths.hx",
  "RailsActiveRecordResultLowering.hx",
  "RailsCallArgumentPlan.hx",
  "RailsMailerPreviewArtifacts.hx",
  "RailsRoutesEmitter.hx",
  "RailsRoutesExtractor.hx",
  "RailsStaticReferenceLowering.hx",
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
if (!existsSync(exceptionLoweringPath)) {
  fail("required exception compiler service is missing: " + relative(root, exceptionLoweringPath));
}
if (!existsSync(int32LoweringPath)) {
  fail("required Int32 compiler service is missing: " + relative(root, int32LoweringPath));
}
if (!existsSync(loopLoweringPath)) {
  fail("required loop compiler service is missing: " + relative(root, loopLoweringPath));
}
if (!existsSync(referenceLoweringPath)) {
  fail("required reference compiler service is missing: " + relative(root, referenceLoweringPath));
}
if (!existsSync(railsCallArgumentPlanPath)) {
  fail("required Rails call-argument plan is missing: " + relative(root, railsCallArgumentPlanPath));
}
if (!existsSync(railsActiveRecordResultLoweringPath)) {
  fail("required Rails ActiveRecord result-lowering service is missing: " + relative(root, railsActiveRecordResultLoweringPath));
}
if (!existsSync(railsStaticReferenceLoweringPath)) {
  fail("required Rails static-reference service is missing: " + relative(root, railsStaticReferenceLoweringPath));
}
const exceptionLowering = readFileSync(exceptionLoweringPath, "utf8");
const int32Lowering = readFileSync(int32LoweringPath, "utf8");
const loopLowering = readFileSync(loopLoweringPath, "utf8");
const referenceLowering = readFileSync(referenceLoweringPath, "utf8");
const railsCallArgumentPlan = readFileSync(railsCallArgumentPlanPath, "utf8");
const railsActiveRecordResultLowering = readFileSync(railsActiveRecordResultLoweringPath, "utf8");
const railsStaticReferenceLowering = readFileSync(railsStaticReferenceLoweringPath, "utf8");
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
if (/^\s*import\s+reflaxe\.ruby\.RubyCompiler\b/m.test(exceptionLowering) || exceptionLowering.includes("reflaxe.ruby.RubyCompiler")) {
  fail("RubyExceptionLowering depends back on RubyCompiler; compiler services must remain one-way dependencies");
}
if (/^\s*import\s+reflaxe\.ruby\.RubyCompiler\b/m.test(int32Lowering) || int32Lowering.includes("reflaxe.ruby.RubyCompiler")) {
  fail("RubyInt32Lowering depends back on RubyCompiler; compiler services must remain one-way dependencies");
}
if (/^\s*import\s+reflaxe\.ruby\.RubyCompiler\b/m.test(loopLowering) || loopLowering.includes("reflaxe.ruby.RubyCompiler")) {
  fail("RubyLoopLowering depends back on RubyCompiler; compiler services must remain one-way dependencies");
}
if (/^\s*import\s+reflaxe\.ruby\.RubyCompiler\b/m.test(referenceLowering) || referenceLowering.includes("reflaxe.ruby.RubyCompiler")) {
  fail("RubyReferenceLowering depends back on RubyCompiler; compiler services must remain one-way dependencies");
}

for (const expected of [
  "import reflaxe.ruby.compiler.RubyExceptionLowering;",
  "RubyExceptionLowering.compileTry(tryExpr, catches, compileFunctionBody",
  "RubyExceptionLowering.compileThrow(thrown, compileExpr)",
  "applyExceptionLowering(result:RubyExceptionLoweringResult)",
  "import reflaxe.ruby.compiler.RubyInt32Lowering;",
  "RubyInt32Lowering.shiftLeft(compileExpr(lhs), compileExpr(rhs))",
  "RubyInt32Lowering.shiftRight(compileExpr(lhs), compileExpr(rhs))",
  "RubyInt32Lowering.shiftRightUnsigned(compileExpr(lhs), compileExpr(rhs))",
  "RubyInt32Lowering.clamp(value)",
  "import reflaxe.ruby.compiler.RubyLoopLowering;",
  "return RubyLoopLowering.compileFor(iteratorName, variableName, compileExpr(iterable), compileFunctionBody(body));",
  "return RubyExprStatement(RubyBreak);",
  "return RubyExprStatement(RubyNext);",
  "import reflaxe.ruby.compiler.RubyReferenceLowering;",
  "RubyReferenceLowering.knownStaticValue(fullTypeName(classType.pack, classType.name), field.name)",
  "RubyReferenceLowering.iteratorFactory(iteratorExpr)",
  "RubyReferenceLowering.member(compileExpr(target), fieldAccessName(access))",
  "RubyReferenceLowering.resolvedOwner(moduleTypeName(moduleType))",
  "import reflaxe.ruby.rails.RailsStaticReferenceLowering;",
  "RailsStaticReferenceLowering.token(fullTypeName(classType.pack, classType.name),",
  "import reflaxe.ruby.rails.RailsActiveRecordResultLowering;",
  "RailsActiveRecordResultLowering.projection(",
  "RailsActiveRecordResultLowering.groupedCount(",
  "import reflaxe.ruby.rails.RailsCallArgumentPlan;",
  "RailsCallArgumentPlan.classifyStatus(expr)",
  "RailsCallArgumentPlan.classifyLocals(expr)",
  "import reflaxe.ruby.rails.RailsMailerPreviewArtifacts;",
  "import reflaxe.ruby.rails.RailsTestArtifacts;",
  "railsMailerPreviewArtifacts.prepare(classType, buildContext.railsMode)",
  "RailsMailerPreviewArtifacts.render(plan, body)",
  "railsTestArtifacts.prepare(classType, buildContext.railsMode)",
  "RailsTestArtifacts.render(plan, body, railsTestIncludes(funcFields))",
]) {
  if (!compiler.includes(expected)) fail(`RubyCompiler is missing typed service delegation: ${expected}`);
}
for (const expected of [
  "class RubyExceptionLowering",
  "RubyBeginRescue",
  "RubyRuntimeHelper.ExceptionCaught",
  "RubyRuntimeHelper.ExceptionWrap",
  "RubyRuntimeHelper.IsOfType",
  "coreRuntimeUseCount",
]) {
  if (!exceptionLowering.includes(expected)) fail(`RubyExceptionLowering is missing owned exception contract: ${expected}`);
}
if (/\b(?:Dynamic|Any|Reflect|cast)\b/.test(exceptionLowering)) {
  fail("RubyExceptionLowering introduced an unsafe broad type or reflection escape");
}
for (const expected of [
  "class RubyInt32Lowering",
  "RubyBinary(\"%\"",
  "RubyBinary(\"<<\"",
  "RubyBinary(\">>\"",
  "RubyCall(value, \"to_i\", [])",
]) {
  if (!int32Lowering.includes(expected)) fail(`RubyInt32Lowering is missing owned fixed-width contract: ${expected}`);
}
if (/\b(?:Dynamic|Any|Reflect|cast)\b/.test(int32Lowering) || /RubyRaw(?:Expr|Statement)|RubyASTPrinter/.test(int32Lowering)) {
  fail("RubyInt32Lowering introduced an unsafe broad type or raw/print boundary");
}
for (const expected of [
  "class RubyLoopLowering",
  "RubyStatementSequence",
  "RubyWhileStmt",
  "RubyCall(iterator, \"has_next\"",
  "RubyCall(iterator, \"next_\"",
]) {
  if (!loopLowering.includes(expected)) fail(`RubyLoopLowering is missing owned loop contract: ${expected}`);
}
if (/\b(?:Dynamic|Any|Reflect|cast)\b/.test(loopLowering) || /RubyRaw(?:Expr|Statement)|RubyASTPrinter/.test(loopLowering)) {
  fail("RubyLoopLowering introduced an unsafe broad type or raw/print boundary");
}
for (const expected of [
  "class RubyReferenceLowering",
  "RubyConstantPath(path)",
  "RubyMember(receiver, name)",
  'return path == "self" ? RubyLocal("self") : constant(path);',
  'RubyCall(resolvedOwner(ownerPath), "method", [RubySymbol(rubyName)])',
  "RubyLambda([], [RubyExprStatement(iteratorExpr)])",
  "public static function knownStaticValue",
  "public static function mathConstant",
]) {
  if (!referenceLowering.includes(expected)) fail(`RubyReferenceLowering is missing owned structural reference contract: ${expected}`);
}
if (/\b(?:Dynamic|Any|cast)\b/.test(referenceLowering) || /\bReflect\s*\./.test(referenceLowering)
  || /RubyRaw(?:Expr|Statement)|RubyASTPrinter/.test(referenceLowering)) {
  fail("RubyReferenceLowering introduced an unsafe broad type or raw/print boundary");
}
for (const expected of [
  "class RailsStaticReferenceLowering",
  "RubyIndex(RubyConstantPath(\"Mime\"), RubySymbol(\"html\"))",
  "RubyConstantPath(\"Mime::ALL\")",
  "RubySymbol(\"native_app\")",
]) {
  if (!railsStaticReferenceLowering.includes(expected)) fail(`RailsStaticReferenceLowering is missing owned structural token contract: ${expected}`);
}
if (/\b(?:Dynamic|Any|Reflect|cast)\b/.test(railsStaticReferenceLowering)
  || /RubyRaw(?:Expr|Statement)|RubyASTPrinter/.test(railsStaticReferenceLowering)) {
  fail("RailsStaticReferenceLowering introduced an unsafe broad type or raw/print boundary");
}
for (const expected of [
  "class RailsActiveRecordResultLowering",
  "enum RailsActiveRecordGroupCountKeyKind",
  "RubyCallableCall(rows, \"map\"",
  "RubyConditional(RubyCall(row, \"is_a?\"",
  "RubyCallableCall(counts, \"each_with_object\"",
  "RubyConstantPath(mapPlan.mapClass)",
  "RubyIndex(entry, RubyInt(\"0\"))",
]) {
  if (!railsActiveRecordResultLowering.includes(expected)) {
    fail(`RailsActiveRecordResultLowering is missing owned structural result contract: ${expected}`);
  }
}
if (/\b(?:Dynamic|Any|Reflect|cast)\b/.test(railsActiveRecordResultLowering)
  || /RubyRaw(?:Expr|Statement)|RubyASTPrinter/.test(railsActiveRecordResultLowering)) {
  fail("RailsActiveRecordResultLowering introduced an unsafe broad type or raw/print boundary");
}
for (const expected of [
  "enum RailsStatusArgumentPlan",
  "enum RailsLocalsArgumentPlan",
  "class RailsCallArgumentPlan",
  "public static function classifyStatus(expr:TypedExpr)",
  "public static function classifyLocals(expr:TypedExpr)",
  "RailsStatusSymbol",
  "RailsLocalsProjection",
  '"rails.action_controller._Status.Status_Impl_"',
]) {
  if (!railsCallArgumentPlan.includes(expected)) fail(`RailsCallArgumentPlan is missing owned Rails value contract: ${expected}`);
}
if (/\b(?:Dynamic|Any|Reflect|cast)\b/.test(railsCallArgumentPlan) || /RubyRaw(?:Expr|Statement)|RubyASTPrinter/.test(railsCallArgumentPlan)) {
  fail("RailsCallArgumentPlan introduced an unsafe broad type or raw/print boundary");
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
  "RailsActiveRecordResultLowering",
  "RailsCallArgumentPlan",
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
if (packageJson.scripts["test:ruby-loop-control"] !== "node scripts/ci/loop-control-smoke.js") {
  fail("package.json must expose the structural loop-control contract");
}
if (!packageJson.scripts.test.includes("npm run test:ruby-loop-control")) {
  fail("the full npm test gate must run the structural loop-control contract");
}
if (packageJson.scripts["test:ruby-structural-references"] !== "node scripts/ci/structural-reference-smoke.js") {
  fail("package.json must expose the structural-reference contract");
}
if (!packageJson.scripts.test.includes("npm run test:ruby-structural-references")) {
  fail("the full npm test gate must run the structural-reference contract");
}
if (packageJson.scripts["test:ruby-compiler-decomposition"] !== "node scripts/ci/ruby-compiler-decomposition-check.js") {
  fail("package.json must expose the decomposition guard");
}
if (!packageJson.scripts.test.includes("npm run test:ruby-compiler-decomposition")) {
  fail("the full npm test gate must run the decomposition guard");
}
if (!readFileSync(workflowPath, "utf8").includes("run: npm test")) {
  fail("canonical CI must run the full npm test gate");
}

console.log(`[ruby-compiler-decomposition] OK: ${compilerLines}/${MAX_ROOT_LINES} lines, ${functionNames.length}/${MAX_ROOT_FUNCTIONS} functions, one-way typed compiler and Rails services`);
