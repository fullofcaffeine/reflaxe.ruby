# Ruby Profiles

`reflaxe.ruby` has two public profile contracts:

```bash
-D reflaxe_ruby_profile=idiomatic|portable
```

Aliases are also accepted:

```bash
-D ruby_idiomatic
-D ruby_portable
```

The default profile is `idiomatic`.

## Core Model

Profiles are semantic contracts, not prettiness levels.

Both profiles should emit idiomatic Ruby whenever that is compatible with their contract. `portable` does not mean "unidiomatic Ruby"; it means Haxe semantics win when Haxe behavior conflicts with Ruby or Rails conventions. `idiomatic` means Ruby/Rails shape wins when the compiler has a legitimate target-specific choice.

Use this decision rule:

| Profile | Conflict winner | Use when |
| --- | --- | --- |
| `portable` | Haxe semantics and cross-target reuse | You are porting shared Haxe code, validating std behavior, or want accidental Ruby/Rails coupling surfaced. |
| `idiomatic` | Ruby/Rails conventions | You are writing Ruby-first or Rails-first code and want native Ruby shapes by default. |

## `portable`

`portable` is the Haxe-semantics-first contract.

Expected behavior:

- Preserve Haxe std and core semantics over Ruby convenience when they differ.
- Use Ruby idioms where they are behavior-preserving.
- Prefer runtime helpers when Ruby core behavior would drift from Haxe behavior.
- Keep target-specific imports and raw `__ruby__` usage visible to policy checks.
- Treat `ruby.*` and `rails.*` surfaces as explicit non-portable choices unless an allowlist or boundary policy says otherwise.

Good candidates for portable-specific enforcement include:

- `Array` edge cases such as `splice`, `slice`, negative indexes, and mutation behavior.
- `String` indexing and Unicode-sensitive behavior.
- `Reflect` field access, anonymous object semantics, and `Hash`/object differences.
- `Std.string` formatting for target-native values.
- enum/reflection metadata retention.
- exception normalization where Haxe and Ruby diverge.

## `idiomatic`

`idiomatic` is the Ruby-first contract.

Expected behavior:

- Prefer Ruby-native `Array`, `Hash`, `String`, `Integer`, `Float`, and `Proc`/lambda shapes where safe.
- Prefer snake_case methods and locals, CamelCase constants, keyword arguments, blocks, and Rails-friendly file layout.
- Keep the runtime minimal when Ruby core can provide equivalent behavior.
- Treat `ruby.*`, `rails.*`, and framework-owned abstractions as first-class APIs.
- Preserve Haxe semantics where practical, but do not block useful Ruby/Rails shapes solely because another target would not expose them.

## Why There Is No `metal` Profile

Rust and Go use `metal` because those targets have a meaningful native-performance contract: typed native surfaces, stricter fallback policy, runtime minimization, and measurable hot-path lowering.

Ruby does not have the same profile axis. Ruby performance is mostly shaped by VM/JIT behavior, allocation patterns, dynamic dispatch, gems/C extensions, database/framework IO, and generated code shape. Those concerns should be controlled by optimizer/runtime defines, not by a third semantic profile.

Do not add a public `metal` profile unless all of these are true:

- It changes compiler or runtime behavior in a way that cannot be represented by `portable`, `idiomatic`, or an optimizer define.
- It has automated tests.
- It has public documentation and "choose this when..." guidance.
- It has a measurable performance or boundary contract.
- It does not duplicate the Ruby-first `idiomatic` contract.

If a future third contract is justified, prefer a Ruby-specific name such as `ruby_first`, `native`, or `rails` over `metal`. Until then, keep performance policy orthogonal with explicit defines.

## Optimization Is Orthogonal

Future optimization knobs should not silently change profile semantics.

Examples of acceptable future defines:

```bash
-D reflaxe_ruby_opt=yjit_friendly
-D ruby_frozen_string_literals
-D ruby_no_reflection_metadata
-D ruby_allocation_low
```

These should be documented as optimization or runtime-planning choices, not as profile replacements.

## Admission Rule

Do not add or keep a profile unless it has:

- a real behavior difference,
- automated coverage,
- public docs,
- clear audience guidance,
- migration behavior for conflicts or deprecations.

A profile that only changes the name of an existing behavior adds cognitive load without improving the compiler.
