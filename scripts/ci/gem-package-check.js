#!/usr/bin/env node

const { existsSync, mkdtempSync, readFileSync, rmSync } = require("node:fs");
const { delimiter, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");

const root = resolve(__dirname, "..", "..");
const packageJson = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
const gemName = `hxruby-${packageJson.version}.gem`;
const gemPath = join(root, "dist", gemName);

function fail(message) {
  console.error(`[gem-package] ERROR: ${message}`);
  process.exit(1);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    env: options.env ?? process.env,
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

function rubySupportsGemInstallCheck() {
  const version = run("ruby", ["-e", "print RUBY_VERSION"]).stdout.trim();
  const [major, minor] = version.split(".").map((part) => Number(part));
  return major > 3 || (major === 3 && minor >= 2);
}

run("node", ["scripts/release/build-gem-package.js"]);

const tempRoot = mkdtempSync(join(tmpdir(), "hxruby-gem."));
try {
  run("gem", ["unpack", gemPath, "--target", tempRoot]);
  const unpackedRoot = join(tempRoot, `hxruby-${packageJson.version}`);

  for (const required of [
    "haxelib.json",
    "hxruby.gemspec",
    "lib/hxruby.rb",
    "lib/hxruby/tasks.rb",
    "lib/generators/hxruby/adopt/adopt_generator.rb",
    "lib/generators/hxruby/install/install_generator.rb",
    "lib/generators/hxruby/routes/routes_generator.rb",
    "lib/generators/hxruby/scaffold/scaffold_generator.rb",
    "runtime/hxruby/core.rb",
    "runtime/hxruby/data_define.rb",
    "runtime/hxruby/hx_exception.rb",
    "scripts/rails/adopt.rb",
    "scripts/rails/app.rb",
    "scripts/rails/generate-routes.rb",
    "scripts/rails/scaffold.rb",
  ]) {
    if (!existsSync(join(unpackedRoot, required))) {
      fail(`gem missing required entry: ${required}`);
    }
  }

  const runtimeCheck = [
    "require 'hxruby'",
    `abort 'version mismatch' unless HXRuby::VERSION == ${JSON.stringify(packageJson.version)}`,
    "abort 'stringify mismatch' unless HXRuby.stringify([1, 2]) == '[1, 2]'",
    "raise HxException.new({ 'message' => 'boom' }) rescue (ex = $!)",
    "abort 'exception mismatch' unless ex.message == '{\"message\"=>\"boom\"}'",
  ].join("; ");
  run("ruby", ["-I", join(unpackedRoot, "lib"), "-e", runtimeCheck]);

  const tasksCheck = [
    "require 'rake'",
    "require 'hxruby/tasks'",
    "expected = %w[hxruby:compile hxruby:compile:client hxruby:watch hxruby:watch:client hxruby:gen:adopt hxruby:gen:app hxruby:gen:model hxruby:gen:routes]",
    "names = Rake::Task.tasks.map(&:name)",
    "missing = expected - names",
    "abort \"missing tasks: #{missing.join(', ')}\" unless missing.empty?",
  ].join("; ");
  run("ruby", ["-I", join(unpackedRoot, "lib"), "-e", tasksCheck]);

  if (rubySupportsGemInstallCheck()) {
    const gemHome = join(tempRoot, "gems");
    const gemBin = join(tempRoot, "bin");
    run("gem", ["install", "--local", gemPath, "--install-dir", gemHome, "--bindir", gemBin, "--no-document", "--force"]);

    const installCheck = [
      "require 'rubygems'",
      `gem 'hxruby', ${JSON.stringify(packageJson.version)}`,
      "require 'hxruby'",
      `abort 'installed version mismatch' unless HXRuby::VERSION == ${JSON.stringify(packageJson.version)}`,
      "abort 'installed stringify mismatch' unless HXRuby.stringify({ 'a' => 1 }) == '{\"a\"=>1}'",
    ].join("; ");
    const installEnv = {
      ...process.env,
      GEM_HOME: gemHome,
      GEM_PATH: gemHome,
      PATH: `${gemBin}:${process.env.PATH}`,
    };
    run("ruby", ["-e", installCheck], {
      env: installEnv,
    });

    const rubyDefaultGemPath = run("ruby", ["-rrubygems", "-e", "print Gem.path.join(File::PATH_SEPARATOR)"]).stdout.trim();
    const installedTasksEnv = {
      ...installEnv,
      GEM_PATH: [gemHome, rubyDefaultGemPath].filter(Boolean).join(delimiter),
    };
    const installedTasksCheck = [
      "require 'rubygems'",
      `gem 'hxruby', ${JSON.stringify(packageJson.version)}`,
      "require 'hxruby/tasks'",
      "expected = %w[hxruby:compile hxruby:compile:client hxruby:watch hxruby:watch:client hxruby:gen:adopt hxruby:gen:app hxruby:gen:model hxruby:gen:routes]",
      "names = Rake::Task.tasks.map(&:name)",
      "missing = expected - names",
      "abort \"installed gem missing tasks: #{missing.join(', ')}\" unless missing.empty?",
    ].join("; ");
    run("ruby", ["-e", installedTasksCheck], {
      env: installedTasksEnv,
    });
  } else {
    process.stdout.write("[gem-package] Skipped gem install smoke on local Ruby < 3.2\n");
  }
} finally {
  rmSync(tempRoot, { force: true, recursive: true });
}

console.log(`[gem-package] OK: ${gemName}`);
