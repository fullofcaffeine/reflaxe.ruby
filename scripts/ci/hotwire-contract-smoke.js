#!/usr/bin/env node

const { existsSync, readFileSync, rmSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const sourceDir = join(root, "test", "hotwire_contract", "src_haxe");
const invalidRoot = join(root, "test", "hotwire_contract", "invalid");
const rubyOutput = join(root, "test", ".generated", "hotwire_contract");
const jsOutput = join(root, "test", ".generated", "hotwire_contract_client.js");
const reflaxeCandidates = [
  join(root, "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.elixir.codex", "vendor", "reflaxe", "src"),
  resolve(root, "..", "haxe.rust", "vendor", "reflaxe", "src"),
];
const reflaxeSrc = reflaxeCandidates.find((path) => existsSync(join(path, "reflaxe", "ReflectCompiler.hx")));

if (!reflaxeSrc) {
  fail("Unable to find vendored Reflaxe source for Hotwire contract smoke.");
}

rmSync(rubyOutput, { force: true, recursive: true });
rmSync(jsOutput, { force: true });

compileRuby(sourceDir, "Main", false);
const mainRuby = join(rubyOutput, "app", "lib", "railshx", "generated", "main.rb");
if (!existsSync(mainRuby)) {
  fail("Hotwire contract Ruby main output is missing.");
}
const rubySource = readFileSync(mainRuby, "utf8");
for (const expected of ['"rooms:updates"', '"room-rows"', '"rooms/row"', '"typed"']) {
  if (!rubySource.includes(expected)) {
    fail(`Hotwire contract output did not inline ${expected}.`);
  }
}
if (/class RoomContract|RoomContract\./.test(rubySource)) {
  fail("Declaration-only Hotwire contract leaked a runtime RoomContract wrapper.");
}

const runtime = run("ruby", [join(rubyOutput, "run.rb")], { allowFailure: true });
if (runtime.status !== 0) {
  process.stdout.write(runtime.stdout);
  process.stderr.write(runtime.stderr);
  process.exit(runtime.status ?? 1);
}
if (runtime.stdout.trim() !== ["rooms:updates", "room-rows", "typed"].join("\n")) {
  fail(`Unexpected Hotwire contract runtime output:\n${runtime.stdout}`);
}

const jsCompile = run("haxe", [
  "-lib",
  "railshx.client",
  "-cp",
  sourceDir,
  "-main",
  "ClientMain",
  "-js",
  jsOutput,
  "--dce=full",
], { allowFailure: true });
if (jsCompile.status !== 0) {
  process.stdout.write(jsCompile.stdout);
  process.stderr.write(jsCompile.stderr);
  process.exit(jsCompile.status ?? 1);
}
const jsSource = readFileSync(jsOutput, "utf8");
for (const expected of ["rooms:updates", "room-rows", "rooms/row"]) {
  if (!jsSource.includes(expected)) {
    fail(`Hotwire contract client output did not preserve ${expected}.`);
  }
}

for (const invalid of [
  ["dynamic", "InvalidDynamicMain", /must be a checked String-compatible token, not Dynamic/],
  ["missing", "InvalidMissingMain", /requires a private static final `row` declaration/],
  ["target", "InvalidTargetMain", /`target` must be String-compatible/],
  ["row", "InvalidRowMain", /`row` must declare Template<TLocals> explicitly/],
  ["locals", "InvalidLocalsMain", /row locals must be a precise type, not Dynamic/],
  ["reserved", "InvalidReservedMain", /reserves `streamName` for its generated typed accessor/],
]) {
  const result = compileRuby(join(invalidRoot, invalid[0]), invalid[1], true);
  if (result.status === 0) {
    fail(`Expected ${invalid[0]} Hotwire contract fixture to fail compilation.`);
  }
  if (!invalid[2].test(result.stdout + result.stderr)) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    fail(`${invalid[0]} Hotwire contract fixture failed with an unexpected diagnostic.`);
  }
}

console.log("[hotwire-contract] OK");

function compileRuby(classPath, main, allowFailure) {
  return run("haxe", [
    "-D",
    `ruby_output=${rubyOutput}`,
    "-D",
    "reflaxe_runtime",
    "-D",
    "reflaxe_ruby_rails",
    "-cp",
    join(root, "src"),
    "-cp",
    classPath,
    "-cp",
    reflaxeSrc,
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    main,
  ], { allowFailure });
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    env: process.env,
  });
  if (!options.allowFailure && result.status !== 0) {
    process.stdout.write(result.stdout ?? "");
    process.stderr.write(result.stderr ?? "");
    process.exit(result.status ?? 1);
  }
  return result;
}

function fail(message) {
  console.error(message);
  process.exit(1);
}
