# DeviseHx Adoption

- Gem: `devise`
- Version: `5.0.0`
- Runtime owner: Devise, Warden, Rails routes, Rails controllers, and Bundler.
- Haxe owner: app-local typed auth contracts under `src_haxe/app/auth`.

DeviseHx does not replace Devise. It records deterministic app metadata and emits typed Haxe contracts that call normal Rails/Devise helpers.

## Scopes

### User

- Scope: `user`
- Route resource: `users`
- Modules: `database_authenticatable`, `registerable`, `recoverable`, `rememberable`, `validatable`
- Schema status: `ok`
- Generated contract: `app.auth.UserAuth`
- Typed helpers: `current`, `currentRequired`, `signedIn`, `signIn`, `signOut`, `authenticate`.

## Review Checklist

- Keep Devise installation, initializer, migrations, and route macros in Rails unless a later Haxe-owned route slice explicitly takes ownership.
- Run `bundle exec rake hxruby:routes` after changing Devise routes so route externs keep using Rails as the helper oracle.
- Run `bundle exec rake hxruby:compile` and Rails request/browser tests after changing auth boundaries.
- Treat missing/dynamic Devise metadata as a generator failure or explicit unsafe seam, not as `Dynamic` app code.
