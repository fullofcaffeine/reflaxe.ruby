#!/usr/bin/env node

const { existsSync, readFileSync, readdirSync } = require("node:fs");

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

function markdownFilesUnder(directory) {
  return readdirSync(directory, { withFileTypes: true })
    .flatMap((entry) => {
      const path = `${directory}/${entry.name}`;
      if (entry.isDirectory()) return markdownFilesUnder(path);
      return entry.isFile() && entry.name.endsWith(".md") ? [path] : [];
    })
    .sort();
}

const packageJson = readJson("package.json");
const haxelibJson = readJson("haxelib.json");
const haxerc = readJson(".haxerc");
const ciWorkflow = readFileSync(".github/workflows/ci.yml", "utf8");
const agentsGuide = readFileSync("AGENTS.md", "utf8");
const debuggingGuide = readFileSync("docs/debugging.md", "utf8");
const performanceGuide = readFileSync("docs/performance.md", "utf8");
const stableBenchmark = readFileSync("scripts/benchmark/stable-viability.js", "utf8");
const publicContract = readFileSync("docs/public-contract.md", "utf8");
const generatedOwnership = readFileSync("docs/railshx-generated-artifact-ownership.md", "utf8");
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
const docsIndex = readFileSync("docs/README.md", "utf8");
const productPositioning = readFileSync("docs/why-rubyhx.md", "utf8");
const fullStackDesign = readFileSync("docs/railshx-full-stack-hotwire-design.md", "utf8");
const sharedDomainReadme = readFileSync("examples/shared_domain/README.md", "utf8");
const sharedBehaviorCheck = readFileSync("scripts/ci/full-stack-shared-behavior-smoke.js", "utf8");
const productionReadiness = readFileSync("docs/railshx-production-readiness.md", "utf8");
const stableReviewPrompt = readFileSync("docs/rubyhx-railshx-gpt56-1.0-review.md", "utf8");
const stableReviewReport = readFileSync(
  "docs/reviews/rubyhx-railshx-1.0-readiness-review.md",
  "utf8"
);
const typedViews = readFileSync("docs/railshx-typed-views.md", "utf8");
const clientJavaScript = readFileSync("docs/railshx-client-javascript.md", "utf8");
const rubyStdlibFacades = readFileSync("docs/ruby-stdlib-facades.md", "utf8");
const rubyStdlibCoverageDocs = readFileSync("docs/ruby-stdlib-coverage.md", "utf8");
const rubyStdlibCoverage = readJson("lib/hxruby/stdlib_coverage.json");
const rubyStdlibCoverageCheck = readFileSync("scripts/ci/ruby-stdlib-coverage-check.js", "utf8");
const rbsGeneratorDocs = readFileSync("docs/rbs-to-haxe-generator.md", "utf8");
const rbsSourceParser = readFileSync("lib/hxruby/rbs/source_parser.rb", "utf8");
const rbsExternRenderer = readFileSync("lib/hxruby/rbs/haxe_extern_renderer.rb", "utf8");
const rbsExternGenerator = readFileSync("lib/hxruby/rbs/extern_generator.rb", "utf8");
const rbsGeneratorCheck = readFileSync("scripts/ci/rbs-generator-smoke.js", "utf8");
const packageInstallation = readFileSync("docs/packages-and-installation.md", "utf8");
const gettingStarted = readFileSync("docs/getting-started.md", "utf8");
const developmentDocs = readFileSync("docs/development.md", "utf8");
const artifactUtils = readFileSync("scripts/release/artifact-utils.js", "utf8");
const deterministicZip = readFileSync("scripts/release/deterministic-zip.js", "utf8");
const artifactReproducibilityCheck = readFileSync("scripts/ci/release-artifact-reproducibility-check.js", "utf8");
const releaseArtifactPrepare = readFileSync("scripts/release/prepare-release-artifacts.js", "utf8");
const releaseHosting = readFileSync("scripts/release/release-hosting.mjs", "utf8");
const releaseHostingCheck = readFileSync("scripts/ci/release-hosting-check.mjs", "utf8");
const releaseRepairWorkflow = readFileSync(".github/workflows/release-repair.yml", "utf8");
const publicUpgradeCheck = readFileSync("scripts/ci/public-release-upgrade-check.js", "utf8");
const gemPackageBuilder = readFileSync("scripts/release/build-gem-package.js", "utf8");
const gemPackageCheck = readFileSync("scripts/ci/gem-package-check.js", "utf8");
const haxelibPackageCheckText = readFileSync("scripts/ci/haxelib-package-check.js", "utf8");
const reflaxeLazyFunctionFieldCheck = readFileSync("scripts/ci/reflaxe-lazy-function-field-check.js", "utf8");
const reflaxePatchDocs = readFileSync("vendor/reflaxe/PATCHES.md", "utf8");
const reflaxeClassFieldHelper = readFileSync("vendor/reflaxe/src/reflaxe/helpers/ClassFieldHelper.hx", "utf8");
const hxrubyGemspec = readFileSync("hxruby.gemspec", "utf8");
const hxrubyTasks = readFileSync("lib/hxruby/tasks.rb", "utf8");
const hxrubyAdoptGenerator = readFileSync("lib/hxruby/generators/adopt.rb", "utf8");
const railsHxrubyAdoptGenerator = readFileSync("lib/generators/hxruby/adopt/adopt_generator.rb", "utf8");
const railsAdoptGeneratorCheck = readFileSync("scripts/ci/rails-adopt-generator-smoke.js", "utf8");
const yardAdoptGeneratorCheck = readFileSync("scripts/ci/yard-adopt-generator-smoke.js", "utf8");
const railsAppGenerator = readFileSync("lib/hxruby/generators/app.rb", "utf8");
const rubyHxml = readFileSync("haxe_libraries/reflaxe.ruby.hxml", "utf8");
const clientHxml = readFileSync("haxe_libraries/railshx.client.hxml", "utf8");
const devisehxReleaseLane = readFileSync("docs/railshx-devisehx-release-lane.md", "utf8");
const gemLayersGuide = readFileSync("docs/railshx-gem-layers.md", "utf8");
const gradualAdoptionGuide = readFileSync("docs/railshx-gradual-adoption.md", "utf8");
const compatibilityMatrix = readFileSync("docs/compatibility-matrix.md", "utf8");
const securityPolicy = readFileSync("SECURITY.md", "utf8");
const supportPolicy = readFileSync("SUPPORT.md", "utf8");
const dependabotConfig = readFileSync(".github/dependabot.yml", "utf8");
const rubyAdvisoryCheck = readFileSync("scripts/ci/ruby-advisory-check.js", "utf8");
const supportMatrix = readJson("lib/hxruby/support_matrix.json");
const devisehxDesign = readFileSync("docs/railshx-devisehx-design.md", "utf8");
const escapeHatchAudit = readFileSync("docs/railshx-escape-hatch-security-audit.md", "utf8");
const railsRuntimeFixtures = [
  ["todoapp committed Gemfile", readFileSync("examples/todoapp_rails/build/rails/Gemfile", "utf8")],
  ["todoapp materializer", readFileSync("scripts/rails/todoapp.js", "utf8")],
  ["Rails interop materializer", readFileSync("scripts/ci/rails-interop-smoke.js", "utf8")],
  ["controller runtime materializer", readFileSync("scripts/ci/action-controller-params-smoke.js", "utf8")],
  ["scaffold runtime materializer", readFileSync("scripts/ci/scaffold-cli-smoke.js", "utf8")],
];
const railsPinnedRuntimeFixtures = [
  ["Active Storage materializer", readFileSync("scripts/ci/active-storage-smoke.js", "utf8")],
  ["Active Job materializer", readFileSync("scripts/ci/active-job-smoke.js", "utf8")],
  ["Action Cable materializer", readFileSync("scripts/ci/action-cable-smoke.js", "utf8")],
  ["Action Mailer materializer", readFileSync("scripts/ci/action-mailer-smoke.js", "utf8")],
];
const sqliteRuntimeFixtures = [
  ["todoapp committed Gemfile", readFileSync("examples/todoapp_rails/build/rails/Gemfile", "utf8")],
  ["todoapp materializer", readFileSync("scripts/rails/todoapp.js", "utf8")],
  ["Rails interop materializer", readFileSync("scripts/ci/rails-interop-smoke.js", "utf8")],
  ["Active Storage materializer", readFileSync("scripts/ci/active-storage-smoke.js", "utf8")],
  ["scaffold runtime materializer", readFileSync("scripts/ci/scaffold-cli-smoke.js", "utf8")],
];

if (packageJson.name !== "reflaxe-ruby") {
  fail(`package.json name must be reflaxe-ruby, got ${packageJson.name}`);
}
if (haxelibJson.name !== "reflaxe.ruby") {
  fail(`haxelib.json name must be reflaxe.ruby, got ${haxelibJson.name}`);
}
if (haxelibJson.classPath !== "src") {
  fail(`haxelib.json classPath must be src, got ${haxelibJson.classPath}`);
}
expectIncludes(
  agentsGuide,
  'Treat external, LLM, GPT, and "Oracle" reviews as evidence-backed hypotheses',
  "external review evidence policy"
);
expectIncludes(
  agentsGuide,
  "Do not turn an accepted dependency range",
  "review support-claim boundary"
);
expectIncludes(agentsGuide, "compatibility matrices as tested support and maintenance promises", "forward compatibility agent policy");
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
expectIncludes(readme, "Write typed Haxe. Ship ordinary Ruby.", "README product thesis");
expectIncludes(readme, "Start Where It Pays", "README entrypoint design");
expectIncludes(readme, "stable `1.x` for the documented and tested surface", "README maturity contract");
expectIncludes(readme, "docs/why-rubyhx.md", "README product thesis link");
expectIncludes(readme, "docs/getting-started.md", "README getting-started link");
expectIncludes(readme, "docs/packages-and-installation.md", "README package docs link");
expectIncludes(readme, "docs/railshx-typed-views.md", "README typed views link");
expectIncludes(readme, "docs/railshx-client-javascript.md", "README Genes architecture link");
expectIncludes(readme, "docs/public-contract.md", "README public contract link");
expectIncludes(readme, "You can also go\nHaxe-first", "README Haxe-first product path");
expectIncludes(readme, "without making Ruby your day-to-day authoring language", "README Haxe-first value");
if (readme.split(/\r?\n/).length > 240) {
  fail("README must remain a concise product landing page (maximum 240 lines)");
}
for (const referenceHeading of [
  "## Target Defines",
  "## Haxelib Package",
  "## Ruby Gem Package",
  "## Gap Report",
  "## Repository Map",
]) {
  expectExcludes(readme, referenceHeading, "README landing-page scope");
}
expectIncludes(gettingStarted, "## Compiler Defines", "getting-started compiler reference");
expectIncludes(gettingStarted, "npm run test:hello-world", "getting-started executable path");
expectIncludes(developmentDocs, "## Local Hooks", "repository development docs");
expectIncludes(developmentDocs, "## Repository Map", "repository development docs");
expectIncludes(
  securityPolicy,
  "https://github.com/fullofcaffeine/reflaxe.ruby/security/advisories/new",
  "private vulnerability reporting policy"
);
expectIncludes(securityPolicy, ".github/workflows/ci.yml", "security workflow documentation");
expectExcludes(securityPolicy, ".github/workflows/security-gitleaks.yml", "security workflow documentation");
expectIncludes(readme, "[Support And Maintenance](SUPPORT.md)", "README support policy link");
expectIncludes(docsIndex, "[Support And Maintenance](../SUPPORT.md)", "docs support policy link");
expectIncludes(supportPolicy, "Marcelo Serpa", "maintainer of record");
expectIncludes(supportPolicy, "There is no secondary privileged maintainer today", "single-maintainer risk");
expectIncludes(supportPolicy, "artificial compatibility ceiling", "forward compatibility policy");
expectIncludes(supportPolicy, "Dependabot checks GitHub Actions, npm", "dependency review cadence");
expectIncludes(supportPolicy, "Independently released companions", "companion ownership routing");
expectIncludes(supportPolicy, "repository-scoped `GITHUB_TOKEN`", "release authority");
expectIncludes(dependabotConfig, "package-ecosystem: bundler", "Bundler dependency updates");
expectIncludes(dependabotConfig, "/examples/todoapp_rails/build/rails", "Rails reference dependency updates");
expectIncludes(rubyAdvisoryCheck, 'const expectedVersion = "bundler-audit 0.9.3"', "Ruby advisory scanner pin");
expectIncludes(rubyAdvisoryCheck, '"*Gemfile.lock"', "Ruby advisory lock inventory");
expectIncludes(rubyAdvisoryCheck, "test/fixtures/security/vulnerable.lock", "Ruby advisory detection fixture");
expectIncludes(productPositioning, "RubyHx is a typed way to author software for the Ruby ecosystem", "product positioning");
expectIncludes(productPositioning, "Ruby/JavaScript applications commonly share", "full-stack positioning boundary");
expectIncludes(readme, "examples/shared_domain", "README bounded shared-domain proof");
expectIncludes(productPositioning, "seven common vectors", "two-target shared behavior evidence");
expectIncludes(fullStackDesign, "## Maintained Two-Target Domain Proof", "full-stack shared behavior boundary");
expectIncludes(sharedDomainReadme, "does not claim arbitrary", "shared-domain example non-goal");
expectIncludes(packageJson.scripts.test, "test:full-stack-shared-behavior", "mandatory shared behavior gate");
expectIncludes(sharedBehaviorCheck, "Ruby and JavaScript outputs are not byte-identical", "two-target byte parity guard");
expectIncludes(productPositioning, "does not promise zero support code", "generated Ruby positioning boundary");
expectIncludes(productPositioning, "a better way to write the Ruby-bound parts", "Ruby alternative positioning boundary");
expectIncludes(productPositioning, "## Two First-Class Starting Points", "Haxe-first and Ruby-first positioning");
expectIncludes(productPositioning, "### Haxe-first Ruby library or CLI", "framework-independent Haxe-first adoption mode");
expectIncludes(typedViews, "TSX-like typed authoring surface", "typed HHX product contract");
expectIncludes(typedViews, "no virtual DOM, hydration pass", "typed HHX runtime boundary");
expectIncludes(typedViews, "## Honest Limits", "typed HHX claim limits");
expectIncludes(clientJavaScript, "Genes performs the final code emission", "Genes custom-emitter contract");
expectIncludes(clientJavaScript, "## Why Not Reflaxe.Ruby Or The Stock Haxe Emitter?", "Genes target boundary");
expectIncludes(clientJavaScript, "canonical generated RailsHx client contract today", "stock Haxe emitter scope");
expectIncludes(rubyStdlibFacades, "## Coverage Goal", "Ruby stdlib facade coverage contract");
expectIncludes(rubyStdlibFacades, "## Relationship To Haxe Std", "Ruby and Haxe std layering contract");
expectIncludes(rubyStdlibFacades, '"what does Ruby do?"', "Ruby std semantic ownership");
expectIncludes(rubyStdlibFacades, "### URI", "typed URI facade docs");
expectIncludes(rubyStdlibCoverageDocs, "curated", "Ruby stdlib catalog claim boundary");
expectIncludes(rubyStdlibCoverageDocs, "strict deterministic foundation", "RBS generator scope boundary");
expectIncludes(rbsGeneratorDocs, "Precise-Or-Omitted Subset", "RBS generator supported subset");
expectIncludes(rbsGeneratorDocs, "does not claim whole-RBS or", "RBS generator claim boundary");
expectIncludes(docsIndex, "ruby-stdlib-coverage.md", "docs index Ruby stdlib catalog");
expectIncludes(docsIndex, "rbs-to-haxe-generator.md", "docs index RBS generator");
expectIncludes(packageJson.scripts.test, "test:ruby-stdlib-coverage", "mandatory Ruby stdlib catalog gate");
expectIncludes(packageJson.scripts.test, "test:rbs-generator", "mandatory RBS generator gate");
expectIncludes(packageJson.scripts["test:rbs-generator"] ?? "", "rbs_generator_test.rb", "RBS generator unit gate");
expectIncludes(packageJson.scripts["test:rbs-generator"] ?? "", "rbs-generator-smoke.js", "RBS generator smoke gate");
expectIncludes(packageJson.scripts.test, "test:uri-facade", "mandatory typed URI gate");
expectIncludes(rubyStdlibCoverageCheck, "support_matrix.json", "Ruby stdlib catalog support-matrix lock");
expectIncludes(rubyStdlibCoverageCheck, "committed ruby facade is missing", "Ruby stdlib complete facade accounting");
if (rubyStdlibCoverage.schemaVersion !== 1) {
  fail("Ruby stdlib coverage schema version must remain explicit");
}
if (rubyStdlibCoverage.supportMatrix !== "lib/hxruby/support_matrix.json") {
  fail("Ruby stdlib coverage must consume the canonical support matrix");
}
if (rubyStdlibCoverage.scope?.completeness !== "curated-not-whole-stdlib") {
  fail("Ruby stdlib coverage must retain its bounded completeness claim");
}
if (
  rubyStdlibCoverage.rbsGeneration?.scope !== "strict-precise-or-omitted-subset" ||
  rubyStdlibCoverage.rbsGeneration?.evidence !== "npm run test:rbs-generator" ||
  rubyStdlibCoverage.rbsGeneration?.claim !== "generator-infrastructure-not-library-coverage"
) {
  fail("Ruby stdlib coverage must retain its bounded deterministic RBS generation contract");
}
if (JSON.stringify(rubyStdlibCoverage.rubyBranches) !== JSON.stringify(supportMatrix.ruby.ciBranches)) {
  fail("Ruby stdlib coverage branches must match canonical Ruby CI branches");
}
const uriCoverage = rubyStdlibCoverage.domains?.find((domain) => domain.id === "library.uri");
if (
  uriCoverage?.coverageStatus !== "implemented-public" ||
  JSON.stringify(uriCoverage.facadePaths) !== JSON.stringify(["std/ruby/URI.hx", "std/ruby/URIValue.hx"]) ||
  !uriCoverage.evidence?.includes("npm run test:uri-facade") ||
  uriCoverage.contractProvenance?.kind !== "reviewed-rbs"
) {
  fail("Ruby stdlib coverage must retain the bounded reviewed-RBS URI contract");
}
expectIncludes(productionReadiness, "Stable 1.0 Exit Rules", "stable 1.0 readiness contract");
expectIncludes(productionReadiness, "Performance and resource behavior", "stable 1.0 performance gate");
expectIncludes(productionReadiness, "Debugging and observability", "stable 1.0 debugging gate");
expectIncludes(productionReadiness, "Maintenance and support", "stable 1.0 maintenance gate");
expectIncludes(debuggingGuide, "supported line-level debugging source", "server debugging source contract");
expectIncludes(debuggingGuide, "not a Haxe file-and-line mapping", "manifest provenance boundary");
expectIncludes(debuggingGuide, "source map emitted by the Haxe client build", "browser debugging source contract");
expectIncludes(stableReviewPrompt, "Do not answer from the README alone", "stable 1.0 independent review prompt");
expectIncludes(stableReviewPrompt, "claim-evidence matrix", "stable 1.0 claim audit");
expectIncludes(stableReviewPrompt, "Test these as separate claims", "independent Haxe-first review contract");
expectIncludes(stableReviewPrompt, "NOT READY: P1 STABLE-RELEASE BLOCKERS", "stable 1.0 verdict rubric");
expectIncludes(stableReviewPrompt, "docs/reviews/rubyhx-railshx-1.0-readiness-review.md", "stable 1.0 review artifact");
expectIncludes(stableReviewReport, "08faba040457165b883ae5327315581979ea07db", "stable 1.0 reviewed commit");
expectIncludes(stableReviewReport, "NOT READY: P1 STABLE-RELEASE BLOCKERS", "stable 1.0 review verdict");
for (const finding of [
  "RHX-1.0-001",
  "RHX-1.0-002",
  "RHX-1.0-003",
  "RHX-1.0-004",
  "RHX-1.0-005",
  "RHX-1.0-006",
  "RHX-1.0-007",
  "RHX-1.0-008",
  "RHX-1.0-009",
]) {
  expectIncludes(stableReviewReport, finding, "stable 1.0 review finding");
}
expectIncludes(docsIndex, "why-rubyhx.md", "docs index product thesis");
expectIncludes(docsIndex, "rubyhx-railshx-gpt56-1.0-review.md", "docs index stable review prompt");
expectIncludes(docsIndex, "public-contract.md", "docs index public contract");
expectIncludes(
  docsIndex,
  "reviews/rubyhx-railshx-1.0-readiness-review.md",
  "docs index stable review report"
);
expectIncludes(
  compatibilityMatrix,
  "| Rails fixture dependency range | `>= 7.0` |",
  "current Rails fixture range"
);
expectIncludes(publicContract, "The public inventory stays federated", "federated public surface policy");
expectIncludes(publicContract, "Exact prose and compiler-private diagnostic implementation", "diagnostic compatibility boundary");
expectIncludes(publicContract, "generic migration engine because no v2 exists", "bounded manifest migration policy");
expectIncludes(publicContract, "npm run test:public-upgrade", "public upgrade command documentation");
expectIncludes(generatedOwnership, "cleanup fails before deleting any output", "checksum-safe cleanup policy");
expectIncludes(publicUpgradeCheck, "releases/download/${baseline.tag}", "public release asset path");
expectIncludes(publicUpgradeCheck, "3de7a3133bc2c7032eceb64d03f52de9bdc9b50401690a9ab5912772faf189c3", "v0.4.0 Haxelib identity");
expectIncludes(publicUpgradeCheck, "3b775ca2f869404e067c861b5f989204ca8aef59f233d6a5448c8a08d3725a65", "v0.4.0 gem identity");
expectIncludes(
  compatibilityMatrix,
  "| Rails supported line | `8.1` | Supported stable line |",
  "current Rails supported line"
);
expectIncludes(
  compatibilityMatrix,
  "| Rails runtime evidence | `8.1.3` | Exact locked lane |",
  "current Rails runtime evidence"
);
expectIncludes(
  compatibilityMatrix,
  "not evidence that every Rails version is independently supported",
  "Rails range evidence boundary"
);
expectExcludes(compatibilityMatrix, "Rails 7+/8 style app shape", "Rails support wording");
expectIncludes(productionReadiness, "verified RailsHx stable line is Rails `8.1`", "verified Rails line");
expectIncludes(productionReadiness, "exercised at Rails `8.1.3`", "exact Rails evidence");
expectIncludes(
  stableReviewReport,
  "This report records an independent review, not an automatically accepted product",
  "stable review reconciliation rule"
);
for (const [label, source] of railsRuntimeFixtures) {
  expectIncludes(source, 'gem "rails", ">= 7.0"', `${label} current Rails runtime range`);
}
for (const [label, source] of railsPinnedRuntimeFixtures) {
  expectIncludes(
    source,
    `gem "rails", "${supportMatrix.railsHx.verifiedRuntime.railsVersion}"`,
    `${label} exact Rails runtime evidence`,
  );
}
for (const [label, source] of sqliteRuntimeFixtures) {
  expectIncludes(source, 'gem "sqlite3", "~> 2.9", ">= 2.9.5"', `${label} safe SQLite runtime range`);
}
expectIncludes(docsIndex, "getting-started.md", "docs index getting started");
expectIncludes(docsIndex, "packages-and-installation.md", "docs index package installation");
expectIncludes(docsIndex, "development.md", "docs index repository development");
expectIncludes(docsIndex, "railshx-typed-views.md", "docs index typed views");
expectIncludes(docsIndex, "railshx-client-javascript.md", "docs index Genes architecture");

// Public prose uses compact punctuation consistently. Keeping this automated
// prevents the README and detailed guides from drifting back to em dashes.
const emDash = String.fromCodePoint(0x2014);
for (const path of ["README.md", "prd.md", ...markdownFilesUnder("docs")]) {
  expectExcludes(readFileSync(path, "utf8"), emDash, `${path} prose style`);
}

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
  if (!policyPlugin || JSON.stringify(policyPlugin[1]?.approvedStableMajors) !== "[1]") {
    fail("release policy must record the reviewed approval of stable major 1 only");
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
expectIncludes(releaseVersionPolicyDocs, "normal releases from `main`", "release version policy docs");
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
expectIncludes(packageInstallation, "Hosted Release Identity And Repair", "package installation hosted release documentation");
expectIncludes(packageInstallation, "GitHub Releases is currently the sole public distribution host", "package installation distribution host documentation");
expectIncludes(packageInstallation, "Live Release Protocol Evidence", "package installation live release evidence");
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
for (const evidence of [
  "## Stable 1.0 publication",
  "82f7b09d807bd468febd98bf540a391d3484857a",
  "29452140844",
  "87483615576",
  "`draft=false`, `prerelease=false`, and `immutable=true`",
  "hxruby-1.0.0.gem",
  "13d09d13347dff13c4fa8969fdecd6196a9392d29373edbbca7935d172a12ec9",
  "reflaxe.ruby-1.0.0.zip",
  "cb9c1fb6d97c4e1c7f2016915c28ba99eb1c70ddd19b480ef8300119e2d787d4",
  "all 663 ZIP entries",
  "all 303 gem entries",
]) {
  expectIncludes(releaseEvidenceDocs, evidence, "stable 1.0 hosted release evidence");
}
for (const evidence of [
  "## Stable 1.1 typed stdlib publication",
  "9404b5e5f71f268153c59e1943e615e5d2eb6eaf",
  "29474882954",
  "87551001411",
  "hxruby-1.1.0.gem",
  "a854c8357c76a2831e5be04d9eb7726b124b7b335679286257204365c1898c41",
  "reflaxe.ruby-1.1.0.zip",
  "048afed2aead8a4933813d157b3f4a530183e3a646cd91d7485711daf0312b22",
  "676 ZIP payload entries",
  "306 gem payload entries",
  "catalog contains 20 bounded domains",
]) {
  expectIncludes(releaseEvidenceDocs, evidence, "stable 1.1 hosted release evidence");
}
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
expectIncludes(releaseWorkflowDocs, "22.23.1", "publication toolchain docs");
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
expectIncludes(agentsGuide, "normal releases from `main`", "AGENTS release policy");
expectIncludes(agentsGuide, "approvedStableMajors", "AGENTS stable-major policy");
expectIncludes(agentsGuide, "`0.0.0` development sentinel", "AGENTS staging policy");
expectIncludes(agentsGuide, "upload only fixed exact local artifact paths rather than globs", "AGENTS artifact path policy");
expectExcludes(agentsGuide, "until the package is ready for stable `1.x`", "AGENTS obsolete beta policy");

expectIncludes(ciWorkflow, `HAXE_VERSION: "${haxerc.version}"`, "CI workflow");
expectIncludes(ciWorkflow, "ruby-version:", "CI workflow");
for (const rubyVersion of ['"3.3"', '"3.4"', '"4.0"']) {
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
expectIncludes(packageJson.scripts.test, "test:yard-adopt-generator", "npm test");
expectIncludes(packageJson.scripts["test:yard-adopt-generator"] ?? "", "yard-adopt-generator-smoke.js", "package.json scripts");
expectIncludes(packageJson.scripts.test, "test:generator-common", "npm test");
expectIncludes(packageJson.scripts["test:generator-common"] ?? "", "test/generators/common_test.rb", "package.json scripts");
expectIncludes(packageJson.scripts["test:todoapp-playwright"] ?? "", "todoapp-playwright.js", "package.json scripts");
expectIncludes(packageJson.scripts["test:todoapp-production"] ?? "", "production-smoke", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1", "package.json scripts");
expectIncludes(packageJson.scripts["test:rails-runtime"] ?? "", "REQUIRE_RAILS=1 npm run test:rails-component-runtime", "package.json scripts");
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
expectIncludes(versionSyncCheck, "release version policy must document the development sentinel", "version sync check");
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
expectIncludes(haxelibPackageCheckText, "lib/hxruby/stdlib_coverage.json", "Haxelib stdlib catalog package check");
expectIncludes(haxelibPackageCheckText, "lib/hxruby/rbs/source_parser.rb", "Haxelib RBS parser package check");
expectIncludes(haxelibPackageCheckText, "lib/hxruby/rbs/haxe_extern_renderer.rb", "Haxelib RBS renderer package check");
expectIncludes(haxelibPackageCheckText, "packaged RBS generator mismatch", "Haxelib RBS library package smoke");
expectIncludes(haxelibPackageCheckText, "src/ruby/URI.hx", "Haxelib typed URI package check");
expectIncludes(haxelibPackageCheckText, "src/ruby/URIValue.hx", "Haxelib typed URI value package check");
expectIncludes(haxelibPackageCheckText, "src/devisehx/Auth.hx", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "src/devisehx/macros/ContractTools.hx", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "src/devisehx/macros/DeviseModelMacro.hx", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "src/devisehx/macros/RubyFragments.hx", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "src/devisehx/routes/DeviseRoutes.hx", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "src/devisehx/test/IntegrationHelpers.hx", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "vendor/reflaxe/PATCHES.md", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "vendor/reflaxe/src/reflaxe/helpers/ClassFieldHelper.hx", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "packaged haxelib.json must be sanitized", "Haxelib package check");
expectIncludes(haxelibPackageCheckText, "\"haxe_libraries/\"", "Haxelib package check");
expectIncludes(haxelibPackageCheck, "haxelib\", [\"newrepo\"]", "Haxelib package check");
expectIncludes(haxelibPackageCheck, "\"-lib\"", "Haxelib package check");
expectIncludes(haxelibPackageCheck, "installed haxelib CLI mismatch", "Haxelib package check");
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
expectIncludes(gemPackageCheck, "lib/hxruby/stdlib_coverage.json", "Ruby gem stdlib catalog package check");
expectIncludes(gemPackageCheck, "lib/hxruby/rbs/source_parser.rb", "Ruby gem RBS parser package check");
expectIncludes(gemPackageCheck, "lib/hxruby/rbs/haxe_extern_renderer.rb", "Ruby gem RBS renderer package check");
expectIncludes(gemPackageCheck, "scripts/rbs/generate-extern.rb", "Ruby gem RBS command package check");
expectIncludes(gemPackageCheck, "packaged gem RBS generator mismatch", "Ruby gem RBS command package smoke");
expectIncludes(gemPackageCheck, "std/ruby/URI.hx", "Ruby gem typed URI package check");
expectIncludes(gemPackageCheck, "std/ruby/URIValue.hx", "Ruby gem typed URI value package check");
expectIncludes(gemPackageCheck, "railshx.client gem smoke", "Ruby gem package check");
expectIncludes(gemPackageCheck, "vendor/genes/src/genes/Generator.hx", "Ruby gem package check");
expectIncludes(gemPackageCheck, "hxruby:production", "Ruby gem package check");
expectIncludes(gemPackageCheck, "verifyArtifactManifest", "gem exact content check");
expectIncludes(gemPackageCheck, "sidecar.sha256", "gem exact byte check");
expectIncludes(hxrubyGemspec, 'spec.name = "hxruby"', "hxruby.gemspec");
expectIncludes(hxrubyGemspec, 'std/**/*.hx', "hxruby.gemspec");
expectIncludes(hxrubyGemspec, 'lib/hxruby/stdlib_coverage.json', "hxruby.gemspec");
expectIncludes(hxrubyGemspec, 'scripts/rbs/*.rb', "hxruby.gemspec");
expectIncludes(hxrubyGemspec, 'vendor/genes/src/**/*.hx', "hxruby.gemspec");
expectIncludes(hxrubyGemspec, 'spec.required_ruby_version = ">= 3.3"', "hxruby.gemspec");
if (supportMatrix.schemaVersion !== 1) {
  fail("support matrix schema version must remain explicit");
}
if (supportMatrix.maturity?.rubyhx !== "stable 1.x" || supportMatrix.maturity?.railshx !== "stable 1.x") {
  fail("support matrix must record the approved stable 1.x maturity for RubyHx and RailsHx");
}
if (supportMatrix.railsHx?.status !== "stable") {
  fail("support matrix must record RailsHx as stable within the documented support scope");
}
expectIncludes(hxrubyTasks, 'require "hxruby/support_matrix"', "hxruby support diagnostics");
expectIncludes(hxrubyTasks, "HXRuby::SupportMatrix.ruby_error", "hxruby Ruby support diagnostics");
expectIncludes(hxrubyTasks, "HXRuby::SupportMatrix.ruby_warning", "hxruby Ruby support warnings");
expectIncludes(hxrubyTasks, "HXRuby::SupportMatrix.node_error", "hxruby Node support diagnostics");
expectIncludes(hxrubyTasks, "HXRuby::SupportMatrix.haxe_error", "hxruby Haxe support diagnostics");
expectIncludes(hxrubyTasks, "HXRuby::SupportMatrix.rails_warning", "hxruby Rails support warnings");
expectExcludes(hxrubyGemspec, "add_runtime_dependency", "hxruby.gemspec");
expectExcludes(hxrubyGemspec, "devise", "hxruby.gemspec");
expectIncludes(hxrubyAdoptGenerator, "--devise-hhx-views", "hxruby adopt generator");
expectIncludes(hxrubyAdoptGenerator, "--yard PATH", "hxruby adopt generator");
expectIncludes(hxrubyAdoptGenerator, "class YardSourceParser", "hxruby adopt generator");
expectIncludes(hxrubyAdoptGenerator, "no broad fallback type is synthesized", "hxruby adopt generator");
expectIncludes(hxrubyAdoptGenerator, "HXRuby::Rbs::SourceParser", "shared strict RBS adoption parser");
expectIncludes(hxrubyAdoptGenerator, "HXRuby::Rbs::HaxeExternRenderer", "shared strict RBS adoption renderer");
expectIncludes(rbsSourceParser, "class SourceParser", "packaged strict RBS parser");
expectIncludes(rbsSourceParser, "strict: false", "RBS adoption compatibility mode");
expectIncludes(rbsExternRenderer, "canonical: true", "canonical RBS extern renderer");
expectIncludes(rbsExternRenderer, "Inferred from strict deterministic RBS metadata", "strict RBS output contract");
expectIncludes(rbsExternGenerator, "File.realpath", "RBS canonical path boundary");
expectIncludes(rbsGeneratorCheck, "byte-identical canonical output", "RBS deterministic smoke");
expectIncludes(rbsGeneratorCheck, "must resolve to a file inside", "RBS symlink-escape smoke");
expectIncludes(hxrubyAdoptGenerator, "--rbs must resolve to a file inside", "strict RBS path boundary");
expectIncludes(hxrubyAdoptGenerator, "checked_gem_ruby_files", "automatic gem YARD adoption");
expectIncludes(hxrubyAdoptGenerator, "yard_signature_tags", "automatic gem YARD adoption");
expectIncludes(hxrubyAdoptGenerator, "merge_gem_service_contracts", "automatic gem YARD adoption");
expectIncludes(hxrubyAdoptGenerator, ".railshx\", \"gems\", \"devise\"", "hxruby adopt generator");
expectIncludes(hxrubyAdoptGenerator, "render_devise_doc", "hxruby adopt generator");
expectIncludes(railsHxrubyAdoptGenerator, "class_option :yard", "Rails hxruby adopt generator");
expectIncludes(railsHxrubyAdoptGenerator, '["--yard", hxruby_option(:yard)]', "Rails hxruby adopt generator");
expectIncludes(yardAdoptGeneratorCheck, "Unable to parse YARD source", "YARD adoption smoke");
expectIncludes(yardAdoptGeneratorCheck, "generated YARD contract widened into forbidden escape hatch", "YARD adoption smoke");
expectIncludes(yardAdoptGeneratorCheck, 'run("haxe"', "YARD adoption smoke");
expectIncludes(railsAdoptGeneratorCheck, "strict gem YARD contract contains forbidden broad escape", "automatic gem YARD adoption smoke");
expectIncludes(railsAdoptGeneratorCheck, "strict RBS contract contains forbidden broad escape", "strict RBS adoption smoke");
expectIncludes(railsAdoptGeneratorCheck, "RBS symlink escape", "strict RBS path smoke");
expectIncludes(railsAdoptGeneratorCheck, "Unterminated RBS declaration", "strict RBS malformed-file smoke");
expectIncludes(railsAdoptGeneratorCheck, "Ruby source escapes the resolved gem lib root", "automatic gem YARD adoption smoke");
expectIncludes(railsAdoptGeneratorCheck, "strict YARD contract: DemoAuth::SessionManager", "automatic gem YARD discovery smoke");
expectIncludes(gemLayersGuide, "automatic strict YARD discovery", "gem layer guide");
expectIncludes(gemLayersGuide, "Explicit app-service RBS is also strict precise-or-omitted", "gem layer RBS guide");
expectIncludes(gradualAdoptionGuide, "RBS is a precise-or-omitted contract", "gradual adoption RBS guide");
expectIncludes(compatibilityMatrix, "Strict non-executing precise-or-omitted subset", "RBS compatibility contract");
expectIncludes(escapeHatchAudit, "canonicalizes `lib` sources", "gem YARD security boundary");
expectIncludes(escapeHatchAudit, "explicit RBS is canonicalized", "RBS security boundary");
expectIncludes(hxrubyTasks, 'require "rake"', "hxruby tasks");
expectIncludes(hxrubyTasks, '["--yard", ENV["YARD"]]', "hxruby tasks");
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
expectIncludes(railsAppGenerator, "The optional `--rbs` and `--yard` commands are service-specific", "generated app RBS guidance");
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
expectIncludes(packageInstallation, "rake package:haxelib:build", "package installation Haxelib docs");
expectIncludes(packageInstallation, "rake package:haxelib:test", "package installation Haxelib docs");
expectIncludes(packageInstallation, "-lib reflaxe.ruby", "package installation Haxelib docs");
expectIncludes(packageInstallation, "-lib railshx.client", "package installation RailsHx client docs");
expectIncludes(packageInstallation, "rake package:gem:build", "package installation Ruby gem docs");
expectIncludes(packageInstallation, "rake package:gem:test", "package installation Ruby gem docs");
expectIncludes(packageInstallation, "dist/reflaxe.ruby-release.zip", "package installation Haxelib docs");
expectIncludes(packageInstallation, "dist/hxruby-release.gem", "package installation Ruby gem docs");
expectIncludes(packageInstallation, '`require "hxruby"` has no gem runtime dependencies', "package installation Ruby gem docs");
expectIncludes(packageInstallation, "DeviseHx Release Lane", "package installation DeviseHx docs");
expectIncludes(packageInstallation, "std/devisehx/**", "package installation DeviseHx docs");
expectIncludes(packageInstallation, "bin/rails generate hxruby:adopt --gem devise", "package installation DeviseHx docs");
expectIncludes(changelog, "incubated DeviseHx release lane", "CHANGELOG DeviseHx release docs");
expectIncludes(ciWorkflow, "Release exact CI-tested commit", "CI release job");
expectIncludes(ciWorkflow, "./node_modules/.bin/semantic-release", "CI release job");
expectIncludes(ciWorkflow, "fetch-depth: 0", "CI release job");
expectIncludes(ciWorkflow, "ref: ${{ github.sha }}", "CI release job");
expectIncludes(ciWorkflow, 'ruby-version: "3.4.10"', "CI release job");
expectIncludes(ciWorkflow, 'rubygems: "3.6.9"', "CI release job");
expectExcludes(ciWorkflow, "FORCE_JAVASCRIPT_ACTIONS_TO_NODE24", "CI workflow");
expectIncludes(packageJson.scripts["benchmark:stable"] ?? "", "stable-viability.js", "stable benchmark command");
expectIncludes(ciWorkflow, "npm run benchmark:stable -- --require-rails", "canonical stable benchmark lane");
expectIncludes(stableBenchmark, "npm_config_user_agent", "invoking npm benchmark identity");
expectIncludes(performanceGuide, "broad absolute caps", "performance regression policy");
expectIncludes(performanceGuide, "does not claim", "performance claim boundary");

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
