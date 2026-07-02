#!/usr/bin/env node

const { existsSync, readdirSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputRoot = join(root, "test", ".generated", "examples_compile");

const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "wt-c07bfa5c", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];

const railsExamples = new Set([
  "action_cable",
  "action_controller_params",
  "action_mailer",
  "active_job",
  "active_record_model",
  "active_storage",
  "components",
  "engine_plugin",
  "rails_autoload",
  "rails_interop_app",
  "rails_test_adapters",
  "rails_routes_dsl",
  "todoapp_rails",
  "turbo_streams",
]);

const extraClassPaths = new Map([
  ["todoapp_rails", ["src"]],
]);

const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));

const coverageContracts = new Map([
  ["action_cable", { kind: "snapshot+smoke", script: "test:action-cable" }],
  ["action_controller_params", { kind: "snapshot+smoke", script: "test:action-controller-params" }],
  ["action_mailer", { kind: "snapshot+smoke", script: "test:action-mailer" }],
  ["active_job", { kind: "snapshot+smoke", script: "test:active-job" }],
  ["active_record_model", { kind: "snapshot+smoke", script: "test:active-record-model" }],
  ["active_storage", { kind: "snapshot+smoke", script: "test:active-storage" }],
  ["active_support_facades", { kind: "smoke", script: "test:active-support-facades" }],
  ["class_members", { kind: "snapshot+smoke", script: "test:class-members" }],
  ["components", { kind: "snapshot+smoke", script: "test:components" }],
  ["core_subset", { kind: "snapshot+smoke", script: "test:core-subset" }],
  ["engine_plugin", { kind: "snapshot+smoke", script: "test:rails-engine" }],
  ["enum_adt", { kind: "snapshot+smoke", script: "test:enum-adt" }],
  ["exception_flow", { kind: "snapshot+smoke", script: "test:exception-flow" }],
  ["hello_world", { kind: "smoke", script: "test:hello-world" }],
  ["instrumentation", { kind: "snapshot+smoke", script: "test:instrumentation" }],
  ["lambda_values", { kind: "snapshot+smoke", script: "test:lambda-values" }],
  ["native_mapping", { kind: "snapshot+smoke", script: "test:native-mapping" }],
  ["rails_autoload", { kind: "snapshot+smoke", script: "test:rails-autoload" }],
  ["rails_interop_app", { kind: "snapshot+runtime", script: "test:rails-interop" }],
  ["rails_test_adapters", { kind: "snapshot", script: "test:snapshots" }],
  ["rails_routes_dsl", { kind: "snapshot+smoke", script: "test:routes-dsl" }],
  ["require_metadata", { kind: "snapshot+smoke", script: "test:require-registry" }],
  ["ruby_call_shapes", { kind: "snapshot+smoke", script: "test:ruby-call-shapes" }],
  ["ruby_extensions", { kind: "snapshot+smoke", script: "test:ruby-extensions" }],
  ["ruby_interop", { kind: "snapshot+smoke", script: "test:ruby-interop" }],
  ["stdlib_mvp", { kind: "snapshot+smoke", script: "test:stdlib-mvp" }],
  ["switch_cases", { kind: "snapshot+smoke", script: "test:switch-cases" }],
  ["todoapp_rails", { kind: "snapshot+rails+browser+production", script: "test:todoapp-rails" }],
  ["turbo_streams", { kind: "snapshot+smoke", script: "test:turbo-streams" }],
]);

rmSync(outputRoot, { force: true, recursive: true });

const reflaxeSrc = firstAvailableReflaxe();
if (!reflaxeSrc) {
  console.error("[examples-compile] Unable to run; no Reflaxe candidate found.");
  process.exit(1);
}

const examples = readdirSync(join(root, "examples"), { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .filter((name) => hasExampleMain(name))
  .sort();

for (const example of examples) {
  assertExampleCoverage(example);
  compileExample(example, reflaxeSrc);
}

compileExampleClientBuilds();

console.log(`[examples-compile] OK (${examples.length} Haxe examples compiled)`);

function firstAvailableReflaxe() {
  return reflaxeCandidates.find((candidate) => existsSync(join(candidate, "reflaxe", "ReflectCompiler.hx")));
}

function hasExampleMain(example) {
  const exampleDir = join(root, "examples", example);
  return existsSync(join(exampleDir, "Main.hx")) || existsSync(join(exampleDir, "src", "Main.hx"));
}

function assertExampleCoverage(example) {
  const contract = coverageContracts.get(example);
  if (!contract) {
    console.error(`[examples-compile] examples/${example} is missing an expected-output/test coverage contract.`);
    console.error("[examples-compile] Add it to coverageContracts with snapshot/smoke/runtime/browser coverage before landing the example.");
    process.exit(1);
  }

  if (contract.kind.includes("snapshot") && !existsSync(join(root, "test", "snapshots", "m1", example))) {
    console.error(`[examples-compile] examples/${example} declares snapshot coverage but has no test/snapshots/m1/${example} directory.`);
    process.exit(1);
  }

  if (contract.script && !packageJson.scripts?.[contract.script]) {
    console.error(`[examples-compile] examples/${example} declares ${contract.script}, but package.json does not define it.`);
    process.exit(1);
  }

  if (contract.script && !packageJson.scripts.test.includes(contract.script)) {
    console.error(`[examples-compile] examples/${example} declares ${contract.script}, but npm test does not run it.`);
    process.exit(1);
  }
}

function compileExample(example, reflaxeSrc) {
  const exampleDir = join(root, "examples", example);
  const args = [
    "-D",
    `ruby_output=${join(outputRoot, example)}`,
    "-D",
    "reflaxe_runtime",
  ];
  if (railsExamples.has(example)) {
    args.push("-D", "reflaxe_ruby_rails");
  }
  args.push(
    "-cp",
    join(root, "src"),
    "-cp",
    exampleDir,
  );
  for (const relative of extraClassPaths.get(example) ?? []) {
    args.push("-cp", join(exampleDir, relative));
  }
  args.push(
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    "Main",
  );

  const result = spawnSync("haxe", args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    console.error(`[examples-compile] Failed to compile examples/${example}`);
    process.exit(result.status ?? 1);
  }
}

function compileExampleClientBuilds() {
  const clientBuilds = [
    join(root, "examples", "todoapp_rails", "build-client.hxml"),
  ].filter((path) => existsSync(path));

  for (const hxml of clientBuilds) {
    const result = spawnSync("haxe", [hxml], {
      cwd: root,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
    if (result.status !== 0) {
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      console.error(`[examples-compile] Failed to compile ${hxml}`);
      process.exit(result.status ?? 1);
    }
  }
}
