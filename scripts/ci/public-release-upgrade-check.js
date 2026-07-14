#!/usr/bin/env node

const { copyFileSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } = require("node:fs");
const { tmpdir } = require("node:os");
const { delimiter, join, resolve } = require("node:path");
const { spawnSync } = require("node:child_process");
const { sha256File } = require("../release/artifact-utils");

const root = resolve(__dirname, "..", "..");
const baseline = {
  version: "0.4.0",
  tag: "v0.4.0",
  sourceSha: "fef422bd303f3ddae461230c9b34df01210228c3",
  assets: [
    {
      name: "reflaxe.ruby-0.4.0.zip",
      bytes: 1_095_324,
      sha256: "3de7a3133bc2c7032eceb64d03f52de9bdc9b50401690a9ab5912772faf189c3",
    },
    {
      name: "hxruby-0.4.0.gem",
      bytes: 245_760,
      sha256: "3b775ca2f869404e067c861b5f989204ca8aef59f233d6a5448c8a08d3725a65",
    },
  ],
};
const candidateVersion = "1.0.0-rc.1";
const candidateTag = `v${candidateVersion}`;

main().catch((error) => {
  console.error(`[public-upgrade] ERROR: ${error.message}`);
  process.exitCode = 1;
});

async function main() {
  const trackedBefore = trackedDiff();
  const tempRoot = mkdtempSync(join(tmpdir(), "rubyhx-public-upgrade."));
  try {
    const publicAssets = await downloadBaseline(tempRoot);
    const sourceSha = run("git", ["rev-parse", "HEAD"]).stdout.trim();
    run("node", ["scripts/release/build-haxelib-package.js", candidateVersion, candidateTag, sourceSha]);
    run("node", ["scripts/release/build-gem-package.js", candidateVersion, candidateTag, sourceSha]);

    exerciseHaxelibUpgrade(
      tempRoot,
      publicAssets.get("reflaxe.ruby-0.4.0.zip"),
      join(root, "dist", "reflaxe.ruby-release.zip"),
    );
    exerciseGemUpgrade(
      tempRoot,
      publicAssets.get("hxruby-0.4.0.gem"),
      join(root, "dist", "hxruby-release.gem"),
    );
  } finally {
    rmSync(tempRoot, { force: true, recursive: true });
  }

  if (trackedDiff() !== trackedBefore) fail("upgrade rehearsal changed tracked checkout files");
  console.log("[public-upgrade] OK: checksum-verified v0.4.0 ZIP/gem upgraded to current Git-tree artifacts and rolled back");
}

async function downloadBaseline(tempRoot) {
  const assets = new Map();
  const baseUrl = `https://github.com/fullofcaffeine/reflaxe.ruby/releases/download/${baseline.tag}`;
  for (const expected of baseline.assets) {
    const sidecarName = `${expected.name}.sha256.json`;
    const sidecar = JSON.parse((await fetchWithRetry(`${baseUrl}/${sidecarName}`)).toString("utf8"));
    if (
      sidecar.format !== 1
      || sidecar.hostedFilename !== expected.name
      || sidecar.bytes !== expected.bytes
      || sidecar.sha256 !== expected.sha256
      || sidecar.version !== baseline.version
      || sidecar.gitTag !== baseline.tag
      || sidecar.sourceSha !== baseline.sourceSha
    ) {
      fail(`public checksum sidecar identity drifted: ${sidecarName}`);
    }

    const bytes = await fetchWithRetry(`${baseUrl}/${expected.name}`);
    const path = join(tempRoot, expected.name);
    writeFileSync(path, bytes);
    if (statSync(path).size !== expected.bytes || sha256File(path) !== expected.sha256) {
      fail(`public release asset bytes do not match the immutable baseline: ${expected.name}`);
    }
    assets.set(expected.name, path);
  }
  return assets;
}

async function fetchWithRetry(url) {
  let lastError;
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    try {
      const response = await fetch(url, {
        headers: { "User-Agent": "rubyhx-public-upgrade-check" },
        redirect: "follow",
        signal: AbortSignal.timeout(60_000),
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      return Buffer.from(await response.arrayBuffer());
    } catch (error) {
      lastError = error;
      if (attempt < 3) await new Promise((resolvePromise) => setTimeout(resolvePromise, attempt * 1_000));
    }
  }
  throw new Error(`could not download ${url}: ${lastError.message}`);
}

function exerciseHaxelibUpgrade(tempRoot, oldArchive, currentArchive) {
  const extracted = join(tempRoot, "old-haxelib");
  const consumer = join(tempRoot, "haxelib-consumer");
  const source = join(consumer, "src", "Main.hx");
  mkdirSync(join(consumer, "src"), { recursive: true });
  run("unzip", ["-q", oldArchive, "-d", extracted]);
  copyFileSync(join(extracted, "examples", "hello_world", "Main.hx"), source);
  const sourceDigest = sha256File(source);

  run("haxelib", ["newrepo"], { cwd: consumer });
  run("haxelib", ["install", oldArchive, "--skip-dependencies", "--quiet"], { cwd: consumer });
  compileAndRunHaxelib(consumer);

  run("haxelib", ["install", currentArchive, "--skip-dependencies", "--quiet"], { cwd: consumer });
  run("haxelib", ["set", "reflaxe.ruby", candidateVersion], { cwd: consumer });
  compileAndRunHaxelib(consumer);

  run("haxelib", ["set", "reflaxe.ruby", baseline.version], { cwd: consumer });
  compileAndRunHaxelib(consumer);
  if (sha256File(source) !== sourceDigest) fail("Haxelib upgrade changed the packaged handwritten Haxe source");
}

function compileAndRunHaxelib(consumer) {
  const output = join(consumer, "out");
  rmSync(output, { force: true, recursive: true });
  run("haxe", [
    "-D", `ruby_output=${output}`,
    "-D", "reflaxe_runtime",
    "-cp", "src",
    "-lib", "reflaxe.ruby",
    "-main", "Main",
  ], { cwd: consumer });
  const stdout = run("ruby", [join(output, "run.rb")], { cwd: consumer }).stdout.trim();
  if (stdout !== "Hello from reflaxe.ruby") fail(`unexpected installed Haxelib output: ${JSON.stringify(stdout)}`);
}

function exerciseGemUpgrade(tempRoot, oldGem, currentGem) {
  const gemHome = join(tempRoot, "gems");
  const gemBin = join(tempRoot, "bin");
  const appRoot = join(tempRoot, "rails-ownership-consumer");
  const appSource = join(appRoot, "app", "models", "app_owned.rb");
  const driver = join(tempRoot, "write-owned-output.rb");
  mkdirSync(gemHome, { recursive: true });
  mkdirSync(gemBin, { recursive: true });
  mkdirSync(join(appRoot, "app", "models"), { recursive: true });
  writeFileSync(appSource, "class AppOwned; end\n");
  const appSourceDigest = sha256File(appSource);
  writeFileSync(driver, [
    'require "rubygems"',
    'gem "hxruby", ARGV.fetch(0)',
    'require "hxruby/generators/common"',
    'root = ARGV.fetch(1)',
    'class_name = ARGV.fetch(2)',
    'path = File.join(root, "generated", "service.rb")',
    'HXRuby::Generators::Common.write_file(path, "class #{class_name}; end\\n", root: root, kind: "ruby", source: "public-upgrade", header: true)',
    "",
  ].join("\n"));

  run("gem", ["install", "--local", oldGem, "--install-dir", gemHome, "--bindir", gemBin, "--no-document", "--force"]);
  run("gem", ["install", "--local", currentGem, "--install-dir", gemHome, "--bindir", gemBin, "--no-document", "--force"]);
  const currentGemVersion = run("ruby", [
    "-rrubygems/package",
    "-e",
    "print Gem::Package.new(ARGV.fetch(0)).spec.version",
    currentGem,
  ]).stdout.trim();
  const env = {
    ...process.env,
    GEM_HOME: gemHome,
    GEM_PATH: gemHome,
    PATH: `${gemBin}${delimiter}${process.env.PATH}`,
  };

  writeWithGem(driver, baseline.version, appRoot, "FromV04", env);
  assertOwnershipState(appRoot, "FromV04", appSource, appSourceDigest);
  writeWithGem(driver, currentGemVersion, appRoot, "FromCurrent", env);
  assertOwnershipState(appRoot, "FromCurrent", appSource, appSourceDigest);
  writeWithGem(driver, baseline.version, appRoot, "FromV04", env);
  assertOwnershipState(appRoot, "FromV04", appSource, appSourceDigest);
}

function writeWithGem(driver, version, appRoot, className, env) {
  run("ruby", [driver, version, appRoot, className], { env });
}

function assertOwnershipState(appRoot, className, appSource, appSourceDigest) {
  const generated = join(appRoot, "generated", "service.rb");
  const manifest = JSON.parse(readFileSync(join(appRoot, ".railshx", "manifest.json"), "utf8"));
  if (manifest.version !== 1 || manifest.outputs?.length !== 1) fail("ownership manifest did not remain on schema v1");
  if (!readFileSync(generated, "utf8").includes(`class ${className}; end`)) fail(`unexpected generated ownership state for ${className}`);
  if (manifest.outputs[0].sha256 !== sha256File(generated)) fail("ownership manifest checksum does not match generated output");
  if (sha256File(appSource) !== appSourceDigest) fail("gem upgrade changed handwritten app source");
}

function trackedDiff() {
  return `${run("git", ["diff", "--binary"]).stdout}${run("git", ["diff", "--cached", "--binary"]).stdout}`;
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd ?? root,
    env: options.env ?? process.env,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
    maxBuffer: 16 * 1024 * 1024,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    process.stdout.write(result.stdout);
    process.stderr.write(result.stderr);
    throw new Error(`${command} exited ${result.status ?? "without a status"}`);
  }
  return result;
}

function fail(message) {
  throw new Error(message);
}
