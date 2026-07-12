# Reproducible Release Artifacts

RubyHx publishes two artifacts from one tested commit: the Reflaxe Haxelib ZIP
and the `hxruby` Ruby gem. This contract deliberately follows the established
`haxe.rust` release pattern—canonical Git input, fixed output paths,
deterministic bytes, SHA-256 metadata, and isolated consumer smoke tests. It
does not introduce a second SemVer algorithm. Ruby adds one necessary target
difference: RubyGems must also produce a deterministic gem alongside the ZIP.

## Source and identity

Both builders accept the selected version, canonical `v<SemVer>` tag, and full
tested commit SHA. They extract that SHA with `git archive`; they never collect
files from the checkout. Consequently, dirty tracked files and untracked files
cannot enter a release. Release-only identity is written in temporary staging:

- `haxelib.json`, `lib/hxruby/version.rb`, and the gem specification receive
  the selected version;
- `release-provenance.json` binds the version, tag, and full source SHA;
- tracked `0.0.0` development metadata remains byte-identical.

Release preparation additionally requires the supplied SHA to equal checked-out
`HEAD` and refuses any tracked diff. This is a staging invariant; publication
authorization and exact workflow pins are owned by the next release-protocol
slice.

## Fixed outputs

Release preparation empties `dist/` and must produce exactly:

| Local file | Hosted name |
| --- | --- |
| `dist/reflaxe.ruby-release.zip` | `reflaxe.ruby-<version>.zip` |
| `dist/reflaxe.ruby-release.zip.sha256.json` | `reflaxe.ruby-<version>.zip.sha256.json` |
| `dist/hxruby-release.gem` | `hxruby-<version>.gem` |
| `dist/hxruby-release.gem.sha256.json` | `hxruby-<version>.gem.sha256.json` |

Globs and version-derived local paths are intentionally forbidden. The JSON
sidecar records the exact local and hosted filename, byte count, SHA-256,
version, tag, and source SHA. It is uploaded with its artifact.

## Canonical bytes and content

The ZIP uses the same exactly pinned `fflate` `0.8.3` implementation and
canonical settings as `haxe.rust`: sorted safe UTF-8 paths, fixed timestamp,
Unix regular-file attributes, mode `0644`, and compression level 9. Directory
and file staging modes are normalized before packaging. Symlinks, special
files, duplicate paths, absolute paths, backslashes, empty segments, and path
traversal fail closed.

The gem is built from its isolated Git-derived staging directory with sorted
gemspec files, normalized modes, the source commit timestamp in
`SOURCE_DATE_EPOCH`, `TZ=UTC`, the C locale, and umask `022`. This removes
ambient timestamp, locale, timezone, staging-directory, and umask variation.
The release workflow’s exact Ruby/RubyGems toolchain pin is a separate
publication contract.

Each artifact contains `artifact-manifest.json`. The manifest is the full
content contract, not an advisory inventory: every other regular file appears
once in sorted order with its exact path, byte count, SHA-256, and `0644` mode.
Verification rejects missing, altered, duplicate, extra, unsafe-mode, symlink,
or structurally unsafe content before consumer tests run.

## Gates

Run the focused reproducibility and package-consumer gates with:

```bash
npm run test:release-artifacts
npm run test:haxelib-package
npm run test:gem-package
```

The reproducibility gate performs two complete builds under different time
zones, temp directories, and umasks while package-owned dirty and untracked
checkout contaminants exist. It requires all four output files to be
byte-identical and exercises every fail-closed manifest/path rule. The Haxelib
test installs the exact ZIP into an isolated repository, compiles a consumer,
and executes its Ruby output. The gem test unpacks and installs the exact gem,
then exercises `hxruby` and its Rails task surface. Both validate the sidecar
and embedded manifest before consumption.
