# Ruby Authoring Profiles

`reflaxe.ruby` supports two application authoring profiles:

1. **Portable stdlib-first**
2. **Ruby/Rails-first** (`ruby_first`)

Both are supported today.

## Existing Defines

```bash
-D reflaxe_ruby_profile=ruby_first|portable
```

Aliases are also accepted:

```bash
-D reflaxe_ruby_profile=idiomatic   # legacy alias for ruby_first
-D ruby_first
-D ruby_idiomatic
-D ruby_portable
```

The default profile is `ruby_first`. The older `idiomatic` spelling remains accepted for compatibility, but new docs, examples, and tests should prefer `ruby_first`.

These defines are compatibility-stable public inputs. They should be treated as semantic intent and lint/codegen guardrails, not as separate compiler backends.

## Core Model

Profiles are semantic contracts, not prettiness levels.

`reflaxe.ruby` has one compiler pipeline. Profiles should not fork the compiler into unrelated generated-code engines.

Both profiles should emit idiomatic Ruby whenever that is compatible with their contract. `portable` does not mean "unidiomatic Ruby"; it means Haxe semantics win when Haxe behavior conflicts with Ruby or Rails conventions. `ruby_first` means Ruby/Rails shape wins when the compiler has a legitimate target-specific choice.

Use this decision rule:

| Profile | Conflict winner | Use when |
| --- | --- | --- |
| `portable` | Haxe semantics and cross-target reuse | You are porting shared Haxe code, validating std behavior, or want accidental Ruby/Rails coupling surfaced. |
| `ruby_first` | Ruby/Rails conventions | You are writing Ruby-first or Rails-first code and want native Ruby shapes by default. |

For prose and user education, prefer saying **Ruby-first** or **Rails-first**. Keep `idiomatic` only as a compatibility alias.

## Current Approach vs Profile-Based Backends

The current approach is Ruby-specific:

- Use normal Haxe source shape, imports, externs, Rails mode, strict flags, and local metadata to communicate intent.
- Preserve one compiler pipeline because Ruby does not need separate backend engines for these contracts.
- Let both profiles generate idiomatic Ruby where safe.
- Use profile values as semantic guardrails only where the compiler has a real, tested difference.

Avoid turning profiles into broad backend switches.

| Approach | How it works | Benefits | Costs / risks | Recommendation |
| --- | --- | --- | --- | --- |
| Current Ruby approach | Existing `reflaxe_ruby_profile` define records semantic intent; source shape and Rails/interop APIs do most of the work. | Stable public contract; supports mixed projects; avoids `metal` confusion. | The profile must keep earning its existence with real checks or codegen choices. | Keep, but document as one-pipeline semantic intent. |
| Elixir-style no profile define | No global authoring-profile define; docs/examples/strict flags communicate intent. | Minimal config; best for highly mixed apps. | Would churn existing Ruby public contract and aliases. | Not worth changing right now. |
| Separate profile backends | Different generated-code engines per profile. | Clear if the target truly has different runtime models. | Too much complexity for Ruby; encourages false “idiomatic vs unidiomatic” thinking. | Avoid. |

If future profile behavior is added, it should answer “which semantic/lint contract applies?” rather than “which compiler backend should run?”.

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

## `ruby_first`

`ruby_first` is the Ruby-first contract. `idiomatic` is a compatibility alias for this same contract.

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

- It changes compiler or runtime behavior in a way that cannot be represented by `portable`, `ruby_first`, or an optimizer define.
- It has automated tests.
- It has public documentation and "choose this when..." guidance.
- It has a measurable performance or boundary contract.
- It does not duplicate the Ruby-first `ruby_first` contract.

If a future third contract is justified, prefer a Ruby-specific name such as `native` or `rails` over `metal`. Until then, keep performance policy orthogonal with explicit defines.

## Examples

### Portable domain module

This module is portable because it uses Haxe stdlib/domain types and no Ruby/Rails-specific APIs:

```haxe
package shared;

typedef SlugInput = {
  title:String
};

class SlugRules {
  public static function normalize(input:SlugInput):String {
    var value = StringTools.trim(input.title).toLowerCase();
    return StringTools.replace(value, " ", "-");
  }
}
```

Expected Ruby tendency:

- Use ordinary Ruby methods and strings where behavior matches Haxe.
- Keep Haxe-compatible lowering/runtime helpers where Ruby behavior would drift.
- Avoid accidental `ruby.*`, `rails.*`, or raw `__ruby__` dependencies in shared code.

### Ruby/Rails-first edge

This module is Ruby/Rails-first because it intentionally models Rails-owned APIs and layout:

```haxe
package controllers;

import rails.action_controller.Base;
import rails.action_controller.Params;
import shared.SlugRules;

@:native("TodosController")
class TodosController extends Base {
  public function create(params:Params):Void {
    var permitted = params.requirePermit("todo", ["title"]);
    var slug = SlugRules.normalize({ title: permitted.getString("title") });
    redirectTo("/todos/" + slug);
  }
}
```

Expected Ruby tendency:

- Use Rails-friendly constants, paths, params helpers, and method names.
- Call portable domain helpers at the boundary.
- Avoid forcing the whole app into either profile globally.

### Mixed project layout

Recommended layout for many apps:

```text
src_haxe/
  shared/       # portable stdlib-first domain logic
  models/       # Rails-first ActiveRecord surfaces
  controllers/  # Rails-first ActionController surfaces
  interop/      # typed externs to existing Ruby/gems
```

The default `ruby_first` contract is usually the right fit for Rails apps:

```hxml
-D ruby_output=app/haxe_gen
-D reflaxe_runtime
-D reflaxe_ruby_rails
-D reflaxe_ruby_profile=ruby_first
```

Use `portable` intentionally for shared-library and std-parity builds:

```hxml
-D ruby_output=out/ruby
-D reflaxe_runtime
-D reflaxe_ruby_profile=portable
```

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
