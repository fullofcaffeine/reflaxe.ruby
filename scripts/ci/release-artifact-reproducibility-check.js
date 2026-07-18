#!/usr/bin/env node

const {
  chmodSync,
  existsSync,
  lstatSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} = require("node:fs");
const { delimiter, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { tmpdir } = require("node:os");
const {
  canonicalJson,
  verifyArtifactManifest,
  writeArtifactManifest,
} = require("../release/artifact-utils");
const { validateEntryNames } = require("../release/deterministic-zip");

const root = resolve(__dirname, "..", "..");
const version = "0.2.3";
const tag = `v${version}`;
const sourceSha = run("git", ["rev-parse", "HEAD"]).stdout.trim();
const outputNames = [
  "hxruby-release.gem",
  "hxruby-release.gem.sha256.json",
  "reflaxe.ruby-release.zip",
  "reflaxe.ruby-release.zip.sha256.json",
];

function fail(message) {
  throw new Error(`[release-artifact-reproducibility] ${message}`);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    env: options.env ?? process.env,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
    maxBuffer: 128 * 1024 * 1024,
  });
  if (result.status !== 0) throw new Error(`${command} ${args.join(" ")} failed:\n${result.stdout}${result.stderr}`);
  return result;
}

function trackedDiff() {
  return `${run("git", ["diff", "--binary"]).stdout}${run("git", ["diff", "--cached", "--binary"]).stdout}`;
}

/**
 * Put cwd-sensitive Ruby and gem shims ahead of PATH to reproduce version-manager behavior. The
 * Ruby shim delegates only when invoked from the repository, where `.ruby-version` is meaningful;
 * any lookup after entering a staging directory fails. The gem shim always fails because the gem
 * builder must invoke RubyGems through the already selected absolute Ruby executable.
 */
function cwdSensitiveRubyEnvironment(tempRoot, environment) {
  const selectedRuby = run("ruby", ["-rrbconfig", "-e", "print RbConfig.ruby"]).stdout.trim();
  if (selectedRuby.length === 0) fail("selected Ruby did not report its executable path");
  const shimBin = join(tempRoot, "cwd-sensitive-ruby-bin");
  mkdirSync(shimBin);

  const rubyShim = join(shimBin, "ruby");
  writeFileSync(rubyShim, [
    "#!/usr/bin/env node",
    'const { spawnSync } = require("node:child_process");',
    `const repositoryRoot = ${JSON.stringify(root)};`,
    `const selectedRuby = ${JSON.stringify(selectedRuby)};`,
    "if (process.cwd() !== repositoryRoot) {",
    '  process.stderr.write("cwd-sensitive ruby resolver escaped repository context\\n");',
    "  process.exit(86);",
    "}",
    'const result = spawnSync(selectedRuby, process.argv.slice(2), { env: process.env, stdio: "inherit" });',
    "if (result.error) throw result.error;",
    "process.exit(result.status ?? 1);",
    "",
  ].join("\n"));
  chmodSync(rubyShim, 0o755);

  const gemShim = join(shimBin, "gem");
  writeFileSync(gemShim, [
    "#!/usr/bin/env node",
    'process.stderr.write("ambient gem executable must not build release artifacts\\n");',
    "process.exit(87);",
    "",
  ].join("\n"));
  chmodSync(gemShim, 0o755);

  return { ...environment, PATH: `${shimBin}${delimiter}${environment.PATH ?? ""}` };
}

/**
 * Build both upload candidates while varying ambient values that commonly leak into archive
 * bytes. Child processes inherit the selected umask; each builder must normalize its own staging.
 */
function buildPair(environment, umask) {
  const previousUmask = process.umask(umask);
  try {
    const args = [version, tag, sourceSha];
    run("node", ["scripts/release/build-haxelib-package.js", ...args], { env: environment });
    run("node", ["scripts/release/build-gem-package.js", ...args], { env: environment });
  } finally {
    process.umask(previousUmask);
  }
  return Object.fromEntries(outputNames.map((name) => [name, readFileSync(join(root, "dist", name))]));
}

function expectFailure(label, action) {
  try {
    action();
  } catch (_error) {
    return;
  }
  fail(`${label} was accepted`);
}

/** Exercise the verifier independently so every fail-closed rule has a focused fixture, including
 * structural cases that high-level archive extraction APIs normally conceal. */
function verifyManifestFailures(tempRoot) {
  const fixture = join(tempRoot, "manifest-fixture");
  function reset() {
    rmSync(fixture, { force: true, recursive: true });
    mkdirSync(join(fixture, "nested"), { recursive: true });
    writeFileSync(join(fixture, "a.txt"), "a\n");
    writeFileSync(join(fixture, "nested", "b.txt"), "b\n");
    writeArtifactManifest(fixture, "fixture");
    verifyArtifactManifest(fixture, "fixture");
  }

  reset();
  writeFileSync(join(fixture, "a.txt"), "altered\n");
  expectFailure("altered manifest content", () => verifyArtifactManifest(fixture, "fixture"));

  reset();
  writeFileSync(join(fixture, "extra.txt"), "extra\n");
  expectFailure("extra manifest content", () => verifyArtifactManifest(fixture, "fixture"));

  reset();
  rmSync(join(fixture, "nested", "b.txt"));
  expectFailure("missing manifest content", () => verifyArtifactManifest(fixture, "fixture"));

  reset();
  const manifestPath = join(fixture, "artifact-manifest.json");
  const duplicate = JSON.parse(readFileSync(manifestPath, "utf8"));
  duplicate.entries.push(duplicate.entries[0]);
  writeFileSync(manifestPath, canonicalJson(duplicate));
  expectFailure("duplicate manifest path", () => verifyArtifactManifest(fixture, "fixture"));

  reset();
  chmodSync(join(fixture, "a.txt"), 0o755);
  expectFailure("unsafe executable mode", () => verifyArtifactManifest(fixture, "fixture"));

  reset();
  symlinkSync("a.txt", join(fixture, "link.txt"));
  expectFailure("symbolic link", () => verifyArtifactManifest(fixture, "fixture"));

  for (const [label, names] of [
    ["absolute ZIP path", ["/absolute"]],
    ["Windows absolute ZIP path", ["C:/absolute"]],
    ["traversal ZIP path", ["nested/../escape"]],
    ["duplicate ZIP path", ["same", "same"]],
    ["backslash ZIP path", ["nested\\escape"]],
  ]) expectFailure(label, () => validateEntryNames(names));
}

const baselineDiff = trackedDiff();
const tempRoot = mkdtempSync(join(tmpdir(), "hxruby-release-repro."));
const trackedPath = join(root, "haxelib.json");
const untrackedPath = join(root, "runtime", "release-repro-untracked-marker.rb");
if (existsSync(untrackedPath)) fail(`refusing to overwrite existing fixture path: ${untrackedPath}`);
const trackedBytes = readFileSync(trackedPath);
const trackedMode = lstatSync(trackedPath).mode & 0o777;

try {
  // Both contaminants sit under package-owned paths. Staging must still read the tested Git tree,
  // never the dirty checkout or an untracked file.
  writeFileSync(trackedPath, Buffer.concat([trackedBytes, Buffer.from("\nDIRTY_WORKTREE_MARKER\n")]));
  writeFileSync(untrackedPath, "UNTRACKED_WORKTREE_MARKER\n");

  const firstTmp = join(tempRoot, "tmp-one");
  const secondTmp = join(tempRoot, "tmp-two");
  mkdirSync(firstTmp);
  mkdirSync(secondTmp);
  const toolchainEnvironment = cwdSensitiveRubyEnvironment(tempRoot, process.env);
  const first = buildPair({ ...toolchainEnvironment, TZ: "Pacific/Honolulu", LC_ALL: "C", LANG: "C", TMPDIR: firstTmp }, 0o077);
  const second = buildPair({ ...toolchainEnvironment, TZ: "Europe/Helsinki", LC_ALL: "C", LANG: "C", TMPDIR: secondTmp }, 0o022);

  for (const name of outputNames) {
    if (!first[name].equals(second[name])) fail(`${name} changed across timezone, temp directory, or umask`);
  }
  const zipEntries = run("unzip", ["-Z1", join(root, "dist", "reflaxe.ruby-release.zip")]).stdout;
  if (zipEntries.includes("release-repro-untracked-marker.rb") || first["reflaxe.ruby-release.zip"].includes("DIRTY_WORKTREE_MARKER")) {
    fail("dirty or untracked checkout content entered the Haxelib ZIP");
  }
  const unpackRoot = join(tempRoot, "gem-unpack");
  run("gem", ["unpack", join(root, "dist", "hxruby-release.gem"), "--target", unpackRoot]);
  if (existsSync(join(unpackRoot, "hxruby-release", "runtime", "release-repro-untracked-marker.rb"))) {
    fail("untracked checkout content entered the gem");
  }
  if (readFileSync(join(unpackRoot, "hxruby-release", "haxelib.json"), "utf8").includes("DIRTY_WORKTREE_MARKER")) {
    fail("dirty checkout content entered the gem");
  }

  verifyManifestFailures(tempRoot);
} finally {
  writeFileSync(trackedPath, trackedBytes);
  chmodSync(trackedPath, trackedMode);
  rmSync(untrackedPath, { force: true });
  rmSync(tempRoot, { force: true, recursive: true });
}

if (trackedDiff() !== baselineDiff) fail("reproducibility check did not restore the checkout exactly");
console.log("[release-artifact-reproducibility] OK: ZIP and gem are exact across varied environments");
