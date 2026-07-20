#!/usr/bin/env node

const { copyFileSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } = require("node:fs");
const { join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");
const { sha256File, verifyArtifactManifest } = require("../release/artifact-utils");

const root = resolve(__dirname, "..", "..");
const stagedVersion = "0.2.3";
const stagedTag = `v${stagedVersion}`;
const sourceSha = run("git", ["rev-parse", "HEAD"]).stdout.trim();
// Consumer fixtures live outside the repo's .ruby-version ancestry, so retain
// the selected interpreter instead of letting an rbenv shim choose system Ruby.
const activeRuby = run("ruby", ["-rrbconfig", "-e", "print RbConfig.ruby"]).stdout.trim();
const archiveName = "reflaxe.ruby-release.zip";
const archivePath = join(root, "dist", archiveName);
const sidecarPath = `${archivePath}.sha256.json`;

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

const trackedDiffBefore = `${run("git", ["diff", "--binary"]).stdout}${run("git", ["diff", "--cached", "--binary"]).stdout}`;

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

run("node", ["scripts/release/build-haxelib-package.js", stagedVersion, stagedTag, sourceSha]);

const sidecar = JSON.parse(readFileSync(sidecarPath, "utf8"));
if (
  sidecar.localFilename !== archiveName ||
  sidecar.hostedFilename !== `reflaxe.ruby-${stagedVersion}.zip` ||
  sidecar.bytes !== statSync(archivePath).size ||
  sidecar.sha256 !== sha256File(archivePath) ||
  sidecar.version !== stagedVersion ||
  sidecar.gitTag !== stagedTag ||
  sidecar.sourceSha !== sourceSha
) {
  fail("Haxelib artifact SHA-256 sidecar does not match the exact built ZIP and release identity");
}

const entries = run("unzip", ["-Z1", archivePath]).stdout.trim().split("\n").filter(Boolean);
const entrySet = new Set(entries);
const packagedHaxelib = JSON.parse(run("unzip", ["-p", archivePath, "haxelib.json"]).stdout);
const packagedProvenance = JSON.parse(run("unzip", ["-p", archivePath, "release-provenance.json"]).stdout);
if (packagedHaxelib.version !== stagedVersion || packagedProvenance.version !== stagedVersion || packagedProvenance.gitTag !== stagedTag || packagedProvenance.sourceSha !== sourceSha) {
  fail("packaged release identity does not match staged version/tag/source SHA");
}
if (!run("unzip", ["-p", archivePath, "lib/hxruby/version.rb"]).stdout.includes(`VERSION = "${stagedVersion}"`)) {
  fail("packaged HXRuby::VERSION does not match staged version");
}
if (Object.prototype.hasOwnProperty.call(packagedHaxelib, "reflaxe")) {
  fail("packaged haxelib.json must be sanitized by Reflaxe build and omit the reflaxe metadata field");
}
if (packagedHaxelib.classPath !== "src") {
  fail(`packaged haxelib.json classPath must remain src, got ${JSON.stringify(packagedHaxelib.classPath)}`);
}

for (const required of [
  "haxelib.json",
  "artifact-manifest.json",
  "release-provenance.json",
  "hxruby.gemspec",
  "extraParams.hxml",
  "docs/compiler-metadata.md",
  "docs/public-contract.md",
  "docs/ruby-ast-and-semantic-lowering.md",
  "docs/ruby-ast-lowering-inventory.json",
  "docs/railshx-development-loop.md",
  "docs/ruby-callable-abi.md",
  "docs/temporal-apis.md",
  "lib/hxruby.rb",
  "lib/hxruby/support_matrix.json",
  "lib/hxruby/support_matrix.rb",
  "lib/hxruby/development_watcher.rb",
  "lib/hxruby/stdlib_coverage.json",
  "lib/hxruby/rbs.rb",
  "lib/hxruby/rbs/source_parser.rb",
  "lib/hxruby/rbs/haxe_extern_renderer.rb",
  "lib/hxruby/rbs/extern_generator.rb",
  "lib/hxruby/rbs/cli.rb",
  "lib/hxruby/version.rb",
  "src/reflaxe/ruby/RubyCompiler.hx",
  "src/reflaxe/ruby/CompilerBootstrap.hx",
  "src/reflaxe/ruby/ast/RubyAST.hx",
  "src/reflaxe/ruby/ast/RubyASTPrinter.hx",
  "src/reflaxe/ruby/ast/RubyASTValidator.hx",
  "src/reflaxe/ruby/ast/RubyRuntimePlan.hx",
  "src/reflaxe/ruby/compiler/RubyCallablePlan.hx",
  "src/reflaxe/ruby/rails/RailsCallArgumentPlan.hx",
  "src/reflaxe/ruby/macros/RailsInlineMarkup.hx",
  "src/reflaxe/ruby/macros/RubyExtensionMacro.hx",
  "src/Std.cross.hx",
  "src/ruby/CSV.hx",
  "src/ruby/CSVGenerateOptions.hx",
  "src/ruby/CSVParseOptions.hx",
  "src/ruby/CSVRow.hx",
  "src/ruby/Date.hx",
  "src/ruby/Dir.hx",
  "src/ruby/FileUtils.hx",
  "src/ruby/MatchData.hx",
  "src/ruby/MatchOffset.hx",
  "src/ruby/Open3.hx",
  "src/ruby/Open3Capture.hx",
  "src/ruby/Open3Executable.hx",
  "src/ruby/Open3Status.hx",
  "src/ruby/Regexp.hx",
  "src/ruby/RegexpCompileOptions.hx",
  "src/ruby/RegexpOptions.hx",
  "src/ruby/Set.hx",
  "src/ruby/Time.hx",
  "src/ruby/TimeParsing.hx",
  "src/ruby/Pathname.hx",
  "src/ruby/Tempfile.hx",
  "src/ruby/URI.hx",
  "src/ruby/URIValue.hx",
  "src/ruby/StandardError.hx",
  "src/ruby/NativeHashData.hx",
  "src/ruby/NativeHashEntry.hx",
  "src/devisehx/Auth.hx",
  "src/devisehx/AuthFilter.hx",
  "src/devisehx/DeviseScope.hx",
  "src/devisehx/RouteResource.hx",
  "src/devisehx/ScopeName.hx",
  "src/devisehx/SignInOptions.hx",
  "src/devisehx/hhx/AuthLinks.hx",
  "src/devisehx/hhx/DeviseErrors.hx",
  "src/devisehx/hhx/DeviseFormFields.hx",
  "src/devisehx/mailer/ConfirmationToken.hx",
  "src/devisehx/mailer/DeviseMailer.hx",
  "src/devisehx/mailer/ResetPasswordToken.hx",
  "src/devisehx/mailer/UnlockToken.hx",
  "src/devisehx/mapping/DeviseMapping.hx",
  "src/devisehx/macros/ContractTools.hx",
  "src/devisehx/macros/DeviseModelMacro.hx",
  "src/devisehx/macros/RubyFragments.hx",
  "src/devisehx/model/DeviseModule.hx",
  "src/devisehx/model/DeviseModuleSpec.hx",
  "src/devisehx/model/DeviseResource.hx",
  "src/devisehx/params/DeviseParams.hx",
  "src/devisehx/params/SanitizerAction.hx",
  "src/devisehx/routes/DeviseRouteGroup.hx",
  "src/devisehx/routes/DeviseRoutes.hx",
  "src/devisehx/test/IntegrationHelpers.hx",
  "src/devisehx/warden/WardenAccess.hx",
  "src/devisehx/warden/WardenProxy.hx",
  "src/rails/ActiveRecord.hx",
  "src/rails/ActiveJob.hx",
  "src/rails/ActionMailer.hx",
  "src/rails/ActionCable.hx",
  "src/rails/ActiveStorage.hx",
  "src/rails/active_storage/Attachable.hx",
  "src/rails/active_storage/Attachables.hx",
  "src/rails/active_storage/Blob.hx",
  "src/rails/active_storage/Filename.hx",
  "src/rails/active_job/Base.hx",
  "src/rails/active_job/DeserializationError.hx",
  "src/rails/active_job/LifecycleDecl.hx",
  "src/rails/action_cable/Action.hx",
  "src/rails/action_cable/Channel.hx",
  "src/rails/action_cable/ChannelRef.hx",
  "src/rails/action_cable/Connection.hx",
  "src/rails/action_cable/ConnectionDecl.hx",
  "src/rails/action_cable/ConnectionIdentifier.hx",
  "src/rails/action_cable/ConnectionParam.hx",
  "src/rails/action_cable/Consumer.hx",
  "src/rails/action_cable/Stream.hx",
  "src/rails/action_cable/Subscription.hx",
  "src/rails/action_cable/SubscriptionCallbacks.hx",
  "src/rails/action_cable/SubscriptionParam.hx",
  "src/rails/active_support/EventName.hx",
  "src/rails/active_support/NotificationEvent.hx",
  "src/rails/active_support/Notifications.hx",
  "src/rails/active_support/RailsTime.hx",
  "src/rails/active_support/Subscription.hx",
  "src/rails/active_support/TimeWithZone.hx",
  "src/rails/active_support/TimeZone.hx",
  "src/rails/action_mailer/AttachmentValue.hx",
  "src/rails/action_mailer/Attachments.hx",
  "src/rails/action_mailer/Base.hx",
  "src/rails/action_mailer/MailAddress.hx",
  "src/rails/action_mailer/MailFormat.hx",
  "src/rails/action_mailer/MailLayout.hx",
  "src/rails/action_mailer/MailParam.hx",
  "src/rails/action_mailer/MailOptions.hx",
  "src/rails/action_mailer/MailRenderOptions.hx",
  "src/rails/action_mailer/MessageDelivery.hx",
  "src/rails/action_mailer/Preview.hx",
  "src/rails/active_storage/Many.hx",
  "src/rails/active_storage/One.hx",
  "src/rails/active_storage/SignedId.hx",
  "src/rails/action_controller/KeyValueStore.hx",
  "src/rails/action_controller/InvalidAuthenticityToken.hx",
  "src/rails/action_controller/LifecycleDecl.hx",
  "src/rails/action_controller/ParameterMissing.hx",
  "src/rails/action_controller/PermitSpec.hx",
  "src/rails/action_controller/RedirectOptions.hx",
  "src/rails/action_controller/RenderOptions.hx",
  "src/rails/action_controller/Responder.hx",
  "src/rails/action_controller/RequestFormat.hx",
  "src/rails/action_controller/Request.hx",
  "src/rails/action_controller/Response.hx",
  "src/rails/action_controller/Status.hx",
  "src/rails/active_record/RecordNotFound.hx",
  "src/rails/action_view/H.hx",
  "src/rails/action_view/Component.hx",
  "src/rails/action_view/HtmlAttr.hx",
  "src/rails/action_view/HtmlNode.hx",
  "src/rails/action_view/Layout.hx",
  "src/rails/action_view/Slot.hx",
  "src/rails/action_view/Template.hx",
  "src/rails/migration/Migration.hx",
  "src/rails/migration/MigrationOperation.hx",
  "src/rails/routing/RouteParam.hx",
  "src/rails/turbo/StreamTarget.hx",
  "src/rails/turbo/StreamName.hx",
  "src/rails/turbo/Turbo.hx",
  "src/rails/turbo/TurboStreams.hx",
  "src/rails/turbo/TurboEvent.hx",
  "src/rails/turbo/TurboVisitAction.hx",
  "src/rails/turbo/TurboVisitOptions.hx",
  "src/rails/turbo/TurboSubmitEvent.hx",
  "src/rails/turbo/TurboStreamAction.hx",
  "src/rails/macros/JobDsl.hx",
  "src/rails/macros/JobMacro.hx",
  "src/rails/macros/CableConnectionDsl.hx",
  "src/rails/macros/ChannelMacro.hx",
  "src/rails/macros/ConnectionMacro.hx",
  "src/rails/macros/ControllerDsl.hx",
  "src/rails/macros/MailerMacro.hx",
  "src/rails/macros/ViewMacro.hx",
  "runtime/hxruby/core.rb",
  "vendor/reflaxe/PATCHES.md",
  "vendor/reflaxe/Run.hx",
  "vendor/reflaxe/src/reflaxe/ReflectCompiler.hx",
  "vendor/reflaxe/src/reflaxe/helpers/ClassFieldHelper.hx",
  "vendor/genes/src/genes/Generator.hx",
  "vendor/genes/haxelib.json",
]) {
  if (!entrySet.has(required)) {
    fail(`archive missing required entry: ${required}`);
  }
}

for (const forbiddenPrefix of [".git/", ".beads/", ".github/", "node_modules/", "test/", "scripts/", "std/", "haxe_libraries/"]) {
  const match = entries.find((entry) => entry === forbiddenPrefix.slice(0, -1) || entry.startsWith(forbiddenPrefix));
  if (match) {
    fail(`archive contains forbidden entry: ${match}`);
  }
}
for (const forbiddenEntry of ["src/ruby/_std/Std.hx", "src/ruby/_std/README.cross.hx", "src/README.cross.hx"]) {
  if (entrySet.has(forbiddenEntry)) {
    fail(`archive contains source-checkout-only _std entry: ${forbiddenEntry}`);
  }
}

const tempRoot = mkdtempSync(join(tmpdir(), "reflaxe-ruby-package."));
try {
  run("unzip", ["-q", archivePath, "-d", tempRoot]);
  verifyArtifactManifest(tempRoot, "reflaxe.ruby-haxelib");
  const rbsFixtureRoot = join(tempRoot, "rbs-fixture");
  mkdirSync(rbsFixtureRoot, { recursive: true });
  writeFileSync(join(rbsFixtureRoot, "catalog.rbs"), "class PackagedCatalog\n  def label: (String value) -> String\nend\n");
  const packagedRbsCheck = [
    "require 'hxruby/rbs'",
    "output = HXRuby::Rbs::ExternGenerator.new(root: ARGV.fetch(0), input: 'catalog.rbs', constant_name: 'PackagedCatalog', package_name: 'packaged.rbs').render",
    "abort 'packaged RBS generator mismatch' unless output.include?('extern class PackagedCatalog') && output.include?('public function label(value:String):String;')",
  ].join("; ");
  run(activeRuby, ["-I", join(tempRoot, "lib"), "-e", packagedRbsCheck, rbsFixtureRoot]);
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

  const consumerRoot = join(tempRoot, "consumer");
  const consumerSrc = join(consumerRoot, "src");
  const consumerOutputDir = join(consumerRoot, "out");
  const railsTemporalOutputDir = join(consumerRoot, "rails-temporal-out");
  mkdirSync(consumerSrc, { recursive: true });
  for (const file of ["Main.hx", "ReportCli.hx", "TextAnalyzer.hx", "TextReport.hx", "TextReportJson.hx"]) {
    copyFileSync(join(root, "examples", "rubyhx_cli", file), join(consumerSrc, file));
  }
  copyFileSync(
    join(root, "test", "csv_facade", "package_consumer", "CsvPackageContract.hx"),
    join(consumerSrc, "CsvPackageContract.hx"),
  );
  copyFileSync(
    join(root, "test", "open3_facade", "package_consumer", "Open3PackageContract.hx"),
    join(consumerSrc, "Open3PackageContract.hx"),
  );
  copyFileSync(
    join(root, "test", "set_facade", "package_consumer", "SetPackageContract.hx"),
    join(consumerSrc, "SetPackageContract.hx"),
  );
  copyFileSync(
    join(root, "test", "regexp_facade", "package_consumer", "RegexpPackageContract.hx"),
    join(consumerSrc, "RegexpPackageContract.hx"),
  );
  copyFileSync(
    join(root, "test", "time_date_facade", "package_consumer", "TimeDatePackageContract.hx"),
    join(consumerSrc, "TimeDatePackageContract.hx"),
  );
  copyFileSync(
    join(root, "test", "active_support_facades", "package_consumer", "RailsTimePackageContract.hx"),
    join(consumerSrc, "RailsTimePackageContract.hx"),
  );
  writeFileSync(
    join(consumerSrc, "Main.hx"),
    [
      "class Main {",
      "\tstatic function main():Void {",
      "\t\tCsvPackageContract.verify();",
      "\t\tOpen3PackageContract.verify();",
      "\t\tSetPackageContract.verify();",
      "\t\tRegexpPackageContract.verify();",
      "\t\tTimeDatePackageContract.verify();",
      "\t\tReportCli.execute(Sys.args());",
      "\t}",
      "}",
      "",
    ].join("\n"),
  );
  copyFileSync(join(root, "test", "fixtures", "rubyhx_cli", "sample.txt"), join(consumerRoot, "sample.txt"));

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

  run("haxe", [
    "-D",
    `ruby_output=${railsTemporalOutputDir}`,
    "-D",
    "reflaxe_runtime",
    "-cp",
    "src",
    "-lib",
    "reflaxe.ruby",
    "-main",
    "RailsTimePackageContract",
  ], { cwd: consumerRoot });
  assertNoTodoLowerRubyFiles(railsTemporalOutputDir);
  const packagedRailsTemporalRuby = readFileSync(join(railsTemporalOutputDir, "rails_time_package_contract.rb"), "utf8");
  for (const expected of [
    'require "active_support"',
    'require "active_support/time"',
    'Time.find_zone!("UTC")',
    'zone.iso8601("2026-07-17T12:30:00Z")',
  ]) {
    if (!packagedRailsTemporalRuby.includes(expected)) {
      fail(`installed Haxelib Rails temporal contract is missing direct output: ${expected}`);
    }
  }

  const installedStdout = run(activeRuby, [join(consumerOutputDir, "run.rb"), "sample.txt"], { cwd: consumerRoot }).stdout;
  const installedReport = JSON.parse(installedStdout);
  const expectedReport = { path: "sample.txt", lines: 2, words: 3, characters: 16 };
  if (JSON.stringify(installedReport) !== JSON.stringify(expectedReport)) {
    fail(`installed haxelib CLI mismatch: expected ${JSON.stringify(expectedReport)}, got ${JSON.stringify(installedReport)}`);
  }
} finally {
  rmSync(tempRoot, { force: true, recursive: true });
}

const trackedDiffAfter = `${run("git", ["diff", "--binary"]).stdout}${run("git", ["diff", "--cached", "--binary"]).stdout}`;
if (trackedDiffAfter !== trackedDiffBefore) fail("Haxelib staging changed tracked checkout files");

console.log(`[haxelib-package] OK: ${archiveName} (${entries.length} files)`);
