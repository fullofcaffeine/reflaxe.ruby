# frozen_string_literal: true

require "rake"
require "shellwords"

# Root repository tasks.
#
# RailsHx is a Ruby/Rails-facing project, so app/developer workflows should be
# discoverable through `rake -T` and read naturally to Rails users. Some of the
# implementation remains Node-owned on purpose: Lix is installed through npm in
# this repo, Playwright is a Node tool, and semantic-release is the release
# driver. These Rake tasks are therefore the public Ruby-shaped entrypoints; they
# delegate to Node/Lix only at those boundaries.

def run_cmd(*parts)
  sh(parts.compact.map(&:to_s).map(&:shellescape).join(" "))
end

def node_script(path, *args)
  run_cmd("node", path, *args)
end

def npm_run(script, *args)
  command = ["npm", "run", script]
  command << "--" unless args.empty?
  run_cmd(*command, *args)
end

def ruby_script(path, *args)
  run_cmd("ruby", "-I", "lib", path, *args)
end

def args_env
  Shellwords.split(ENV.fetch("ARGS", ""))
end

desc "Run the full repository test suite"
task :test do
  npm_run("test")
end

namespace :todoapp do
  desc "Compile the RailsHx todoapp into the disposable Rails app"
  task :compile do
    node_script("scripts/rails/todoapp.js", "compile")
  end

  desc "Compile, bundle, prepare DB, and seed the RailsHx todoapp"
  task :prepare do
    node_script("scripts/rails/todoapp.js", "prepare")
  end

  desc "Run the generated RailsHx todoapp server"
  task :server do
    node_script("scripts/rails/todoapp.js", "server")
  end

  desc "Watch RailsHx todoapp Haxe/HHX/client sources and refresh generated Rails artifacts"
  task :watch do
    node_script("scripts/rails/todoapp.js", "watch")
  end

  desc "Run the generated Rails todoapp model/request test suite"
  task :test do
    node_script("scripts/rails/todoapp.js", "test")
  end

  desc "Run the RailsHx todoapp production dogfood smoke"
  task :production do
    node_script("scripts/rails/todoapp.js", "production-smoke")
  end

  desc "Run the RailsHx todoapp Playwright browser sentinel"
  task :playwright do
    npm_run("test:todoapp-playwright")
  end
end

namespace :test do
  namespace :todoapp do
    desc "Run the fast RailsHx todoapp compiler/static smoke"
    task :static do
      npm_run("test:todoapp-rails")
    end

    desc "Run the RailsHx todoapp Playwright browser sentinel"
    task :playwright do
      Rake::Task["todoapp:playwright"].invoke
    end

    desc "Run the RailsHx todoapp production dogfood smoke"
    task :production do
      Rake::Task["todoapp:production"].invoke
    end
  end

  namespace :rails do
    desc "Run the generated Rails integration smoke"
    task :integration do
      npm_run("test:rails-integration")
    end

    desc "Run the mixed Rails/RailsHx interop smoke"
    task :interop do
      npm_run("test:rails-interop")
    end

    desc "Run mandatory Rails runtime lanes"
    task :runtime do
      npm_run("test:rails-runtime")
    end
  end

  desc "Run compiler/codegen snapshot tests"
  task :snapshots do
    npm_run("test:snapshots")
  end

  desc "Run strict-boundary checks"
  task :strict_boundaries do
    npm_run("test:strict-boundaries")
  end

  desc "Run SQL/string policy checks"
  task :sql_string_policy do
    npm_run("test:sql-string-policy")
  end
end

namespace :rails do
  desc 'Generate RailsHx app/adoption files. Pass generator args with ARGS="--output tmp/app --name MyApp"'
  task :app do
    ruby_script("scripts/rails/app.rb", *args_env)
  end

  desc 'Generate typed Rails route externs. Pass args with ARGS="--input routes.txt --output src_haxe/routes/Routes.hx"'
  task :routes do
    ruby_script("scripts/rails/generate-routes.rb", *args_env)
  end

  desc 'Generate a Haxe-authored Rails migration. Pass args with ARGS="AddStatusToTodos status:string"'
  task :migration do
    ruby_script("scripts/rails/migration.rb", *args_env)
  end

  desc 'Generate a Haxe-authored Rails model. Pass args with ARGS="Todo title:string"'
  task :model do
    ruby_script("scripts/rails/model.rb", *args_env)
  end

  desc 'Generate a RailsHx scaffold. Pass args with ARGS="--model Todo --fields title:String --controller"'
  task :scaffold do
    ruby_script("scripts/rails/scaffold.rb", *args_env)
  end

  desc 'Adopt existing Rails/Ruby boundaries. Pass args with ARGS="--service LegacyPriceFormatter"'
  task :adopt do
    ruby_script("scripts/rails/adopt.rb", *args_env)
  end
end

namespace :format do
  desc "Format Haxe sources with haxe-formatter"
  task :haxe do
    run_cmd("bash", "scripts/lint/hx_format_guard.sh", "--write")
  end

  namespace :haxe do
    desc "Check Haxe formatting without rewriting files"
    task :check do
      run_cmd("bash", "scripts/lint/hx_format_guard.sh")
    end
  end
end

namespace :security do
  desc "Run gitleaks against the repository"
  task :gitleaks do
    run_cmd("bash", "scripts/security/run-gitleaks.sh")
  end

  namespace :gitleaks do
    desc "Run gitleaks against staged changes"
    task :staged do
      run_cmd("bash", "scripts/security/run-gitleaks.sh", "--staged")
    end
  end
end

namespace :hooks do
  desc "Install repository-managed git hooks"
  task :install do
    run_cmd("bash", "scripts/hooks/install.sh")
  end
end

namespace :package do
  namespace :haxelib do
    desc "Build the haxelib release zip"
    task :build do
      npm_run("release:haxelib-package")
    end

    desc "Validate the haxelib release package"
    task :test do
      npm_run("test:haxelib-package")
    end
  end

  namespace :gem do
    desc "Build the hxruby gem"
    task :build do
      npm_run("release:gem-package")
    end

    desc "Validate the hxruby gem"
    task :test do
      npm_run("test:gem-package")
    end
  end
end

namespace :ci do
  desc "Check version synchronization across package metadata"
  task :version_sync do
    npm_run("ci:version-sync")
  end

  desc "Check release contract files and workflow expectations"
  task :release_contracts do
    npm_run("ci:release-contracts")
  end
end
