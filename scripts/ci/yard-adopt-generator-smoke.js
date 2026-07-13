#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, symlinkSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "yard_adopt_generator");
const serviceSource = join(outputDir, "app", "services", "billing", "yard_price_formatter.rb");
const reflaxeSrc = join(root, "vendor", "reflaxe", "src");

if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
  fail("Unable to find vendored Reflaxe source for YARD adoption smoke.");
}

rmSync(outputDir, { force: true, recursive: true });
mkdirSync(join(outputDir, "app", "services", "billing"), { recursive: true });
writeFileSync(serviceSource, [
  'raise "YARD adoption executed Ruby source"',
  "",
  "module Commerce",
  "  module Billing",
  "    class YardPriceFormatter",
  "    # @param currency [String] ISO currency code.",
  '    def initialize(currency = "USD")',
  "      @currency = currency",
  "    end",
  "",
  "    # @param kind [String] Label kind.",
  "    # @param cents [Integer, nil] Optional amount.",
  "    # @return [String] Rendered label.",
  "    def label_for(kind, cents = nil)",
  '      "#{kind}:#{cents}"',
  "    end",
  "",
  "    # @param [Array<String>] labels Labels to normalize.",
  "    # @return [Array<String>] Normalized labels.",
  "    def normalize(labels)",
  "      labels",
  "    end",
  "",
  "    # @param flag [true, false] Whether formatting is enabled.",
  "    # @return [Boolean] The normalized flag.",
  "    def self.enabled?(flag)",
  "      flag",
  "    end",
  "",
  "    # @param count [Fixnum] Count.",
  "    # @param ratio [Float] Ratio.",
  "    # @param marker [Symbol] Marker.",
  "    # @return [Float] Score.",
  "    def score(count, ratio, marker)",
  "      ratio",
  "    end",
  "",
  "    # @param flag [true, false, nil] Optional flag.",
  "    # @return [Boolean, nil] Optional normalized flag.",
  "    def maybe_enabled(flag = nil)",
  "      flag",
  "    end",
  "",
  "    # @return [void]",
  "    def clear",
  "    end",
  "",
  "    # @param amount [Money] Domain amount.",
  "    # @return [Money] Domain amount.",
  "    def unsupported(amount)",
  "      amount",
  "    end",
  "",
  "    # @param missing [String] Deliberately mismatched documentation.",
  "    # @return [String] Value.",
  "    def mismatched(actual)",
  "      actual",
  "    end",
  "",
  "    # @param tags [Array<String>] Tags.",
  "    # @return [String] Joined tags.",
  "    def dynamic_tags(*tags)",
  '      tags.join(",")',
  "    end",
  "",
  "    def undocumented(value)",
  "      value",
  "    end",
  "  end",
  "end",
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
  "Commerce::Billing::YardPriceFormatter",
  "--service-source",
  serviceSource,
  "--yard",
  serviceSource,
]);

const contractPath = join(outputDir, "src_haxe", "interop", "commerce", "billing", "YardPriceFormatter.hx");
if (!existsSync(contractPath)) {
  fail("YARD adoption did not generate the nested service contract.");
}
const contract = readFileSync(contractPath, "utf8");
for (const expected of [
  "package interop.commerce.billing;",
  "// Generated from app/services/billing/yard_price_formatter.rb.",
  "// Generated from deterministic YARD @param/@return tags without executing Ruby.",
  "// Unsupported or incomplete signatures are omitted with review markers; no broad fallback type is synthesized.",
  '@:native("Commerce::Billing::YardPriceFormatter")',
  "extern class YardPriceFormatter",
  "public function new(?currency:String):Void;",
  "public function labelFor(kind:String, ?cents:Null<Int>):String;",
  "public function normalize(labels:Array<String>):Array<String>;",
  '@:native("enabled?")',
  "public static function enabled(flag:Bool):Bool;",
  "public function score(count:Int, ratio:Float, marker:ruby.Symbol):Float;",
  "public function maybeEnabled(?flag:Null<Bool>):Null<Bool>;",
  "public function clear():Void;",
  "Review required: skipped unsupported: unsupported YARD @param amount type [Money]",
  "Review required: skipped mismatched: YARD parameter names do not match Ruby",
  "Review required: skipped dynamic_tags: splat, keyword, block, or post arguments",
  "Review required: skipped undocumented: no immediately preceding YARD @param/@return tags were found.",
]) {
  if (!contract.includes(expected)) {
    fail(`generated YARD contract missing: ${expected}`);
  }
}
for (const forbidden of ["Dynamic", "untyped", "__ruby__", " cast("]) {
  if (contract.includes(forbidden)) {
    fail(`generated YARD contract widened into forbidden escape hatch: ${forbidden}`);
  }
}

const manifest = JSON.parse(readFileSync(join(outputDir, ".railshx", "manifest.json"), "utf8"));
const contractOutput = "src_haxe/interop/commerce/billing/YardPriceFormatter.hx";
const manifestEntry = manifest.outputs.find((entry) => entry.output === contractOutput);
if (!manifestEntry || manifestEntry.kind !== "haxe_adopted_service" || manifestEntry.source !== "hxruby:adopt" || !manifestEntry.sha256) {
  fail("YARD contract is missing its owned manifest entry.");
}

writeFileSync(join(outputDir, "src_haxe", "Main.hx"), [
  "import interop.commerce.billing.YardPriceFormatter;",
  "",
  "class Main {",
  "\tstatic function main() {",
  "\t\tvar contract:Class<YardPriceFormatter> = YardPriceFormatter;",
  "\t\tif (false) {",
  '\t\t\tvar formatter = new YardPriceFormatter("USD");',
  '\t\t\tformatter.labelFor("total", 100);',
  '\t\t\tformatter.normalize(["one"]);',
  "\t\t\tYardPriceFormatter.enabled(true);",
  "\t\t}",
  "\t\tSys.println(contract != null);",
  "\t}",
  "}",
  "",
].join("\n"));

const compiledOut = join(outputDir, ".compiled");
run("haxe", [
  "-D",
  `ruby_output=${compiledOut}`,
  "-D",
  "reflaxe_runtime",
  "-cp",
  join(root, "src"),
  "-cp",
  join(root, "std"),
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
]);
if (!existsSync(join(compiledOut, "main.rb"))) {
  fail("YARD adoption contract did not compile through the Ruby backend.");
}

const rbsSource = join(outputDir, "sig", "yard_price_formatter.rbs");
mkdirSync(join(outputDir, "sig"), { recursive: true });
writeFileSync(rbsSource, [
  "class Commerce::Billing::YardPriceFormatter",
  "  def self.rbs_wins: () -> String",
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
  "Commerce::Billing::YardPriceFormatter",
  "--rbs",
  rbsSource,
  "--yard",
  serviceSource,
  "--force",
]);
const precedenceContract = readFileSync(contractPath, "utf8");
if (
  !precedenceContract.includes("Generated from deterministic RBS metadata") ||
  !precedenceContract.includes("public static function rbsWins():String") ||
  precedenceContract.includes("Generated from deterministic YARD")
) {
  fail("RBS did not take deterministic precedence over YARD for the same service constant.");
}

expectGeneratorFailure("YARD without an explicit service", [
  "--output",
  outputDir,
  "--yard",
  serviceSource,
], "--yard requires at least one explicit --service constant");

expectGeneratorFailure("missing YARD source", [
  "--output",
  outputDir,
  "--service",
  "Commerce::Billing::YardPriceFormatter",
  "--yard",
  join(outputDir, "app", "services", "missing.rb"),
], "YARD source does not exist");

expectGeneratorFailure("YARD source outside the app root", [
  "--output",
  outputDir,
  "--service",
  "Commerce::Billing::YardPriceFormatter",
  "--yard",
  join(root, "README.md"),
], "--yard must stay inside the generator output/app root");

const symlinkSource = join(outputDir, "app", "services", "linked_outside.rb");
symlinkSync(join(root, "README.md"), symlinkSource);
expectGeneratorFailure("YARD symlink outside the app root", [
  "--output",
  outputDir,
  "--service",
  "Commerce::Billing::YardPriceFormatter",
  "--yard",
  symlinkSource,
], "--yard must resolve to a file inside the generator output/app root");

const invalidSource = join(outputDir, "app", "services", "invalid.rb");
writeFileSync(invalidSource, "class Invalid\n  def broken(\nend\n");
expectGeneratorFailure("unparseable YARD source", [
  "--output",
  outputDir,
  "--service",
  "Invalid",
  "--yard",
  invalidSource,
], "Unable to parse YARD source");

expectGeneratorFailure("service absent from YARD source", [
  "--output",
  outputDir,
  "--service",
  "Commerce::Billing::Missing",
  "--yard",
  serviceSource,
], "Service Commerce::Billing::Missing not found in --service-source/--rbs/--yard file(s)");

const railsGenerator = readFileSync(join(root, "lib", "generators", "hxruby", "adopt", "adopt_generator.rb"), "utf8");
if (!railsGenerator.includes("class_option :yard") || !railsGenerator.includes('["--yard", hxruby_option(:yard)]')) {
  fail("Rails hxruby:adopt generator does not forward --yard.");
}
const rakeTasks = readFileSync(join(root, "lib", "hxruby", "tasks.rb"), "utf8");
if (!rakeTasks.includes('["--yard", ENV["YARD"]]')) {
  fail("hxruby:gen:adopt Rake task does not forward YARD.");
}

console.log("[yard-adopt-generator] OK");

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
  const output = `${result.stdout}\n${result.stderr}`;
  if (result.status === 0 || !output.includes(expectedMessage)) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    fail(`YARD adoption did not fail closed for ${label}.`);
  }
}

function fail(message) {
  console.error(`[yard-adopt-generator] ERROR: ${message}`);
  process.exit(1);
}
