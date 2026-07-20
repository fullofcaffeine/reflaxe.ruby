#!/usr/bin/env node

const { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "ruby_callable_inheritance");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    env: options.env ?? process.env,
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

rmSync(outputDir, { force: true, recursive: true });
if (!compileWithFirstAvailableReflaxe()) {
  console.error("Unable to compile the callable inheritance fixture through Reflaxe.");
  process.exit(1);
}

const expectedFiles = [
  "block_api.rb",
  "block_base.rb",
  "block_child.rb",
  "callable_concern.rb",
  "callable_module.rb",
  "concern_callable_receiver.rb",
  "interface_worker.rb",
  "keyword_base.rb",
  "keyword_child.rb",
  "main.rb",
  "module_callable_receiver.rb",
  "native_block_base.rb",
  "native_block_child.rb",
  "static_callables.rb",
  "worker_factory.rb",
  "run.rb",
];
for (const relativeFile of expectedFiles) {
  const path = join(outputDir, relativeFile);
  if (!existsSync(path)) {
    console.error(`Expected generated Ruby file missing: ${path}`);
    process.exit(1);
  }
  run("ruby", ["-c", path]);
}

// The compiler matrix intentionally has no Rails gems. This minimal constant
// lets the Haxe-owned Concern fixture execute; the real concern lane owns
// ActiveSupport behavior.
const activeSupportDir = join(outputDir, "active_support");
mkdirSync(activeSupportDir, { recursive: true });
writeFileSync(join(activeSupportDir, "concern.rb"), [
  "module ActiveSupport",
  "  module Concern",
  "  end",
  "end",
  "",
].join("\n"));

assertShapes("main.rb", [
  /child\.visit\(1\) \{ \|value(?:__hx\d+)?\|/,
  /static_block(?:__hx\d+)? = ->\(\*haxe_args(?:__hx\d+)?\) do/,
  /# Adapt this Haxe function value's positional carriers to Ruby keywords and block syntax\./,
  /StaticCallables\.decorate\(\*haxe_args(?:__hx\d+)?, &callable_block(?:__hx\d+)?\)/,
  /keyword_options(?:__hx\d+)? = haxe_args(?:__hx\d+)?\.delete_at\(0\)/,
  /StaticCallables\.label\(prefix: keyword_options(?:__hx\d+)?\["prefix"\]/,
  /haxe_args(?:__hx\d+)?\.length\(\) > 1\) \? haxe_args(?:__hx\d+)?\.pop\(\) : nil/,
  /StaticCallables\.compose\(prefix: keyword_options(?:__hx\d+)?\["prefix"\]/,
  /rest_value(?:__hx\d+)? = StaticCallables\.method\(:join\)/,
  /rest_value(?:__hx\d+)?\.call\("rest:", 1, 2\)/,
  /rest_value(?:__hx\d+)?\.call\("spread:", \*spread(?:__hx\d+)?\)/,
  /WorkerFactory\.positional_value\(\)/,
  /positional(?:__hx\d+)? = 15/,
  /child(?:__hx\d+)?\.visit\(begin/,
  /effectful_plain(?:__hx\d+)? = WorkerFactory\.make\(\)\.method\(:plain\)/,
  /# Evaluate the method-value receiver once at capture, matching Haxe expression semantics\./,
  /callable_receiver(?:__hx\d+)? = WorkerFactory\.make\(\)/,
  /native_child(?:__hx\d+)?\.transform!\(9\) \{/,
  /native_child(?:__hx\d+)?\.transform!\(\*haxe_args(?:__hx\d+)?, &callable_block(?:__hx\d+)?\)/,
]);
assertShapes("block_child.rb", [
  /def visit\(value, &block\)/,
  /super\(\(value \+ 1\), &block\)/,
]);
assertShapes("interface_worker.rb", [
  /def visit\(value\)/,
  /return yield\(\(value \+ 1\)\)/,
]);
assertShapes("keyword_child.rb", [
  /def configure\(prefix:, \*\*optional_keywords\)/,
  /super\(prefix: prefix, \*\*\(optional_keywords\.key\?\(:suffix\)/,
]);
assertShapes("native_block_child.rb", [
  /def transform!\(value, &block\)/,
  /super\(\(value \+ 1\), &block\)/,
]);

const actual = run("ruby", [join(outputDir, "run.rb")], {
  env: { ...process.env, RUBYLIB: [outputDir, process.env.RUBYLIB].filter(Boolean).join(":") },
}).stdout;
const expected = readFileSync(join(root, "test", "fixtures", "ruby_callable_inheritance", "expected.stdout"), "utf8");
if (actual !== expected) {
  console.error("ruby_callable_inheritance stdout mismatch");
  console.error(`expected: ${JSON.stringify(expected)}`);
  console.error(`actual:   ${JSON.stringify(actual)}`);
  process.exit(1);
}

const prelude = readFileSync(join(outputDir, "run.rb"), "utf8")
  .split("\n")
  .filter((line) => line !== "Main.main")
  .join("\n");
const rubyOriginPath = join(outputDir, "ruby_origin.rb");
writeFileSync(rubyOriginPath, [
  prelude,
  "raise 'inherited block' unless BlockChild.new.visit(1) { |value| \"ruby:#{value + 2}\" } == 'child:ruby:4'",
  "raise 'interface block' unless InterfaceWorker.new.visit(2) { |value| (value * 3).to_s } == '9'",
  "raise 'inherited native block' unless NativeBlockChild.new.transform!(2) { |value| \"ruby-native:#{value}\" } == 'native:ruby-native:3'",
  "raise 'inherited keyword' unless KeywordChild.new.configure(prefix: 'ruby') == 'child:ruby:missing'",
  "begin",
  "  KeywordChild.new.configure(prefix: 'ruby', unknown: true)",
  "  raise 'unknown inherited keyword accepted'",
  "rescue ArgumentError => error",
  "  raise error unless error.message.include?('unknown keyword')",
  "end",
  "puts 'ruby-origin-ok'",
  "",
].join("\n"));
const rubyOrigin = run("ruby", [rubyOriginPath], {
  env: { ...process.env, RUBYLIB: [outputDir, process.env.RUBYLIB].filter(Boolean).join(":") },
}).stdout;
if (rubyOrigin !== "ruby-origin-ok\n") {
  console.error(`Ruby-origin callable inheritance output mismatch: ${JSON.stringify(rubyOrigin)}`);
  process.exit(1);
}

console.log("[ruby-callable-inheritance] OK");

function assertShapes(relativeFile, patterns) {
  const source = readFileSync(join(outputDir, relativeFile), "utf8");
  for (const pattern of patterns) {
    if (!pattern.test(source)) {
      console.error(`${relativeFile} missing expected callable shape: ${pattern}`);
      process.exit(1);
    }
  }
}

function compileWithFirstAvailableReflaxe() {
  // A present vendored compiler is authoritative. Falling through after a local
  // compile failure can produce a false green against a sibling checkout.
  const candidates = existsSync(join(reflaxeCandidates[0], "reflaxe", "ReflectCompiler.hx"))
    ? [reflaxeCandidates[0]]
    : reflaxeCandidates.slice(1);
  for (const reflaxeSrc of candidates) {
    if (!existsSync(join(reflaxeSrc, "reflaxe", "ReflectCompiler.hx"))) {
      continue;
    }
    const result = run("haxe", [
      "-D", `ruby_output=${outputDir}`,
      "-D", "reflaxe_runtime",
      "-cp", join(root, "src"),
      "-cp", join(root, "test", "ruby_callable_inheritance", "src_haxe"),
      "-cp", reflaxeSrc,
      "--macro", "reflaxe.ruby.CompilerBootstrap.Start()",
      "--macro", "reflaxe.ruby.CompilerInit.Start()",
      "-main", "Main",
    ], { allowFailure: true });
    if (result.status === 0) {
      return result;
    }
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
  }
  return null;
}
