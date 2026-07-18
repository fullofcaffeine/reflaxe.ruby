# RailsHx Development Loop

Generated RailsHx apps have one preferred development command:

```bash
bin/railshx-dev
```

The script delegates to the dependency-free built-in runner:

```bash
bundle exec rake hxruby:dev
```

The runner compiles the server and client HXML targets once, starts Rails, and
starts one coordinated watcher. `bundle exec rake hxruby:start:watch`,
`WATCH=1 bundle exec rake hxruby:start`, and
`bundle exec rake 'hxruby:start[watch]'` remain compatibility aliases for the
same loop.

## Rebuild Behavior

The watcher is change-aware rather than a compile timer:

1. Discover each target's build HXML, included HXML files, `-cp` /
   `--class-path` roots, `.haxerc`, and the transitively referenced local
   `haxe_libraries/*.hxml` resolver files.
2. Take the first source snapshot after the successful initial builds.
3. Stay idle while those inputs are unchanged.
4. Coalesce an edit burst for the configured debounce window.
5. Rebuild each affected target once. A path shared by the server and client
   targets rebuilds both once.
6. Report a failed rebuild without terminating the watcher, so the next source
   edit can recover.

`hxruby:dev` tells its child watcher to skip its own initial compile because the
runner has already built both targets before Rails starts. This removes the old
duplicate initial server/client builds. It also replaces the old two-watcher
process layout with one scheduler, so shared edits are coalesced consistently.

Standalone target loops remain available:

```bash
bundle exec rake hxruby:watch          # server target
bundle exec rake hxruby:watch:client   # client target
bundle exec rake hxruby:watch:all      # coordinated server + client targets
```

Each standalone task compiles its target once before watching.

## Configuration

The packaged watcher uses Ruby's standard library and works without Foreman,
Overmind, or a native filesystem-watcher gem.

| Variable | Default | Meaning |
| --- | --- | --- |
| `HXRUBY_HXML` | `build.hxml` | Server build contract |
| `HXRUBY_CLIENT_HXML` | `build-client.hxml` | Client build contract |
| `HXRUBY_WATCH_INTERVAL` | `0.2` | Snapshot interval in seconds; must be positive |
| `HXRUBY_WATCH_DEBOUNCE` | `0.1` | Edit-burst debounce in seconds; may be zero |
| `HXRUBY_WATCH_PATHS` | empty | Extra paths shared by all targets |
| `HXRUBY_SERVER_WATCH_PATHS` | empty | Extra server-only paths |
| `HXRUBY_CLIENT_WATCH_PATHS` | empty | Extra client-only paths |

Extra path lists accept the platform path separator or commas. They exist for
macros that deliberately read app-local files which cannot be inferred from
HXML. Keep generated output roots out of these lists, or an output rewrite may
correctly look like another input edit.

For example:

```bash
HXRUBY_WATCH_INTERVAL=0.1 \
HXRUBY_WATCH_DEBOUNCE=0.15 \
HXRUBY_SERVER_WATCH_PATHS=sig,config/typed_inputs \
bin/railshx-dev
```

Missing build HXML files and invalid timing values fail before the long-running
loop starts. Missing explicitly configured extra paths remain in the snapshot,
so creating them later triggers a rebuild.

## Direct Compiles And Haxe Servers

One-shot development, test, CI, and production commands still invoke the Haxe
compiler directly. The watcher optimizes the common loop by eliminating idle
and duplicate compiles; it does not claim a persistent `haxe --wait` compiler
server.

The sibling `haxe.elixir.codex` project demonstrates that a managed Haxe server
can reduce warm compile work further, but it also owns port selection, toolchain
shim compatibility, process-tree cleanup, crash recovery, stale-server
identity, and dedicated integration/performance evidence. RailsHx should add
that lifecycle only as a separately tested optimization, not as an incomplete
port-spawning shortcut in the Rake task.

## Repository Todoapp

The dogfood app exposes the same one-command shape:

```bash
rake todoapp:dev
```

It prepares the disposable Rails app once, starts Rails, skips the child
watcher's duplicate initial compile, and debounces repository Haxe/HHX/client
changes. Its polling controls are expressed in milliseconds because the
watcher is Node-owned:

```bash
HXRUBY_WATCH_INTERVAL_MS=200 \
HXRUBY_WATCH_DEBOUNCE_MS=100 \
rake todoapp:dev
```

`rake todoapp:start:watch`, `WATCH=1 rake todoapp:start`, and
`rake 'todoapp:start[watch]'` remain aliases.
