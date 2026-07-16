#!/usr/bin/env node

const { chmodSync, existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } = require("node:fs");
const { delimiter, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");
const { sha256File, verifyArtifactManifest } = require("../release/artifact-utils");

const root = resolve(__dirname, "..", "..");
const supportMatrix = JSON.parse(readFileSync(join(root, "lib", "hxruby", "support_matrix.json"), "utf8"));
const stagedVersion = "0.2.3";
const stagedTag = `v${stagedVersion}`;
const sourceSha = run("git", ["rev-parse", "HEAD"]).stdout.trim();
const gemName = "hxruby-release.gem";
const gemPath = join(root, "dist", gemName);
const sidecarPath = `${gemPath}.sha256.json`;

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
  if (result.status !== 0 && !options.allowFailure) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }
  return result;
}

// Consumer fixtures live outside the repo's .ruby-version ancestry, so retain
// the selected interpreter instead of letting an rbenv shim choose system Ruby.
const activeRuby = run("ruby", ["-rrbconfig", "-e", "print RbConfig.ruby"]).stdout.trim();
const activeRake = run(activeRuby, [
  "-rrubygems",
  "-e",
  'print Gem.bin_path("rake", "rake")',
]).stdout.trim();
const activeRubyVersion = run(activeRuby, ["-e", "print RUBY_VERSION"]).stdout.trim();

function rubySupportsGemInstallCheck() {
  const current = activeRubyVersion.split(".").slice(0, 2).map(Number);
  const minimum = supportMatrix.ruby.minimumVersion.split(".").map(Number);
  return current[0] > minimum[0] || (current[0] === minimum[0] && current[1] >= minimum[1]);
}

const trackedDiffBefore = `${run("git", ["diff", "--binary"]).stdout}${run("git", ["diff", "--cached", "--binary"]).stdout}`;

run("node", ["scripts/release/build-gem-package.js", stagedVersion, stagedTag, sourceSha]);

const sidecar = JSON.parse(readFileSync(sidecarPath, "utf8"));
if (
  sidecar.localFilename !== gemName ||
  sidecar.hostedFilename !== `hxruby-${stagedVersion}.gem` ||
  sidecar.bytes !== statSync(gemPath).size ||
  sidecar.sha256 !== sha256File(gemPath) ||
  sidecar.version !== stagedVersion ||
  sidecar.gitTag !== stagedTag ||
  sidecar.sourceSha !== sourceSha
) {
  fail("gem artifact SHA-256 sidecar does not match the exact built gem and release identity");
}

const tempRoot = mkdtempSync(join(tmpdir(), "hxruby-gem."));
try {
  run("gem", ["unpack", gemPath, "--target", tempRoot]);
  // RubyGems names the unpack directory from the fixed local artifact path;
  // the gem specification and installed identity still carry stagedVersion.
  const unpackedRoot = join(tempRoot, "hxruby-release");
  verifyArtifactManifest(unpackedRoot, "hxruby-gem");

  for (const required of [
    "haxelib.json",
    "artifact-manifest.json",
    "release-provenance.json",
    "hxruby.gemspec",
    "lib/hxruby.rb",
    "lib/hxruby/support_matrix.json",
    "lib/hxruby/support_matrix.rb",
    "lib/hxruby/stdlib_coverage.json",
    "lib/hxruby/tasks.rb",
    "lib/generators/hxruby/adopt/adopt_generator.rb",
    "lib/generators/hxruby/install/install_generator.rb",
    "lib/generators/hxruby/routes/routes_generator.rb",
    "lib/generators/hxruby/controller/controller_generator.rb",
    "lib/generators/hxruby/mailer/mailer_generator.rb",
    "lib/generators/hxruby/template/template_generator.rb",
    "lib/generators/hxruby/test/test_generator.rb",
    "lib/generators/hxruby/scaffold/scaffold_generator.rb",
    "runtime/hxruby/core.rb",
    "runtime/hxruby/data_define.rb",
    "runtime/hxruby/hx_exception.rb",
    "vendor/genes/src/genes/Generator.hx",
    "vendor/genes/haxelib.json",
    "scripts/rails/adopt.rb",
    "scripts/rails/app.rb",
    "scripts/rails/controller.rb",
    "scripts/rails/mailer.rb",
    "scripts/rails/template.rb",
    "scripts/rails/test.rb",
    "scripts/rails/generate-routes.rb",
    "scripts/rails/scaffold.rb",
    "std/ruby/URI.hx",
    "std/ruby/URIValue.hx",
    "std/reflaxe/js/Async.hx",
    "std/rails/turbo/StreamName.hx",
    "std/rails/turbo/StreamTarget.hx",
    "std/rails/turbo/Turbo.hx",
    "std/rails/turbo/TurboStreams.hx",
    "std/rails/turbo/TurboVisitAction.hx",
  ]) {
    if (!existsSync(join(unpackedRoot, required))) {
      fail(`gem missing required entry: ${required}`);
    }
  }
  const provenance = JSON.parse(readFileSync(join(unpackedRoot, "release-provenance.json"), "utf8"));
  if (provenance.version !== stagedVersion || provenance.gitTag !== stagedTag || provenance.sourceSha !== sourceSha) {
    fail("gem release identity does not match staged version/tag/source SHA");
  }

  const runtimeCheck = [
    "require 'hxruby'",
    `abort 'version mismatch' unless HXRuby::VERSION == ${JSON.stringify(stagedVersion)}`,
    "abort 'stringify mismatch' unless HXRuby.stringify([1, 2]) == '[1,2]'",
    "raise HxException.new({ 'message' => 'boom' }) rescue (ex = $!)",
    "abort 'exception mismatch' unless ex.message == '{\"message\"=>\"boom\"}'",
  ].join("; ");
  run(activeRuby, ["-I", join(unpackedRoot, "lib"), "-e", runtimeCheck]);

  const tasksCheck = [
    "require 'rake'",
    "require 'hxruby/tasks'",
    "expected = %w[hxruby:compile hxruby:compile:client hxruby:db:migrate hxruby:db:prepare hxruby:db:rollback hxruby:rails hxruby:start hxruby:start:watch hxruby:test hxruby:routes hxruby:doctor hxruby:check hxruby:clean hxruby:production hxruby:watch hxruby:watch:client hxruby:gen:adopt hxruby:gen:app hxruby:gen:controller hxruby:gen:mailer hxruby:gen:template hxruby:gen:test hxruby:gen:model hxruby:gen:routes]",
    "names = Rake::Task.tasks.map(&:name)",
    "missing = expected - names",
    "abort \"missing tasks: #{missing.join(', ')}\" unless missing.empty?",
  ].join("; ");
  run(activeRuby, ["-I", join(unpackedRoot, "lib"), "-e", tasksCheck]);
  smokeDoctorTask(unpackedRoot);
  smokeDoctorFailureTask(unpackedRoot);
  smokeClientLibrary(unpackedRoot);
  smokeCheckTask(unpackedRoot);
  smokeCleanTask(unpackedRoot);
  smokeProductionTask(unpackedRoot);

  if (rubySupportsGemInstallCheck()) {
    const gemHome = join(tempRoot, "gems");
    const gemBin = join(tempRoot, "bin");
    run("gem", ["install", "--local", gemPath, "--install-dir", gemHome, "--bindir", gemBin, "--no-document", "--force"]);

    const installCheck = [
      "require 'rubygems'",
      `gem 'hxruby', ${JSON.stringify(stagedVersion)}`,
      "require 'hxruby'",
      `abort 'installed version mismatch' unless HXRuby::VERSION == ${JSON.stringify(stagedVersion)}`,
      "abort 'installed stringify mismatch' unless HXRuby.stringify({ 'a' => 1 }) == '{\"a\"=>1}'",
    ].join("; ");
    const installEnv = {
      ...process.env,
      GEM_HOME: gemHome,
      GEM_PATH: gemHome,
      PATH: `${gemBin}:${process.env.PATH}`,
    };
    run(activeRuby, ["-e", installCheck], {
      env: installEnv,
    });

    const rubyDefaultGemPath = run(activeRuby, ["-rrubygems", "-e", "print Gem.path.join(File::PATH_SEPARATOR)"]).stdout.trim();
    const installedTasksEnv = {
      ...installEnv,
      GEM_PATH: [gemHome, rubyDefaultGemPath].filter(Boolean).join(delimiter),
    };
    const installedTasksCheck = [
      "require 'rubygems'",
      `gem 'hxruby', ${JSON.stringify(stagedVersion)}`,
      "require 'hxruby/tasks'",
      "expected = %w[hxruby:compile hxruby:compile:client hxruby:db:migrate hxruby:db:prepare hxruby:db:rollback hxruby:rails hxruby:start hxruby:start:watch hxruby:test hxruby:routes hxruby:doctor hxruby:check hxruby:clean hxruby:production hxruby:watch hxruby:watch:client hxruby:gen:adopt hxruby:gen:app hxruby:gen:controller hxruby:gen:mailer hxruby:gen:template hxruby:gen:test hxruby:gen:model hxruby:gen:routes]",
      "names = Rake::Task.tasks.map(&:name)",
      "missing = expected - names",
      "abort \"installed gem missing tasks: #{missing.join(', ')}\" unless missing.empty?",
    ].join("; ");
    run(activeRuby, ["-e", installedTasksCheck], {
      env: installedTasksEnv,
    });
  } else {
    process.stdout.write(`[gem-package] Skipped gem install smoke on unsupported local Ruby ${activeRubyVersion}\n`);
  }
} finally {
  rmSync(tempRoot, { force: true, recursive: true });
}

const trackedDiffAfter = `${run("git", ["diff", "--binary"]).stdout}${run("git", ["diff", "--cached", "--binary"]).stdout}`;
if (trackedDiffAfter !== trackedDiffBefore) fail("gem staging changed tracked checkout files");

console.log(`[gem-package] OK: ${gemName}`);

function smokeDoctorTask(unpackedRoot) {
  const appRoot = join(tempRoot, "doctor-smoke-app");
  const fakeBin = join(appRoot, "fake-bin");
  mkdirSync(fakeBin, { recursive: true });
  mkdirSync(join(appRoot, ".railshx"), { recursive: true });
  mkdirSync(join(appRoot, "generated"), { recursive: true });
  writeFileSync(join(appRoot, "build.hxml"), "-D ruby_output=generated\n# fake server build\n");
  writeFileSync(join(appRoot, "build-client.hxml"), "# fake client build\n");
  const generatedPath = join(appRoot, "generated", "owned.rb");
  writeFileSync(generatedPath, "# Generated by RailsHx.\nclass Owned; end\n");
  writeFileSync(join(appRoot, ".railshx", "manifest.json"), `${JSON.stringify({
    version: 1,
    outputs: [{
      output: "generated/owned.rb",
      kind: "ruby",
      source: "hxruby:generator",
      sha256: sha256File(generatedPath),
    }],
  })}\n`);
  writeExecutable(join(fakeBin, "haxe"), [
    "#!/usr/bin/env ruby",
    'puts "4.3.7"',
  ]);
  writeExecutable(join(fakeBin, "node"), [
    "#!/usr/bin/env ruby",
    'puts "v22.14.0"',
  ]);
  writeFileSync(join(appRoot, "Rakefile"), 'require "hxruby/tasks"\n');

  const result = run(activeRuby, [activeRake, "hxruby:doctor"], {
    cwd: appRoot,
    env: {
      ...process.env,
      RUBYLIB: [join(unpackedRoot, "lib"), process.env.RUBYLIB].filter(Boolean).join(delimiter),
      PATH: [fakeBin, process.env.PATH].filter(Boolean).join(delimiter),
    },
  });
  const output = `${result.stdout}\n${result.stderr}`;
  for (const expected of [
    `[hxruby:doctor] INFO: hxruby ${stagedVersion}; Ruby`,
    "[hxruby:doctor] INFO: Haxe 4.3.7",
    "generated Ruby roots from build.hxml: generated",
    'generated ownership manifest .railshx/manifest.json version 1 tracks 1 outputs; generator sources ["hxruby:generator"]',
    "[hxruby:doctor] OK",
  ]) {
    if (!output.includes(expected)) {
      process.stdout.write(result.stdout);
      process.stderr.write(result.stderr);
      fail(`hxruby:doctor output is missing installed identity or provenance: ${expected}`);
    }
  }
}

function smokeDoctorFailureTask(unpackedRoot) {
  const appRoot = join(tempRoot, "doctor-failure-smoke-app");
  const fakeBin = join(appRoot, "fake-bin");
  mkdirSync(fakeBin, { recursive: true });
  mkdirSync(join(appRoot, "db", "migrate"), { recursive: true });
  writeFileSync(join(appRoot, "build.hxml"), "-D ruby_output=generated\n# fake server build\n");
  writeFileSync(join(appRoot, "build-client.hxml"), "# fake client build\n");
  writeFileSync(join(appRoot, "db", "migrate", "20260101000000_create_users.rb"), "class CreateUsers < ActiveRecord::Migration[7.1]\nend\n");
  writeFileSync(join(appRoot, "db", "migrate", "20260101000000_create_members.rb"), "class CreateUsers < ActiveRecord::Migration[7.1]\nend\n");
  writeExecutable(join(fakeBin, "haxe"), [
    "#!/usr/bin/env ruby",
    'puts "4.3.7"',
  ]);
  writeFileSync(join(appRoot, "Rakefile"), 'require "hxruby/tasks"\n');

  const result = run(activeRuby, [activeRake, "hxruby:doctor"], {
    cwd: appRoot,
    allowFailure: true,
    env: {
      ...process.env,
      RUBYLIB: [join(unpackedRoot, "lib"), process.env.RUBYLIB].filter(Boolean).join(delimiter),
      PATH: [fakeBin, process.env.PATH].filter(Boolean).join(delimiter),
    },
  });
  const output = `${result.stdout}\n${result.stderr}`;
  if (result.status === 0 || !output.includes("duplicate Rails migration timestamp") || !output.includes("duplicate Rails migration class")) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    fail("hxruby:doctor did not fail on duplicate migration timestamp/class diagnostics");
  }
}

function smokeClientLibrary(unpackedRoot) {
  const appRoot = join(tempRoot, "client-library-smoke-app");
  const clientOut = join(appRoot, "client.js");
  const unexpectedRubyOut = join(appRoot, "unexpected-ruby-out");
  mkdirSync(join(appRoot, "src"), { recursive: true });
  mkdirSync(join(appRoot, "haxe_libraries"), { recursive: true });
  writeFileSync(join(appRoot, ".haxerc"), '{\n  "version": "4.3.7",\n  "resolveLibs": "scoped"\n}\n');
  writeFileSync(
    join(appRoot, "haxe_libraries", "railshx.client.hxml"),
    [
      `-cp ${join(unpackedRoot, "std")}`,
      `-D railshx.client=${stagedVersion}`,
      "",
    ].join("\n"),
  );
  writeFileSync(
    join(appRoot, "src", "ClientMain.hx"),
    [
      "import rails.turbo.Turbo;",
      "import rails.turbo.TurboVisitAction;",
      "import reflaxe.js.Async;",
      "class ClientMain {",
      "\tstatic function main():Void {",
      "\t\tTurbo.onLoad(function(_) {});",
      "\t\tTurbo.visit(\"/\", { action: TurboVisitAction.Replace });",
      "\t\tAsync.delay(1);",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );

  run("haxe", [
    "-cp",
    "src",
    "-lib",
    "railshx.client",
    "-main",
    "ClientMain",
    "-js",
    clientOut,
    "--dce=full",
  ], { cwd: appRoot });

  if (!existsSync(clientOut)) {
    fail("railshx.client gem smoke did not emit client.js");
  }
  if (existsSync(unexpectedRubyOut)) {
    fail("railshx.client gem smoke unexpectedly produced Ruby output");
  }
}

function smokeCheckTask(unpackedRoot) {
  const appRoot = join(tempRoot, "check-smoke-app");
  const fakeBin = join(appRoot, "fake-bin");
  const logPath = join(appRoot, "task.log");
  mkdirSync(fakeBin, { recursive: true });
  writeFileSync(join(appRoot, "build.hxml"), "-D ruby_output=generated\n# fake server build\n");
  writeExecutable(join(fakeBin, "haxe"), [
    "#!/usr/bin/env ruby",
    `File.open(ENV.fetch("HXRUBY_TASK_LOG"), "a") { |file| file.puts("haxe #{ARGV.join(' ')}") }`,
    `Dir.mkdir("generated") unless Dir.exist?("generated")`,
    `File.write("generated/ok.rb", "class GeneratedOk; end\\n")`,
  ]);
  writeFileSync(join(appRoot, "Rakefile"), 'require "hxruby/tasks"\n');

  run(activeRuby, [activeRake, "hxruby:check"], {
    cwd: appRoot,
    env: {
      ...process.env,
      HXRUBY_TASK_LOG: logPath,
      RUBYLIB: [join(unpackedRoot, "lib"), process.env.RUBYLIB].filter(Boolean).join(delimiter),
      PATH: [fakeBin, process.env.PATH].filter(Boolean).join(delimiter),
    },
  });

  const actual = readFileSync(logPath, "utf8");
  if (actual !== "haxe build.hxml\n") {
    fail(`hxruby:check task compile order mismatch:\n${actual}`);
  }
}

function smokeCleanTask(unpackedRoot) {
  const appRoot = join(tempRoot, "clean-smoke-app");
  mkdirSync(join(appRoot, ".railshx"), { recursive: true });
  mkdirSync(join(appRoot, "generated"), { recursive: true });
  const ownedPath = join(appRoot, "generated", "owned.rb");
  writeFileSync(ownedPath, "class Owned; end\n");
  writeFileSync(join(appRoot, "generated", "rails_owned.rb"), "class RailsOwned; end\n");
  writeFileSync(join(appRoot, ".railshx", "manifest.json"), JSON.stringify({
    version: 1,
    outputs: [
      {
        output: "generated/owned.rb",
        kind: "ruby",
        source: "test",
        sha256: sha256File(ownedPath),
      },
    ],
  }, null, 2) + "\n");
  writeFileSync(join(appRoot, "Rakefile"), 'require "hxruby/tasks"\n');

  run(activeRuby, [activeRake, "hxruby:clean"], {
    cwd: appRoot,
    env: {
      ...process.env,
      RUBYLIB: [join(unpackedRoot, "lib"), process.env.RUBYLIB].filter(Boolean).join(delimiter),
    },
  });

  if (existsSync(join(appRoot, "generated", "owned.rb"))) {
    fail("hxruby:clean did not remove manifest-owned output");
  }
  if (!existsSync(join(appRoot, "generated", "rails_owned.rb"))) {
    fail("hxruby:clean removed a non-manifest-owned file");
  }
}

function smokeProductionTask(unpackedRoot) {
  const appRoot = join(tempRoot, "production-smoke-app");
  const fakeBin = join(appRoot, "fake-bin");
  const railsBin = join(appRoot, "bin");
  const logPath = join(appRoot, "task.log");
  mkdirSync(fakeBin, { recursive: true });
  mkdirSync(railsBin, { recursive: true });
  writeFileSync(join(appRoot, "build.hxml"), "# fake server build\n");
  writeFileSync(join(appRoot, "build-client.hxml"), "# fake client build\n");
  writeExecutable(join(fakeBin, "haxe"), [
    "#!/usr/bin/env ruby",
    `File.open(ENV.fetch("HXRUBY_TASK_LOG"), "a") { |file| file.puts("haxe #{ARGV.join(' ')}") }`,
  ]);
  writeExecutable(join(railsBin, "rails"), [
    "#!/usr/bin/env ruby",
    `File.open(ENV.fetch("HXRUBY_TASK_LOG"), "a") { |file| file.puts("rails #{ENV.fetch('RAILS_ENV', '')} #{ENV.fetch('SECRET_KEY_BASE_DUMMY', '')} #{ARGV.join(' ')}") }`,
  ]);
  writeFileSync(join(appRoot, "Rakefile"), 'require "hxruby/tasks"\n');

  run(activeRuby, [activeRake, "hxruby:production"], {
    cwd: appRoot,
    env: {
      ...process.env,
      HXRUBY_TASK_LOG: logPath,
      RUBYLIB: [join(unpackedRoot, "lib"), process.env.RUBYLIB].filter(Boolean).join(delimiter),
      PATH: [fakeBin, process.env.PATH].filter(Boolean).join(delimiter),
    },
  });

  const expected = [
    "haxe build.hxml",
    "haxe build-client.hxml",
    "rails production 1 zeitwerk:check",
    "rails production 1 assets:precompile",
  ].join("\n") + "\n";
  const actual = readFileSync(logPath, "utf8");
  if (actual !== expected) {
    fail(`hxruby:production task order mismatch:\nexpected:\n${expected}\nactual:\n${actual}`);
  }
}

function writeExecutable(path, lines) {
  writeFileSync(path, `${lines.join("\n")}\n`);
  chmodSync(path, 0o755);
}
