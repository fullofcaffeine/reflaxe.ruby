#!/usr/bin/env node

const { existsSync, readFileSync, readdirSync, statSync, writeFileSync } = require("node:fs");
const { join, relative, resolve } = require("node:path");

const root = resolve(__dirname, "..", "..");
const sourceRoot = join(root, "src", "reflaxe", "ruby");
const inventoryPath = join(root, "docs", "ruby-ast-lowering-inventory.json");
const update = process.env.UPDATE_RUBY_AST_INVENTORY === "1";

const tokens = [
  "RubyRawExpr(",
  "RubyRawStatement(",
  "RubyASTPrinter.printExpr(",
  "RubyASTPrinter.printFile(",
  "printInlineExpr(",
  "statementToInlineRuby(",
];

const categories = [
  {
    id: "explicit-authorized-raw-ruby",
    owner: "RawInjectionPolicy and the explicit ruby.Syntax/native extension boundary",
    evidence: ["npm run test:strict-boundaries", "npm run test:ruby-extensions"],
    action: "Retain only at checked, user-authorized raw Ruby seams.",
  },
  {
    id: "validated-framework-artifact",
    owner: "Focused RailsHx artifact extractors and their compiler delegates",
    evidence: ["npm run test:rails-integration", "npm run test:rails-runtime"],
    action: "Move ordinary Ruby syntax into focused IR emitters as each Rails slice is extracted.",
  },
  {
    id: "core-lowering-migration",
    owner: "RubyCompiler core TypedExpr lowering",
    evidence: [
      "npm run test:core-subset",
      "npm run test:ruby-loop-control",
      "npm run test:ruby-unsupported-expressions",
      "npm run test:snapshots",
    ],
    action: "Replace ordinary Ruby syntax and semantic transforms with structural RubyAST slices.",
  },
  {
    id: "callable-lowering-migration",
    owner: "Ruby callable ABI and RubyCallablePlan",
    evidence: [
      "npm run test:ruby-owned-blocks",
      "npm run test:ruby-keyword-rest",
      "npm run test:ruby-callable-inheritance",
      "npm run test:ruby-callable-abi-example",
    ],
    action: "Keep decisions in the validated callable plan and migrate remaining adapter text structurally.",
  },
  {
    id: "compatibility-semantic-boundary",
    owner: "RubyHx profile and hxruby compatibility semantics",
    evidence: ["npm run test:profile-resolver", "npm run test:runtime-usage", "npm run test:unitstd-ruby"],
    action: "Retain only where target syntax is secondary to an independently tested semantic bridge.",
  },
  {
    id: "target-declaration-migration",
    owner: "RubyCompiler declaration lowering",
    evidence: ["npm run test:class-members", "npm run test:enum-adt", "npm run test:ruby-extensions"],
    action: "Add declaration nodes incrementally without changing public Ruby shape.",
  },
  {
    id: "print-reembed-debt",
    owner: "RubyAST and RubyCompiler structural lowering",
    evidence: ["npm run test:ruby-ast-inventory", "npm run test:snapshots"],
    action: "Remove print-then-reembed bridges family by family; never add one to a migrated path.",
  },
  {
    id: "ast-infrastructure",
    owner: "RubyAST, RubyASTValidator, and RubyASTPrinter",
    evidence: ["npm run test:ruby-ast"],
    action: "Retain the raw node definitions while validating structural nodes before printing.",
  },
  {
    id: "final-output-boundary",
    owner: "RubyOutputIterator",
    evidence: ["npm run test:hello-world", "npm run test:haxelib-package"],
    action: "Retain exactly one AST-to-file print at the final compiler output boundary.",
  },
];

const explicitRawFunctions = new Set([
  "compileRubyExtensionExpr",
  "compileRubyInjection",
  "compileUntypedDefaultExpr",
]);

const declarationFunctions = new Set([
  "compileClassImpl",
  "compileDynamicMethodSetter",
  "compileEnumBody",
  "compileMathConstantField",
  "compileVarField",
  "haxeInterfaceIncludeStatements",
  "requirePreludeStatements",
  "rubyExtensionStatements",
  "typeFieldsMetadata",
  "typeNameMetadata",
]);

const compatibilityFunctions = new Set([
  "compileArrayCall",
  "compileBinaryOp",
  "compileIncrementExpr",
  "compileSpecialCall",
  "compileStringCall",
  "compileStringStaticCall",
  "rubyStringToolsHex",
  "rubyStringToolsHtmlEscape",
  "rubyStringToolsReplace",
  "staticRuntimeMethodValue",
]);

function fail(message) {
  console.error("[ruby-ast-inventory] ERROR: " + message);
  process.exit(1);
}

function haxeFiles(directory) {
  const files = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...haxeFiles(path));
    } else if (entry.isFile() && entry.name.endsWith(".hx")) {
      files.push(path);
    }
  }
  return files.sort();
}

function categoryFor(file, token, functionName) {
  if (file.startsWith("src/reflaxe/ruby/ast/")) {
    return "ast-infrastructure";
  }
  if (file === "src/reflaxe/ruby/RubyOutputIterator.hx" && token === "RubyASTPrinter.printFile(") {
    return "final-output-boundary";
  }
  if (
    token === "RubyASTPrinter.printExpr(" ||
    token === "RubyASTPrinter.printFile(" ||
    token === "printInlineExpr(" ||
    token === "statementToInlineRuby("
  ) {
    return "print-reembed-debt";
  }
  if (explicitRawFunctions.has(functionName)) {
    return "explicit-authorized-raw-ruby";
  }
  if (/(Callable|Keyword|RubyBlock|MethodValue)/.test(functionName)) {
    return "callable-lowering-migration";
  }
  if (declarationFunctions.has(functionName)) {
    return "target-declaration-migration";
  }
  if (
    /(Rails|ActionCable|ActionController|ActionMailer|ActiveJob|ActiveRecord|ActiveStorage|ActiveSupport|Turbo|Template)/.test(
      functionName,
    )
  ) {
    return "validated-framework-artifact";
  }
  if (compatibilityFunctions.has(functionName)) {
    return "compatibility-semantic-boundary";
  }
  return "core-lowering-migration";
}

function scanFile(path) {
  const file = relative(root, path).split("\\").join("/");
  const lines = readFileSync(path, "utf8").split(/\r?\n/);
  const ordinals = new Map();
  const entries = [];
  let functionName = "<module>";

  for (let lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    const line = lines[lineIndex];
    const declaration = line.match(
      /^\s*(?:(?:public|private|static|inline|override)\s+)*function\s+([A-Za-z0-9_]+)/,
    );
    if (declaration) {
      functionName = declaration[1];
    }

    for (const token of tokens) {
      let from = 0;
      while (from < line.length) {
        const column = line.indexOf(token, from);
        if (column === -1) {
          break;
        }
        const ordinalKey = functionName + "\u0000" + token;
        const ordinal = (ordinals.get(ordinalKey) || 0) + 1;
        ordinals.set(ordinalKey, ordinal);
        entries.push({
          id:
            file +
            "::" +
            functionName +
            "::" +
            token.slice(0, -1) +
            "::" +
            ordinal,
          file,
          line: lineIndex + 1,
          column: column + 1,
          token: token.slice(0, -1),
          function: functionName,
          category: categoryFor(file, token, functionName),
          snippet: line.trim(),
        });
        from = column + token.length;
      }
    }
  }
  return entries;
}

const categoryIds = new Set(categories.map((category) => category.id));
for (const category of categories) {
  if (!category.owner || !Array.isArray(category.evidence) || category.evidence.length === 0 || !category.action) {
    fail("category " + category.id + " must record an owner, executable evidence, and an action");
  }
}

const entries = haxeFiles(sourceRoot).flatMap(scanFile);
const entryIds = new Set();
for (const entry of entries) {
	if (!categoryIds.has(entry.category)) {
		fail("unclassified source site: " + entry.file + ":" + entry.line);
	}
	if (entryIds.has(entry.id)) {
		fail("duplicate inventory site id: " + entry.id);
	}
	entryIds.add(entry.id);
}

function requireIncludes(source, expected, label) {
	if (!source.includes(expected)) {
		fail(label + " is missing structural source contract: " + expected);
	}
}

function forbidIncludes(source, forbidden, label) {
	if (source.includes(forbidden)) {
		fail(label + " reintroduced migrated raw/ambient contract: " + forbidden);
	}
}

const compiler = readFileSync(join(sourceRoot, "RubyCompiler.hx"), "utf8");
const ast = readFileSync(join(sourceRoot, "ast", "RubyAST.hx"), "utf8");
const printer = readFileSync(join(sourceRoot, "ast", "RubyASTPrinter.hx"), "utf8");
const callablePlan = readFileSync(join(sourceRoot, "compiler", "RubyCallablePlan.hx"), "utf8");
const exceptionLowering = readFileSync(join(sourceRoot, "compiler", "RubyExceptionLowering.hx"), "utf8");
const int32Lowering = readFileSync(join(sourceRoot, "compiler", "RubyInt32Lowering.hx"), "utf8");
const loopLowering = readFileSync(join(sourceRoot, "compiler", "RubyLoopLowering.hx"), "utf8");

for (const expected of [
	"case TArray(target, index): RubyIndex(compileExpr(target), compileExpr(index));",
	"return RubyStatementSequence(compileStatementList(exprs));",
	"RubyBegin(compileStatementList(exprs));",
	"RubyConditional(compileExpr(cond), compileExpr(eThen), eElse == null ? RubyNil : compileExpr(eElse));",
	"return RubyExprStatement(compileSwitch(switchExpr, cases, edef));",
	"return RubyCase(scrutinee, branches, edef == null ? null : compileFunctionBody(edef));",
	"return RubyExprStatement(applyExceptionLowering(RubyExceptionLowering.compileTry(",
	"return RubyExprStatement(applyExceptionLowering(RubyExceptionLowering.compileThrow(",
	"static function applyExceptionLowering(result:RubyExceptionLoweringResult):RubyExpr",
	"RubyInt32Lowering.shiftLeft(compileExpr(lhs), compileExpr(rhs))",
	"RubyInt32Lowering.shiftRight(compileExpr(lhs), compileExpr(rhs))",
	"RubyInt32Lowering.shiftRightUnsigned(compileExpr(lhs), compileExpr(rhs))",
	"return isInt32Type(type) ? RubyInt32Lowering.clamp(value) : value;",
	"return RubyLoopLowering.compileFor(iteratorName, variableName, compileExpr(iterable), compileFunctionBody(body));",
	"return RubyExprStatement(RubyBreak);",
	"return RubyExprStatement(RubyNext);",
	"allocateSyntheticLocalName(\"hx_iter_\" + variableName + \"_\" + pos.min)",
	"var callablePlan = RubyCallablePlan.resolve(field, contract);",
	"static var activeRubyCallableContext:Null<ActiveRubyCallableContext> = null;",
	"static function hxrubyCall(helper:RubyRuntimeHelper, args:Array<RubyExpr>):RubyExpr",
	"return RubyRuntimeCall(RubyRuntimePlan.select(helper), args);",
]) {
	requireIncludes(compiler, expected, "RubyCompiler");
}
for (const expected of [
	"class RubyExceptionLowering",
	"expr: RubyBeginRescue(body, [",
	"expr: RubyRaise(runtimeCall(RubyRuntimeHelper.ExceptionWrap, [compileExpr(thrown)]))",
	"RubyRuntimeHelper.ExceptionCaught",
	"RubyRuntimeHelper.IsOfType",
	"body: [RubyExprStatement(RubyRaise())]",
]) {
	requireIncludes(exceptionLowering, expected, "RubyExceptionLowering");
}
for (const forbidden of [
	"statementToInlineRuby",
	"renderSwitch(",
	"renderTry(",
	"renderFor(",
	"loopIteratorExpression(",
	"RubyRawStatement(\"break\")",
	"RubyRawStatement(\"next\")",
	"RubyRawExpr(\"break\")",
	"RubyRawExpr(\"next\")",
	"HxException.new(",
	"directYieldBlockVariableId",
	"activeRubyKeywordCarrier",
	"withDirectYieldBlock",
	"withActiveRubyKeywordCarrier",
	'hxrubyCall("',
	"case TArray(target, index): RubyRawExpr",
]) {
	forbidIncludes(compiler, forbidden, "RubyCompiler");
}
for (const forbidden of ["RubyRawExpr(", "RubyRawStatement(", "RubyASTPrinter."]) {
	forbidIncludes(exceptionLowering, forbidden, "RubyExceptionLowering");
	forbidIncludes(int32Lowering, forbidden, "RubyInt32Lowering");
	forbidIncludes(loopLowering, forbidden, "RubyLoopLowering");
}
for (const expected of [
	"RubyStatementSequence(body:Array<RubyStatement>);",
	"RubyMember(receiver:RubyExpr, name:String);",
	"RubyCase(scrutinee:RubyExpr",
	"RubyBeginRescue(body:Array<RubyStatement>, rescues:Array<RubyRescueClause>);",
	"RubyRaise(?exception:RubyExpr);",
	"RubyBreak;",
	"RubyNext;",
	"RubyRuntimeCall(use:RubyRuntimeUse",
]) {
	requireIncludes(ast, expected, "RubyAST");
}
for (const expected of [
	"RubyASTValidator.validateFile(file);",
	"RubyASTValidator.validateExpr(expr);",
	"case RubyCase(scrutinee, branches, defaultBody):",
	"case RubyBeginRescue(body, rescues):",
	"case RubyRaise(exception):",
	"case RubyBreak:",
	"case RubyNext:",
	"case RubyRuntimeCall(use, args):",
]) {
	requireIncludes(printer, expected, "RubyASTPrinter");
}
for (const expected of [
	"enum RubyOwnedBlockPlan",
	"enum RubyOwnedKeywordPlan",
	"class RubyCallablePlan",
	"validate(plan);",
]) {
	requireIncludes(callablePlan, expected, "RubyCallablePlan");
}
if (entries.filter((entry) => entry.category === "final-output-boundary").length !== 1) {
	fail("exactly one final RubyAST-to-file print boundary must remain");
}

const inventory = {
  schemaVersion: 1,
  generatedBy: "scripts/ci/ruby-ast-inventory-check.js",
  issue: "https://github.com/fullofcaffeine/reflaxe.ruby/issues/20",
  scope: "src/reflaxe/ruby/**/*.hx",
  note:
    "Counts are migration-planning evidence, not a product-quality score. Category ownership and focused behavior tests are the contract.",
  categories,
  entries,
};
const rendered = JSON.stringify(inventory, null, 2) + "\n";

if (update) {
  writeFileSync(inventoryPath, rendered);
  console.log("[ruby-ast-inventory] updated " + relative(root, inventoryPath) + " with " + entries.length + " sites");
  process.exit(0);
}

if (!existsSync(inventoryPath)) {
  fail("missing " + relative(root, inventoryPath) + "; run UPDATE_RUBY_AST_INVENTORY=1 npm run test:ruby-ast-inventory");
}
if (readFileSync(inventoryPath, "utf8") !== rendered) {
  fail("inventory is stale; run UPDATE_RUBY_AST_INVENTORY=1 npm run test:ruby-ast-inventory and review the classified diff");
}

const sourceStat = statSync(sourceRoot);
if (!sourceStat.isDirectory()) {
  fail("Ruby compiler source root is not a directory");
}

console.log("[ruby-ast-inventory] OK: " + entries.length + " classified raw/print-reembed sites");
