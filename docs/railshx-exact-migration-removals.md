# Exact migration removals

Rails can reverse an index or foreign-key removal only when it knows the complete object definition.

Use `RemoveIndexExactly` or `RemoveForeignKeyExactly` when automatic rollback must recreate the removed object. Each operation has two separate records:

- `restoration` defines the object that the down path must add again.
- `removal` contains only removal policy, such as `ifExists`.

RailsHx emits an explicit `reversible` block. The up branch removes the object. The down branch adds it from the restoration record. The `ifExists` guard never reaches the add call.

Use `Irreversible(reason)` when no truthful rollback exists. It is valid only as the sole operation in a `Reversible` down array. RailsHx emits `raise ActiveRecord::IrreversibleMigration, reason`, so Rails stops the rollback with the supplied explanation.

## Evidence and oracle

The contract comes from ActiveRecord 8.1.3.1 migration behavior and its command recorder. A focused Haxe fixture first failed because the three constructors did not exist. The failing command was:

```sh
npm run test:migration-rollback-safety
```

The focused contract now checks generated Ruby and invalid placements. The Rails integration lane creates real SQLite tables, rows, an index, and a foreign key. It removes both objects, rolls back, and checks their restored definitions and retained data. A separate generated migration proves that Rails raises the native irreversibility error and preserves its reason.

SQLite does not expose a custom foreign-key constraint name through its schema inspector. Generated Ruby owns the name check. The runtime check owns the target table, column, cascade action, deferred mode, and preserved row.

## Review disposition

The separate high-risk review found that ActiveRecord carried `if_exists` into an automatic foreign-key restore call. RailsHx now emits explicit up and down branches, which remove that ambiguity. The generated-shape test rejects a restore call that contains `if_exists`.

The review also checked top-level, up-branch, mixed down-branch, and empty-reason failures. The runtime test uses real ActiveRecord and SQLite without a mocked migration boundary. Adapter-specific option parity remains outside this SQLite proof and is not a portable adoption claim.
