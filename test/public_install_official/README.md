# Public-install official representative lane

This fixture set proves three bounded official Haxe source families through an
isolated installation of the release-shaped `reflaxe.ruby` ZIP. It is a tracer
bullet, not full Haxe target qualification.

- `official/unit/TestOps.hx` and `official/unit/issues/Issue10098.hx` are
  byte-identical Haxe 4.3.7 sources at the commit pinned in `manifest.json`.
- `StringBuf.unit.hx` is reused from the active unitstd lane and remains
  honestly classified as formatter-normalized rather than unmodified.
- `harness/unit/Test.hx` replaces only the upstream utest runner. Expected
  values remain in the official sources.

The owning command builds the public package shape, installs it into a new
temporary Haxelib repository, rejects checkout classpaths, checks every emitted
Ruby file, runs MRI, and preserves machine/human reports plus generated output
under `test/.generated/public_install_official`.

Run `npm run test:public-install-official` for a cold package build or
`npm run test:public-install-official:reuse` immediately after the canonical
Haxelib package gate. The latter still creates a fresh consumer and Haxelib
repository; it reuses only the already verified artifact bytes.

The success mode executes 65 assertions from the selected official top-level
class. Two additional invocations of the same generated `run.rb` deliberately
fail through the typed assertion harness and a target-runtime exception. This
proves process failures are observable without inventing separate probe-only
compiler paths.
