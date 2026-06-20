#!/usr/bin/env node

const { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync } = require("node:fs");
const { dirname, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");

const root = resolve(__dirname, "..", "..");
const outputDir = join(root, "test", ".generated", "route_parity_hx_check");
const generatedRoot = join(root, "lib", "hxruby", "generated", "route_parity");
const update = process.env.UPDATE_ROUTE_PARITY_GENERATED === "1";

const trackedFiles = [
  "ruby/native_hash.rb",
  "hxruby/generators/routes/devise_expected_field.rb",
  "hxruby/generators/routes/manifest_route.rb",
  "hxruby/generators/routes/rails_route.rb",
  "hxruby/generators/routes/parity_core.rb",
];

rmSync(outputDir, { force: true, recursive: true });

const compile = spawnSync("haxe", [
  "-D",
  `ruby_output=${outputDir}`,
  "-D",
  "reflaxe_runtime",
  "-cp",
  "src",
  "-cp",
  "tools/route_parity_hx/src_haxe",
  "-cp",
  "vendor/reflaxe/src",
  "--macro",
  "reflaxe.ruby.CompilerBootstrap.Start()",
  "--macro",
  "reflaxe.ruby.CompilerInit.Start()",
  "-main",
  "hxruby.generators.routes.ParityCore",
], {
  cwd: root,
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});

if (compile.status !== 0) {
  process.stdout.write(compile.stdout);
  process.stderr.write(compile.stderr);
  process.exit(compile.status ?? 1);
}

for (const relativePath of trackedFiles) {
  const compiled = join(outputDir, relativePath);
  const committed = join(generatedRoot, relativePath);
  if (!existsSync(compiled)) {
    console.error(`Route parity dogfood compile did not produce ${relativePath}`);
    process.exit(1);
  }

  if (update) {
    mkdirSync(dirname(committed), { recursive: true });
    copyFileSync(compiled, committed);
    continue;
  }

  if (!existsSync(committed)) {
    console.error(`Missing committed route parity generated file: ${relativePath}`);
    process.exit(1);
  }

  if (readFileSync(compiled, "utf8") !== readFileSync(committed, "utf8")) {
    console.error(`Committed route parity generated Ruby is stale: ${relativePath}`);
    console.error("Run `UPDATE_ROUTE_PARITY_GENERATED=1 npm run test:route-parity-dogfood` and commit the regenerated files.");
    process.exit(1);
  }
}

const parityCore = readFileSync(join(generatedRoot, "hxruby/generators/routes/parity_core.rb"), "utf8");
for (const expectedSnippet of [
  'require "json"',
  "JSON.parse(manifest_json",
  "JSON.parse(devise_facts_json",
  "File.read(manifest_path",
  "File.read(devise_facts_path",
]) {
  if (!parityCore.includes(expectedSnippet)) {
    console.error(`Generated route parity core no longer dogfoods Ruby API usage: missing ${expectedSnippet}`);
    process.exit(1);
  }
}

if (update) {
  console.log("Updated committed route parity generated Ruby from Haxe source.");
}
