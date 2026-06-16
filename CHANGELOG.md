# [0.1.0-beta.2](https://github.com/fullofcaffeine/reflaxe.ruby/releases/tag/v0.1.0-beta.2) (2026-06-16)

### Notes

* document RailsHx source-of-truth inversion: Haxe-owned greenfield artifacts by default, Rails/Ruby-owned adoption seams through checked typed contracts
* update routing design so Rails-owned `config/routes.rb` and future Haxe-owned route DSLs are both first-class, with Rails route output remaining the helper-name oracle
* track follow-up work for Haxe-owned routes and Genes-style `@:async`/`@:await` client JavaScript
* keep the current package metadata aligned across npm metadata, haxelib metadata, and the Ruby gem version
