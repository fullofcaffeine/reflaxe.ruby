#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import {
	mkdtempSync,
	readFileSync,
	readdirSync,
	rmSync,
	statSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { generateNotes as generateConventionalNotes } from "@semantic-release/release-notes-generator";
import semver from "semver";
import artifactUtils from "./artifact-utils.js";
import releaseIdentityModule from "./release-identity.js";

const { canonicalJson, sha256File, verifyArtifactManifest } = artifactUtils;
const { releaseIdentity } = releaseIdentityModule;
const API_VERSION = "2026-03-10";
const root = resolve(fileURLToPath(new URL("../..", import.meta.url)));

const ARTIFACTS = Object.freeze([
	Object.freeze({
		kind: "gem",
		localFilename: "hxruby-release.gem",
		hostedName: (version) => `hxruby-${version}.gem`,
		artifactLabel: (version) => `hxruby ${version} Ruby gem`,
		sidecarLabel: (version) => `hxruby ${version} SHA-256 metadata`,
	}),
	Object.freeze({
		kind: "zip",
		localFilename: "reflaxe.ruby-release.zip",
		hostedName: (version) => `reflaxe.ruby-${version}.zip`,
		artifactLabel: (version) => `reflaxe.ruby ${version} haxelib package`,
		sidecarLabel: (version) => `reflaxe.ruby ${version} SHA-256 metadata`,
	}),
]);

export class ReleaseHostingError extends Error {
	constructor(message) {
		super(message);
		this.name = "ReleaseHostingError";
		this.code = "ERUBYHXRELEASEHOSTING";
	}
}

function fail(message) {
	throw new ReleaseHostingError(message);
}

function sha256Buffer(bytes) {
	return createHash("sha256").update(bytes).digest("hex");
}

function run(command, args, options = {}) {
	const result = spawnSync(command, args, {
		cwd: options.cwd ?? root,
		encoding: options.encoding === undefined ? "utf8" : options.encoding,
		env: options.env ?? process.env,
		maxBuffer: 128 * 1024 * 1024,
		stdio: ["ignore", "pipe", "pipe"],
	});
	if (result.status !== 0) {
		const stdout = Buffer.isBuffer(result.stdout) ? result.stdout.toString() : result.stdout;
		const stderr = Buffer.isBuffer(result.stderr) ? result.stderr.toString() : result.stderr;
		fail(`${command} ${args.join(" ")} failed (${result.status}):\n${stdout ?? ""}${stderr ?? ""}`);
	}
	return result.stdout;
}

function readCanonicalJson(path, label) {
	const text = readFileSync(path, "utf8");
	const value = JSON.parse(text);
	if (text !== canonicalJson(value)) fail(`${label} must use canonical JSON`);
	return value;
}

function assertEmbeddedIdentity(value, identity, label) {
	if (
		value?.version !== identity.version
		|| value?.gitTag !== identity.gitTag
		|| value?.sourceSha !== identity.sourceSha
	) {
		fail(`${label} does not match ${identity.gitTag} at ${identity.sourceSha}`);
	}
}

function validateZipEntries(path) {
	const entries = run("unzip", ["-Z1", path]).split("\n").filter(Boolean);
	if (entries.length === 0 || new Set(entries).size !== entries.length) {
		fail("ZIP must contain a non-empty, duplicate-free entry set");
	}
	for (const entry of entries) {
		const normalized = entry.endsWith("/") ? entry.slice(0, -1) : entry;
		if (
			!normalized
			|| normalized.startsWith("/")
			|| normalized.includes("\\")
			|| normalized.split("/").some((part) => part === "" || part === "." || part === "..")
		) {
			fail(`ZIP contains an unsafe entry path: ${JSON.stringify(entry)}`);
		}
	}
}

function verifyZipIdentity(path, identity) {
	validateZipEntries(path);
	const tempRoot = mkdtempSync(join(tmpdir(), "rubyhx-hosting-zip."));
	try {
		run("unzip", ["-qq", path, "-d", tempRoot]);
		verifyArtifactManifest(tempRoot, "reflaxe.ruby-haxelib");
		assertEmbeddedIdentity(
			readCanonicalJson(join(tempRoot, "release-provenance.json"), "ZIP provenance"),
			identity,
			"ZIP provenance",
		);
		const haxelib = readCanonicalJson(join(tempRoot, "haxelib.json"), "ZIP haxelib.json");
		if (haxelib.version !== identity.version) fail("ZIP haxelib.json version does not match release identity");
		if (!readFileSync(join(tempRoot, "lib", "hxruby", "version.rb"), "utf8").includes(`VERSION = "${identity.version}"`)) {
			fail("ZIP HXRuby::VERSION does not match release identity");
		}
	} finally {
		rmSync(tempRoot, { recursive: true, force: true });
	}
}

function verifyGemIdentity(path, identity) {
	const gemIdentity = run("ruby", [
		"-rrubygems/package",
		"-e",
		"spec = Gem::Package.new(ARGV.fetch(0)).spec; print([spec.name, spec.version.to_s].join(\"\\n\"))",
		path,
	]).trim().split("\n");
	if (gemIdentity.length !== 2 || gemIdentity[0] !== "hxruby" || gemIdentity[1] !== identity.version) {
		fail("gem package name/version does not match release identity");
	}
	const tempRoot = mkdtempSync(join(tmpdir(), "hxruby-hosting-gem."));
	try {
		run("gem", ["unpack", path, "--target", tempRoot]);
		const roots = readdirSync(tempRoot).map((name) => join(tempRoot, name));
		if (roots.length !== 1 || !statSync(roots[0]).isDirectory()) fail("gem unpack produced an unexpected root set");
		const unpacked = roots[0];
		verifyArtifactManifest(unpacked, "hxruby-gem");
		assertEmbeddedIdentity(
			readCanonicalJson(join(unpacked, "release-provenance.json"), "gem provenance"),
			identity,
			"gem provenance",
		);
		const haxelib = readCanonicalJson(join(unpacked, "haxelib.json"), "gem haxelib.json");
		if (haxelib.version !== identity.version) fail("gem haxelib.json version does not match release identity");
		if (!readFileSync(join(unpacked, "lib", "hxruby", "version.rb"), "utf8").includes(`VERSION = "${identity.version}"`)) {
			fail("gem HXRuby::VERSION does not match release identity");
		}
	} finally {
		rmSync(tempRoot, { recursive: true, force: true });
	}
}

/**
 * Verify the exact four local upload candidates and both embedded package identities.
 * This runs in semantic-release's prepare phase, before the real version tag exists,
 * so it deliberately verifies artifacts only; tag and hosted checks happen later.
 */
export function expectedAssetsFromDist(identity, repoRoot = root) {
	const dist = join(repoRoot, "dist");
	const actualNames = readdirSync(dist).sort();
	const expectedLocalNames = ARTIFACTS
		.flatMap(({ localFilename }) => [localFilename, `${localFilename}.sha256.json`])
		.sort();
	if (JSON.stringify(actualNames) !== JSON.stringify(expectedLocalNames)) {
		fail(`dist must contain exactly ${JSON.stringify(expectedLocalNames)}, got ${JSON.stringify(actualNames)}`);
	}

	const expected = [];
	for (const artifact of ARTIFACTS) {
		const artifactPath = join(dist, artifact.localFilename);
		const sidecarPath = `${artifactPath}.sha256.json`;
		const sidecar = readCanonicalJson(sidecarPath, `${artifact.kind} sidecar`);
		const hostedName = artifact.hostedName(identity.version);
		if (
			sidecar?.format !== 1
			|| sidecar.localFilename !== artifact.localFilename
			|| sidecar.hostedFilename !== hostedName
			|| sidecar.bytes !== statSync(artifactPath).size
			|| sidecar.sha256 !== sha256File(artifactPath)
		) {
			fail(`${artifact.kind} sidecar does not bind the exact local artifact bytes`);
		}
		assertEmbeddedIdentity(sidecar, identity, `${artifact.kind} sidecar`);

		if (artifact.kind === "zip") verifyZipIdentity(artifactPath, identity);
		else verifyGemIdentity(artifactPath, identity);

		expected.push({
			name: hostedName,
			label: artifact.artifactLabel(identity.version),
			path: artifactPath,
			bytes: statSync(artifactPath).size,
			sha256: sidecar.sha256,
		});
		expected.push({
			name: `${hostedName}.sha256.json`,
			label: artifact.sidecarLabel(identity.version),
			path: sidecarPath,
			bytes: statSync(sidecarPath).size,
			sha256: sha256File(sidecarPath),
		});
	}

	return expected.sort((left, right) => left.name.localeCompare(right.name));
}

/** Resolve lightweight or annotated local/origin tags to the same tested commit. */
export function verifyGitIdentity(identity, repoRoot = root) {
	const head = run("git", ["rev-parse", "HEAD"], { cwd: repoRoot }).trim();
	if (head !== identity.sourceSha) fail(`HEAD ${head} does not match release source ${identity.sourceSha}`);
	const localTag = run("git", ["rev-parse", `${identity.gitTag}^{commit}`], { cwd: repoRoot }).trim();
	if (localTag !== identity.sourceSha) fail(`local ${identity.gitTag} resolves to ${localTag}, not ${identity.sourceSha}`);

	const remoteText = run("git", [
		"ls-remote",
		"--tags",
		"origin",
		`refs/tags/${identity.gitTag}`,
		`refs/tags/${identity.gitTag}^{}`,
	], { cwd: repoRoot }).trim();
	const remoteRefs = new Map(remoteText.split("\n").filter(Boolean).map((line) => {
		const [sha, ref] = line.split("\t");
		return [ref, sha];
	}));
	const direct = remoteRefs.get(`refs/tags/${identity.gitTag}`);
	const peeled = remoteRefs.get(`refs/tags/${identity.gitTag}^{}`);
	if (!direct) fail(`origin is missing ${identity.gitTag}`);
	if ((peeled ?? direct) !== identity.sourceSha) {
		fail(`origin ${identity.gitTag} does not resolve to ${identity.sourceSha}`);
	}
	return identity;
}

function validateReleaseMetadata(release, identity, expectedDraft) {
	if (release?.tag_name !== identity.gitTag) fail("GitHub Release tag does not match release identity");
	if (release?.name !== identity.gitTag) fail("GitHub Release name must equal its immutable version tag");
	if (release?.prerelease !== false) fail("normal RubyHx releases must not be GitHub prereleases");
	if (expectedDraft != null && release?.draft !== expectedDraft) {
		fail(`GitHub Release draft state must be ${expectedDraft}`);
	}
	if (typeof release?.body !== "string" || !release.body.startsWith(`## ${identity.gitTag}\n`)) {
		fail("GitHub Release body must start with the version heading");
	}
	if (!release.body.includes("/compare/") || !release.body.includes("/commit/")) {
		fail("GitHub Release body must contain compare and commit links");
	}
}

function remoteAssetMap(release, expected) {
	const assets = Array.isArray(release?.assets) ? release.assets : [];
	const names = assets.map(({ name }) => name);
	if (new Set(names).size !== names.length) fail("GitHub Release contains duplicate asset names");
	const allowed = new Set(expected.map(({ name }) => name));
	const unexpected = names.filter((name) => !allowed.has(name));
	if (unexpected.length > 0) fail(`GitHub Release contains unexpected assets: ${unexpected.join(", ")}`);
	return new Map(assets.map((asset) => [asset.name, asset]));
}

async function verifyOneHostedAsset(adapter, remote, expected) {
	if (remote.state !== "uploaded") fail(`${expected.name} is not fully uploaded`);
	if (remote.label !== expected.label) fail(`${expected.name} label does not match the reviewed contract`);
	if (remote.size !== expected.bytes) fail(`${expected.name} hosted size does not match local bytes`);
	if (remote.digest !== `sha256:${expected.sha256}`) fail(`${expected.name} hosted digest does not match local bytes`);
	const hostedBytes = await adapter.downloadAsset(remote.id);
	const localBytes = readFileSync(expected.path);
	if (!Buffer.from(hostedBytes).equals(localBytes) || sha256Buffer(hostedBytes) !== expected.sha256) {
		fail(`${expected.name} downloaded bytes do not match the local candidate`);
	}
}

export async function verifyHostedAssets(adapter, release, expected, { allowPartial = false } = {}) {
	const remote = remoteAssetMap(release, expected);
	if (!allowPartial && remote.size !== expected.length) {
		fail(`GitHub Release must contain exactly ${expected.length} reviewed assets`);
	}
	for (const asset of expected) {
		const hosted = remote.get(asset.name);
		if (!hosted) {
			if (allowPartial) continue;
			fail(`GitHub Release is missing ${asset.name}`);
		}
		await verifyOneHostedAsset(adapter, hosted, asset);
	}
	return remote;
}

async function waitForImmutableRelease(adapter, tag) {
	for (let attempt = 0; attempt < 20; attempt += 1) {
		const release = await adapter.getRelease(tag);
		if (release && release.draft === false && release.immutable === true) return release;
		await new Promise((resolvePromise) => setTimeout(resolvePromise, 500));
	}
	fail(`published ${tag} did not become immutable`);
}

/**
 * Own the hosted release state machine. `finalize` is mutation-minimal: it only
 * accepts a complete matching draft, then publishes it. `repair` may create a
 * draft or replace missing/mismatched expected draft assets. Neither mode ever
 * tolerates unexpected assets or mutates a completed release.
 */
export async function reconcileHostedRelease({
	mode,
	identity,
	expected,
	adapter,
	notes,
	beforePublish = async () => {},
}) {
	if (!["finalize", "repair", "verify"].includes(mode)) fail(`unsupported hosted release mode ${mode}`);
	let release = await adapter.getRelease(identity.gitTag);
	if (!release) {
		if (mode !== "repair") fail(`GitHub Release ${identity.gitTag} does not exist`);
		release = await adapter.createDraft(identity, notes);
	}
	validateReleaseMetadata(release, identity, release.draft);

	if (release.draft === false) {
		if (release.immutable !== true) fail(`completed ${identity.gitTag} is not protected by immutable releases`);
		await verifyHostedAssets(adapter, release, expected);
		return { state: "verified-immutable", release };
	}
	if (mode === "verify") fail(`verification-only mode will not publish draft ${identity.gitTag}`);

	if (mode === "repair") {
		// Reject unowned/custom assets before changing even mutable draft metadata.
		remoteAssetMap(release, expected);
		release = await adapter.updateDraftMetadata(release.id, identity, notes);
		validateReleaseMetadata(release, identity, true);
		const remote = remoteAssetMap(release, expected);
		for (const asset of expected) {
			const hosted = remote.get(asset.name);
			if (hosted) {
				try {
					await verifyOneHostedAsset(adapter, hosted, asset);
					continue;
				} catch (error) {
					if (!(error instanceof ReleaseHostingError)) throw error;
					await adapter.deleteAsset(hosted.id);
				}
			}
			await adapter.uploadAsset(release.id, asset);
		}
		release = await adapter.getRelease(identity.gitTag);
	}

	validateReleaseMetadata(release, identity, true);
	await verifyHostedAssets(adapter, release, expected);
	await beforePublish();
	await adapter.publishRelease(release.id);
	const immutable = await waitForImmutableRelease(adapter, identity.gitTag);
	validateReleaseMetadata(immutable, identity, false);
	await verifyHostedAssets(adapter, immutable, expected);
	return { state: "published-immutable", release: immutable };
}

export class GitHubReleaseAdapter {
	constructor({ repository, token, fetchImpl = globalThis.fetch }) {
		if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository ?? "")) fail("GITHUB_REPOSITORY is invalid");
		if (typeof token !== "string" || token.length === 0) fail("GITHUB_TOKEN or GH_TOKEN is required");
		this.repository = repository;
		this.token = token;
		this.fetch = fetchImpl;
	}

	async request(path, {
		method = "GET",
		body,
		rawBody = false,
		binaryResponse = false,
		allow404 = false,
		upload = false,
	} = {}) {
		const base = upload ? "https://uploads.github.com" : "https://api.github.com";
		const response = await this.fetch(`${base}${path}`, {
			method,
			headers: {
				Accept: binaryResponse ? "application/octet-stream" : "application/vnd.github+json",
				Authorization: `Bearer ${this.token}`,
				"Content-Type": rawBody ? "application/octet-stream" : "application/json",
				"X-GitHub-Api-Version": API_VERSION,
			},
			body: body == null ? undefined : (rawBody ? body : JSON.stringify(body)),
		});
		if (allow404 && response.status === 404) return null;
		if (!response.ok) {
			const detail = await response.text();
			fail(`GitHub API ${method} ${path} failed (${response.status}): ${detail}`);
		}
		if (response.status === 204) return null;
		return binaryResponse ? Buffer.from(await response.arrayBuffer()) : response.json();
	}

	getRelease(tag) {
		return this.request(`/repos/${this.repository}/releases/tags/${encodeURIComponent(tag)}`, { allow404: true });
	}

	downloadAsset(id) {
		return this.request(`/repos/${this.repository}/releases/assets/${id}`, { binaryResponse: true });
	}

	deleteAsset(id) {
		return this.request(`/repos/${this.repository}/releases/assets/${id}`, { method: "DELETE" });
	}

	uploadAsset(releaseId, asset) {
		const query = new URLSearchParams({ name: asset.name, label: asset.label });
		return this.request(`/repos/${this.repository}/releases/${releaseId}/assets?${query}`, {
			method: "POST",
			body: readFileSync(asset.path),
			rawBody: true,
			upload: true,
		});
	}

	createDraft(identity, notes) {
		return this.request(`/repos/${this.repository}/releases`, {
			method: "POST",
			body: {
				tag_name: identity.gitTag,
				target_commitish: identity.sourceSha,
				name: identity.gitTag,
				body: notes,
				draft: true,
				prerelease: false,
				generate_release_notes: false,
			},
		});
	}

	updateDraftMetadata(id, identity, notes) {
		return this.request(`/repos/${this.repository}/releases/${id}`, {
			method: "PATCH",
			body: { name: identity.gitTag, body: notes, draft: true, prerelease: false },
		});
	}

	publishRelease(id) {
		return this.request(`/repos/${this.repository}/releases/${id}`, {
			method: "PATCH",
			body: { draft: false, prerelease: false, make_latest: "true" },
		});
	}
}

function canonicalVersionTagsAt(sourceSha, repoRoot) {
	return run("git", ["tag", "--merged", sourceSha, "--list", "v*"], { cwd: repoRoot })
		.split("\n")
		.filter(Boolean)
		.map((tag) => ({ tag, version: tag.slice(1) }))
		.filter(({ tag, version }) => tag === `v${version}` && semver.valid(version) === version);
}

function commitsBetween(fromTag, toTag, repoRoot) {
	const hashes = run("git", ["log", "--format=%H", `${fromTag}..${toTag}`], { cwd: repoRoot })
		.split("\n")
		.filter(Boolean);
	return hashes.map((hash) => {
		const message = run("git", ["show", "-s", "--format=%B", hash], { cwd: repoRoot }).trim();
		const [subject, ...body] = message.split("\n");
		return {
			hash,
			message,
			subject,
			body: body.join("\n").trim(),
			committerDate: run("git", ["show", "-s", "--format=%cI", hash], { cwd: repoRoot }).trim(),
			author: {
				name: run("git", ["show", "-s", "--format=%an", hash], { cwd: repoRoot }).trim(),
				email: run("git", ["show", "-s", "--format=%ae", hash], { cwd: repoRoot }).trim(),
			},
		};
	});
}

/** Rebuild semantic-release-style notes from an existing input tag without selecting a new version. */
export async function notesForExistingTag(identity, repoRoot = root) {
	const previous = canonicalVersionTagsAt(identity.sourceSha, repoRoot)
		.filter(({ tag, version }) => tag !== identity.gitTag && semver.lt(version, identity.version))
		.sort((left, right) => semver.rcompare(left.version, right.version))[0];
	if (!previous) fail(`cannot find a canonical previous tag for ${identity.gitTag}`);
	const packageJson = JSON.parse(readFileSync(join(repoRoot, "package.json"), "utf8"));
	const repositoryUrl = packageJson.repository?.url;
	if (typeof repositoryUrl !== "string" || repositoryUrl.length === 0) fail("package repository URL is missing");
	const notes = await generateConventionalNotes({}, {
		branch: { name: "main", type: "release", channel: null },
		commits: commitsBetween(previous.tag, identity.gitTag, repoRoot),
		lastRelease: {
			version: previous.version,
			gitTag: previous.tag,
			gitHead: run("git", ["rev-parse", `${previous.tag}^{commit}`], { cwd: repoRoot }).trim(),
			channels: [null],
		},
		nextRelease: {
			version: identity.version,
			gitTag: identity.gitTag,
			gitHead: identity.sourceSha,
			type: semver.diff(previous.version, identity.version) ?? "patch",
		},
		options: { repositoryUrl, tagFormat: "v${version}" },
		logger: { log() {}, error() {}, success() {} },
	});
	if (!notes.includes(`/compare/${previous.tag}...${identity.gitTag}`) || !notes.includes("/commit/")) {
		fail("regenerated release notes lack the expected compare or commit links");
	}
	return `## ${identity.gitTag}\n\n${notes}`;
}

async function main() {
	const [mode, version, gitTag, sourceSha] = process.argv.slice(2);
	if (!["local", "finalize", "repair", "verify"].includes(mode) || !version || !gitTag || !sourceSha) {
		fail("usage: release-hosting.mjs <local|finalize|repair|verify> <version> <vTag> <sourceSha>");
	}
	const identity = releaseIdentity(version, gitTag, sourceSha);
	const expected = expectedAssetsFromDist(identity);
	if (mode === "local") {
		process.stderr.write(`[release-hosting] local identity OK: ${gitTag} at ${sourceSha}\n`);
		return;
	}
	verifyGitIdentity(identity);
	const adapter = new GitHubReleaseAdapter({
		repository: process.env.GITHUB_REPOSITORY,
		token: process.env.GH_TOKEN ?? process.env.GITHUB_TOKEN,
	});
	const result = await reconcileHostedRelease({
		mode,
		identity,
		expected,
		adapter,
		notes: mode === "repair" ? await notesForExistingTag(identity) : undefined,
		beforePublish: async () => verifyGitIdentity(identity),
	});
	process.stderr.write(`[release-hosting] ${result.state}: ${gitTag} at ${sourceSha}\n`);
	process.stdout.write(`${JSON.stringify({ name: gitTag, url: result.release.html_url })}\n`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
	main().catch((error) => {
		process.stderr.write(`${error.stack ?? error}\n`);
		process.exitCode = 1;
	});
}
