#!/usr/bin/env node

const { existsSync, readFileSync } = require("node:fs");

function fail(message) {
  console.error(`[release-contracts] ERROR: ${message}`);
  process.exitCode = 1;
}

function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

function expectIncludes(haystack, needle, label) {
  if (!haystack.includes(needle)) {
    fail(`${label} missing ${needle}`);
  }
}

function expectExcludes(haystack, needle, label) {
  if (haystack.includes(needle)) {
    fail(`${label} must not include ${needle}`);
  }
}

const packageJson = readJson("package.json");
const haxelibJson = readJson("haxelib.json");
const haxerc = readJson(".haxerc");
const ciWorkflow = readFileSync(".github/workflows/ci.yml", "utf8");
const releaseWorkflow = readFileSync(".github/workflows/release.yml", "utf8");
const readme = readFileSync("README.md", "utf8");
const haxelibPackageBuilder = readFileSync("scripts/release/build-haxelib-package.js", "utf8");
const haxelibPackageCheck = readFileSync("scripts/ci/haxelib-package-check.js", "utf8");
const versionSyncCheck = readFileSync("scripts/ci/version-sync-check.js", "utf8");
const gemPackageBuilder = readFileSync("scripts/release/build-gem-package.js", "utf8");
const gemPackageCheck = readFileSync("scripts/ci/gem-package-check.js", "utf8");
const hxrubyGemspec = readFileSync("hxruby.gemspec", "utf8");
const hxrubyTasks = readFileSync("lib/hxruby/tasks.rb", "utf8");
const railsAppGenerator = readFileSync("lib/hxruby/generators/app.rb", "utf8");
const rubyHxml = readFileSync("haxe_libraries/reflaxe.ruby.hxml", "utf8");

if (packageJson.name !== "reflaxe-ruby") {
  fail(`package.json name must be reflaxe-ruby, got ${packageJson.name}`);
}
if (haxelibJson.name !== "reflaxe.ruby") {
  fail(`haxelib.json name must be reflaxe.ruby, got ${haxelibJson.name}`);
}
if (haxelibJson.classPath !== "src") {
  fail(`haxelib.json classPath must be src, got ${haxelibJson.classPath}`);
}
if (!rubyHxml.includes("-cp ${SCOPE_DIR}/std/")) {
  fail("haxe_libraries/reflaxe.ruby.hxml must include std/ classpath");
}
expectExcludes(readme, "pre-1.0", "README release status");
expectIncludes(readme, `current \`${packageJson.version}\` baseline`, "README release status");

const releaseConfig = packageJson.release;
if (!releaseConfig || !Array.isArray(releaseConfig.plugins)) {
  fail("package.json release.plugins must be configured");
} else {
  for (const plugin of [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/exec",
    "@semantic-release/git",
    "@semantic-release/github",
  ]) {
    if (!releaseConfig.plugins.some((entry) => Array.isArray(entry) ? entry[0] === plugin : entry === plugin)) {
      fail(`semantic-release plugin missing: ${plugin}`);
    }
  }

  const execPlugin = releaseConfig.plugins.find((entry) => Array.isArray(entry) && entry[0] === "@semantic-release/exec");
  const prepareCmd = execPlugin?.[1]?.prepareCmd ?? "";
  expectIncludes(prepareCmd, "sync-versions.js ${nextRelease.version}", "@semantic-release/exec prepareCmd");
  expectIncludes(prepareCmd, "build-haxelib-package.js", "@semantic-release/exec prepareCmd");
  expectIncludes(prepareCmd, "build-gem-package.js", "@semantic-release/exec prepareCmd");
  expectIncludes(readFileSync("scripts/release/sync-versions.js", "utf8"), "updateReadmeCurrentVersion", "sync-versions script");

  const gitPlugin = releaseConfig.plugins.find((entry) => Array.isArray(entry) && entry[0] === "@semantic-release/git");
  const assets = gitPlugin?.[1]?.assets ?? [];
  const releaseMessage = gitPlugin?.[1]?.message ?? "";
  if (releaseMessage.includes("\\n")) {
    fail("@semantic-release/git message must use newline escapes, not literal backslash-n text");
  }
  if (!releaseMessage.includes("\n\n")) {
    fail("@semantic-release/git message must separate subject and notes with a blank line");
  }
  for (const asset of assets) {
    if (!existsSync(asset)) {
      fail(`release asset does not exist: ${asset}`);
    }
  }
  for (const requiredAsset of ["package.json", "haxelib.json", "hxruby.gemspec", "haxe_libraries/reflaxe.ruby.hxml", "lib/hxruby/version.rb", "README.md", "CHANGELOG.md"]) {
    if (!assets.includes(requiredAsset)) {
      fail(`release git assets missing required file: ${requiredAsset}`);
    }
  }

  const githubPlugin = releaseConfig.plugins.find((entry) => Array.isArray(entry) && entry[0] === "@semantic-release/github");
  const githubAssets = githubPlugin?.[1]?.assets ?? [];
  if (!githubAssets.some((asset) => asset?.path === "dist/reflaxe.ruby-*.zip")) {
    fail("@semantic-release/github assets must include the Haxelib package zip");
  }
  if (!githubAssets.some((asset) => asset?.path === "dist/hxruby-*.gem")) {
    fail("@semantic-release/github assets must include the hxruby gem");
  }
  if (!githubAssets.some((asset) => asset?.label?.includes("${nextRelease.version}"))) {
    fail("@semantic-release/github asset label must include the release version");
  }
}

expectIncludes(ciWorkflow, `HAXE_VERSION: "${haxerc.version}"`, "CI workflow");
expectIncludes(ciWorkflow, "ruby-version:", "CI workflow");
for (const rubyVersion of ['"3.2"', '"3.3"', '"4.0"']) {
  expectIncludes(ciWorkflow, rubyVersion, "CI Ruby matrix");
}
expectIncludes(ciWorkflow, "npx lix download haxe", "CI Haxe setup");
expectIncludes(ciWorkflow, "npm test", "CI test step");
expectIncludes(ciWorkflow, "RailsHx browser sentinel", "CI workflow");
expectIncludes(ciWorkflow, "npx playwright install --with-deps chromium", "CI workflow");
expectIncludes(ciWorkflow, "npm run test:todoapp-playwright", "CI workflow");
expectIncludes(ciWorkflow, "RailsHx runtime integration", "CI workflow");
expectIncludes(ciWorkflow, "RailsHx runtime integration / Ruby ${{ matrix.ruby_version }}", "CI workflow");
expectIncludes(ciWorkflow, "npm run test:rails-runtime", "CI workflow");
expectIncludes(ciWorkflow, "ruby-version: ${{ matrix.ruby_version }}", "CI workflow");
expectIncludes(ciWorkflow, "RailsHx production dogfood", "CI workflow");
expectIncludes(ciWorkflow, "npm run test:todoapp-production", "CI workflow");
expectIncludes(ciWorkflow, "actions/checkout@v6", "CI workflow");
expectIncludes(ciWorkflow, "actions/setup-node@v6", "CI workflow");
expectExcludes(ciWorkflow, "FORCE_JAVASCRIPT_ACTIONS_TO_NODE24", "CI workflow");
expectIncludes(packageJson.scripts.test, "test:haxelib-package", "npm test");
expectIncludes(packageJson.scripts.test, "test:gem-package", "npm test");
expectIncludes(packageJson.scripts["test:todoapp-playwright"] ?? "", "todoapp-playwright.js", "package.json scripts");
expectIncludes(packageJson.scripts["test:todoapp-production"] ?? "", "production-smoke", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1 npm run test:active-job", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1 npm run test:rails-integration", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1 npm run test:rails-interop", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "test:active-job", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "test:rails-integration", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "test:rails-interop", "package.json scripts");
expectIncludes(packageJson.scripts["test:haxelib-package"] ?? "", "haxelib-package-check.js", "package.json scripts");
expectIncludes(packageJson.scripts["test:gem-package"] ?? "", "gem-package-check.js", "package.json scripts");
expectIncludes(packageJson.scripts["release:haxelib-package"] ?? "", "build-haxelib-package.js", "package.json scripts");
expectIncludes(packageJson.scripts["release:gem-package"] ?? "", "build-gem-package.js", "package.json scripts");
expectIncludes(versionSyncCheck, "README current baseline", "version sync check");
expectIncludes(haxelibPackageBuilder, `"zip", ["-X", "-q", "-@", outPath]`, "Haxelib package builder");
expectIncludes(haxelibPackageBuilder, `"lib/"`, "Haxelib package builder");
expectIncludes(haxelibPackageBuilder, `"hxruby.gemspec"`, "Haxelib package builder");
expectIncludes(haxelibPackageCheck, "haxelib\", [\"newrepo\"]", "Haxelib package check");
expectIncludes(haxelibPackageCheck, "\"-lib\"", "Haxelib package check");
expectIncludes(haxelibPackageCheck, "Hello from installed reflaxe.ruby", "Haxelib package check");
expectIncludes(haxelibPackageCheck, "TODO: lower", "Haxelib package check");
expectIncludes(gemPackageBuilder, "gem", "Ruby gem package builder");
expectIncludes(gemPackageCheck, "installed gem missing tasks", "Ruby gem package check");
expectIncludes(gemPackageCheck, "rubyDefaultGemPath", "Ruby gem package check");
expectIncludes(gemPackageCheck, "hxruby:production", "Ruby gem package check");
expectIncludes(hxrubyGemspec, 'spec.name = "hxruby"', "hxruby.gemspec");
expectIncludes(hxrubyGemspec, 'spec.required_ruby_version = ">= 3.2"', "hxruby.gemspec");
expectExcludes(hxrubyGemspec, "add_runtime_dependency", "hxruby.gemspec");
expectIncludes(hxrubyTasks, 'require "rake"', "hxruby tasks");
expectIncludes(hxrubyTasks, "task :production", "hxruby tasks");
expectIncludes(hxrubyTasks, "assets:precompile", "hxruby tasks");
expectIncludes(railsAppGenerator, "bin/railshx-prod", "RailsHx app generator");
expectIncludes(railsAppGenerator, "hxruby:production", "RailsHx app generator");
expectIncludes(readFileSync("scripts/rails/todoapp.js", "utf8"), "assets:precompile", "todoapp production smoke");
expectIncludes(readFileSync("scripts/rails/todoapp.js", "utf8"), "zeitwerk:check", "todoapp production smoke");
expectIncludes(readFileSync("scripts/rails/todoapp.js", "utf8"), "rails_integration_release.tgz", "todoapp production smoke");
expectIncludes(readme, "npm run release:haxelib-package", "README Haxelib package docs");
expectIncludes(readme, "npm run test:haxelib-package", "README Haxelib package docs");
expectIncludes(readme, "-lib reflaxe.ruby", "README Haxelib package docs");
expectIncludes(readme, "npm run release:gem-package", "README Ruby gem package docs");
expectIncludes(readme, "npm run test:gem-package", "README Ruby gem package docs");
expectIncludes(readme, "dist/reflaxe.ruby-*.zip", "README Haxelib package docs");
expectIncludes(readme, "dist/hxruby-*.gem", "README Ruby gem package docs");
expectIncludes(readme, 'Plain `require "hxruby"` has no gem runtime dependencies.', "README Ruby gem package docs");
expectIncludes(releaseWorkflow, "npx semantic-release", "Release workflow");
expectIncludes(releaseWorkflow, "fetch-depth: 0", "Release workflow");
expectIncludes(releaseWorkflow, "actions/checkout@v6", "Release workflow");
expectIncludes(releaseWorkflow, "actions/setup-node@v6", "Release workflow");
expectIncludes(releaseWorkflow, "ruby/setup-ruby@v1", "Release workflow");
expectIncludes(releaseWorkflow, 'RUBY_VERSION: "3.3"', "Release workflow");
expectExcludes(releaseWorkflow, "FORCE_JAVASCRIPT_ACTIONS_TO_NODE24", "Release workflow");

if (process.exitCode) {
  process.exit(process.exitCode);
}

console.log("[release-contracts] OK");
