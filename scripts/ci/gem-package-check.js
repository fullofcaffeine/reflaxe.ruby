#!/usr/bin/env node

const { chmodSync, existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } = require("node:fs");
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
  if (result.status !== 0 && !options.allowFailure) {
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
    "vendor/genes/src/genes/Generator.hx",
    "vendor/genes/haxelib.json",
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
    "expected = %w[hxruby:compile hxruby:compile:client hxruby:db:migrate hxruby:db:prepare hxruby:db:rollback hxruby:rails hxruby:start hxruby:start:watch hxruby:test hxruby:routes hxruby:doctor hxruby:check hxruby:clean hxruby:production hxruby:watch hxruby:watch:client hxruby:gen:adopt hxruby:gen:app hxruby:gen:model hxruby:gen:routes]",
    "names = Rake::Task.tasks.map(&:name)",
    "missing = expected - names",
    "abort \"missing tasks: #{missing.join(', ')}\" unless missing.empty?",
  ].join("; ");
  run("ruby", ["-I", join(unpackedRoot, "lib"), "-e", tasksCheck]);
  smokeDoctorTask(unpackedRoot);
  smokeDoctorFailureTask(unpackedRoot);
  smokeCheckTask(unpackedRoot);
  smokeCleanTask(unpackedRoot);
  smokeProductionTask(unpackedRoot);

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
      "expected = %w[hxruby:compile hxruby:compile:client hxruby:db:migrate hxruby:db:prepare hxruby:db:rollback hxruby:rails hxruby:start hxruby:start:watch hxruby:test hxruby:routes hxruby:doctor hxruby:check hxruby:clean hxruby:production hxruby:watch hxruby:watch:client hxruby:gen:adopt hxruby:gen:app hxruby:gen:model hxruby:gen:routes]",
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

function smokeDoctorTask(unpackedRoot) {
  const appRoot = join(tempRoot, "doctor-smoke-app");
  const fakeBin = join(appRoot, "fake-bin");
  mkdirSync(fakeBin, { recursive: true });
  mkdirSync(join(appRoot, ".railshx"), { recursive: true });
  mkdirSync(join(appRoot, "generated"), { recursive: true });
  writeFileSync(join(appRoot, "build.hxml"), "-D ruby_output=generated\n# fake server build\n");
  writeFileSync(join(appRoot, "build-client.hxml"), "# fake client build\n");
  writeFileSync(join(appRoot, ".railshx", "manifest.json"), '{"version":1,"outputs":[]}\n');
  writeExecutable(join(fakeBin, "haxe"), [
    "#!/usr/bin/env ruby",
    "exit 0",
  ]);
  writeFileSync(join(appRoot, "Rakefile"), 'require "hxruby/tasks"\n');

  run("rake", ["hxruby:doctor"], {
    cwd: appRoot,
    env: {
      ...process.env,
      RUBYLIB: [join(unpackedRoot, "lib"), process.env.RUBYLIB].filter(Boolean).join(delimiter),
      PATH: [fakeBin, process.env.PATH].filter(Boolean).join(delimiter),
    },
  });
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
    "exit 0",
  ]);
  writeFileSync(join(appRoot, "Rakefile"), 'require "hxruby/tasks"\n');

  const result = run("rake", ["hxruby:doctor"], {
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

  run("rake", ["hxruby:check"], {
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
  writeFileSync(join(appRoot, "generated", "owned.rb"), "class Owned; end\n");
  writeFileSync(join(appRoot, "generated", "rails_owned.rb"), "class RailsOwned; end\n");
  writeFileSync(join(appRoot, ".railshx", "manifest.json"), JSON.stringify({
    version: 1,
    outputs: [
      {
        output: "generated/owned.rb",
        kind: "ruby",
        source: "test",
        sha256: "ignored-by-clean",
      },
    ],
  }, null, 2) + "\n");
  writeFileSync(join(appRoot, "Rakefile"), 'require "hxruby/tasks"\n');

  run("rake", ["hxruby:clean"], {
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

  run("rake", ["hxruby:production"], {
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
