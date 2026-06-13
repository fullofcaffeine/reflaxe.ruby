#!/usr/bin/env node

const { mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");

const root = resolve(__dirname, "..", "..");
const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
const archiveName = `reflaxe.ruby-${packageJson.version}.zip`;
const archivePath = join(root, "dist", archiveName);

function fail(message) {
  console.error(`[haxelib-package] ERROR: ${message}`);
  process.exit(1);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
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

function assertNoTodoLowerRubyFiles(dir) {
  for (const path of rubyFilesUnder(dir)) {
    const content = readFileSync(path, "utf8");
    if (content.includes("TODO: lower")) {
      fail(`generated Ruby contains internal TODO-lower marker: ${path}`);
    }
  }
}

function rubyFilesUnder(dir) {
  const out = [];
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    const stat = statSync(path);
    if (stat.isDirectory()) {
      out.push(...rubyFilesUnder(path));
    } else if (path.endsWith(".rb")) {
      out.push(path);
    }
  }
  return out;
}

run("node", ["scripts/release/build-haxelib-package.js"]);

const entries = run("unzip", ["-Z1", archivePath]).stdout.trim().split("\n").filter(Boolean);
const entrySet = new Set(entries);

for (const required of [
  "haxelib.json",
  "hxruby.gemspec",
  "extraParams.hxml",
  "lib/hxruby.rb",
  "lib/hxruby/version.rb",
  "src/reflaxe/ruby/RubyCompiler.hx",
  "src/reflaxe/ruby/CompilerBootstrap.hx",
  "src/reflaxe/ruby/macros/RailsInlineMarkup.hx",
  "src/reflaxe/ruby/macros/RubyExtensionMacro.hx",
  "std/Std.cross.hx",
  "std/rails/ActiveRecord.hx",
  "std/rails/ActionMailer.hx",
  "std/rails/action_mailer/Base.hx",
  "std/rails/action_mailer/MailFormat.hx",
  "std/rails/action_mailer/MailOptions.hx",
  "std/rails/action_controller/KeyValueStore.hx",
  "std/rails/action_controller/PermitSpec.hx",
  "std/rails/action_controller/Request.hx",
  "std/rails/action_controller/Response.hx",
  "std/rails/action_controller/Status.hx",
  "std/rails/action_view/H.hx",
  "std/rails/action_view/HtmlAttr.hx",
  "std/rails/action_view/HtmlNode.hx",
  "std/rails/action_view/Slot.hx",
  "std/rails/action_view/Template.hx",
  "std/rails/migration/Migration.hx",
  "std/rails/migration/MigrationOperation.hx",
  "std/rails/turbo/Turbo.hx",
  "std/rails/macros/MailerMacro.hx",
  "std/rails/macros/ViewMacro.hx",
  "runtime/hxruby/core.rb",
  "vendor/reflaxe/src/reflaxe/ReflectCompiler.hx",
]) {
  if (!entrySet.has(required)) {
    fail(`archive missing required entry: ${required}`);
  }
}

for (const forbiddenPrefix of [".git/", ".beads/", ".github/", "node_modules/", "test/", "scripts/"]) {
  const match = entries.find((entry) => entry === forbiddenPrefix.slice(0, -1) || entry.startsWith(forbiddenPrefix));
  if (match) {
    fail(`archive contains forbidden entry: ${match}`);
  }
}

const tempRoot = mkdtempSync(join(tmpdir(), "reflaxe-ruby-package."));
try {
  run("unzip", ["-q", archivePath, "-d", tempRoot]);
  const outputDir = join(tempRoot, "out");
  run("haxe", [
    "-D",
    `ruby_output=${outputDir}`,
    "-D",
    "reflaxe_runtime",
    "-cp",
    join(tempRoot, "src"),
    "-cp",
    join(tempRoot, "examples", "hello_world"),
    "--macro",
    "reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro",
    "reflaxe.ruby.CompilerInit.Start()",
    "-main",
    "Main",
  ]);
  assertNoTodoLowerRubyFiles(outputDir);

  const clientSrc = join(tempRoot, "client_src");
  const clientOut = join(tempRoot, "client.js");
  mkdirSync(clientSrc, { recursive: true });
  writeFileSync(
    join(clientSrc, "ClientMain.hx"),
    [
      "import rails.turbo.Turbo;",
      "class ClientMain {",
      "\tstatic function main():Void {",
      "\t\tTurbo.onLoad(function(_) {});",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );
  run("haxe", [
    "-cp",
    join(tempRoot, "std"),
    "-cp",
    clientSrc,
    "-main",
    "ClientMain",
    "-js",
    clientOut,
    "--dce=full",
  ]);

  const consumerRoot = join(tempRoot, "consumer");
  const consumerSrc = join(consumerRoot, "src");
  const consumerOutputDir = join(consumerRoot, "out");
  mkdirSync(consumerSrc, { recursive: true });
  writeFileSync(
    join(consumerSrc, "Main.hx"),
    'class Main { static function main():Void { Sys.println("Hello from installed reflaxe.ruby"); } }\n',
  );

  run("haxelib", ["newrepo"], { cwd: consumerRoot });
  run("haxelib", ["install", archivePath, "--skip-dependencies", "--quiet"], { cwd: consumerRoot });
  run("haxe", [
    "-D",
    `ruby_output=${consumerOutputDir}`,
    "-D",
    "reflaxe_runtime",
    "-cp",
    "src",
    "-lib",
    "reflaxe.ruby",
    "-main",
    "Main",
  ], { cwd: consumerRoot });
  assertNoTodoLowerRubyFiles(consumerOutputDir);

  const installedStdout = run("ruby", [join(consumerOutputDir, "main.rb")], { cwd: consumerRoot }).stdout;
  if (installedStdout !== "Hello from installed reflaxe.ruby\n") {
    fail(`installed haxelib stdout mismatch: ${JSON.stringify(installedStdout)}`);
  }
} finally {
  rmSync(tempRoot, { force: true, recursive: true });
}

console.log(`[haxelib-package] OK: ${archiveName} (${entries.length} files)`);
