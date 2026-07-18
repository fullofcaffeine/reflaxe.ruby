# Performance Viability

This contract does not claim RubyHx or RailsHx outperforms handwritten Ruby,
Rails, another compiler, or another type system. Stable evidence instead answers
a smaller operational question: do representative authoring and
generated-runtime paths finish with bounded time, memory, and output growth on
the maintained stack?

Run the repeatable workload set from the repository root:

```bash
npm run benchmark:stable
```

The command writes `tmp/stable-benchmark.json` and prints a human summary plus
the same JSON to stdout. The canonical production job runs it with
`--require-rails` after the todo app production smoke has prepared its bundle.
Use `--samples 1` for a quick local implementation check; canonical evidence
always uses the default three samples.

## Measured Workloads

| Workload | What it measures |
| --- | --- |
| `rubyhx_cli_compile` | Clean compilation of the maintained multi-file pure-Ruby CLI/library example. |
| `railshx_server_compile` | Clean compilation of the RailsHx todo app's Haxe/HHX server source to Ruby, Rails artifacts, and ERB. |
| `railshx_client_compile` | Clean compilation of the todo app's Haxe client through Genes to JavaScript and source maps. |
| `rubyhx_cli_startup` | Startup and real fixture execution of the generated Ruby CLI. |
| `rails_production_boot` | Production boot of the already prepared generated Rails app through `rails runner`. |

Each sample records elapsed wall time and peak child RSS when the host's
`/usr/bin/time` supports it. Compiler workloads also record generated regular
file count and bytes. The JSON includes the exact Git SHA, OS, architecture,
CPU, available memory, CI image metadata, and Node/npm/Haxe/Ruby versions.

“Cold” means the first clean-output invocation in that process; repeat samples
still clean their outputs but may benefit from operating-system caches. RubyHx
does not currently promise a persistent incremental compiler server, so this
contract does not relabel repeated clean builds as incremental compilation.
The RailsHx development watcher still improves the edit loop materially by
staying idle on unchanged inputs, removing duplicate initial compiles, and
debouncing each affected HXML target. Those rebuilds remain direct Haxe
invocations; a future managed `haxe --wait` claim needs separate lifecycle and
performance evidence.

## Regression Policy

The script's reviewed limits are broad absolute caps intended to catch runaway
compiler work, memory growth, or output explosions. Any cap breach fails the
canonical production job and therefore blocks publication. Small wall-time
changes and high percentage spread do not fail the lane because GitHub-hosted
runner scheduling and hardware vary; maintainers inspect that evidence when
reviewing a release candidate.

This contract deliberately has no benchmark service, historical dashboard, or
tight relative timing gate. It also does not duplicate the Rails request, job,
browser, asset, or production correctness suites. Those mandatory exact-SHA
lanes remain the behavioral evidence. A future public claim about latency,
throughput, allocations, JIT behavior, or relative speed must first add a
purpose-built workload and an appropriately stable threshold.

At release-candidate review, record the exact canonical run URL and its JSON
summary alongside the other release evidence. Numbers from developer machines
are useful for investigation but are not substituted for the canonical Ubuntu
lane.
