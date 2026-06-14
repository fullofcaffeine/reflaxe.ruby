#!/usr/bin/env node

const { existsSync, mkdtempSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { tmpdir } = require("node:os");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "rails_engine");
const engineRoot = "engines/blog/app/haxe_gen";
const tempGeneratorRoot = mkdtempSync(join(tmpdir(), "railshx-engine-generator."));
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

rmSync(outputDir, { force: true, recursive: true });

try {
  const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));
  if (!reflaxeSrc) {
    fail("Unable to find vendored Reflaxe source for Rails engine smoke.");
  }

  compileEngine(outputDir, reflaxeSrc);

  for (const file of [
    "engines/blog/app/haxe_gen/blog_engine/services/engine_greeting.rb",
    "engines/blog/app/haxe_gen/hxruby/core.rb",
    "engines/blog/app/haxe_gen/main.rb",
    "config/initializers/hxruby_autoload.rb",
    "run.rb",
  ]) {
    const fullPath = join(outputDir, file);
    if (!existsSync(fullPath)) {
      fail(`Expected engine/plugin output file missing: ${fullPath}`);
    }
  }

  const greetingRuby = readFileSync(join(outputDir, "engines", "blog", "app", "haxe_gen", "blog_engine", "services", "engine_greeting.rb"), "utf8");
  for (const expected of [
    "module BlogEngine",
    "module Services",
    "class EngineGreeting",
    "def self.message",
  ]) {
    if (!greetingRuby.includes(expected)) {
      fail(`Engine service output missing expected constant shape: ${expected}`);
    }
  }

  const initializer = readFileSync(join(outputDir, "config", "initializers", "hxruby_autoload.rb"), "utf8");
  for (const expected of [
    'hxruby_root = Rails.root.join("engines/blog/app/haxe_gen")',
    'hxruby_runtime_root = hxruby_root.join("hxruby")',
    "Rails.autoloaders.main.ignore(hxruby_runtime_root)",
    'Dir[hxruby_runtime_root.join("*.rb")].sort.each { |path| require path }',
    "Rails.application.config.autoload_paths << hxruby_root",
    "Rails.application.config.eager_load_paths << hxruby_root",
  ]) {
    if (!initializer.includes(expected)) {
      fail(`Engine autoload initializer missing expected line: ${expected}`);
    }
  }

  const runRuby = readFileSync(join(outputDir, "run.rb"), "utf8");
  assertOrdered(runRuby, [
    'require_relative "engines/blog/app/haxe_gen/hxruby/core"',
    'require_relative "engines/blog/app/haxe_gen/blog_engine/services/engine_greeting"',
    'require_relative "engines/blog/app/haxe_gen/main"',
  ]);

  for (const file of [
    "engines/blog/app/haxe_gen/blog_engine/services/engine_greeting.rb",
    "engines/blog/app/haxe_gen/main.rb",
    "run.rb",
  ]) {
    const result = run("ruby", ["-c", join(outputDir, file)], { allowFailure: true });
    if (result.status !== 0) {
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      process.exit(result.status ?? 1);
    }
  }

  const actual = run("ruby", [join(outputDir, "run.rb")]).stdout;
  if (actual !== "RailsHx engine says hello to host app\n") {
    fail(`engine/plugin stdout mismatch: ${JSON.stringify(actual)}`);
  }

  const invalidRoot = compileEngine(join(root, "test", ".generated", "rails_engine_invalid"), reflaxeSrc, {
    railsOutputRoot: "../bad",
    allowFailure: true,
  });
  if (invalidRoot.status === 0) {
    fail("Expected unsafe reflaxe_ruby_rails_output_root compile to fail.");
  }
  if (!/Unsafe `reflaxe_ruby_rails_output_root` value/.test(invalidRoot.stderr + invalidRoot.stdout)) {
    process.stdout.write(invalidRoot.stdout);
    process.stderr.write(invalidRoot.stderr);
    fail("Unsafe rails output root failed for an unexpected reason.");
  }

  run("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "app.rb"),
    "--output",
    tempGeneratorRoot,
    "--name",
    "BlogEngine",
    "--source",
    "engine_haxe",
    "--main",
    "Boot",
    "--rails-output-root",
    engineRoot,
  ]);

  const build = readFileSync(join(tempGeneratorRoot, "build.hxml"), "utf8");
  for (const expected of [
    "-D reflaxe_ruby_rails",
    `-D reflaxe_ruby_rails_output_root=${engineRoot}`,
    "-cp engine_haxe",
    "-main Boot",
  ]) {
    if (!build.includes(expected)) {
      fail(`engine-aware app generator build.hxml missing expected line: ${expected}`);
    }
  }

  const badGenerator = run("ruby", [
    "-I",
    join(root, "lib"),
    join(root, "scripts", "rails", "app.rb"),
    "--output",
    mkdtempSync(join(tmpdir(), "railshx-engine-generator-bad.")),
    "--rails-output-root",
    "../bad",
  ], { allowFailure: true });
  if (badGenerator.status === 0) {
    fail("Expected unsafe generator --rails-output-root to fail.");
  }
  if (!/--rails-output-root must be a safe relative path/.test(badGenerator.stderr + badGenerator.stdout)) {
    process.stdout.write(badGenerator.stdout);
    process.stderr.write(badGenerator.stderr);
    fail("Unsafe generator rails output root failed for an unexpected reason.");
  }
} finally {
  rmSync(tempGeneratorRoot, { force: true, recursive: true });
}

console.log("[rails-engine] OK");

function compileEngine(targetDir, reflaxeSrc, options = {}) {
  rmSync(targetDir, { force: true, recursive: true });
  const args = [
    "-D",
    `ruby_output=${targetDir}`,
    "-D",
    "reflaxe_runtime",
    "-D",
    "reflaxe_ruby_rails",
    "-D",
    `reflaxe_ruby_rails_output_root=${options.railsOutputRoot ?? engineRoot}`,
    "-cp",
    join(root, "src"),
    "-cp",
    join(root, "examples", "engine_plugin"),
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    "Main",
  ];
  return run("haxe", args, { allowFailure: options.allowFailure });
}

function assertOrdered(haystack, needles) {
  let lastIndex = -1;
  for (const needle of needles) {
    const index = haystack.indexOf(needle);
    if (index === -1) {
      fail(`Missing expected run.rb require: ${needle}`);
    }
    if (index <= lastIndex) {
      fail(`run.rb require out of order: ${needle}`);
    }
    lastIndex = index;
  }
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
  console.error(`[rails-engine] ERROR: ${message}`);
  process.exit(1);
}
