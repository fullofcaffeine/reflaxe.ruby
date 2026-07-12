const { readFileSync, writeFileSync } = require("node:fs");
const { join } = require("node:path");
const semver = require("semver");

const DEVELOPMENT_VERSION = "0.0.0";
const HAXELIB_RELEASE_NOTE = "Development sentinel; release identity is injected only into staged artifacts.";

function releaseIdentity(version, gitTag, sourceSha) {
  if (semver.valid(version) !== version || semver.parse(version).build.length > 0) {
    throw new Error(`Release version must be canonical SemVer without build metadata: ${JSON.stringify(version)}`);
  }
  if (gitTag !== `v${version}`) {
    throw new Error(`Release tag ${JSON.stringify(gitTag)} must exactly match v${version}`);
  }
  if (!/^[0-9a-f]{40}$/.test(sourceSha)) {
    throw new Error(`Release source SHA must be 40 lowercase hexadecimal characters: ${JSON.stringify(sourceSha)}`);
  }
  return Object.freeze({ version, gitTag, sourceSha });
}

function identityFromArgs(args) {
  if (args.length !== 3) {
    throw new Error("Expected release identity arguments: <version> <vTag> <40-character-source-SHA>");
  }
  return releaseIdentity(...args);
}

function developmentIdentity(sourceSha) {
  return releaseIdentity(DEVELOPMENT_VERSION, `v${DEVELOPMENT_VERSION}`, sourceSha);
}

function stageHaxelibMetadata(root, identity) {
  const path = join(root, "haxelib.json");
  const metadata = JSON.parse(readFileSync(path, "utf8"));
  metadata.version = identity.version;
  metadata.releasenote = `${identity.gitTag} from ${identity.sourceSha}: See CHANGELOG.md`;
  writeFileSync(path, `${JSON.stringify(metadata, null, 2)}\n`);
}

function stageRubyVersion(root, identity) {
  const path = join(root, "lib", "hxruby", "version.rb");
  const original = readFileSync(path, "utf8");
  const pattern = /^\s*VERSION\s*=\s*"[^"]+"\s*$/m;
  if (!pattern.test(original)) throw new Error(`Missing HXRuby::VERSION in ${path}`);
  writeFileSync(path, original.replace(pattern, `  VERSION = "${identity.version}"`));
}

function stageProvenance(root, identity) {
  writeFileSync(join(root, "release-provenance.json"), `${JSON.stringify(identity, null, 2)}\n`);
}

module.exports = {
  DEVELOPMENT_VERSION,
  HAXELIB_RELEASE_NOTE,
  developmentIdentity,
  identityFromArgs,
  releaseIdentity,
  stageHaxelibMetadata,
  stageProvenance,
  stageRubyVersion,
};
