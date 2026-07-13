import { analyzeCommits as analyzeConventionalCommits } from "@semantic-release/commit-analyzer";
import { generateNotes as generateConventionalNotes } from "@semantic-release/release-notes-generator";
import { execFileSync } from "node:child_process";
import semver from "semver";

const BASELINE_ENV = "RUBYHX_RELEASE_BASELINE_TAG";
const ALIAS_ENV = "RUBYHX_RELEASE_TRANSITION_ALIAS";

/**
 * A fail-closed policy error raised before semantic-release can select a tag.
 * Keeping one error code makes policy failures distinguishable from parser or
 * network failures in CI without weakening the diagnostic text.
 */
export class ReleasePolicyError extends Error {
	constructor(message) {
		super(message);
		this.name = "ReleasePolicyError";
		this.code = "ERUBYHXRELEASEPOLICY";
	}
}

function fail(message) {
	throw new ReleasePolicyError(message);
}

/**
 * Read the one-time prerelease-to-stable bridge prepared from Git before
 * semantic-release starts. Stable release branches intentionally ignore
 * prerelease tags, so the bridge exposes an ephemeral stable alias to the
 * engine without publishing that alias or treating package metadata as
 * lineage. Both variables must be present together or the run fails closed.
 */
function transitionContext(context) {
	const baselineTag = context?.env?.[BASELINE_ENV];
	const aliasTag = context?.env?.[ALIAS_ENV];
	if (baselineTag == null && aliasTag == null) return null;
	if (typeof baselineTag !== "string" || baselineTag.length === 0 || typeof aliasTag !== "string" || aliasTag.length === 0) {
		fail("historical prerelease transition requires both baseline and alias tags");
	}

	const baselineVersion = baselineTag.slice(1);
	const baseline = semver.parse(baselineVersion);
	if (baselineTag !== `v${baselineVersion}` || semver.valid(baselineVersion) !== baselineVersion) {
		fail(`historical prerelease baseline ${JSON.stringify(baselineTag)} must be an exact canonical v<SemVer> tag`);
	}
	if (baseline?.major !== 0 || baseline.prerelease.length === 0) {
		fail(`historical prerelease baseline ${baselineTag} must be a major-zero prerelease`);
	}
	if (aliasTag !== "v0.0.0") {
		fail(`historical prerelease transition alias must be the reserved local tag v0.0.0, got ${JSON.stringify(aliasTag)}`);
	}
	if (context?.lastRelease?.gitTag !== aliasTag || context?.lastRelease?.version !== aliasTag.slice(1)) {
		fail(`semantic-release must derive the historical transition from ephemeral ${aliasTag}`);
	}

	return {
		aliasTag,
		baselineTag,
		stableVersion: `${baseline.major}.${baseline.minor}.${baseline.patch}`,
	};
}

function tagCommit(tag, context) {
	try {
		return execFileSync("git", ["rev-list", "-n", "1", tag], {
			cwd: context.cwd,
			encoding: "utf8",
			env: { ...process.env, ...context.env },
			stdio: ["ignore", "pipe", "pipe"],
		}).trim();
	} catch {
		fail(`cannot resolve required release tag ${tag}`);
	}
}

/**
 * Stable-major approvals must form 1..N. That makes approval for major N
 * independent and reviewable: approving 1 never implicitly approves 2, and a
 * typo such as [1, 3] cannot silently skip an unsupported release lineage.
 */
export function validateApprovedStableMajors(value) {
	if (!Array.isArray(value)) {
		fail("approvedStableMajors must be an array of explicitly approved positive integers");
	}

	for (let index = 0; index < value.length; index += 1) {
		const major = value[index];
		const expected = index + 1;
		if (!Number.isSafeInteger(major) || major !== expected) {
			fail(`approvedStableMajors must be the contiguous sequence 1..N; expected ${expected} at index ${index}`);
		}
	}

	return value;
}

/**
 * semantic-release derives lastRelease from Git tags. Requiring the canonical
 * version/tag pair here prevents package.json, gemspec, or another mutable
 * metadata file from becoming an alternate version lineage. Major-zero
 * prereleases are accepted as historical baselines, including
 * v0.1.0-beta.2; main itself is configured as a normal release branch.
 */
export function validateTagLineage(lastRelease, approvedStableMajors) {
	const version = lastRelease?.version;
	const gitTag = lastRelease?.gitTag;

	if (typeof version !== "string" || version.length === 0 || typeof gitTag !== "string" || gitTag.length === 0) {
		fail("a canonical previous v<SemVer> Git tag is required; package metadata cannot seed release lineage");
	}

	const parsed = semver.parse(version);
	if (parsed?.build.length > 0) {
		fail(`last release version ${version} uses unsupported build metadata`);
	}
	if (semver.valid(version) !== version) {
		fail(`last release version ${JSON.stringify(version)} is not canonical SemVer`);
	}
	if (gitTag !== `v${version}`) {
		fail(`last release tag ${JSON.stringify(gitTag)} must exactly match v${version}`);
	}
	if (parsed.prerelease.length > 0 && parsed.major !== 0) {
		fail(`stable-major prerelease lineage ${version} is unsupported on the normal main release channel`);
	}
	if (parsed.major > 0 && !approvedStableMajors.includes(parsed.major)) {
		fail(`stable major ${parsed.major} is not present in approvedStableMajors`);
	}

	return parsed;
}

/**
 * Run the official Conventional Commit analyzer, then apply only RubyHx's
 * major-zero and stable-major guardrails. Fix/feature/no-release behavior stays
 * conventional. A breaking 0.x change advances minor until major 1 is
 * approved; breaking a stable major fails until its next major has its own
 * approval.
 */
export async function analyzeCommits(pluginConfig, context) {
	// semantic-release intentionally merges global options (branches,
	// tagFormat, repositoryUrl, and others) into every plugin config. Only the
	// policy-owned field is consumed here; global options remain owned by the
	// semantic-release core that already validated them.
	const approvedStableMajors = validateApprovedStableMajors(pluginConfig?.approvedStableMajors ?? []);
	const lineage = validateTagLineage(context?.lastRelease, approvedStableMajors);
	const transition = transitionContext(context);
	const conventionalType = await analyzeConventionalCommits(
		{
			// The analyzer's bundled Angular preset recognizes BREAKING CHANGE
			// footers but not the Conventional Commits `type!:` shorthand. Keep
			// both paths inside the official analyzer by parsing the marker into
			// a named field and assigning the same major release rule to it.
			parserOpts: {
				headerPattern: /^(\w*)(?:\((.*)\))?(!)?: (.*)$/,
				headerCorrespondence: ["type", "scope", "breakingMarker", "subject"],
			},
			releaseRules: [{ breakingMarker: "!", release: "major" }],
		},
		context
	);
	if (transition && conventionalType) {
		if (semver.inc(lineage.version, "minor") !== transition.stableVersion) {
			fail(`ephemeral ${lineage.version} cannot promote ${transition.baselineTag} to ${transition.stableVersion}`);
		}
		context.logger.log(
			`Promoting historical ${transition.baselineTag} to stable ${transition.stableVersion}; ephemeral ${transition.aliasTag} will not be published`
		);
		return "minor";
	}

	if (conventionalType !== "major") {
		return conventionalType;
	}

	const nextStableMajor = lineage.major + 1;
	if (approvedStableMajors.includes(nextStableMajor)) {
		return "major";
	}
	if (lineage.major === 0) {
		context.logger.log(
			"RubyHx stable major 1 is not approved; treating the breaking major-zero change as a minor release"
		);
		return "minor";
	}

	fail(`breaking stable major ${lineage.major} requires independent approval for major ${nextStableMajor}`);
}

/**
 * Delegate release-note construction to the official generator. During the
 * one-time stable promotion, semantic-release sees the local alias; replace
 * only that compare-link baseline with the immutable public prerelease tag so
 * published notes remain truthful and navigable.
 */
export async function generateNotes(pluginConfig, context) {
	const notes = await generateConventionalNotes(pluginConfig, context);
	const transition = transitionContext(context);
	if (!transition) return notes;

	const aliasCompare = `/compare/${transition.aliasTag}...`;
	if (!notes.includes(aliasCompare)) {
		fail(`generated release notes do not contain expected transition comparison ${aliasCompare}`);
	}
	return notes.replaceAll(aliasCompare, `/compare/${transition.baselineTag}...`);
}

/**
 * Delete the ephemeral alias in the first prepare hook, before semantic-release
 * creates or pushes the real tag. Matching both refs to one commit prevents a
 * stale or attacker-controlled local tag from being used as the bridge.
 */
export async function prepare(_pluginConfig, context) {
	const transition = transitionContext(context);
	if (!transition) return;
	if (tagCommit(transition.aliasTag, context) !== tagCommit(transition.baselineTag, context)) {
		fail(`${transition.aliasTag} must resolve to the same commit as ${transition.baselineTag}`);
	}
	execFileSync("git", ["tag", "-d", transition.aliasTag], {
		cwd: context.cwd,
		env: { ...process.env, ...context.env },
		stdio: "ignore",
	});
}
