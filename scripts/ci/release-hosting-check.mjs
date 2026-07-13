#!/usr/bin/env node

import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
	GitHubReleaseAdapter,
	ReleaseHostingError,
	reconcileHostedRelease,
} from "../release/release-hosting.mjs";

const identity = Object.freeze({
	version: "0.2.3",
	gitTag: "v0.2.3",
	sourceSha: "a".repeat(40),
});
const notes = [
	"## v0.2.3",
	"",
	"# [0.2.3](https://github.com/fullofcaffeine/reflaxe.ruby/compare/v0.2.2...v0.2.3)",
	"",
	"* fix ([abc1234](https://github.com/fullofcaffeine/reflaxe.ruby/commit/abc1234))",
].join("\n");

function sha256(bytes) {
	return createHash("sha256").update(bytes).digest("hex");
}

function releaseRecord({ draft = true, immutable = false, assets = [], tag = identity.gitTag } = {}) {
	return {
		id: 42,
		tag_name: tag,
		name: tag,
		target_commitish: identity.sourceSha,
		draft,
		prerelease: false,
		immutable,
		body: notes,
		html_url: `https://example.test/releases/${tag}`,
		assets,
	};
}

class FakeAdapter {
	constructor(release, bytesById = new Map()) {
		this.release = release;
		this.bytesById = bytesById;
		this.operations = [];
		this.nextId = 100;
	}

	async getRelease() {
		return this.release;
	}

	async downloadAsset(id) {
		return this.bytesById.get(id);
	}

	async createDraft(_identity, body) {
		this.operations.push("create");
		this.release = releaseRecord();
		this.release.body = body;
		return this.release;
	}

	async updateDraftMetadata(_id, _identity, body) {
		this.operations.push("metadata");
		this.release.tag_name = _identity.gitTag;
		this.release.name = _identity.gitTag;
		this.release.target_commitish = _identity.sourceSha;
		if (body !== undefined) this.release.body = body;
		return this.release;
	}

	async deleteAsset(id) {
		this.operations.push(`delete:${id}`);
		this.release.assets = this.release.assets.filter((asset) => asset.id !== id);
		this.bytesById.delete(id);
	}

	async uploadAsset(_releaseId, expected) {
		const id = this.nextId++;
		this.operations.push(`upload:${expected.name}`);
		this.release.assets.push({
			id,
			name: expected.name,
			label: expected.label,
			state: "uploaded",
			size: expected.bytes,
			digest: `sha256:${expected.sha256}`,
		});
		this.bytesById.set(id, expected.content);
	}

	async publishRelease() {
		this.operations.push("publish");
		this.release.draft = false;
		this.release.immutable = true;
		return this.release;
	}
}

function hostedAsset(expected, id, overrides = {}) {
	return {
		id,
		name: expected.name,
		label: expected.label,
		state: "uploaded",
		size: expected.bytes,
		digest: `sha256:${expected.sha256}`,
		...overrides,
	};
}

function completeFixture(expected, releaseOptions = {}) {
	const bytes = new Map();
	const assets = expected.map((asset, index) => {
		const id = index + 1;
		bytes.set(id, asset.content);
		return hostedAsset(asset, id);
	});
	return new FakeAdapter(releaseRecord({ ...releaseOptions, assets }), bytes);
}

async function expectHostingFailure(label, action, pattern) {
	await assert.rejects(action, (error) => {
		assert.ok(error instanceof ReleaseHostingError, `${label}: expected ReleaseHostingError`);
		assert.equal(error.code, "ERUBYHXRELEASEHOSTING", `${label}: error code`);
		assert.match(error.message, pattern, `${label}: diagnostic`);
		return true;
	});
}

const tempRoot = mkdtempSync(join(tmpdir(), "rubyhx-hosting-state-"));
try {
	const expected = [
		["hxruby-0.2.3.gem", "hxruby 0.2.3 Ruby gem", "gem-bytes"],
		["hxruby-0.2.3.gem.sha256.json", "hxruby 0.2.3 SHA-256 metadata", "gem-sidecar"],
		["reflaxe.ruby-0.2.3.zip", "reflaxe.ruby 0.2.3 haxelib package", "zip-bytes"],
		["reflaxe.ruby-0.2.3.zip.sha256.json", "reflaxe.ruby 0.2.3 SHA-256 metadata", "zip-sidecar"],
	].map(([name, label, content], index) => {
		const bytes = Buffer.from(content);
		const path = join(tempRoot, String(index));
		writeFileSync(path, bytes);
		return { name, label, path, content: bytes, bytes: bytes.length, sha256: sha256(bytes) };
	});

	const finalized = completeFixture(expected);
	const finalizedResult = await reconcileHostedRelease({
		mode: "finalize", identity, expected, adapter: finalized, beforePublish: async () => finalized.operations.push("tag-check"),
	});
	assert.equal(finalizedResult.state, "published-immutable");
	assert.deepEqual(finalized.operations, ["tag-check", "publish"], "normal publication only verifies then publishes");

	const temporaryDraft = completeFixture(expected);
	temporaryDraft.release.tag_name = "untagged-deadbeef";
	const temporaryResult = await reconcileHostedRelease({ mode: "finalize", identity, expected, adapter: temporaryDraft });
	assert.equal(temporaryResult.state, "published-immutable");
	assert.deepEqual(temporaryDraft.operations, ["metadata", "publish"], "temporary GitHub draft tag must bind before publication");
	assert.equal(temporaryDraft.release.tag_name, identity.gitTag, "published draft must use the real immutable tag");

	const partialFinalize = completeFixture(expected.slice(0, 2));
	await expectHostingFailure(
		"normal partial draft",
		() => reconcileHostedRelease({ mode: "finalize", identity, expected, adapter: partialFinalize }),
		/must contain exactly 4/,
	);
	assert.deepEqual(partialFinalize.operations, [], "normal publication must not repair a partial draft");

	const absent = new FakeAdapter(null);
	const absentResult = await reconcileHostedRelease({ mode: "repair", identity, expected, adapter: absent, notes });
	assert.equal(absentResult.state, "published-immutable");
	assert.equal(absent.operations.filter((operation) => operation.startsWith("upload:")).length, 4, "tag/no-release uploads all assets");
	assert(absent.operations.includes("create") && absent.operations.includes("publish"), "tag/no-release creates a draft then publishes");

	const partial = completeFixture(expected.slice(0, 2));
	await reconcileHostedRelease({ mode: "repair", identity, expected, adapter: partial, notes });
	assert.equal(partial.operations.filter((operation) => operation.startsWith("upload:")).length, 2, "partial draft uploads missing assets");

	const mismatched = completeFixture(expected);
	mismatched.release.assets[0].digest = `sha256:${"0".repeat(64)}`;
	await reconcileHostedRelease({ mode: "repair", identity, expected, adapter: mismatched, notes });
	assert(mismatched.operations.includes("delete:1"), "mismatched expected draft asset must be removed");
	assert(mismatched.operations.includes(`upload:${expected[0].name}`), "mismatched expected draft asset must be replaced");

	const unexpected = completeFixture(expected);
	unexpected.release.assets.push({ id: 99, name: "surprise.bin", label: "", state: "uploaded", size: 1, digest: `sha256:${"0".repeat(64)}` });
	await expectHostingFailure(
		"unexpected draft asset",
		() => reconcileHostedRelease({ mode: "repair", identity, expected, adapter: unexpected, notes }),
		/unexpected assets: surprise\.bin/,
	);
	assert.deepEqual(unexpected.operations, [], "unexpected assets must fail without any draft mutation");

	const immutable = completeFixture(expected, { draft: false, immutable: true });
	const immutableResult = await reconcileHostedRelease({ mode: "repair", identity, expected, adapter: immutable, notes });
	assert.equal(immutableResult.state, "verified-immutable");
	assert.deepEqual(immutable.operations, [], "completed immutable release must be verification-only");

	const mutableFinal = completeFixture(expected, { draft: false, immutable: false });
	await expectHostingFailure(
		"mutable final release",
		() => reconcileHostedRelease({ mode: "repair", identity, expected, adapter: mutableFinal, notes }),
		/not protected by immutable releases/,
	);
	assert.deepEqual(mutableFinal.operations, [], "mutable final release must not be edited");

	const incompleteFinal = completeFixture(expected.slice(0, 3), { draft: false, immutable: true });
	await expectHostingFailure(
		"incomplete immutable release",
		() => reconcileHostedRelease({ mode: "repair", identity, expected, adapter: incompleteFinal, notes }),
		/must contain exactly 4/,
	);
	assert.deepEqual(incompleteFinal.operations, [], "incomplete final release must not be edited");

	const wrongTag = completeFixture(expected);
	wrongTag.release.tag_name = "v9.9.9";
	await expectHostingFailure(
		"release tag mismatch",
		() => reconcileHostedRelease({ mode: "repair", identity, expected, adapter: wrongTag, notes }),
		/tag does not match/,
	);

	const requests = [];
	const draftLookup = new GitHubReleaseAdapter({
		repository: "fullofcaffeine/reflaxe.ruby",
		token: "test-token",
		fetchImpl: async (url) => {
			requests.push(url);
			if (url.endsWith(`/releases/tags/${identity.gitTag}`)) {
				return new Response("not found", { status: 404 });
			}
			if (url.endsWith("/releases?per_page=100&page=1")) {
				return Response.json([{ ...releaseRecord(), tag_name: "untagged-deadbeef" }]);
			}
			return new Response("unexpected request", { status: 500 });
		},
	});
	const rediscoveredDraft = await draftLookup.getRelease(identity.gitTag);
	assert.equal(rediscoveredDraft?.draft, true, "authenticated list lookup must rediscover a draft omitted by tag lookup");
	assert.equal(requests.length, 2, "draft lookup must use one tag request and one bounded list page");

	console.log("[release-hosting] OK: 12 creation, draft binding, lookup, repair, verification, and immutability states");
} finally {
	rmSync(tempRoot, { recursive: true, force: true });
}
