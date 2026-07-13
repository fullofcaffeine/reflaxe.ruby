#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { appendFileSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
import semver from "semver";

export const BASELINE_ENV = "RUBYHX_RELEASE_BASELINE_TAG";
export const ALIAS_ENV = "RUBYHX_RELEASE_TRANSITION_ALIAS";

export class ReleaseTransitionError extends Error {
	constructor(message) {
		super(message);
		this.name = "ReleaseTransitionError";
		this.code = "ERUBYHXRELEASETRANSITION";
	}
}

function fail(message) {
	throw new ReleaseTransitionError(message);
}

function git(args, { cwd, env }) {
	try {
		return execFileSync("git", args, {
			cwd,
			encoding: "utf8",
			env: { ...process.env, ...env },
			stdio: ["ignore", "pipe", "pipe"],
		}).trim();
	} catch {
		fail(`git ${args.join(" ")} failed while preparing release lineage`);
	}
}

function canonicalVersionTag(tag) {
	if (typeof tag !== "string" || !tag.startsWith("v")) return null;
	const version = tag.slice(1);
	return semver.valid(version) === version ? semver.parse(version) : null;
}

/**
 * semantic-release deliberately ignores prerelease tags on stable branches.
 * Until RubyHx has its first stable 0.x tag, create a local-only v0.0.0 alias
 * at the reviewed historical prerelease commit. The policy plugin forces the
 * qualifying release to the prerelease's stable version and removes this alias
 * in `prepare`, before semantic-release executes `git push --tags`.
 */
export function prepareHistoricalBaseline({
	cwd,
	env = process.env,
	historicalPrereleaseBaseline,
	transitionAliasTag,
}) {
	if (transitionAliasTag !== "v0.0.0") {
		fail("transitionAliasTag must be the reserved local-only v0.0.0 tag");
	}
	if (git(["tag", "--list", transitionAliasTag], { cwd, env })) {
		fail(`${transitionAliasTag} already exists; the local-only transition tag must never be persistent`);
	}

	const mergedTags = git(["tag", "--merged", "HEAD", "--list", "v*"], { cwd, env })
		.split("\n")
		.filter(Boolean);
	const versionTags = mergedTags
		.map((tag) => ({ tag, version: canonicalVersionTag(tag) }))
		.filter(({ version }) => version != null);
	if (versionTags.some(({ version }) => version.prerelease.length === 0)) {
		return { kind: "stable", environment: {} };
	}

	const baselineVersion = canonicalVersionTag(historicalPrereleaseBaseline);
	if (baselineVersion?.major !== 0 || baselineVersion.prerelease.length === 0) {
		fail("historicalPrereleaseBaseline must be an exact canonical major-zero prerelease tag");
	}
	if (!versionTags.some(({ tag }) => tag === historicalPrereleaseBaseline)) {
		fail(`required historical prerelease baseline ${historicalPrereleaseBaseline} is not merged into HEAD`);
	}
	const newestPrerelease = versionTags
		.filter(({ version }) => version.prerelease.length > 0)
		.sort((left, right) => semver.rcompare(left.version, right.version))[0]?.tag;
	if (newestPrerelease !== historicalPrereleaseBaseline) {
		fail(`configured baseline ${historicalPrereleaseBaseline} is not the newest merged prerelease ${newestPrerelease}`);
	}

	git(["tag", transitionAliasTag, `${historicalPrereleaseBaseline}^{commit}`], { cwd, env });
	return {
		kind: "historical-prerelease",
		environment: {
			[BASELINE_ENV]: historicalPrereleaseBaseline,
			[ALIAS_ENV]: transitionAliasTag,
		},
	};
}

function releasePolicyConfig(packageJson) {
	const entry = packageJson.release?.plugins?.find(
		(plugin) => Array.isArray(plugin) && plugin[0] === "./scripts/release/analyze-commits.mjs"
	);
	if (!entry || typeof entry[1] !== "object") fail("release policy plugin configuration is missing");
	return entry[1];
}

function main() {
	const cwd = resolve(process.cwd());
	const packageJson = JSON.parse(readFileSync(resolve(cwd, "package.json"), "utf8"));
	const policy = releasePolicyConfig(packageJson);
	const githubEnv = process.env.GITHUB_ENV;
	if (typeof githubEnv !== "string" || githubEnv.length === 0) {
		fail("GITHUB_ENV is required so semantic-release receives the transition contract");
	}
	const result = prepareHistoricalBaseline({
		cwd,
		historicalPrereleaseBaseline: policy.historicalPrereleaseBaseline,
		transitionAliasTag: policy.transitionAliasTag,
	});
	if (result.kind === "stable") {
		console.log("[release-transition] stable tag lineage already exists; no bridge needed");
		return;
	}

	for (const [name, value] of Object.entries(result.environment)) {
		appendFileSync(githubEnv, `${name}=${value}\n`);
	}
	console.log(`[release-transition] prepared local-only ${policy.transitionAliasTag} from ${policy.historicalPrereleaseBaseline}`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
	main();
}
