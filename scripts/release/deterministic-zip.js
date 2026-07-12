#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");
const { zipSync } = require("fflate");

// ZIP stores a timezone-free DOS date. Construct the same local wall-clock value in every process
// so changing TZ cannot change archive bytes. This follows the established haxe.rust release
// implementation rather than maintaining a target-specific ZIP encoder here.
const FIXED_MTIME = new Date(2000, 0, 1, 0, 0, 0);
const FILE_ATTRIBUTES = 0o644 << 16;

function compareEntryNames(left, right) {
  return left < right ? -1 : left > right ? 1 : 0;
}

/**
 * Reject names whose meaning can change while an archive is inspected or extracted. Duplicate
 * rejection happens before `fflate` receives an object, because an object would otherwise hide the
 * duplicate and weaken the artifact-content contract.
 */
function validateEntryNames(names) {
  const seen = new Set();
  for (const name of names) {
    if (
      typeof name !== "string" ||
      name.length === 0 ||
      name.includes("\0") ||
      name.includes("\\") ||
      name.startsWith("/") ||
      /^[A-Za-z]:/.test(name) ||
      name.endsWith("/") ||
      path.posix.normalize(name) !== name ||
      name.split("/").some((segment) => segment === "" || segment === "." || segment === "..")
    ) {
      throw new Error(`Unsafe ZIP entry: ${String(name)}`);
    }
    if (seen.has(name)) throw new Error(`Duplicate ZIP entry: ${name}`);
    seen.add(name);
  }
  return [...names];
}

/**
 * Create the one canonical ZIP representation used for releases: sorted UTF-8 paths, fixed
 * timestamps, normalized regular-file permissions, and the exactly locked compressor. Staging is
 * walked with `lstat` so symlinks and special files fail closed instead of being dereferenced.
 */
function createDeterministicZip(sourceDirectory, outputPath) {
  const root = path.resolve(sourceDirectory);
  if (!fs.statSync(root).isDirectory()) throw new Error(`ZIP source is not a directory: ${sourceDirectory}`);

  const files = [];
  function visit(directory, segments) {
    const entries = fs.readdirSync(directory, { withFileTypes: true })
      .sort((left, right) => compareEntryNames(left.name, right.name));
    for (const entry of entries) {
      const absolute = path.join(directory, entry.name);
      const nextSegments = [...segments, entry.name];
      const name = nextSegments.join("/");
      const stat = fs.lstatSync(absolute);
      if (stat.isSymbolicLink()) throw new Error(`Symlink is forbidden in release ZIP: ${name}`);
      if (stat.isDirectory()) {
        visit(absolute, nextSegments);
      } else if (stat.isFile()) {
        files.push({ absolute, name });
      } else {
        throw new Error(`Special file is forbidden in release ZIP: ${name}`);
      }
    }
  }
  visit(root, []);
  files.sort((left, right) => compareEntryNames(left.name, right.name));
  validateEntryNames(files.map(({ name }) => name));

  const zipEntries = Object.create(null);
  for (const file of files) {
    Object.defineProperty(zipEntries, file.name, {
      enumerable: true,
      value: [fs.readFileSync(file.absolute), {
        level: 9,
        mtime: FIXED_MTIME,
        os: 3,
        attrs: FILE_ATTRIBUTES,
      }],
    });
  }

  const output = path.resolve(outputPath);
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, Buffer.from(zipSync(zipEntries, {
    level: 9,
    mtime: FIXED_MTIME,
    os: 3,
    attrs: FILE_ATTRIBUTES,
  })));
  fs.chmodSync(output, 0o644);
  return output;
}

module.exports = { createDeterministicZip, validateEntryNames };
