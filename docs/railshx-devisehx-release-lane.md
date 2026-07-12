# DeviseHx Release Lane

DeviseHx is currently an incubated companion layer inside the
`reflaxe.ruby` haxelib and the `hxruby` Ruby gem generator bridge. The public
contract is intentionally conservative: Devise, Warden, Rails, and Bundler own
runtime authentication; DeviseHx owns typed Haxe contracts, deterministic
inventory, generated app-local auth scopes, HHX helpers, route parity checks,
and release gates around those seams.

This document is the package/release checklist for `haxe.ruby-bjv.6.4.10`.
It defines what ships today, what must stay green in CI, and what has to be
true before splitting DeviseHx into a standalone `devisehx` haxelib or
`hxruby-devise` gem.

## Current Packaging

Today DeviseHx ships as part of the main packages:

- Haxe API: `std/devisehx/**` is included in the fixed local artifact `dist/reflaxe.ruby-release.zip`; the hosted asset receives its versioned name from the selected tag identity.
- Ruby generator bridge: `hxruby` exposes `hxruby:adopt` and
  `bin/rails generate hxruby:adopt --gem devise`.
- Runtime dependency ownership: Rails apps keep `gem "devise"` in their own
  `Gemfile`; neither `reflaxe.ruby` nor `hxruby` declares a Devise runtime
  dependency.
- App-local metadata: adoption writes `.railshx/gems/devise/inventory.json`,
  `.railshx/gems/devise/diagnostics.json`, generated Haxe contracts, and
  `docs/railshx/gems/devise.md` under manifest/header ownership.

The current package checks must continue to prove that the Haxe DeviseHx API
ships in the haxelib archive, while the gem package remains dependency-light
and Rails-owned at runtime.

## Supported CI Lanes

DeviseHx release confidence comes from these existing gates:

- `npm run test:devisehx-core` covers typed auth scopes, HHX helpers,
  sanitizer helpers, mailer/test-helper seams, model module/schema validation,
  negative compile diagnostics, and app-facing `Dynamic` checks.
- `npm run test:devisehx-controller` covers lifecycle filters,
  `currentRequired` flow analysis, strict skipped-action behavior, and
  generated Rails controller output.
- `npm run test:rails-adopt-generator` covers deterministic Devise inventory,
  generated contracts, HHX view skeletons, diagnostics, ownership docs, and
  committed snapshots for reviewable output.
- `npm run test:routes-generator` and `npm run test:routes-dsl` cover Devise
  route helper sync and Haxe-owned `DeviseRoutes.deviseFor(...)` parity.
- `npm run test:todoapp-rails`, `npm run test:todoapp-playwright`, and
  `npm run test:todoapp-production` keep the dogfood Rails app, browser flow,
  and deployable boot lane honest.
- `npm run test:rails-runtime` runs the Rails runtime seam tests across Ruby
  `3.2`, `3.3`, and `4.0` in CI. The todoapp Gemfile fixture uses
  `gem "devise", ">= 4.9"` so Bundler, not RailsHx, selects the concrete
  Devise runtime version for the supported Rails/Ruby lane.
- `npm run test:haxelib-package`, `npm run test:gem-package`, and
  `npm run ci:release-contracts` keep package contents, version metadata, and
  release docs synchronized.

These gates test the RailsHx layer rather than Devise internals. Do not add a
Devise password/session/hash matrix here unless RailsHx starts owning that
runtime behavior.

## Security And Escape-Hatch Contract

DeviseHx unsafe boundaries are auditable and opt-in:

- `DeviseModule.unsafeCustom(...)` is for custom Devise modules that cannot be
  proven from the known module set.
- `DeviseParams.unsafePermit(...)` is for literal extra sanitizer keys that are
  intentionally outside typed model field refs.
- `WardenAccess.unsafeWarden(...)` is a lower-level Warden escape.
- `DeviseRoutes.uncheckedRuby(...)` is for unsupported route shapes and must
  stay out of canonical examples.
- Existing Devise ERB remains Rails-owned unless `--devise-hhx-views` or a
  future manifest-backed force/repair flow explicitly transfers ownership.

Any new unsafe DeviseHx surface must update
[`railshx-escape-hatch-security-audit.md`](railshx-escape-hatch-security-audit.md),
add a focused compile/generator/runtime test, and use a searchable unsafe or
unchecked name.

## Standalone Split Criteria

Keep DeviseHx incubated in this repo until all of these are true:

- The incubated API has passed at least one public beta cycle without changing
  app-local generated contract metadata in a breaking way.
- The supported Devise/Rails/Ruby matrix is documented with exact known-good
  versions and CI coverage.
- The split package has its own `haxelib.json` or equivalent package metadata,
  README, changelog, license, and release workflow.
- The Ruby bridge is either still supplied by `hxruby` or moved into a separate
  `hxruby-devise` gem with generator/task entrypoints and no hidden runtime
  ownership of Devise.
- The dogfood app and generator snapshots can run against the split dependency
  instead of a monorepo classpath.
- Migration guidance exists for apps using the incubated `std/devisehx/**`
  namespace.

Until then, release notes should describe DeviseHx as "incubated in
`reflaxe.ruby`/`hxruby`" and point users at
[`railshx-devisehx-design.md`](railshx-devisehx-design.md),
[`railshx-gem-layers.md`](railshx-gem-layers.md), and
[`railshx-gem-layer-testing.md`](railshx-gem-layer-testing.md).
