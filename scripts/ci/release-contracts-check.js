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
const agentsGuide = readFileSync("AGENTS.md", "utf8");
const readme = readFileSync("README.md", "utf8");
const changelog = readFileSync("CHANGELOG.md", "utf8");
const rootRakefile = readFileSync("Rakefile", "utf8");
const haxelibPackageBuilder = readFileSync("scripts/release/build-haxelib-package.js", "utf8");
const haxelibPackageCheck = readFileSync("scripts/ci/haxelib-package-check.js", "utf8");
const versionSyncCheck = readFileSync("scripts/ci/version-sync-check.js", "utf8");
const releaseVersionPolicy = readFileSync("scripts/release/analyze-commits.mjs", "utf8");
const releaseTransition = readFileSync("scripts/release/prepare-semver-transition.mjs", "utf8");
const releaseVersionPolicyCheck = readFileSync("scripts/ci/release-version-policy-check.mjs", "utf8");
const releaseVersionPolicyDocs = readFileSync("docs/release-version-policy.md", "utf8");
const releaseArtifactDocs = readFileSync("docs/release-artifacts.md", "utf8");
const releaseWorkflowDocs = readFileSync("docs/release-publication-workflow.md", "utf8");
const releaseHostingDocs = readFileSync("docs/release-hosting-and-repair.md", "utf8");
const releaseEvidenceDocs = readFileSync("docs/release-live-evidence.md", "utf8");
const artifactUtils = readFileSync("scripts/release/artifact-utils.js", "utf8");
const deterministicZip = readFileSync("scripts/release/deterministic-zip.js", "utf8");
const artifactReproducibilityCheck = readFileSync("scripts/ci/release-artifact-reproducibility-check.js", "utf8");
const releaseArtifactPrepare = readFileSync("scripts/release/prepare-release-artifacts.js", "utf8");
const releaseHosting = readFileSync("scripts/release/release-hosting.mjs", "utf8");
const releaseHostingCheck = readFileSync("scripts/ci/release-hosting-check.mjs", "utf8");
const releaseRepairWorkflow = readFileSync(".github/workflows/release-repair.yml", "utf8");
const gemPackageBuilder = readFileSync("scripts/release/build-gem-package.js", "utf8");
const gemPackageCheck = readFileSync("scripts/ci/gem-package-check.js", "utf8");
const haxelibPackageCheckText = readFileSync("scripts/ci/haxelib-package-check.js", "utf8");
const reflaxeLazyFunctionFieldCheck = readFileSync("scripts/ci/reflaxe-lazy-function-field-check.js", "utf8");
const reflaxePatchDocs = readFileSync("vendor/reflaxe/PATCHES.md", "utf8");
const reflaxeClassFieldHelper = readFileSync("vendor/reflaxe/src/reflaxe/helpers/ClassFieldHelper.hx", "utf8");
const hxrubyGemspec = readFileSync("hxruby.gemspec", "utf8");
const hxrubyTasks = readFileSync("lib/hxruby/tasks.rb", "utf8");
const hxrubyAdoptGenerator = readFileSync("lib/hxruby/generators/adopt.rb", "utf8");
const railsAppGenerator = readFileSync("lib/hxruby/generators/app.rb", "utf8");
const rubyHxml = readFileSync("haxe_libraries/reflaxe.ruby.hxml", "utf8");
const clientHxml = readFileSync("haxe_libraries/railshx.client.hxml", "utf8");
const devisehxReleaseLane = readFileSync("docs/railshx-devisehx-release-lane.md", "utf8");
const gemLayersGuide = readFileSync("docs/railshx-gem-layers.md", "utf8");
const devisehxDesign = readFileSync("docs/railshx-devisehx-design.md", "utf8");
const escapeHatchAudit = readFileSync("docs/railshx-escape-hatch-security-audit.md", "utf8");

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
if (!rubyHxml.includes("-cp ${SCOPE_DIR}/std/ruby/_std/")) {
  fail("haxe_libraries/reflaxe.ruby.hxml must include source-layout _std overrides");
}
if (!clientHxml.includes("-cp ${SCOPE_DIR}/std/")) {
  fail("haxe_libraries/railshx.client.hxml must include std/ classpath");
}
for (const forbidden of ["std/ruby/_std", "CompilerBootstrap", "CompilerInit", "-lib reflaxe"]) {
  if (clientHxml.includes(forbidden)) {
    fail(`haxe_libraries/railshx.client.hxml must not include Ruby target wiring: ${forbidden}`);
  }
}
if ((haxelibJson.reflaxe?.stdPaths ?? []).join("\n") !== "std\nstd/ruby/_std") {
  fail('haxelib.json reflaxe.stdPaths must be ["std", "std/ruby/_std"]');
}
expectExcludes(readme, "pre-1.0", "README release status");
expectIncludes(readme, "Tracked version files intentionally use the `0.0.0` development sentinel", "README release status");

const releaseConfig = packageJson.release;
if (!releaseConfig || !Array.isArray(releaseConfig.plugins)) {
  fail("package.json release.plugins must be configured");
} else {
  for (const plugin of [
    "./scripts/release/analyze-commits.mjs",
    "@semantic-release/exec",
    "@semantic-release/github",
  ]) {
    if (!releaseConfig.plugins.some((entry) => Array.isArray(entry) ? entry[0] === plugin : entry === plugin)) {
      fail(`semantic-release plugin missing: ${plugin}`);
    }
  }

  if ((releaseConfig.branches ?? []).join("\n") !== "main") {
    fail("semantic-release must use normal releases from main only");
  }
  if (releaseConfig.tagFormat !== "v${version}") {
    fail("semantic-release tagFormat must be canonical v${version}");
  }
  const policyPlugin = releaseConfig.plugins.find(
    (entry) => Array.isArray(entry) && entry[0] === "./scripts/release/analyze-commits.mjs"
  );
  if (!policyPlugin || JSON.stringify(policyPlugin[1]?.approvedStableMajors) !== "[]") {
    fail("release policy must keep stable majors unapproved until an explicit reviewed policy change");
  }
  if (policyPlugin?.[1]?.historicalPrereleaseBaseline !== "v0.1.0-beta.2" || policyPlugin?.[1]?.transitionAliasTag !== "v0.0.0") {
    fail("release policy must pin the public beta baseline and reserved local-only transition alias");
  }

  const execPlugin = releaseConfig.plugins.find((entry) => Array.isArray(entry) && entry[0] === "@semantic-release/exec");
  const prepareCmd = execPlugin?.[1]?.prepareCmd ?? "";
  expectIncludes(prepareCmd, "prepare-release-artifacts.js ${nextRelease.version} ${nextRelease.gitTag} ${nextRelease.gitHead}", "@semantic-release/exec prepareCmd");
  expectIncludes(execPlugin?.[1]?.publishCmd ?? "", "release-hosting.mjs finalize ${nextRelease.version} ${nextRelease.gitTag} ${nextRelease.gitHead}", "@semantic-release/exec publishCmd");
  if (releaseConfig.plugins.some((entry) => ["@semantic-release/git", "@semantic-release/changelog"].includes(Array.isArray(entry) ? entry[0] : entry))) {
    fail("release configuration must not create release commits or mutate CHANGELOG.md");
  }

  const githubPlugin = releaseConfig.plugins.find((entry) => Array.isArray(entry) && entry[0] === "@semantic-release/github");
  if (releaseConfig.plugins.indexOf(githubPlugin) > releaseConfig.plugins.indexOf(execPlugin)) {
    fail("GitHub must upload the draft before the exec plugin verifies and publishes it");
  }
  if (githubPlugin?.[1]?.draftRelease !== true) {
    fail("GitHub releases must remain draft until hosted bytes pass verification");
  }
  const githubAssets = githubPlugin?.[1]?.assets ?? [];
  expectIncludes(githubPlugin?.[1]?.releaseBodyTemplate ?? "", "## v${nextRelease.version}", "GitHub release body heading");
  expectIncludes(githubPlugin?.[1]?.releaseBodyTemplate ?? "", "${nextRelease.notes}", "GitHub generated release notes");
  if (!githubAssets.some((asset) => asset?.path === "dist/reflaxe.ruby-release.zip" && asset?.name === "reflaxe.ruby-${nextRelease.version}.zip")) {
    fail("@semantic-release/github assets must include the Haxelib package zip");
  }
  if (!githubAssets.some((asset) => asset?.path === "dist/hxruby-release.gem" && asset?.name === "hxruby-${nextRelease.version}.gem")) {
    fail("@semantic-release/github assets must include the hxruby gem");
  }
  if (!githubAssets.some((asset) => asset?.path === "dist/reflaxe.ruby-release.zip.sha256.json" && asset?.name === "reflaxe.ruby-${nextRelease.version}.zip.sha256.json")) {
    fail("@semantic-release/github assets must include exact Haxelib SHA-256 metadata");
  }
  if (!githubAssets.some((asset) => asset?.path === "dist/hxruby-release.gem.sha256.json" && asset?.name === "hxruby-${nextRelease.version}.gem.sha256.json")) {
    fail("@semantic-release/github assets must include exact gem SHA-256 metadata");
  }
  if (!githubAssets.some((asset) => asset?.label?.includes("${nextRelease.version}"))) {
    fail("@semantic-release/github asset label must include the release version");
  }
  if (githubPlugin?.[1]?.successCommentCondition !== false || githubPlugin?.[1]?.failCommentCondition !== false || githubPlugin?.[1]?.releasedLabels !== false) {
    fail("@semantic-release/github must not require issue or pull-request write permissions");
  }
}

if (packageJson.devDependencies?.semver !== "7.8.4") {
  fail("the release policy must directly pin the standards-tested semver library at 7.8.4");
}
if (packageJson.devDependencies?.fflate !== "0.8.3") {
  fail("deterministic ZIP creation must directly pin fflate at the haxe.rust-aligned 0.8.3 version");
}
expectIncludes(releaseVersionPolicy, 'from "@semantic-release/commit-analyzer"', "release version policy");
expectIncludes(releaseVersionPolicy, 'from "@semantic-release/release-notes-generator"', "release note policy");
expectIncludes(releaseVersionPolicy, 'from "semver"', "release version policy");
expectIncludes(releaseVersionPolicy, "validateTagLineage", "release version policy");
expectIncludes(releaseVersionPolicy, "approvedStableMajors", "release version policy");
expectExcludes(releaseVersionPolicy, 'readFileSync("package.json"', "release version policy");
expectIncludes(releaseTransition, "git push --tags", "release transition safety explanation");
expectIncludes(releaseTransition, "newest merged prerelease", "release transition baseline guard");
expectIncludes(releaseVersionPolicyCheck, 'from "semantic-release"', "release version policy check");
expectIncludes(releaseVersionPolicyCheck, '"99.99.99"', "release version policy package-independence fixture");
expectIncludes(releaseVersionPolicyDocs, "normal `0.x` releases from `main`", "release version policy docs");
expectIncludes(releaseVersionPolicyDocs, "v0.1.0-beta.2", "release version policy transition docs");
expectIncludes(releaseVersionPolicyDocs, "separate SemVer concepts", "release version policy prerelease distinction");
expectIncludes(releaseVersionPolicyDocs, "## v<SemVer>", "release notes format documentation");
expectIncludes(releaseArtifactDocs, "follows the established", "release artifact design rationale");
expectIncludes(releaseArtifactDocs, "artifact-manifest.json", "release artifact content contract docs");
expectIncludes(releaseArtifactDocs, "SHA-256", "release artifact sidecar docs");
expectIncludes(releaseArtifactDocs, "GitHub Releases is currently the sole public distribution host", "release distribution host documentation");
expectIncludes(releaseArtifactDocs, "does not publish it to the Haxelib registry", "Haxelib distribution documentation");
expectIncludes(releaseArtifactDocs, "does not push it to", "RubyGems distribution documentation");
expectIncludes(releaseArtifactDocs, "Digest::SHA256.file", "consumer digest verification documentation");
expectIncludes(releaseHostingDocs, "Completed immutable release", "hosted repair state documentation");
expectIncludes(releaseHostingDocs, "dedicated GitHub App identity", "multi-writer creation identity documentation");
expectIncludes(releaseHostingDocs, "Historical `v0.1.0`", "legacy immutability boundary documentation");
expectIncludes(releaseHostingDocs, "gh workflow run release-repair.yml", "existing-tag repair operator documentation");
expectIncludes(readme, "Hosted Release Identity And Repair", "README hosted release documentation");
expectIncludes(readme, "GitHub Releases is currently the sole distribution host", "README distribution host documentation");
expectIncludes(readme, "Live Release Protocol Evidence", "README live release evidence");
for (const evidence of [
  "56c65adedf0a56b24a32a4161f9235171eac6cbe",
  "29215071466",
  "86712738698",
  "hxruby-0.1.0.gem",
  "281bab21677bb7dd24762baa612430d4a066ce25518b4e5467394009d76ba5da",
  "reflaxe.ruby-0.1.0.zip",
  "cfa2f0c74d727974cc9849758254aabfec6dae3e4efbd1ed226ef6ee003c0de1",
  "a78bb96858e02210388be66c7b3ba4edfa94e813",
  "a45eb02dd1dbaaa8bc8dec0da426613c3c3e0e98",
  "29221904625",
  "29221893930",
  "immutable=true",
]) {
  expectIncludes(releaseEvidenceDocs, evidence, "live release protocol evidence");
}
expectIncludes(releaseEvidenceDocs, "`prerelease=true`", "historical prerelease channel evidence");
expectIncludes(releaseEvidenceDocs, "`prerelease=false`", "normal major-zero channel evidence");
expectIncludes(releaseEvidenceDocs, "`immutable=false`", "historical host immutability evidence");
expectIncludes(releaseEvidenceDocs, "`v0.0.0` alias is absent", "transition alias absence evidence");
expectIncludes(releaseEvidenceDocs, "## No-release continuity proof", "hosted no-release evidence section");
for (const evidence of [
  "e485d098056cc3b1377a8b52928a302963570538",
  "29225406658",
  "86742889294",
  "analyzed exactly one commit",
  "no new version is released",
  "zero drafts",
  "spurious `v0.1.3`",
]) {
  expectIncludes(releaseEvidenceDocs, evidence, "hosted no-release continuity evidence");
}
expectIncludes(releaseWorkflowDocs, "final job", "tested-commit publication docs");
expectIncludes(releaseWorkflowDocs, "contents: write", "publication permission docs");
expectIncludes(releaseWorkflowDocs, "22.14.0", "publication toolchain docs");
expectIncludes(releaseWorkflowDocs, "failed, cancelled, skipped", "publication trigger matrix docs");
expectIncludes(deterministicZip, 'require("fflate")', "deterministic ZIP builder");
expectIncludes(deterministicZip, "FIXED_MTIME", "deterministic ZIP builder");
expectIncludes(deterministicZip, "validateEntryNames", "deterministic ZIP structural validation");
expectExcludes(haxelibPackageBuilder, 'spawnSync("zip"', "Haxelib package builder");
expectIncludes(haxelibPackageBuilder, "createDeterministicZip", "Haxelib package builder");
expectIncludes(haxelibPackageBuilder, "extractGitSource", "Haxelib tested-commit input");
expectIncludes(gemPackageBuilder, "extractGitSource", "gem tested-commit input");
expectIncludes(artifactUtils, "artifact-manifest.json", "artifact full content contract");
expectIncludes(artifactUtils, "sha256", "artifact SHA-256 contract");
expectIncludes(artifactReproducibilityCheck, "DIRTY_WORKTREE_MARKER", "dirty checkout exclusion gate");
expectIncludes(artifactReproducibilityCheck, "UNTRACKED_WORKTREE_MARKER", "untracked checkout exclusion gate");
expectIncludes(artifactReproducibilityCheck, "Pacific/Honolulu", "artifact environment-variation gate");
expectIncludes(artifactReproducibilityCheck, "unsafe executable mode", "artifact mode rejection gate");
expectIncludes(releaseArtifactPrepare, '"hxruby-release.gem.sha256.json"', "fixed release outputs");
expectIncludes(releaseArtifactPrepare, '"reflaxe.ruby-release.zip.sha256.json"', "fixed release outputs");
expectIncludes(versionSyncCheck, "DEVELOPMENT_VERSION", "version sentinel check");
expectExcludes(readme, "dist/reflaxe.ruby-*.zip", "README stale Haxelib glob");
expectExcludes(readme, "dist/hxruby-*.gem", "README stale gem glob");
expectIncludes(agentsGuide, "normal `0.x` releases from `main`", "AGENTS release policy");
expectIncludes(agentsGuide, "approvedStableMajors", "AGENTS stable-major policy");
expectIncludes(agentsGuide, "`0.0.0` development sentinel", "AGENTS staging policy");
expectIncludes(agentsGuide, "upload only fixed exact local artifact paths rather than globs", "AGENTS artifact path policy");
expectExcludes(agentsGuide, "until the package is ready for stable `1.x`", "AGENTS obsolete beta policy");

expectIncludes(ciWorkflow, `HAXE_VERSION: "${haxerc.version}"`, "CI workflow");
expectIncludes(ciWorkflow, "ruby-version:", "CI workflow");
for (const rubyVersion of ['"3.2"', '"3.3"', '"4.0"']) {
  expectIncludes(ciWorkflow, rubyVersion, "CI Ruby matrix");
}
expectIncludes(ciWorkflow, "npx lix download haxe", "CI Haxe setup");
expectIncludes(ciWorkflow, "npm test", "CI test step");
expectIncludes(ciWorkflow, "npm run test:release-version-policy", "CI release policy step");
expectIncludes(ciWorkflow, "RailsHx browser sentinel", "CI workflow");
expectIncludes(ciWorkflow, "./node_modules/.bin/playwright install --with-deps chromium", "CI workflow");
expectIncludes(ciWorkflow, "npm run test:todoapp-playwright", "CI workflow");
expectIncludes(ciWorkflow, "RailsHx runtime integration", "CI workflow");
expectIncludes(ciWorkflow, "RailsHx runtime integration / Ruby ${{ matrix.ruby_version }}", "CI workflow");
expectIncludes(ciWorkflow, "npm run test:rails-runtime", "CI workflow");
expectIncludes(ciWorkflow, "ruby-version: ${{ matrix.ruby_version }}", "CI workflow");
expectIncludes(ciWorkflow, "RailsHx production dogfood", "CI workflow");
expectIncludes(ciWorkflow, "npm run test:todoapp-production", "CI workflow");
expectIncludes(ciWorkflow, "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10", "CI workflow");
expectIncludes(ciWorkflow, "actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e", "CI workflow");
expectExcludes(ciWorkflow, "FORCE_JAVASCRIPT_ACTIONS_TO_NODE24", "CI workflow");
expectIncludes(packageJson.scripts.test, "test:examples-compile", "npm test");
expectIncludes(packageJson.scripts["test:examples-compile"] ?? "", "examples-compile-smoke.js", "package.json scripts");
expectIncludes(packageJson.scripts.test, "test:devisehx-core", "npm test");
expectIncludes(packageJson.scripts.test, "test:devisehx-controller", "npm test");
expectIncludes(packageJson.scripts["test:devisehx-core"] ?? "", "devisehx-core-smoke.js", "package.json scripts");
expectIncludes(packageJson.scripts["test:devisehx-controller"] ?? "", "devisehx-controller-smoke.js", "package.json scripts");
expectIncludes(packageJson.scripts.test, "test:haxelib-package", "npm test");
expectIncludes(packageJson.scripts.test, "test:gem-package", "npm test");
expectIncludes(packageJson.scripts.test, "test:reflaxe-lazy-function-field", "npm test");
expectIncludes(packageJson.scripts["test:reflaxe-lazy-function-field"] ?? "", "reflaxe-lazy-function-field-check.js", "package.json scripts");
expectIncludes(packageJson.scripts["test:todoapp-playwright"] ?? "", "todoapp-playwright.js", "package.json scripts");
expectIncludes(packageJson.scripts["test:todoapp-production"] ?? "", "production-smoke", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1 npm run test:action-controller-params", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1 npm run test:action-mailer", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1 npm run test:active-job", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1 npm run test:active-storage", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1 npm run test:action-cable", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1 npm run test:rails-integration", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1 npm run test:rails-interop", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "test:action-controller-params", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "test:action-mailer", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "test:active-job", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "test:active-storage", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "test:action-cable", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "test:rails-integration", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "test:rails-interop", "package.json scripts");
expectIncludes(packageJson.scripts["test:haxelib-package"] ?? "", "haxelib-package-check.js", "package.json scripts");
expectIncludes(packageJson.scripts["test:gem-package"] ?? "", "gem-package-check.js", "package.json scripts");
expectIncludes(packageJson.scripts["test:release-artifacts"] ?? "", "release-artifact-reproducibility-check.js", "package.json scripts");
expectIncludes(packageJson.scripts["test:release-workflow"] ?? "", "release-workflow-check.js", "package.json scripts");
expectIncludes(packageJson.scripts["test:release-hosting"] ?? "", "release-hosting-check.mjs", "package.json scripts");
expectIncludes(packageJson.scripts["ci:release-contracts"] ?? "", "test:release-workflow", "npm test release workflow wiring");
expectIncludes(packageJson.scripts["ci:release-contracts"] ?? "", "test:release-hosting", "npm test release hosting wiring");
expectIncludes(packageJson.scripts["ci:release-contracts"] ?? "", "test:release-artifacts", "npm test release artifact wiring");
expectIncludes(packageJson.scripts["release:haxelib-package"] ?? "", "build-haxelib-package.js", "package.json scripts");
expectIncludes(packageJson.scripts["release:gem-package"] ?? "", "build-gem-package.js", "package.json scripts");
expectIncludes(versionSyncCheck, "README must document the development sentinel", "version sync check");
expectIncludes(versionSyncCheck, "railshx.client", "version sync check");
expectIncludes(releaseArtifactPrepare, 'release-hosting.mjs", "local"', "pre-tag local identity gate");
expectIncludes(releaseHosting, "published-immutable", "hosted release finalizer");
expectIncludes(releaseHosting, "unexpected assets", "hosted release fail-closed asset set");
expectIncludes(releaseHosting, '"ls-remote"', "local/origin tag identity gate");
expectIncludes(releaseHosting, "releases?per_page=100", "authenticated draft release lookup");
expectIncludes(releaseHostingCheck, "completed immutable release must be verification-only", "hosted release state tests");
expectIncludes(releaseHostingCheck, "draft lookup must use one tag request", "hosted draft lookup regression test");
expectIncludes(releaseRepairWorkflow, "persist-credentials: false", "repair workflow tag mutation guard");
expectIncludes(haxelibPackageBuilder, `"--run", "Run", "build", "_Build"`, "Haxelib package builder");
expectIncludes(haxelibPackageBuilder, `"vendor", "reflaxe"`, "Haxelib package builder");
expectIncludes(haxelibPackageBuilder, `"lib/"`, "Haxelib package builder");
expectIncludes(haxelibPackageBuilder, `"vendor/genes/src/"`, "Haxelib package builder");
expectIncludes(haxelibPackageBuilder, `"hxruby.gemspec"`, "Haxelib package builder");
expectExcludes(haxelibPackageBuilder, `"haxe_libraries/"`, "Haxelib package builder");
expectIncludes(haxelibPackageCheckText, "src/Std.cross.hx", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "src/devisehx/Auth.hx", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "src/devisehx/routes/DeviseRoutes.hx", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "src/devisehx/test/IntegrationHelpers.hx", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "vendor/reflaxe/PATCHES.md", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "vendor/reflaxe/src/reflaxe/helpers/ClassFieldHelper.hx", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "packaged haxelib.json must be sanitized", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "\"haxe_libraries/\"", "Haxelib package check");
expectIncludes(haxelibPackageCheck, "haxelib\", [\"newrepo\"]", "Haxelib package check");
expectIncludes(haxelibPackageCheck, "\"-lib\"", "Haxelib package check");
expectIncludes(haxelibPackageCheck, "Hello from installed reflaxe.ruby", "Haxelib package check");
expectIncludes(haxelibPackageCheck, "TODO: lower", "Haxelib package check");
expectIncludes(haxelibPackageCheck, "verifyArtifactManifest", "Haxelib exact content check");
expectIncludes(haxelibPackageCheck, "sidecar.sha256", "Haxelib exact byte check");
expectIncludes(reflaxeLazyFunctionFieldCheck, "test/reflaxe_lazy_function_field/compile.hxml", "lazy function-field runtime regression");
expectIncludes(reflaxeLazyFunctionFieldCheck, "lazySwitchCount !== 2", "lazy function-field dual call-site contract");
expectIncludes(reflaxeClassFieldHelper, "case TLazy(resolve): resolveLazyType(resolve());", "vendored Reflaxe lazy type resolver");
expectIncludes(reflaxePatchDocs, "https://github.com/SomeRanDev/reflaxe/pull/52", "vendored Reflaxe patch provenance");
expectIncludes(reflaxePatchDocs, "024937acffd242f129265d969a840d3779f02bcd", "vendored Reflaxe patch commit");
expectIncludes(gemPackageBuilder, "gem", "Ruby gem package builder");
expectIncludes(gemPackageCheck, "installed gem missing tasks", "Ruby gem package check");
expectIncludes(gemPackageCheck, "rubyDefaultGemPath", "Ruby gem package check");
expectIncludes(gemPackageCheck, "std/rails/turbo/Turbo.hx", "Ruby gem package check");
expectIncludes(gemPackageCheck, "railshx.client gem smoke", "Ruby gem package check");
expectIncludes(gemPackageCheck, "vendor/genes/src/genes/Generator.hx", "Ruby gem package check");
expectIncludes(gemPackageCheck, "hxruby:production", "Ruby gem package check");
expectIncludes(gemPackageCheck, "verifyArtifactManifest", "gem exact content check");
expectIncludes(gemPackageCheck, "sidecar.sha256", "gem exact byte check");
expectIncludes(hxrubyGemspec, 'spec.name = "hxruby"', "hxruby.gemspec");
expectIncludes(hxrubyGemspec, 'std/**/*.hx', "hxruby.gemspec");
expectIncludes(hxrubyGemspec, 'vendor/genes/src/**/*.hx', "hxruby.gemspec");
expectIncludes(hxrubyGemspec, 'spec.required_ruby_version = ">= 3.2"', "hxruby.gemspec");
expectExcludes(hxrubyGemspec, "add_runtime_dependency", "hxruby.gemspec");
expectExcludes(hxrubyGemspec, "devise", "hxruby.gemspec");
expectIncludes(hxrubyAdoptGenerator, "--devise-hhx-views", "hxruby adopt generator");
expectIncludes(hxrubyAdoptGenerator, ".railshx\", \"gems\", \"devise\"", "hxruby adopt generator");
expectIncludes(hxrubyAdoptGenerator, "render_devise_doc", "hxruby adopt generator");
expectIncludes(hxrubyTasks, 'require "rake"', "hxruby tasks");
expectIncludes(hxrubyTasks, "task :start", "hxruby tasks");
expectIncludes(hxrubyTasks, "start_with_watch", "hxruby tasks");
expectIncludes(hxrubyTasks, "task :routes", "hxruby tasks");
expectIncludes(hxrubyTasks, "task :doctor", "hxruby tasks");
expectIncludes(hxrubyTasks, "task :check", "hxruby tasks");
expectIncludes(hxrubyTasks, "syntax_check_generated_ruby", "hxruby tasks");
expectIncludes(hxrubyTasks, "validate_generated_artifacts_for_check", "hxruby tasks");
expectIncludes(hxrubyTasks, "task :clean", "hxruby tasks");
expectIncludes(hxrubyTasks, "clean_owned_outputs", "hxruby tasks");
expectIncludes(hxrubyTasks, "task :production", "hxruby tasks");
expectIncludes(hxrubyTasks, "assets:precompile", "hxruby tasks");
expectIncludes(railsAppGenerator, "bin/railshx-prod", "RailsHx app generator");
expectIncludes(railsAppGenerator, "render_railshx_client_hxml", "RailsHx app generator");
expectIncludes(railsAppGenerator, "-lib railshx.client", "RailsHx app generator");
expectIncludes(railsAppGenerator, "HomeController", "RailsHx app generator");
expectIncludes(railsAppGenerator, "HomeIndexView", "RailsHx app generator");
expectIncludes(railsAppGenerator, "@:railsRoutes", "RailsHx app generator");
expectIncludes(railsAppGenerator, "hxruby:start:watch", "RailsHx app generator");
expectIncludes(railsAppGenerator, "hxruby:production", "RailsHx app generator");
expectIncludes(readFileSync("scripts/rails/todoapp.js", "utf8"), "assets:precompile", "todoapp production smoke");
expectIncludes(readFileSync("scripts/rails/todoapp.js", "utf8"), "zeitwerk:check", "todoapp production smoke");
expectIncludes(readFileSync("scripts/rails/todoapp.js", "utf8"), "todoapp_rails_release.tgz", "todoapp production smoke");
expectIncludes(rootRakefile, "namespace :todoapp", "root Rakefile");
expectIncludes(rootRakefile, "task :start", "root Rakefile todoapp tasks");
expectIncludes(rootRakefile, "start_todoapp_with_watch", "root Rakefile todoapp tasks");
expectIncludes(rootRakefile, "task :production", "root Rakefile todoapp tasks");
expectIncludes(rootRakefile, "namespace :rails", "root Rakefile");
expectIncludes(rootRakefile, "task :routes", "root Rakefile Rails generator tasks");
expectIncludes(rootRakefile, "task :controller", "root Rakefile Rails generator tasks");
expectIncludes(rootRakefile, "namespace :package", "root Rakefile package tasks");
expectIncludes(readme, "rake package:haxelib:build", "README Haxelib package docs");
expectIncludes(readme, "rake package:haxelib:test", "README Haxelib package docs");
expectIncludes(readme, "-lib reflaxe.ruby", "README Haxelib package docs");
expectIncludes(readme, "-lib railshx.client", "README RailsHx client package docs");
expectIncludes(readme, "rake package:gem:build", "README Ruby gem package docs");
expectIncludes(readme, "rake package:gem:test", "README Ruby gem package docs");
expectIncludes(readme, "dist/reflaxe.ruby-release.zip", "README Haxelib package docs");
expectIncludes(readme, "dist/hxruby-release.gem", "README Ruby gem package docs");
expectIncludes(readme, 'Plain `require "hxruby"` has no gem runtime dependencies.', "README Ruby gem package docs");
expectIncludes(readme, "DeviseHx Release Lane", "README DeviseHx release docs");
expectIncludes(readme, "std/devisehx/**", "README DeviseHx release docs");
expectIncludes(readme, "bin/rails generate hxruby:adopt --gem devise", "README DeviseHx release docs");
expectIncludes(changelog, "incubated DeviseHx release lane", "CHANGELOG DeviseHx release docs");
expectIncludes(ciWorkflow, "Release exact CI-tested commit", "CI release job");
expectIncludes(ciWorkflow, "./node_modules/.bin/semantic-release", "CI release job");
expectIncludes(ciWorkflow, "fetch-depth: 0", "CI release job");
expectIncludes(ciWorkflow, "ref: ${{ github.sha }}", "CI release job");
expectIncludes(ciWorkflow, 'ruby-version: "3.3.11"', "CI release job");
expectIncludes(ciWorkflow, 'rubygems: "3.5.22"', "CI release job");
expectExcludes(ciWorkflow, "FORCE_JAVASCRIPT_ACTIONS_TO_NODE24", "CI workflow");

expectIncludes(devisehxReleaseLane, "std/devisehx/**", "DeviseHx release lane docs");
expectIncludes(devisehxReleaseLane, "bin/rails generate hxruby:adopt --gem devise", "DeviseHx release lane docs");
expectIncludes(devisehxReleaseLane, "npm run test:devisehx-core", "DeviseHx release lane docs");
expectIncludes(devisehxReleaseLane, "npm run test:devisehx-controller", "DeviseHx release lane docs");
expectIncludes(devisehxReleaseLane, "npm run test:rails-adopt-generator", "DeviseHx release lane docs");
expectIncludes(devisehxReleaseLane, "npm run test:todoapp-production", "DeviseHx release lane docs");
expectIncludes(devisehxReleaseLane, "gem \"devise\", \">= 4.9\"", "DeviseHx release lane docs");
expectIncludes(devisehxReleaseLane, "DeviseModule.unsafeCustom", "DeviseHx release lane docs");
expectIncludes(devisehxReleaseLane, "WardenAccess.unsafeWarden", "DeviseHx release lane docs");
expectIncludes(devisehxReleaseLane, "standalone `devisehx` haxelib", "DeviseHx release lane docs");
expectIncludes(gemLayersGuide, "railshx-devisehx-release-lane.md", "Gem layers DeviseHx release docs");
expectIncludes(devisehxDesign, "railshx-devisehx-release-lane.md", "DeviseHx design release docs");
expectIncludes(escapeHatchAudit, "DeviseHx companion escapes", "Escape hatch audit DeviseHx docs");

if (process.exitCode) {
  process.exit(process.exitCode);
}

console.log("[release-contracts] OK");
