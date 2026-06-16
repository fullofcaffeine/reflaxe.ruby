#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "rails_adopt_generator");
const existingErb = join(outputDir, "app", "views", "legacy", "_badge.html.erb");

rmSync(outputDir, { force: true, recursive: true });
mkdirSync(join(outputDir, "app", "views", "legacy"), { recursive: true });
mkdirSync(join(outputDir, "app", "services"), { recursive: true });
mkdirSync(join(outputDir, "app", "models", "concerns"), { recursive: true });
mkdirSync(join(outputDir, "sig"), { recursive: true });
writeFileSync(existingErb, "<strong><%= label %></strong>\n");
const serviceSource = join(outputDir, "app", "services", "legacy_price_formatter.rb");
writeFileSync(serviceSource, [
  "raise \"service source was executed\"",
  "",
  "class LegacyPriceFormatter",
  "  def initialize(currency = \"USD\")",
  "    @currency = currency",
  "  end",
  "",
  "  def badge_label(kind, cents = 0)",
  "    \"#{kind}:#{cents}\"",
  "  end",
  "",
  "  def ambiguous(*values)",
  "    values.join(',')",
  "  end",
  "",
  "  def self.call(cents, include_symbol = true)",
  "    cents.to_s",
  "  end",
  "end",
  "",
].join("\n"));
const extensionSource = join(outputDir, "app", "models", "concerns", "sluggable.rb");
writeFileSync(extensionSource, [
  "module Sluggable",
  "  def slug",
  "    title.downcase",
  "  end",
  "",
  "  def decorated_title(prefix, tone = nil)",
  "    \"#{prefix}:#{title}\"",
  "  end",
  "",
  "  def dynamic_tags(*tags)",
  "    tags.join(',')",
  "  end",
  "",
  "  module ClassMethods",
  "    def find_by_slug(slug)",
  "      nil",
  "    end",
  "  end",
  "end",
  "",
].join("\n"));
const rbsSource = join(outputDir, "sig", "rbs_price_formatter.rbs");
writeFileSync(rbsSource, [
  "class RbsPriceFormatter",
  "  def initialize: (?String currency) -> void",
  "  def label_for: (String kind, ?Integer cents) -> String",
  "  def unknown_shape: (Money amount) -> Money",
  "  def self.call: (Integer cents, ?bool include_symbol) -> String",
  "end",
  "",
].join("\n"));

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--package",
  "interop",
  "--service",
  "LegacyPriceFormatter",
  "--service",
  "RbsPriceFormatter",
  "--service-source",
  serviceSource,
  "--rbs",
  rbsSource,
  "--template",
  "legacy/badge",
  "--locals",
  "label:String,tone:String",
  "--extension-source",
  extensionSource,
  "--extension-module",
  "Sluggable",
]);

assertIncludes("src_haxe/interop/LegacyPriceFormatter.hx", [
  "package interop;",
  "// Generated from app/services/legacy_price_formatter.rb.",
  "// Replace Dynamic placeholders with precise types as this boundary stabilizes.",
  '@:native("LegacyPriceFormatter")',
  "extern class LegacyPriceFormatter",
  "public function new(?currency:String):Void;",
  "public function badgeLabel(kind:Dynamic, ?cents:Int):Dynamic;",
  "TODO: ambiguous uses splat",
  "public static function call(cents:Dynamic, ?includeSymbol:Bool):Dynamic;",
]);
assertIncludes("src_haxe/interop/RbsPriceFormatter.hx", [
  "package interop;",
  "// Generated from sig/rbs_price_formatter.rbs.",
  "// Generated from deterministic RBS metadata.",
  "// TODO: Review any Dynamic placeholders from unsupported or application-specific RBS types.",
  '@:native("RbsPriceFormatter")',
  "extern class RbsPriceFormatter",
  "public function new(?currency:String):Void;",
  "public function labelFor(kind:String, ?cents:Int):String;",
  "public function unknownShape(amount:Dynamic):Dynamic;",
  "public static function call(cents:Int, ?includeSymbol:Bool):String;",
]);
assertIncludes("src_haxe/interop/templates/LegacyBadgeTemplate.hx", [
  "package interop.templates;",
  "import rails.action_view.Template;",
  "typedef LegacyBadgeLocals",
  "var label:String;",
  "var tone:String;",
  'Template.existing("legacy/badge")',
]);
assertIncludes("src_haxe/interop/extensions/SluggableInstance.hx", [
  "package interop.extensions;",
  "// Review required: Ruby source does not carry Haxe return/argument types.",
  '@:rubyMixin({module: "Sluggable"})',
  "extern interface SluggableInstance",
  "public function slug():Dynamic;",
  "public function decoratedTitle(prefix:Dynamic, ?tone:Dynamic):Dynamic;",
  "Skipped dynamic_tags",
]);
assertIncludes("src_haxe/interop/extensions/SluggableClassMethods.hx", [
  "package interop.extensions;",
  '@:rubyMixin({module: "Sluggable"})',
  "extern class SluggableClassMethods",
  "public static function findBySlug(slug:Dynamic):Dynamic;",
]);
assertManifest([
  ["src_haxe/interop/LegacyPriceFormatter.hx", "haxe_adopted_service"],
  ["src_haxe/interop/RbsPriceFormatter.hx", "haxe_adopted_service"],
  ["src_haxe/interop/templates/LegacyBadgeTemplate.hx", "haxe_adopted_template"],
  ["src_haxe/interop/extensions/SluggableInstance.hx", "haxe_adopted_extension"],
  ["src_haxe/interop/extensions/SluggableClassMethods.hx", "haxe_adopted_extension"],
]);

const erbAfter = readFileSync(existingErb, "utf8");
if (erbAfter !== "<strong><%= label %></strong>\n") {
  fail("adoption generator overwrote Rails-owned ERB source");
}

writeFileSync(join(outputDir, "src_haxe", "Main.hx"), [
  "import interop.LegacyPriceFormatter;",
  "import interop.RbsPriceFormatter;",
  "import interop.extensions.SluggableClassMethods;",
  "import interop.extensions.SluggableInstance;",
  "import interop.templates.LegacyBadgeTemplate;",
  "",
  "class Main {",
  "\tstatic function main() {",
  "\t\tvar service:Class<LegacyPriceFormatter> = LegacyPriceFormatter;",
  "\t\tvar rbsService:Class<RbsPriceFormatter> = RbsPriceFormatter;",
  "\t\tvar classMethods:Class<SluggableClassMethods> = SluggableClassMethods;",
  "\t\tvar instanceContract:Dynamic = (null : SluggableInstance);",
  "\t\tif (false) {",
  "\t\t\tvar formatter = new LegacyPriceFormatter();",
  "\t\t\tformatter.badgeLabel(\"ok\", 1);",
  "\t\t\tLegacyPriceFormatter.call(100);",
  "\t\t\tvar rbsFormatter = new RbsPriceFormatter(\"USD\");",
  "\t\t\trbsFormatter.labelFor(\"ok\", 1);",
  "\t\t\tRbsPriceFormatter.call(100);",
  "\t\t}",
  "\t\tSys.println(service != null);",
  "\t\tSys.println(rbsService != null);",
  "\t\tSys.println(classMethods != null);",
  "\t\tSys.println(instanceContract == null);",
  "\t\tSys.println(LegacyBadgeTemplate.template.templatePath);",
  "\t}",
  "}",
  "",
].join("\n"));

run("haxe", [
  "-cp",
  join(root, "src"),
  "-cp",
  join(root, "std"),
  "-cp",
  join(outputDir, "src_haxe"),
  "-main",
  "Main",
  "--interp",
]);

run("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--service",
  "LegacyPriceFormatter",
]);

const collisionOutput = join(root, "test", ".generated", "rails_adopt_generator_collision");
rmSync(collisionOutput, { force: true, recursive: true });
mkdirSync(join(collisionOutput, "src_haxe", "interop"), { recursive: true });
writeFileSync(join(collisionOutput, "src_haxe", "interop", "LegacyPriceFormatter.hx"), "// hand-written wrapper\n");
const overwrite = spawnSync("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  collisionOutput,
  "--service",
  "LegacyPriceFormatter",
], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});
if (overwrite.status === 0 || !overwrite.stderr.includes("Refusing to overwrite non-RailsHx-owned file")) {
  process.stdout.write(overwrite.stdout);
  process.stderr.write(overwrite.stderr);
  fail("adoption generator did not protect non-owned wrapper files");
}

const missingSource = spawnSync("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--extension-source",
  join(outputDir, "app", "models", "concerns", "missing.rb"),
], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});
if (missingSource.status === 0 || !missingSource.stderr.includes("Extension source does not exist")) {
  process.stdout.write(missingSource.stdout);
  process.stderr.write(missingSource.stderr);
  fail("adoption generator did not fail closed for missing extension source");
}

const missingRbs = spawnSync("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--service",
  "RbsPriceFormatter",
  "--rbs",
  join(outputDir, "sig", "missing.rbs"),
], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});
if (missingRbs.status === 0 || !missingRbs.stderr.includes("RBS source does not exist")) {
  process.stdout.write(missingRbs.stdout);
  process.stderr.write(missingRbs.stderr);
  fail("adoption generator did not fail closed for missing RBS source");
}

expectGeneratorFailure("unsafe package", [
  "--output",
  outputDir,
  "--package",
  "interop;bad",
  "--template",
  "legacy/badge",
], "--package must be a safe Haxe package path");

expectGeneratorFailure("unsafe local name", [
  "--output",
  outputDir,
  "--template",
  "legacy/badge",
  "--locals",
  "class:String",
], "Invalid local name");

expectGeneratorFailure("unsafe local type", [
  "--output",
  outputDir,
  "--template",
  "legacy/badge",
  "--locals",
  "label:String);trace('bad')",
], "Invalid local type");

expectGeneratorFailure("unsafe template path", [
  "--output",
  outputDir,
  "--template",
  "../legacy/badge",
], "--template must be a safe relative path");

expectGeneratorFailure("backslash template path", [
  "--output",
  outputDir,
  "--template",
  "legacy\\badge",
], "--template must use forward-slash relative paths");

expectGeneratorFailure("unsafe service constant", [
  "--output",
  outputDir,
  "--service",
  "legacy_price_formatter",
], "--service must be a safe Ruby constant path");

expectGeneratorFailure("source outside app root", [
  "--output",
  outputDir,
  "--service",
  "LegacyPriceFormatter",
  "--service-source",
  join(root, "README.md"),
], "--service-source must stay inside the generator output/app root");

console.log("[rails-adopt-generator] OK");

function assertIncludes(relativeFile, expectedLines) {
  const fullPath = join(outputDir, relativeFile);
  if (!existsSync(fullPath)) {
    fail(`missing generated file: ${relativeFile}`);
  }
  const content = readFileSync(fullPath, "utf8");
  for (const expected of expectedLines) {
    if (!content.includes(expected)) {
      fail(`${relativeFile} missing expected line: ${expected}`);
    }
  }
}

function assertManifest(entries) {
  const manifest = JSON.parse(readFileSync(join(outputDir, ".railshx", "manifest.json"), "utf8"));
  if (manifest.version !== 1) {
    fail(`unexpected manifest version: ${manifest.version}`);
  }
  for (const [output, kind] of entries) {
    const entry = manifest.outputs.find((candidate) => candidate.output === output);
    if (!entry || entry.kind !== kind || entry.source !== "hxruby:adopt" || !entry.sha256) {
      fail(`manifest missing expected ${output} ${kind} entry`);
    }
  }
}

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

function expectGeneratorFailure(label, args, expectedMessage) {
  const result = spawnSync("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "adopt.rb"),
    ...args,
  ], {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status === 0 || !(`${result.stdout}\n${result.stderr}`).includes(expectedMessage)) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    fail(`adoption generator did not fail closed for ${label}`);
  }
}

function fail(message) {
  console.error(`[rails-adopt-generator] ERROR: ${message}`);
  process.exit(1);
}
