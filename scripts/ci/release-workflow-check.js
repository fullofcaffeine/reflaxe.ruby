#!/usr/bin/env node

const assert = require("node:assert/strict");
const { existsSync, readFileSync } = require("node:fs");

const ciPath = ".github/workflows/ci.yml";
const ci = readFileSync(ciPath, "utf8");
const packageJson = JSON.parse(readFileSync("package.json", "utf8"));
const requiredNeeds = [
  "security",
  "haxe-format",
  "test",
  "rails-browser",
  "rails-runtime",
  "rails-production",
  "release-contracts",
];

function requireMatch(text, pattern, message) {
  assert.match(text, pattern, message);
}

/**
 * Model GitHub's release-job scheduling contract for focused event-matrix tests. `needs` results
 * are tied to the same workflow run and therefore the same `github.sha`; a missing result is an
 * untested SHA and must be rejected just like failure, cancellation, or skipping.
 */
function canPublish({ eventName, ref, repository, sha, testedSha, needs }) {
  return eventName === "push"
    && ref === "refs/heads/main"
    && repository === "fullofcaffeine/reflaxe.ruby"
    && sha === testedSha
    && requiredNeeds.every((name) => needs[name] === "success");
}

const successfulNeeds = Object.fromEntries(requiredNeeds.map((name) => [name, "success"]));
const base = {
  eventName: "push",
  ref: "refs/heads/main",
  repository: "fullofcaffeine/reflaxe.ruby",
  sha: "a".repeat(40),
  testedSha: "a".repeat(40),
  needs: successfulNeeds,
};
const cases = [
  ["canonical main push after every gate", base, true],
  ["pull request", { ...base, eventName: "pull_request" }, false],
  ["manual arbitrary ref", { ...base, eventName: "workflow_dispatch", ref: "refs/heads/other" }, false],
  ["feature push", { ...base, ref: "refs/heads/feature" }, false],
  ["fork main push", { ...base, repository: "someone/reflaxe.ruby" }, false],
  ["untested SHA", { ...base, testedSha: "b".repeat(40) }, false],
  ["failed gate", { ...base, needs: { ...successfulNeeds, test: "failure" } }, false],
  ["cancelled gate", { ...base, needs: { ...successfulNeeds, "rails-runtime": "cancelled" } }, false],
  ["skipped gate", { ...base, needs: { ...successfulNeeds, security: "skipped" } }, false],
  ["missing gate result", { ...base, needs: { ...successfulNeeds, "release-contracts": undefined } }, false],
];
for (const [label, context, expected] of cases) {
  assert.equal(canPublish(context), expected, `publication eligibility mismatch: ${label}`);
}

assert(!existsSync(".github/workflows/release.yml"), "separate branch/manual normal release workflow must be removed");
assert(!existsSync(".github/workflows/security-gitleaks.yml"), "security must be a declared need in the publication graph");
assert(!ci.includes("workflow_dispatch"), "normal CI/publication must not have a manual-ref bypass");
assert(!ci.includes("workflow_run"), "publication must not cross into a separately privileged workflow");
requireMatch(ci, /push: \{\}/, "CI must test pushes");
requireMatch(ci, /pull_request:\n\s+branches: \[main\]/, "CI must test pull requests to main");
requireMatch(ci, /cancel-in-progress: \$\{\{ github\.ref != 'refs\/heads\/main' \}\}/, "main publication runs must not cancel one another");
requireMatch(ci, /\n  security:\n/, "security must be part of the same workflow graph");
requireMatch(ci, /npm audit\n/, "locked dependency audit must gate publication");
requireMatch(ci, /gitleaks\/gitleaks-action@[0-9a-f]{40}/, "secret scanning action must be commit-pinned");

const releaseStart = ci.indexOf("\n  release:\n");
assert.notEqual(releaseStart, -1, "CI must contain the final release job");
const release = ci.slice(releaseStart);
requireMatch(
  release,
  /if: github\.event_name == 'push' && github\.ref == 'refs\/heads\/main' && github\.repository == 'fullofcaffeine\/reflaxe\.ruby'/,
  "release must be canonical-repository push/main only",
);
for (const need of requiredNeeds) requireMatch(release, new RegExp(`\\n      - ${need.replaceAll("-", "\\-")}`), `release must wait for ${need}`);
requireMatch(release, /runs-on: ubuntu-24\.04/, "release runner image must be exact");
requireMatch(release, /permissions:\n\s+contents: write/, "only release content publication needs write authority");
assert(!release.includes("issues: write"), "release must not receive issue write authority");
assert(!release.includes("pull-requests: write"), "release must not receive pull-request write authority");
requireMatch(release, /group: release-\$\{\{ github\.repository \}\}/, "normal and repair publication must share one fixed concurrency group");
requireMatch(release, /cancel-in-progress: false/, "publication must never cancel another publication");
requireMatch(release, /fetch-depth: 0/, "release checkout must include full tag history");
requireMatch(release, /ref: \$\{\{ github\.sha \}\}/, "release must check out the exact CI-tested SHA");
requireMatch(release, /package-manager-cache: false/, "privileged Node setup must disable its implicit npm cache");
assert(!release.includes("actions/cache"), "privileged release must not restore executable caches");
assert(!release.includes("download-artifact"), "privileged release must rebuild instead of importing artifacts");
assert(!release.includes("RELEASE_TOKEN"), "release must use the scoped workflow token, not a broad custom token");

const directLixDownloads = [...ci.matchAll(/^\s*\.\/node_modules\/\.bin\/lix download$/gm)];
assert.equal(directLixDownloads.length, 2, "contract and publication jobs must each install the exact Haxe toolchain");
for (const download of directLixDownloads) {
  const stepStart = ci.lastIndexOf("\n      - name:", download.index);
  const stepPrefix = ci.slice(stepStart, download.index);
  requireMatch(
    stepPrefix,
    /export PATH="\$\(pwd\)\/node_modules\/\.bin:\$PATH"/,
    "direct lix installs must expose the local binary to child processes before downloading Haxe",
  );
}

for (const { 1: action } of ci.matchAll(/^\s*uses:\s*([^\s#]+)/gm)) {
  assert.match(action, /@[0-9a-f]{40}$/, `workflow action must use a full commit SHA: ${action}`);
}
assert(!ci.includes("ubuntu-latest"), "runner images must be explicit");
assert(!/\bnpm install\b/.test(ci), "workflow dependency installation must use npm ci exclusively");
requireMatch(release, /node-version: "22\.14\.0"/, "release Node must be exact");
requireMatch(release, /test "\$\(npm --version\)" = "10\.9\.2"/, "release npm must be exact");
requireMatch(release, /ruby-version: "3\.3\.11"/, "release Ruby must be exact");
requireMatch(release, /rubygems: "3\.5\.22"/, "release RubyGems must be exact");
requireMatch(release, /lix download haxe "4\.3\.7"/, "release Haxe must be exact");
requireMatch(release, /\.\/node_modules\/\.bin\/semantic-release/, "release must execute the locked semantic-release binary directly");

assert.equal(packageJson.packageManager, "npm@10.9.2", "package manager must pin release npm");
assert.equal(packageJson.engines?.node, ">=22.14.0 <23", "package engine must bound the exact release Node major");
assert.equal(packageJson.engines?.npm, "10.9.2", "package engine must pin release npm");
for (const dependency of [
  "@semantic-release/commit-analyzer",
  "@semantic-release/exec",
  "@semantic-release/github",
  "@semantic-release/release-notes-generator",
  "fflate",
  "lix",
  "semantic-release",
  "semver",
]) {
  assert.match(packageJson.devDependencies?.[dependency] ?? "", /^\d+\.\d+\.\d+$/, `${dependency} must be an exact version`);
}
const githubPlugin = packageJson.release.plugins.find((entry) => Array.isArray(entry) && entry[0] === "@semantic-release/github")?.[1];
assert.equal(githubPlugin?.successCommentCondition, false, "release issue/PR success comments must be disabled");
assert.equal(githubPlugin?.failCommentCondition, false, "release failure issues/comments must be disabled");
assert.equal(githubPlugin?.releasedLabels, false, "release issue/PR labeling must be disabled");

console.log(`[release-workflow] OK: ${cases.length} publication event and gate cases`);
