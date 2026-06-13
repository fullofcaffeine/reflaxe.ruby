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
writeFileSync(existingErb, "<strong><%= label %></strong>\n");
const serviceSource = join(outputDir, "app", "services", "legacy_price_formatter.rb");
writeFileSync(serviceSource, [
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
  "--service-source",
  serviceSource,
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

const erbAfter = readFileSync(existingErb, "utf8");
if (erbAfter !== "<strong><%= label %></strong>\n") {
  fail("adoption generator overwrote Rails-owned ERB source");
}

writeFileSync(join(outputDir, "src_haxe", "Main.hx"), [
  "import interop.LegacyPriceFormatter;",
  "import interop.extensions.SluggableClassMethods;",
  "import interop.extensions.SluggableInstance;",
  "import interop.templates.LegacyBadgeTemplate;",
  "",
  "class Main {",
  "\tstatic function main() {",
  "\t\tvar service:Class<LegacyPriceFormatter> = LegacyPriceFormatter;",
  "\t\tvar classMethods:Class<SluggableClassMethods> = SluggableClassMethods;",
  "\t\tvar instanceContract:Dynamic = (null : SluggableInstance);",
  "\t\tif (false) {",
  "\t\t\tvar formatter = new LegacyPriceFormatter();",
  "\t\t\tformatter.badgeLabel(\"ok\", 1);",
  "\t\t\tLegacyPriceFormatter.call(100);",
  "\t\t}",
  "\t\tSys.println(service != null);",
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

const overwrite = spawnSync("ruby", [
  "-I",
  join(root, "lib"),
  join(root, "scripts", "rails", "adopt.rb"),
  "--output",
  outputDir,
  "--service",
  "LegacyPriceFormatter",
], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});
if (overwrite.status === 0 || !overwrite.stderr.includes("Refusing to overwrite")) {
  process.stdout.write(overwrite.stdout);
  process.stderr.write(overwrite.stderr);
  fail("adoption generator did not protect existing wrapper files");
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

function fail(message) {
  console.error(`[rails-adopt-generator] ERROR: ${message}`);
  process.exit(1);
}
