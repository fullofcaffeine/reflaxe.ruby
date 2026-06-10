# hxruby

Ruby runtime support package for generated reflaxe.ruby output.

Responsibilities:

- `HxException` wrapper for Haxe throw-anything semantics.
- `Data.define` compatibility shim for Ruby versions older than 3.2.
- Core helpers for stringification, type names, and enum metadata.
- Future helpers for arrays, strings, hashes, dynamic access, reflection, bytes, JSON, and sys/io surfaces as they graduate from compiler-local snippets.
