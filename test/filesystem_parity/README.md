# Broader-Suite Filesystem Parity

This focused lane complements the direct upstream `sys/io/File.unit.hx`
fixture with Ruby runtime cases from Haxe's broader `tests/sys` suite.

Provenance:

- directory creation, listing, root/stat, and absolute-path behavior are adapted
  from upstream `tests/sys/src/TestFileSystem.hx`;
- copy overwrite and missing-source behavior come from
  `tests/sys/src/io/TestFile.hx`;
- byte reads, seek/tell, and latched EOF behavior come from
  `tests/sys/src/io/TestFileInput.hx`;
- missing file/directory delete catches come from upstream Issue5742.

Run it with:

```bash
npm run test:filesystem-parity
```

The smoke ensures stateless filesystem facades remain direct Ruby
`File`/`Dir`/`FileUtils` operations while the stateful input/output/seek
carriers live under the existing Ruby `Sys` class.
