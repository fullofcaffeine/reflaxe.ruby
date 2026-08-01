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
