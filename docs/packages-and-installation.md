# Packages And Installation

RubyHx has two release artifacts with different consumers:

- the Haxelib-compatible `reflaxe.ruby` ZIP contains the compiler, Haxe std
  surfaces, examples, docs, and vendored Reflaxe;
- the `hxruby` gem contains Ruby runtime helpers, Rails generators/tasks, and
  the browser-safe shared/client Haxe source used by generated Rails apps.

GitHub Releases is currently the sole public distribution host. The ZIP is not
published to the Haxelib registry, and the gem is not pushed to RubyGems.org.
Download the matching SHA-256 sidecar and follow
[Reproducible Release Artifacts](release-artifacts.md) before installing either
artifact.

## Haxelib-Compatible Compiler Package

Build the fixed local artifact:

```bash
rake package:haxelib:build
```

Validate package contents, compile the extracted hello-world fixture, and test
an installed `-lib reflaxe.ruby` consumer:

```bash
rake package:haxelib:test
```

The local build path is `dist/reflaxe.ruby-release.zip`; release hosting gives
the verified bytes a versioned `reflaxe.ruby-<version>.zip` name. Install the
downloaded asset locally with:

```bash
haxelib install ./reflaxe.ruby-<version>.zip --skip-dependencies
```

Installed Ruby-target builds use:

```hxml
-lib reflaxe.ruby
-D ruby_output=out/ruby
-D reflaxe_runtime
-main Main
```

The package follows Reflaxe conventions: source-checkout std overrides under
`std/ruby/_std/**/*.hx` become generated `src/**/*.cross.hx` package entries.
See [Haxelib Packaging](haxelib-packaging.md) for layout, consumer smoke, and
vendored dependency details.

The package includes the vendored Reflaxe revision used by the compiler and the
narrow lazy function-field fix from
[Reflaxe PR #52](https://github.com/SomeRanDev/reflaxe/pull/52). The exact
upstream boundary and replacement rule live in
[`vendor/reflaxe/PATCHES.md`](../vendor/reflaxe/PATCHES.md).

## Ruby Runtime And Rails Tooling Gem

Build the fixed local gem:

```bash
rake package:gem:build
```

Validate contents, `require` paths, task registration, and a local install:

```bash
rake package:gem:test
```

The local build path is `dist/hxruby-release.gem`; release hosting gives the
verified bytes a versioned `hxruby-<version>.gem` name. Install it with:

```bash
gem install --local ./hxruby-<version>.gem --no-document
```

The gem exposes `require "hxruby"` for runtime helpers and
`require "hxruby/tasks"` for Rails-oriented Rake tasks. Plain
`require "hxruby"` has no gem runtime dependencies. The task entrypoint uses
Rake, which is already part of the supported Rails workflow.

Generated Rails apps use normal entrypoints such as:

```bash
bin/rails generate hxruby:install MyApp
bin/rails generate hxruby:routes
bin/rails generate hxruby:scaffold Todo title:String --controller
bundle exec rake hxruby:start:watch
bundle exec rake hxruby:doctor
bundle exec rake hxruby:check
RAILS_ENV=production bundle exec rake hxruby:production
```

See [RailsHx Generator Workflows](railshx-generator-workflows.md) for the full
generator/task surface and ownership rules.

## Browser-Safe RailsHx Client Library

Generated Rails client builds use `-lib railshx.client` plus `-lib genes`.
`railshx.client` exposes shared/browser-safe Haxe sources from the gem/source
layout without pulling Ruby compiler wiring into JavaScript builds. Ruby server
builds continue to use `-lib reflaxe.ruby`.

This client lane still uses Haxe's `-js` typing pipeline, but
`genes.Generator.use()` installs Genes as the final custom emitter instead of
the stock Haxe JavaScript generator. The result is a split ES-module graph for
Rails importmap/Propshaft. Genes is vendored in the package and is never loaded
by the Ruby server runtime. See
[RailsHx Client JavaScript And Genes](railshx-client-javascript.md) for the
complete build, import rewrite, alternative-toolchain, and upgrade contract.

## DeviseHx Packaging Boundary

The incubated typed Devise API ships under `std/devisehx/**` in the compiler
package. The `hxruby` gem is a generator bridge, not an authentication runtime:
Devise remains installed and owned by the Rails app’s Bundler environment.

```bash
bin/rails generate hxruby:adopt --gem devise
```

See [DeviseHx Release Lane](railshx-devisehx-release-lane.md) for the current
contract and the criteria for a future standalone companion package.

## Release Identity

Release preparation stages the ZIP and gem from the exact tested Git commit.
Each archive includes `release-provenance.json` and a full
`artifact-manifest.json`; adjacent SHA-256 JSON sidecars bind the exact hosted
filename and bytes. The gem specification, `HXRuby::VERSION`, staged
`haxelib.json`, Git tag, and provenance must expose the same version/source
identity.

Publication, immutable hosted assets, and repair are documented in:

- [Release Version Policy](release-version-policy.md)
- [Reproducible Release Artifacts](release-artifacts.md)
- [Tested-Commit Publication Workflow](release-publication-workflow.md)
- [Hosted Release Identity And Repair](release-hosting-and-repair.md)
- [Live Release Protocol Evidence](release-live-evidence.md)
