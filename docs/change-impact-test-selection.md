# Change-impact test recommendations

RubyHx records which stable test commands are expected to observe each kind of
repository change. The recommendation gives developers and agents a quick,
reviewable starting point without allowing a guessed test set to replace the
complete CI safety net.

```text
changed paths -> first matching semantic owner -> selected test shards + reasons
                                             \-> unknown/high-risk -> every backstop
```

Run explain mode for one or more paths:

```bash
npm run test:change-impact-explain -- --path src/reflaxe/ruby/rails/RailsArtifactPlanner.hx
npm run test:change-impact-explain -- --path docs/development.md
```

Use `--base <sha> --head <sha>` to inspect a Git range. The command writes
`test/.generated/change-impact/report.json` and prints every selected and
omitted shard with its reason. The canonical workflow runs this observation
from its full-history security job, but still executes the same complete test,
Rails runtime, browser, production, release-contract, format, compatibility,
and security jobs as before.

## Ownership contract

[`test/change-impact-ownership.json`](../test/change-impact-ownership.json) is
the machine authority. Each shard names its local command, corresponding hosted
job, feedback ring, product surfaces, behavior axes, profiles, timeout, and
artifacts. Its ordered path rules describe the component that owns a change,
not merely the directory where a test happens to live.

The first matching rule names the semantic owner and affected product surfaces;
its selected shards are the recorded reverse dependencies. Compiler core,
runtime, standard library,
profile, test-runner, provenance manifest, package, dependency, workflow,
toolchain, security, release, and unknown paths deliberately expand to every
backstop. More bounded Rails, browser, example, and ordinary documentation
paths can produce focused recommendations. The agent canary and selector
contract are always selected.

The contract test checks representative focused and full-fallback changes:

```bash
npm run test:change-impact-selector
```

## Miss observation and authority

A **selector miss** means a backstop found a failure in a shard the
recommendation omitted. When such a result is known, record it without changing
the original selection:

```bash
npm run test:change-impact-explain -- \
  --path docs/development.md \
  --observed-failure rails-browser
```

The JSON report then includes the omitted failure under `selectorMisses`. This
input is evidence supplied by the unchanged backstop; it is not inferred from
the implementation under test. Hosted explain logs and full-job outcomes can be
correlated as observations, while the checked fixture proves miss detection is
sensitive before a real failure exists.

This slice is intentionally advisory. It does not execute selected commands,
skip omitted commands, add path ignores, change required checks, alter release
dependencies, or claim a miss rate from green runs. Any future blocking
selection requires a separate review backed by timing and miss history, with
full `main`, periodic nightly, and release runs retained.

Because advisory mode does not schedule jobs, a selected-job aggregator is not
yet meaningful. A future affected-only workflow must add an aggregator that
fails unless every required selected job actually ran; that requirement cannot
be satisfied by trusting path filters or the selector report alone.
