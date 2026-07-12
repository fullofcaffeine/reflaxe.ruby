import { analyzeCommits as analyzeConventionalCommits } from "@semantic-release/commit-analyzer";
import semver from "semver";

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
