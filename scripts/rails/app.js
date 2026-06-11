#!/usr/bin/env node

const { chmodSync, existsSync, mkdirSync, writeFileSync } = require("node:fs");
const { dirname, join, resolve } = require("node:path");

const args = process.argv.slice(2);
const outputDir = resolve(valueAfter("--output") ?? ".");
const appName = valueAfter("--name") ?? "RailsHxApp";
const sourceDir = valueAfter("--source") ?? "src_haxe";
const mainClass = valueAfter("--main") ?? "Main";
const force = args.includes("--force");

write("build.hxml", renderBuild());
write("build-client.hxml", renderClientBuild());
write(join(sourceDir, mainClass + ".hx"), renderMain());
write(join(sourceDir, "client", "Boot.hx"), renderClientBoot());
write(join(sourceDir, "routes", "Routes.hx"), renderRoutes());
write("app/javascript/application.js", renderApplicationJs());
write("app/assets/stylesheets/application.css", renderApplicationCss());
write("config/importmap.rb", renderImportmap());
write("lib/tasks/hxruby.rake", renderRakeTask());
write("Procfile.railshx.dev", renderProcfile());
write("bin/railshx-dev", renderDevRunner(), { executable: true });

console.log(`[rails:app] Generated RailsHx app files in ${outputDir}`);
console.log("[rails:app] Next:");
console.log("  bundle exec rake hxruby:compile");
console.log("  bundle exec rake hxruby:compile:client");
console.log("  bin/railshx-dev");

function valueAfter(name) {
  const index = args.indexOf(name);
  if (index === -1) {
    return null;
  }
  return args[index + 1] ?? null;
}

function renderBuild() {
  return [
    "-lib reflaxe.ruby",
    "-D ruby_output=.",
    "-D reflaxe_runtime",
    "-D reflaxe_ruby_rails",
    "-cp " + sourceDir,
    "--macro reflaxe.ruby.CompilerBootstrap.Start()",
    "--macro reflaxe.ruby.CompilerInit.Start()",
    "-main " + mainClass,
    "",
  ].join("\n");
}

function renderClientBuild() {
  return [
    "-cp " + sourceDir,
    "# Use `-cp path/to/reflaxe.ruby/std` when consuming RailsHx client std from an installed package.",
    "-main client.Boot",
    "-js app/javascript/railshx/app.js",
    "-D source-map",
    "--dce=full",
    "",
  ].join("\n");
}

function renderMain() {
  return [
    "class " + mainClass + " {",
    "\tstatic function main() {",
    "\t\tSys.println(" + JSON.stringify(appName + " RailsHx compile") + ");",
    "\t}",
    "}",
    "",
  ].join("\n");
}

function renderClientBoot() {
  return [
    "package client;",
    "",
    "import js.Browser;",
    "",
    "class Boot {",
    "\tpublic static function main():Void {",
    "\t\tBrowser.console.log(" + JSON.stringify(appName + " RailsHx client boot") + ");",
    "\t}",
    "}",
    "",
  ].join("\n");
}

function renderRoutes() {
  return [
    "package routes;",
    "",
    "// Run `bundle exec rake hxruby:gen:routes` after adding Rails routes.",
    '@:native("self")',
    "extern class Routes {",
    "\t// Generated route helpers will be written here.",
    "}",
    "",
  ].join("\n");
}

function renderRakeTask() {
  return [
    "begin",
    '  require "hxruby/tasks"',
    "rescue LoadError => error",
    '  warn "RailsHx tasks unavailable: #{error.message}"',
    '  warn "Add the hxruby gem or run with the repository checkout on RUBYLIB."',
    "end",
    "",
  ].join("\n");
}

function renderApplicationJs() {
  return [
    'import "@hotwired/turbo-rails"',
    'import "railshx/app"',
    "",
  ].join("\n");
}

function renderApplicationCss() {
  return [
    "/* RailsHx app stylesheet. Keep app-facing CSS here; generated HHX should emit structure. */",
    "body {",
    "  margin: 0;",
    "}",
    "",
  ].join("\n");
}

function renderImportmap() {
  return [
    'pin "application"',
    'pin "@hotwired/turbo-rails", to: "turbo.min.js"',
    'pin "railshx/app", to: "railshx/app.js"',
    "",
  ].join("\n");
}

function renderProcfile() {
  return [
    "rails: bundle exec rails server",
    "haxe: bundle exec rake hxruby:watch",
    "haxe_client: bundle exec rake hxruby:watch:client",
    "",
  ].join("\n");
}

function renderDevRunner() {
  return [
    "#!/usr/bin/env bash",
    "set -euo pipefail",
    "",
    "if command -v foreman >/dev/null 2>&1; then",
    "  exec foreman start -f Procfile.railshx.dev",
    "fi",
    "",
    "if command -v overmind >/dev/null 2>&1; then",
    "  exec overmind start -f Procfile.railshx.dev",
    "fi",
    "",
    "echo \"No foreman/overmind found.\"",
    "echo \"Run these in separate terminals:\"",
    "echo \"  bundle exec rails server\"",
    "echo \"  bundle exec rake hxruby:watch\"",
    "echo \"  bundle exec rake hxruby:watch:client\"",
    "",
  ].join("\n");
}

function write(relativePath, content, options = {}) {
  const fullPath = join(outputDir, relativePath);
  if (existsSync(fullPath) && !force) {
    console.error(`Refusing to overwrite ${fullPath}. Re-run with --force if intended.`);
    process.exit(1);
  }
  mkdirSync(dirname(fullPath), { recursive: true });
  writeFileSync(fullPath, content);
  if (options.executable) {
    chmodSync(fullPath, 0o755);
  }
}
