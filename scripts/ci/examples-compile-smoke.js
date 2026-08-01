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
const exampleManifest = JSON.parse(readFileSync(join(root, "test", "example-contracts.json"), "utf8"));
const coverageContracts = new Map(exampleManifest.contracts.map((contract) => [contract.id, contract]));
const allowedTiers = new Set(["flagship-application", "capability-showcase", "compile-only-snippet"]);
const allowedSurfaces = new Set([
  "compiler-conformance",
  "ruby-runtime-stdlib",
  "ruby-native-gem-package",
  "upstream-provenance",
  "examples-downstream",
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
    console.error("[examples-compile] Add it to test/example-contracts.json with an honest tier, surface, claim, proof levels, and command.");
    process.exit(1);
  }

  if (!allowedTiers.has(contract.tier) || !allowedSurfaces.has(contract.surface) || !contract.claim?.trim()) {
    console.error(`[examples-compile] examples/${example} has an invalid tier, product surface, or empty claim.`);
    process.exit(1);
  }

  if (contract.tier === "compile-only-snippet" && contract.proves.some((level) => level !== "generation")) {
    console.error(`[examples-compile] compile-only examples/${example} cannot claim runtime, package, or downstream proof.`);
    process.exit(1);
  }

  if (contract.tier === "flagship-application"
    && (!contract.proves.includes("downstream-application") || !contract.proves.includes("browser-e2e"))) {
    console.error(`[examples-compile] flagship examples/${example} must own a real downstream application and browser proof.`);
    process.exit(1);
  }

  if (contract.evidence.includes("snapshot") && !existsSync(join(root, "test", "snapshots", "m1", example))) {
    console.error(`[examples-compile] examples/${example} declares snapshot coverage but has no test/snapshots/m1/${example} directory.`);
    process.exit(1);
  }

  if (contract.command && !packageJson.scripts?.[contract.command]) {
    console.error(`[examples-compile] examples/${example} declares ${contract.command}, but package.json does not define it.`);
    process.exit(1);
  }

  if (contract.command && !packageJson.scripts.test.includes(contract.command)) {
    console.error(`[examples-compile] examples/${example} declares ${contract.command}, but npm test does not run it.`);
    process.exit(1);
  }

  for (const command of contract.extendedCommands ?? []) {
    if (!packageJson.scripts?.[command]) {
      console.error(`[examples-compile] examples/${example} declares extended observer ${command}, but package.json does not define it.`);
      process.exit(1);
    }
  }

  const extendedProofOwners = new Map([
    ["browser-e2e", "test:todoapp-playwright"],
    ["production-build", "test:todoapp-production"],
  ]);
  for (const [proof, command] of extendedProofOwners) {
    if (contract.proves.includes(proof) && !contract.extendedCommands?.includes(command)) {
      console.error(`[examples-compile] examples/${example} claims ${proof} without naming its ${command} observer.`);
      process.exit(1);
    }
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
