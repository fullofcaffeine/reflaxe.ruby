#!/usr/bin/env node

import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { Writable } from "node:stream";
import { fileURLToPath, pathToFileURL } from "node:url";
import semanticRelease from "semantic-release";
import semver from "semver";
import {
	ReleasePolicyError,
	analyzeCommits,
} from "../release/analyze-commits.mjs";
import { prepareHistoricalBaseline } from "../release/prepare-semver-transition.mjs";

const silentLogger = {
	log() {},
	error() {},
};

const silentStream = new Writable({
	write(_chunk, _encoding, callback) {
		callback();
	},
});

function context(version, commits, overrides = {}) {
	return {
		cwd: process.cwd(),
		branch: { name: "main", type: "release" },
		commits: commits.map((message, index) => ({ message, hash: `commit-${index}` })),
		lastRelease: {
			version,
			gitTag: `v${version}`,
			channels: [null],
		},
		logger: silentLogger,
		...overrides,
	};
}

async function expectRelease({ name, version, commits, approved = [], type, next }) {
	const actualType = await analyzeCommits(
		{ approvedStableMajors: approved },
		context(version, commits, {
			// Deliberately contradictory mutable metadata proves the policy uses
			// semantic-release's tag-derived lastRelease and nothing else.
			options: { packageVersion: "99.99.99" },
		})
	);
	assert.equal(actualType, type, `${name}: release type`);
	assert.equal(actualType === null ? null : semver.inc(version, actualType), next, `${name}: next version`);
}

async function expectPolicyFailure(name, action, pattern) {
	await assert.rejects(action, (error) => {
		assert.ok(error instanceof ReleasePolicyError, `${name}: expected ReleasePolicyError`);
		assert.equal(error.code, "ERUBYHXRELEASEPOLICY", `${name}: error code`);
		assert.match(error.message, pattern, `${name}: diagnostic`);
		return true;
	});
}

/**
 * Exercise the plugin through semantic-release itself, not only as a direct
 * function call. The temporary repository has contradictory package metadata,
 * so the asserted 0.2.4 result can only come from the v0.2.3 Git tag.
 */
async function proveSemanticReleaseIntegration() {
	const cwd = mkdtempSync(join(tmpdir(), "rubyhx-release-policy-"));
	const policyPlugin = fileURLToPath(new URL("../release/analyze-commits.mjs", import.meta.url));
	const git = (...args) => execFileSync("git", args, { cwd, stdio: "ignore" });

	try {
		git("init", "-b", "main");
		git("config", "user.email", "release-policy@example.test");
		git("config", "user.name", "RubyHx release policy test");
		writeFileSync(join(cwd, "package.json"), '{"name":"lineage-fixture","version":"99.99.99"}\n');
		writeFileSync(join(cwd, "fixture.txt"), "baseline\n");
		git("add", ".");
		git("commit", "-m", "chore: establish tag lineage");
		git("tag", "v0.2.3");
		writeFileSync(join(cwd, "fixture.txt"), "baseline\nfixed\n");
		git("add", ".");
		git("commit", "-m", "fix: exercise the installed release engine");

		const result = await semanticRelease(
			{
				branches: ["main"],
				tagFormat: "v${version}",
				repositoryUrl: pathToFileURL(cwd).href,
				plugins: [[policyPlugin, { approvedStableMajors: [] }]],
				dryRun: true,
				ci: false,
			},
			{ cwd, env: process.env, stdout: silentStream, stderr: silentStream }
		);

		assert.equal(result?.nextRelease?.type, "patch", "semantic-release integration: release type");
		assert.equal(result?.nextRelease?.version, "0.2.4", "semantic-release integration: tag-derived version");
		assert.match(result?.nextRelease?.notes ?? "", /compare\/v0\.2\.3\.\.\.v0\.2\.4/, "semantic-release integration: compare link");
		assert.match(result?.nextRelease?.notes ?? "", /commit\//, "semantic-release integration: commit link");
	} finally {
		rmSync(cwd, { recursive: true, force: true });
	}
}

/**
 * Exercise the only special transition in the real engine. semantic-release
 * normally excludes prerelease tags on stable branches; the local alias lets
 * the engine select 0.1.0 while the policy plugin rewrites notes to the public
 * beta baseline and removes the alias before `git push --tags`.
 */
async function proveHistoricalPrereleaseTransition() {
	const root = mkdtempSync(join(tmpdir(), "rubyhx-release-transition-"));
	const cwd = join(root, "work");
	const remote = join(root, "remote.git");
	const policyPlugin = fileURLToPath(new URL("../release/analyze-commits.mjs", import.meta.url));
	const git = (directory, ...args) => execFileSync("git", args, {
		cwd: directory,
		encoding: "utf8",
		stdio: ["ignore", "pipe", "pipe"],
	}).trim();

	try {
		execFileSync("git", ["init", "--bare", "--initial-branch=main", remote], { stdio: "ignore" });
		execFileSync("git", ["init", "-b", "main", cwd], { stdio: "ignore" });
		git(cwd, "config", "user.email", "release-transition@example.test");
		git(cwd, "config", "user.name", "RubyHx release transition test");
		writeFileSync(join(cwd, "package.json"), '{"name":"transition-fixture","version":"99.99.99"}\n');
		writeFileSync(join(cwd, "fixture.txt"), "beta baseline\n");
		git(cwd, "add", ".");
		git(cwd, "commit", "-m", "chore: establish historical beta");
		git(cwd, "tag", "v0.1.0-beta.2");
		writeFileSync(join(cwd, "fixture.txt"), "beta baseline\nfixed\n");
		git(cwd, "add", ".");
		git(cwd, "commit", "-m", "fix: publish the tested compiler");
		git(cwd, "remote", "add", "origin", pathToFileURL(remote).href);
		git(cwd, "push", "-u", "origin", "main");
		git(cwd, "push", "origin", "v0.1.0-beta.2");

		const transition = prepareHistoricalBaseline({
			cwd,
			historicalPrereleaseBaseline: "v0.1.0-beta.2",
			transitionAliasTag: "v0.0.0",
		});
		assert.equal(transition.kind, "historical-prerelease", "historical transition must be selected");

		const result = await semanticRelease(
			{
				branches: ["main"],
				tagFormat: "v${version}",
				repositoryUrl: pathToFileURL(remote).href,
				plugins: [[policyPlugin, {
					approvedStableMajors: [],
					historicalPrereleaseBaseline: "v0.1.0-beta.2",
					transitionAliasTag: "v0.0.0",
				}]],
				ci: false,
			},
			{
				cwd,
				env: { ...process.env, ...transition.environment },
				stdout: silentStream,
				stderr: silentStream,
			}
		);

		assert.equal(result?.nextRelease?.type, "minor", "historical transition: release type");
		assert.equal(result?.nextRelease?.version, "0.1.0", "historical transition: stable version");
		assert.match(
			result?.nextRelease?.notes ?? "",
			/compare\/v0\.1\.0-beta\.2\.\.\.v0\.1\.0/,
			"historical transition: public compare link"
		);
		assert.deepEqual(
			git(remote, "tag", "--list").split("\n").filter(Boolean).sort(),
			["v0.1.0", "v0.1.0-beta.2"],
			"historical transition: remote tags"
		);
		assert.equal(git(cwd, "tag", "--list", "v0.0.0"), "", "historical transition: local alias removed");
		assert.equal(
			prepareHistoricalBaseline({
				cwd,
				historicalPrereleaseBaseline: "v0.1.0-beta.2",
				transitionAliasTag: "v0.0.0",
			}).kind,
			"stable",
			"historical transition: future stable releases bypass the bridge"
		);
	} finally {
		rmSync(root, { recursive: true, force: true });
	}
}

await expectRelease({
	name: "major-zero fix",
	version: "0.2.3",
	commits: ["fix: preserve callable arity"],
	type: "patch",
	next: "0.2.4",
});
await expectRelease({
	name: "major-zero feature",
	version: "0.2.3",
	commits: ["feat: add typed Ruby module values"],
	type: "minor",
	next: "0.3.0",
});
await expectRelease({
	name: "unapproved major-zero breaking change",
	version: "0.2.3",
	commits: ["feat!: revise the compiler profile contract"],
	type: "minor",
	next: "0.3.0",
});
await expectRelease({
	name: "approved 1.0 graduation",
	version: "0.9.4",
	commits: ["feat: graduate the public API\n\nBREAKING CHANGE: the stable contract begins"],
	approved: [1],
	type: "major",
	next: "1.0.0",
});
await expectRelease({
	name: "approved stable breaking change",
	version: "1.7.2",
	commits: ["feat(callable)!: remove the deprecated callable ABI"],
	approved: [1, 2],
	type: "major",
	next: "2.0.0",
});
await expectRelease({
	name: "historical prerelease promotion",
	version: "0.1.0-beta.2",
	commits: ["fix: publish the tested compiler"],
	type: "patch",
	next: "0.1.0",
});
await expectRelease({
	name: "no-release commits",
	version: "0.2.3",
	commits: ["docs: explain typed block forwarding", "test: cover Ruby-origin calls"],
	type: null,
	next: null,
});

await expectPolicyFailure(
	"missing tag lineage",
	() => analyzeCommits({ approvedStableMajors: [] }, context("0.2.3", ["fix: test"], { lastRelease: {} })),
	/previous v<SemVer> Git tag is required/
);
await expectPolicyFailure(
	"invalid SemVer",
	() => analyzeCommits({ approvedStableMajors: [] }, context("0.2", ["fix: test"])),
	/not canonical SemVer/
);
await expectPolicyFailure(
	"mismatched tag",
	() => analyzeCommits(
		{ approvedStableMajors: [] },
		context("0.2.3", ["fix: test"], { lastRelease: { version: "0.2.3", gitTag: "v9.9.9", channels: [null] } })
	),
	/must exactly match v0\.2\.3/
);
await expectPolicyFailure(
	"unsupported build metadata",
	() => analyzeCommits({ approvedStableMajors: [] }, context("0.2.3+rebuilt", ["fix: test"])),
	/unsupported build metadata/
);
await expectPolicyFailure(
	"unsupported stable prerelease channel",
	() => analyzeCommits({ approvedStableMajors: [1] }, context("1.1.0-beta.1", ["fix: test"])),
	/stable-major prerelease lineage/
);
await expectPolicyFailure(
	"unknown stable major",
	() => analyzeCommits({ approvedStableMajors: [1] }, context("2.1.0", ["fix: test"])),
	/stable major 2 is not present/
);
await expectPolicyFailure(
	"stable breaking without next-major approval",
	() => analyzeCommits({ approvedStableMajors: [1] }, context("1.7.2", ["feat!: break stable API"])),
	/requires independent approval for major 2/
);
await expectPolicyFailure(
	"non-contiguous approvals",
	() => analyzeCommits({ approvedStableMajors: [1, 3] }, context("0.9.0", ["feat!: test"])),
	/contiguous sequence 1\.\.N/
);

await proveSemanticReleaseIntegration();
await proveHistoricalPrereleaseTransition();

console.log("[release-version-policy] OK: conventional 0.x and independently approved stable majors");
