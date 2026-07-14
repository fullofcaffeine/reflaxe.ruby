#!/usr/bin/env node

const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const yaml = require("js-yaml");

const matrix = JSON.parse(readFileSync("lib/hxruby/support_matrix.json", "utf8"));
const packageJson = JSON.parse(readFileSync("package.json", "utf8"));
const ci = yaml.load(readFileSync(".github/workflows/ci.yml", "utf8"));
const repair = yaml.load(readFileSync(".github/workflows/release-repair.yml", "utf8"));
const gemspec = readFileSync("hxruby.gemspec", "utf8");
const rubyVersion = readFileSync(".ruby-version", "utf8").trim();
const readme = readFileSync("README.md", "utf8");
const compatibilityDocs = readFileSync("docs/compatibility-matrix.md", "utf8");
const gettingStarted = readFileSync("docs/getting-started.md", "utf8");
const productionReadiness = readFileSync("docs/railshx-production-readiness.md", "utf8");
const productRequirements = readFileSync("prd.md", "utf8");
const todoPlaywright = readFileSync("scripts/ci/todoapp-playwright.js", "utf8");
const todoProduction = readFileSync("scripts/rails/todoapp.js", "utf8");
const todoLock = readFileSync("examples/todoapp_rails/build/rails/Gemfile.lock", "utf8");

function step(job, name) {
  const found = job.steps.find((candidate) => candidate.name === name);
  assert(found, `workflow step missing: ${name}`);
  return found;
}

function assertNotExpired(label, date) {
  const today = new Date().toISOString().slice(0, 10);
  assert(today <= date, `${label} expired on ${date}; update support claims and CI before continuing`);
}

assert.equal(matrix.schemaVersion, 1, "support matrix schema version must be explicit");
assert.deepEqual(matrix.railsHx.fixtureDependencyRequirements, [">= 7.0"]);
assert.deepEqual(matrix.ruby.ciBranches, ["3.3", "3.4", "4.0"]);
assert.deepEqual(ci.jobs.test.strategy.matrix.ruby_version, matrix.ruby.ciBranches);
assert.deepEqual(ci.jobs["rails-runtime"].strategy.matrix.ruby_version, matrix.ruby.ciBranches);
assert.deepEqual(
  matrix.railsHx.verifiedRuntime.rubyBranches,
  matrix.ruby.ciBranches,
  "Rails runtime evidence must cover every supported Ruby branch",
);
assert(!matrix.ruby.ciBranches.includes("3.2"), "EOL Ruby 3.2 must not remain in CI");

assert.equal(ci.env.NODE_VERSION, matrix.node.currentTestedVersion);
assert.equal(ci.env.NPM_VERSION, matrix.node.releaseNpmVersion);
assert.equal(ci.env.HAXE_VERSION, matrix.haxe.ciVersion);
for (const [name, job] of Object.entries(ci.jobs)) {
  assert.equal(job["runs-on"], matrix.canonicalPlatform.runner, `${name} runner must match the canonical platform`);
}
assert.deepEqual(
  ci.jobs["node-compatibility"].strategy.matrix.node_version,
  [matrix.node.minimumVersion, matrix.node.currentTestedVersion],
  "CI must exercise both the declared Node minimum and current tested patch",
);

const release = ci.jobs.release;
assert.equal(step(release, "Setup exact Node.js").with["node-version"], matrix.node.releaseVersion);
assert.equal(step(release, "Setup exact Ruby and RubyGems").with["ruby-version"], matrix.ruby.releaseVersion);
assert.equal(
  step(release, "Setup exact Ruby and RubyGems").with.rubygems,
  matrix.ruby.releaseRubyGemsVersion,
);
assert.equal(
  step(repair.jobs.repair, "Setup exact Node.js without executable cache restore").with["node-version"],
  matrix.node.releaseVersion,
);
assert.equal(step(repair.jobs.repair, "Setup exact Ruby and RubyGems").with["ruby-version"], matrix.ruby.releaseVersion);
assert.equal(
  step(repair.jobs.repair, "Setup exact Ruby and RubyGems").with.rubygems,
  matrix.ruby.releaseRubyGemsVersion,
);
const representativeRuby = matrix.railsHx.verifiedRuntime.browserAndProductionRepresentativeRubyBranch;
assert.equal(step(ci.jobs["rails-browser"], "Setup Ruby").with["ruby-version"], representativeRuby);
assert.equal(step(ci.jobs["rails-production"], "Setup Ruby").with["ruby-version"], representativeRuby);
assert(step(ci.jobs["rails-browser"], "Install Playwright Chromium").run.includes("chromium"));

assert.equal(packageJson.packageManager, `npm@${matrix.node.releaseNpmVersion}`);
assert.equal(packageJson.engines.node, matrix.node.supportedRange);
assert.equal(packageJson.engines.npm, matrix.node.npmSupportedRange);
assert.equal(rubyVersion, matrix.ruby.releaseVersion);
assert(gemspec.includes(`spec.required_ruby_version = ">= ${matrix.ruby.minimumVersion}"`));

for (const branch of matrix.ruby.branches) {
  assertNotExpired(`Ruby ${branch.version} support`, branch.supportEndsOn);
  assert(compatibilityDocs.includes(`\`${branch.version}\``), `compatibility docs missing Ruby ${branch.version}`);
}
assertNotExpired("Node.js support", matrix.node.supportEndsOn);
assertNotExpired(
  `Rails ${matrix.railsHx.verifiedRuntime.railsVersion} beta evidence`,
  matrix.railsHx.verifiedRuntime.upstreamSecuritySupportEndsOn,
);

assert(compatibilityDocs.includes(`\`${matrix.node.minimumVersion}\``));
assert(compatibilityDocs.includes(`\`${matrix.node.currentTestedVersion}\``));
assert(compatibilityDocs.includes(`\`${matrix.railsHx.verifiedRuntime.railsVersion}\``));
assert(compatibilityDocs.includes(`\`${matrix.railsHx.verifiedRuntime.railsLine}\``));
assert(compatibilityDocs.includes("lib/hxruby/support_matrix.json"));
for (const [name, document] of Object.entries({ readme, gettingStarted, productionReadiness, productRequirements })) {
  assert(document.includes(`Haxe \`${matrix.haxe.ciVersion}\``), `${name} missing exact Haxe support`);
  assert(document.includes("MRI Ruby `3.3`"), `${name} missing supported MRI branches`);
  assert(
    document.includes(`Rails \`${matrix.railsHx.verifiedRuntime.railsLine}\``),
    `${name} missing supported Rails line`,
  );
}
for (const [name, document] of Object.entries({ productionReadiness, productRequirements })) {
  assert(
    document.includes(matrix.railsHx.verifiedRuntime.railsVersion),
    `${name} missing verified Rails runtime`,
  );
}
assert(!productRequirements.includes("Rails: Rails 8.0+"), "PRD must not advertise unverified Rails 8 support");
assert(!productRequirements.includes("Rails 8.1 support is planned"), "PRD must not describe verified Rails 8.1 as planned");
assert(!productRequirements.includes("Ruby runtime: Ruby >= 3.2"), "PRD must not advertise EOL Ruby 3.2");
for (const [name, entrypoint] of Object.entries({ todoPlaywright, todoProduction })) {
  assert(entrypoint.includes("support_matrix.json"), `${name} must enforce the machine support matrix`);
  assert(entrypoint.includes("supportMatrix.ruby.minimumVersion"), `${name} must enforce the Ruby minimum`);
}
assert(todoLock.includes(`rails (${matrix.railsHx.verifiedRuntime.railsVersion})`));
assert(todoLock.includes("sqlite3 ("), "reference runtime lock must retain the verified SQLite adapter");

console.log("[support-matrix] OK: machine contract, CI, packages, docs, and support dates agree");
