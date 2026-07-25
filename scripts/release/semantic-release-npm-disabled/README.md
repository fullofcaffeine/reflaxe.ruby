# Disabled npm registry publisher

RubyHx distributes its ZIP and gem exclusively through immutable GitHub
Releases. Its explicit semantic-release plugin list therefore does not use
`@semantic-release/npm`.

Semantic-release still declares that publisher as a default dependency. This
local package satisfies that unused dependency with fail-closed hooks, avoiding
an unnecessary executable npm-registry publishing tree. If configuration drift
ever selects the plugin, release preparation stops with an actionable error
before contacting a registry.

The package version intentionally matches the compatible upstream dependency
range required by the pinned semantic-release version. Revisit or remove this
replacement when semantic-release stops installing unused default publishers,
when RubyHx adopts a separately reviewed registry lane, or when the upstream
dependency range changes.
