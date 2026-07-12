const {
  chmodSync,
  lstatSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  statSync,
  writeFileSync,
} = require("node:fs");
const { createHash } = require("node:crypto");
const { join, relative } = require("node:path");
const { spawnSync } = require("node:child_process");

const MANIFEST_NAME = "artifact-manifest.json";
const PROVENANCE_NAME = "release-provenance.json";
const FILE_MODE = 0o644;

/*
 * Shared release-staging primitives. These functions deliberately keep every trust boundary local:
 * source comes from one Git object, staging contains regular files only, the embedded manifest owns
 * the complete tree, and the external sidecar owns the exact upload bytes and release identity.
 */

function canonicalJson(value) {
  return `${JSON.stringify(value, null, 2)}\n`;
}

function sha256Buffer(buffer) {
  return createHash("sha256").update(buffer).digest("hex");
}

function sha256File(path) {
  return sha256Buffer(readFileSync(path));
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd,
    env: options.env,
    encoding: options.encoding === undefined ? "utf8" : options.encoding,
    input: options.input,
    maxBuffer: 128 * 1024 * 1024,
    stdio: [options.input === undefined ? "ignore" : "pipe", "pipe", "pipe"],
  });
  if (result.status !== 0) {
    const stdout = Buffer.isBuffer(result.stdout) ? result.stdout.toString() : result.stdout;
    const stderr = Buffer.isBuffer(result.stderr) ? result.stderr.toString() : result.stderr;
    throw new Error(`${command} ${args.join(" ")} failed (${result.status}):\n${stdout ?? ""}${stderr ?? ""}`);
  }
  return result;
}

/** Extract exactly one Git tree rather than reading the mutable checkout. The subsequent staging
 * walk rejects symlinks and special files before any selected content is packaged. */
function extractGitSource(repoRoot, sourceSha, destination) {
  mkdirSync(destination, { recursive: true });
  const archive = run("git", ["archive", "--format=tar", sourceSha], { cwd: repoRoot, encoding: null }).stdout;
  run("tar", ["-xf", "-", "-C", destination], { input: archive, encoding: null });
}

/** Return the sorted, safe regular-file paths below a staging root. `lstat` is intentional: callers
 * must never silently follow a link supplied by a source tree or staging mutation. */
function walkFiles(root) {
  const files = [];
  function walk(dir) {
    for (const name of readdirSync(dir).sort()) {
      const path = join(dir, name);
      const stat = lstatSync(path);
      const entry = relative(root, path).split("\\").join("/");
      validateArchivePath(entry);
      if (stat.isSymbolicLink()) throw new Error(`Symlink is forbidden in artifact staging: ${entry}`);
      if (stat.isDirectory()) {
        walk(path);
      } else if (stat.isFile()) {
        files.push(entry);
      } else {
        throw new Error(`Non-regular artifact entry is forbidden: ${entry}`);
      }
    }
  }
  walk(root);
  return files;
}

/** Normalize directory traversal and regular-file modes before hashing or archiving so ambient
 * checkout permissions and process umask cannot affect the artifact contract. */
function normalizeTree(root) {
  function normalize(dir) {
    chmodSync(dir, 0o755);
    for (const name of readdirSync(dir).sort()) {
      const path = join(dir, name);
      const stat = lstatSync(path);
      if (stat.isSymbolicLink()) throw new Error(`Symlink is forbidden in artifact staging: ${relative(root, path)}`);
      if (stat.isDirectory()) normalize(path);
      else if (stat.isFile()) chmodSync(path, FILE_MODE);
      else throw new Error(`Non-regular artifact entry is forbidden: ${relative(root, path)}`);
    }
  }
  normalize(root);
}

function validateArchivePath(path) {
  if (!path || path.startsWith("/") || path.includes("\\") || path.split("/").some((part) => part === "" || part === "." || part === "..")) {
    throw new Error(`Unsafe artifact path: ${JSON.stringify(path)}`);
  }
}

/** Write the full staged-tree contract. The manifest excludes itself because recursive self-hashing
 * is impossible; canonical JSON and the outer artifact sidecar own the manifest bytes. */
function writeArtifactManifest(root, artifact) {
  normalizeTree(root);
  const entries = walkFiles(root)
    .filter((path) => path !== MANIFEST_NAME)
    .map((path) => {
      const absolute = join(root, path);
      return { path, bytes: statSync(absolute).size, sha256: sha256File(absolute), mode: "0644" };
    });
  const manifest = { format: 1, artifact, entries };
  writeFileSync(join(root, MANIFEST_NAME), canonicalJson(manifest));
  chmodSync(join(root, MANIFEST_NAME), FILE_MODE);
  return manifest;
}

/** Verify the complete extracted tree before consumer smoke tests. This is stricter than an outer
 * checksum: it reports which content/path/mode contract changed and rejects hidden extra files. */
function verifyArtifactManifest(root, artifact) {
  const manifestPath = join(root, MANIFEST_NAME);
  const manifestStat = lstatSync(manifestPath);
  if (!manifestStat.isFile() || manifestStat.isSymbolicLink() || (manifestStat.mode & 0o777) !== FILE_MODE) {
    throw new Error(`Invalid ${artifact} artifact manifest file type or mode`);
  }
  const manifestText = readFileSync(manifestPath, "utf8");
  const manifest = JSON.parse(manifestText);
  if (manifest.format !== 1 || manifest.artifact !== artifact || !Array.isArray(manifest.entries)) {
    throw new Error(`Invalid ${artifact} artifact manifest header`);
  }
  if (manifestText !== canonicalJson(manifest)) throw new Error(`Non-canonical ${artifact} artifact manifest JSON`);
  const actual = walkFiles(root).filter((path) => path !== MANIFEST_NAME);
  const declared = manifest.entries.map((entry) => entry.path);
  if (new Set(declared).size !== declared.length) throw new Error("Artifact manifest contains duplicate paths");
  for (const entry of manifest.entries) {
    if (
      typeof entry !== "object" ||
      entry === null ||
      typeof entry.path !== "string" ||
      !Number.isSafeInteger(entry.bytes) ||
      entry.bytes < 0 ||
      typeof entry.sha256 !== "string" ||
      !/^[0-9a-f]{64}$/.test(entry.sha256) ||
      entry.mode !== "0644"
    ) {
      throw new Error("Artifact manifest contains an invalid entry contract");
    }
    validateArchivePath(entry.path);
  }
  if (JSON.stringify(declared) !== JSON.stringify(actual)) throw new Error("Artifact manifest path set/order does not match staging tree");
  for (const entry of manifest.entries) {
    const path = join(root, entry.path);
    const stat = statSync(path);
    if ((stat.mode & 0o777) !== FILE_MODE || stat.size !== entry.bytes || sha256File(path) !== entry.sha256) {
      throw new Error(`Artifact manifest mismatch: ${entry.path}`);
    }
  }
  return manifest;
}

/** Bind one fixed local upload candidate to its versioned hosted name and release provenance. */
function writeArtifactSidecar(outPath, hostedName, identity) {
  const sidecar = {
    format: 1,
    localFilename: outPath.split(/[\\/]/).pop(),
    hostedFilename: hostedName,
    bytes: statSync(outPath).size,
    sha256: sha256File(outPath),
    version: identity.version,
    gitTag: identity.gitTag,
    sourceSha: identity.sourceSha,
  };
  const sidecarPath = `${outPath}.sha256.json`;
  writeFileSync(sidecarPath, canonicalJson(sidecar));
  chmodSync(sidecarPath, FILE_MODE);
  return sidecar;
}

module.exports = {
  MANIFEST_NAME,
  PROVENANCE_NAME,
  canonicalJson,
  extractGitSource,
  run,
  sha256File,
  normalizeTree,
  verifyArtifactManifest,
  walkFiles,
  writeArtifactManifest,
  writeArtifactSidecar,
};
