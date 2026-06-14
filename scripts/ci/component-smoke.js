#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "components");
const invalidSourceDir = join(root, "test", ".generated", "components_invalid_src");
const invalidOutputDir = join(root, "test", ".generated", "components_invalid_out");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });
rmSync(invalidSourceDir, { force: true, recursive: true });
rmSync(invalidOutputDir, { force: true, recursive: true });

const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
if (!reflaxeSrc) {
  fail("Unable to find vendored Reflaxe source for component smoke.");
}

compileComponents(outputDir);

for (const file of [
  "app/views/components/_card.html.erb",
  "app/views/components/show.html.erb",
  "app/haxe_gen/main.rb",
  "run.rb",
]) {
  const fullPath = join(outputDir, file);
  if (!existsSync(fullPath)) {
    fail(`Expected component output file missing: ${fullPath}`);
  }
}

const card = readFileSync(join(outputDir, "app", "views", "components", "_card.html.erb"), "utf8");
for (const expected of [
  '<article class="<%= "component-card component-card--" + tone %>">',
  '<h2><%= title %></h2>',
  '<%= body %>',
]) {
  if (!card.includes(expected)) {
    fail(`Component card partial missing expected ERB: ${expected}`);
  }
}

const shell = readFileSync(join(outputDir, "app", "views", "components", "show.html.erb"), "utf8");
for (const expected of [
  "<% railshx_component_body = capture do %>",
  "Children stay HHX and are captured into an ActionView buffer.",
  "Rails still receives a normal partial local.",
  '<%= render partial: "components/card", locals: {title: "Typed components, Rails output", tone: "warm", body: railshx_component_body} %>',
]) {
  if (!shell.includes(expected)) {
    fail(`Component shell missing expected Rails output: ${expected}`);
  }
}

for (const file of ["app/haxe_gen/main.rb", "run.rb"]) {
  const result = run("ruby", ["-c", join(outputDir, file)], { allowFailure: true });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
}

writeInvalidFixtures();

const invalidSlot = compileComponents(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidSlotMain",
  allowFailure: true,
});
if (invalidSlot.status === 0) {
  fail("Expected invalid component slot compile to fail.");
}
if (!/HtmlNode\.Component locals must include a "content" slot local|content/.test(invalidSlot.stderr + invalidSlot.stdout)) {
  process.stdout.write(invalidSlot.stdout);
  process.stderr.write(invalidSlot.stderr);
  fail("Invalid component slot failed for an unexpected reason.");
}

const invalidLocals = compileComponents(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidLocalsMain",
  allowFailure: true,
});
if (invalidLocals.status === 0) {
  fail("Expected invalid component locals compile to fail.");
}
if (!/Int should be String|String should be Int|Cannot unify|tone/.test(invalidLocals.stderr + invalidLocals.stdout)) {
  process.stdout.write(invalidLocals.stdout);
  process.stderr.write(invalidLocals.stderr);
  fail("Invalid component locals failed for an unexpected reason.");
}

const invalidTemplate = compileComponents(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidTemplateMain",
  allowFailure: true,
});
if (invalidTemplate.status === 0) {
  fail("Expected invalid Component.of view compile to fail.");
}
if (!/Component\.of expects a class annotated with @:railsTemplate/.test(invalidTemplate.stderr + invalidTemplate.stdout)) {
  process.stdout.write(invalidTemplate.stdout);
  process.stderr.write(invalidTemplate.stderr);
  fail("Invalid Component.of view failed for an unexpected reason.");
}

const invalidExisting = compileComponents(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidExistingComponentMain",
  allowFailure: true,
});
if (invalidExisting.status === 0) {
  fail("Expected missing Component.existing file compile to fail.");
}
if (!/Component\.existing could not find a Rails ERB template/.test(invalidExisting.stderr + invalidExisting.stdout)) {
  process.stdout.write(invalidExisting.stdout);
  process.stderr.write(invalidExisting.stderr);
  fail("Missing Component.existing file failed for an unexpected reason.");
}

const invalidSlotName = compileComponents(invalidOutputDir, {
  classPath: invalidSourceDir,
  main: "InvalidSlotNameMain",
  allowFailure: true,
});
if (invalidSlotName.status === 0) {
  fail("Expected unsafe Component.of slot name compile to fail.");
}
if (!/Component\.of slot name must be a safe Haxe\/Ruby local identifier/.test(invalidSlotName.stderr + invalidSlotName.stdout)) {
  process.stdout.write(invalidSlotName.stdout);
  process.stderr.write(invalidSlotName.stderr);
  fail("Unsafe Component.of slot name failed for an unexpected reason.");
}

console.log("[components] OK");

function compileComponents(targetDir, options = {}) {
  const args = [
    "-D",
    `ruby_output=${targetDir}`,
    "-D",
    "reflaxe_runtime",
    "-D",
    "reflaxe_ruby_rails",
    "-cp",
    join(root, "src"),
    "-cp",
    join(root, "examples", "components"),
    "-cp",
    options.classPath ?? join(root, "examples", "components"),
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    options.main ?? "Main",
  ];
  return run("haxe", args, { allowFailure: options.allowFailure });
}

function writeInvalidFixtures() {
  mkdirSync(join(invalidSourceDir, "views"), { recursive: true });

  writeFileSync(join(invalidSourceDir, "InvalidSlotMain.hx"), [
    "import views.BadSlotShellView;",
    "class InvalidSlotMain { static function main():Void { Sys.println(BadSlotShellView != null); } }",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "views", "BadSlotShellView.hx"), [
    "package views;",
    "import rails.action_view.Component as RailsComponent;",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Slot;",
    "import views.ComponentCardView;",
    "import views.ComponentCardView.ComponentCardLocals;",
    "@:railsTemplate(\"components/bad_slot\")",
    "@:railsTemplateAst(\"render\")",
    "class BadSlotShellView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <component component=${(RailsComponent.of(ComponentCardView, \"content\") : RailsComponent<ComponentCardLocals>)} locals=${{",
    "\t\t\ttitle: \"Bad slot\",",
    "\t\t\ttone: \"warm\",",
    "\t\t\tbody: Slot.content()",
    "\t\t}}>Bad slot</component>;",
    "\t}",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(invalidSourceDir, "InvalidLocalsMain.hx"), [
    "import views.BadLocalsShellView;",
    "class InvalidLocalsMain { static function main():Void { Sys.println(BadLocalsShellView != null); } }",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "views", "BadLocalsShellView.hx"), [
    "package views;",
    "import rails.action_view.Component as RailsComponent;",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Slot;",
    "import shared.CardSlots;",
    "import views.ComponentCardView;",
    "import views.ComponentCardView.ComponentCardLocals;",
    "@:railsTemplate(\"components/bad_locals\")",
    "@:railsTemplateAst(\"render\")",
    "class BadLocalsShellView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <component component=${(RailsComponent.of(ComponentCardView, CardSlots.body) : RailsComponent<ComponentCardLocals>)} locals=${{",
    "\t\t\ttitle: \"Bad locals\",",
    "\t\t\ttone: 42,",
    "\t\t\tbody: Slot.content()",
    "\t\t}}>Bad locals</component>;",
    "\t}",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(invalidSourceDir, "InvalidTemplateMain.hx"), [
    "import views.BadTemplateShellView;",
    "class InvalidTemplateMain { static function main():Void { Sys.println(BadTemplateShellView != null); } }",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "views", "PlainView.hx"), [
    "package views;",
    "class PlainView {}",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "views", "BadTemplateShellView.hx"), [
    "package views;",
    "import rails.action_view.Component as RailsComponent;",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Slot;",
    "import views.ComponentCardView.ComponentCardLocals;",
    "import views.PlainView;",
    "@:railsTemplate(\"components/bad_template\")",
    "@:railsTemplateAst(\"render\")",
    "class BadTemplateShellView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <component component=${(RailsComponent.of(PlainView, \"body\") : RailsComponent<ComponentCardLocals>)} locals=${{",
    "\t\t\ttitle: \"Bad template\",",
    "\t\t\ttone: \"warm\",",
    "\t\t\tbody: Slot.content()",
    "\t\t}}>Bad template</component>;",
    "\t}",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(invalidSourceDir, "InvalidExistingComponentMain.hx"), [
    "import views.BadExistingComponentShellView;",
    "class InvalidExistingComponentMain { static function main():Void { Sys.println(BadExistingComponentShellView != null); } }",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "views", "BadExistingComponentShellView.hx"), [
    "package views;",
    "import rails.action_view.Component as RailsComponent;",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Slot;",
    "import views.ComponentCardView.ComponentCardLocals;",
    "@:railsTemplate(\"components/bad_existing_component\")",
    "@:railsTemplateAst(\"render\")",
    "class BadExistingComponentShellView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <component component=${(RailsComponent.existing(\"legacy/missing_card\", \"body\") : RailsComponent<ComponentCardLocals>)} locals=${{",
    "\t\t\ttitle: \"Missing component\",",
    "\t\t\ttone: \"warm\",",
    "\t\t\tbody: Slot.content()",
    "\t\t}}>Missing component</component>;",
    "\t}",
    "}",
    "",
  ].join("\n"));

  writeFileSync(join(invalidSourceDir, "InvalidSlotNameMain.hx"), [
    "import views.BadSlotNameShellView;",
    "class InvalidSlotNameMain { static function main():Void { Sys.println(BadSlotNameShellView != null); } }",
    "",
  ].join("\n"));
  writeFileSync(join(invalidSourceDir, "views", "BadSlotNameShellView.hx"), [
    "package views;",
    "import rails.action_view.Component as RailsComponent;",
    "import rails.action_view.HtmlNode;",
    "import rails.action_view.Slot;",
    "import views.ComponentCardView;",
    "import views.ComponentCardView.ComponentCardLocals;",
    "@:railsTemplate(\"components/bad_slot_name\")",
    "@:railsTemplateAst(\"render\")",
    "class BadSlotNameShellView {",
    "\tpublic static function render():HtmlNode {",
    "\t\treturn <component component=${(RailsComponent.of(ComponentCardView, \"bad-slot\") : RailsComponent<ComponentCardLocals>)} locals=${{",
    "\t\t\ttitle: \"Bad slot name\",",
    "\t\t\ttone: \"warm\",",
    "\t\t\tbody: Slot.content()",
    "\t\t}}>Bad slot name</component>;",
    "\t}",
    "}",
    "",
  ].join("\n"));
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
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
  console.error(`[components] ERROR: ${message}`);
  process.exit(1);
}
