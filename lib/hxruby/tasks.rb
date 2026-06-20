# frozen_string_literal: true

require "rake"
require "fileutils"
require "json"
require "open3"
require "shellwords"
require "pathname"
require "tempfile"
require "hxruby/generators/adopt"
require "hxruby/generators/app"
require "hxruby/generators/common"
require "hxruby/generators/routes"
require "hxruby/generators/routes_parity"
require "hxruby/generators/scaffold"

module HXRuby
  module Tasks
    extend Rake::DSL

    module_function

    def install
      return if @installed

      namespace :hxruby do
        desc "Compile Haxe sources with HXRUBY_HXML or build.hxml"
        task :compile do
          compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml"))
        end

        namespace :compile do
          desc "Compile Haxe-authored JavaScript with HXRUBY_CLIENT_HXML or build-client.hxml"
          task :client do
            compile_client_haxe(ENV.fetch("HXRUBY_CLIENT_HXML", "build-client.hxml"))
          end
        end

        desc "Repeatedly run hxruby:compile every HXRUBY_WATCH_INTERVAL seconds"
        task :watch do
          watch_task("hxruby:compile")
        end

        namespace :watch do
          desc "Repeatedly run hxruby:compile:client every HXRUBY_WATCH_INTERVAL seconds"
          task :client do
            watch_task("hxruby:compile:client")
          end
        end

        desc "Compile RailsHx server artifacts, then run a Rails task. Use TASK=db:migrate ARGS='...'"
        task :rails do
          task_name = ENV["TASK"] || abort("TASK is required, for example: bundle exec rake hxruby:rails TASK=db:migrate")
          compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml"))
          compile_client_haxe(ENV.fetch("HXRUBY_CLIENT_HXML", "build-client.hxml")) if truthy?(ENV["CLIENT"])
          rails([task_name, *Shellwords.split(ENV.fetch("ARGS", ""))])
        end

        namespace :db do
          desc "Compile RailsHx migration artifacts, then run Rails db:migrate"
          task :migrate do
            compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml"))
            rails(["db:migrate"])
          end

          desc "Compile RailsHx migration artifacts, then run Rails db:prepare"
          task :prepare do
            compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml"))
            rails(["db:prepare"])
          end

          desc "Compile RailsHx migration artifacts, then run Rails db:rollback"
          task :rollback do
            compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml"))
            rails(["db:rollback", *Shellwords.split(ENV.fetch("ARGS", ""))])
          end
        end

        desc "Compile RailsHx server/client artifacts, then run Rails tests"
        task :test do
          compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml"))
          compile_client_haxe(ENV.fetch("HXRUBY_CLIENT_HXML", "build-client.hxml"))
          rails(["test", *Shellwords.split(ENV.fetch("ARGS", ""))])
        end

        desc "Compile RailsHx server/client artifacts and start Rails. Use WATCH=1 for server + watchers"
        task :start, [:mode] do |_task, args|
          if truthy?(ENV["WATCH"]) || args[:mode] == "watch"
            start_with_watch
          else
            compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml"))
            compile_client_haxe(ENV.fetch("HXRUBY_CLIENT_HXML", "build-client.hxml"))
            rails(["server"])
          end
        end

        namespace :start do
          desc "Compile RailsHx server/client artifacts, then run Rails and Haxe watchers together"
          task :watch do
            start_with_watch
          end
        end

        desc "Generate Haxe route externs from Rails routes. MODE=rails-owned|haxe-owned|auto"
        task :routes do
          sync_routes
        end

        desc "Compile RailsHx server/client artifacts and run production Rails checks"
        task :production do
          compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml"))
          compile_client_haxe(ENV.fetch("HXRUBY_CLIENT_HXML", "build-client.hxml"))
          rails(["zeitwerk:check"], env: production_env)
          rails(["assets:precompile"], env: production_env)
        end

        namespace :gen do
          desc "Generate RailsHx app/adoption files in a Rails app"
          task :app do
            args = []
            args += ["--name", ENV["NAME"]] if ENV["NAME"]
            args += ["--source", ENV["SOURCE"]] if ENV["SOURCE"]
            args += ["--main", ENV["MAIN"]] if ENV["MAIN"]
            args += ["--rails-output-root", ENV["RAILS_OUTPUT_ROOT"]] if ENV["RAILS_OUTPUT_ROOT"]
            args += ["--output", ENV["OUTPUT"]] if ENV["OUTPUT"]
            args << "--force" if truthy?(ENV["FORCE"])
            HXRuby::Generators::App.run(args)
          end

          desc "Generate Haxe route externs from Rails routes"
          task :routes do
            output = ENV.fetch("OUTPUT", "src_haxe/routes/Routes.hx")
            package_name = ENV.fetch("PACKAGE", "routes")
            class_name = ENV.fetch("CLASS", "Routes")
            routes = capture_rails_routes
            HXRuby::Generators::Routes.run(["--output", output, "--package", package_name, "--class", class_name], input: routes)
          end

          desc "Generate a Rails-oriented Haxe model/controller scaffold"
          task :model do
            model = ENV["MODEL"] || abort("MODEL is required, for example: rake hxruby:gen:model MODEL=Todo FIELDS=title:String")
            args = ["--model", model]
            args += ["--fields", ENV["FIELDS"]] if ENV["FIELDS"]
            args += ["--validate", ENV["VALIDATE"]] if ENV["VALIDATE"]
            args += ["--output", ENV["OUTPUT"]] if ENV["OUTPUT"]
            args << "--controller" if truthy?(ENV["CONTROLLER"])
            HXRuby::Generators::Scaffold.run(args)
          end

          desc "Adopt existing Ruby/ERB boundaries through typed Haxe wrappers"
          task :adopt do
            args = []
            args += ["--output", ENV["OUTPUT"]] if ENV["OUTPUT"]
            args += ["--package", ENV["PACKAGE"]] if ENV["PACKAGE"]
            args += ["--service", ENV["SERVICE"]] if ENV["SERVICE"]
            args += ["--service-source", ENV["SERVICE_SOURCE"]] if ENV["SERVICE_SOURCE"]
            args += ["--rbs", ENV["RBS"]] if ENV["RBS"]
            args += ["--template", ENV["TEMPLATE"]] if ENV["TEMPLATE"]
            args += ["--extension-source", ENV["EXTENSION_SOURCE"]] if ENV["EXTENSION_SOURCE"]
            args += ["--extension-module", ENV["EXTENSION_MODULE"]] if ENV["EXTENSION_MODULE"]
            args += ["--locals", ENV["LOCALS"]] if ENV["LOCALS"]
            args << "--force" if truthy?(ENV["FORCE"])
            HXRuby::Generators::Adopt.run(args)
          end
        end
      end

      @installed = true
    end

    def gem_root
      File.expand_path("../..", __dir__)
    end

    def rails_command
      ENV.fetch("RAILS", "bin/rails")
    end

    def compile_haxe(hxml)
      env = { "HXRUBY_GEM_ROOT" => gem_root }
      sh(env.map { |key, value| "#{key}=#{value.to_s.shellescape}" }.concat(["haxe", hxml].map(&:shellescape)).join(" "))
    end

    def sync_routes
      mode = ENV.fetch("MODE", "auto")
      unless ["rails-owned", "haxe-owned", "auto"].include?(mode)
        abort("MODE must be rails-owned, haxe-owned, or auto")
      end

      haxe_owned = mode == "haxe-owned" || (mode == "auto" && haxe_owned_routes_available?)
      compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml")) if haxe_owned

      output = ENV.fetch("OUTPUT", "src_haxe/routes/Routes.hx")
      package_name = ENV.fetch("PACKAGE", "routes")
      class_name = ENV.fetch("CLASS", "Routes")
      routes = capture_rails_routes

      unless haxe_owned
        HXRuby::Generators::Routes.run(["--output", output, "--package", package_name, "--class", class_name], input: routes)
        return
      end

      manifest = ENV.fetch("HXRUBY_ROUTES_MANIFEST", ".railshx/routes.haxe.json")
      facts_file = nil
      parity_args = ["--manifest", manifest]
      if route_manifest_has_devise?(manifest)
        facts_file = Tempfile.new(["hxruby-devise-route-facts", ".json"])
        facts_file.write(capture_devise_mapping_facts)
        facts_file.flush
        parity_args += ["--devise-facts", facts_file.path]
      end

      HXRuby::Generators::RoutesParity.run(parity_args, input: routes)
      content = HXRuby::Generators::Routes.render_from_rails_routes(routes, package: package_name, class_name: class_name)
      write_route_extern_atomically(output, content)
    ensure
      facts_file&.close!
    end

    def haxe_owned_routes_available?
      File.file?(".railshx/routes.haxe.json") || File.file?("src_haxe/routes/AppRoutes.hx")
    end

    def capture_rails_routes
      capture_rails_stdout("routes", "Rails route helper extraction")
    end

    def capture_devise_mapping_facts
      code = [
        'require "json"',
        'unless defined?(Devise); warn "Devise is not loaded"; exit 2; end',
        'facts = { mappings: {} }',
        'Devise.mappings.each do |name, mapping|',
        '  model = mapping.to',
        '  facts[:mappings][name.to_s] = {',
        '    name: mapping.name.to_s,',
        '    className: mapping.class_name.to_s,',
        '    path: mapping.path.to_s,',
        '    scopedPath: mapping.scoped_path.to_s,',
        '    fullpath: mapping.fullpath.to_s,',
        '    modelHasDevise: model.respond_to?(:devise_modules)',
        '  }',
        'end',
        'puts JSON.generate(facts)',
      ].join("; ")
      capture_rails_stdout("runner #{code.shellescape}", "Devise mapping facts probe")
    end

    def capture_rails_stdout(command_suffix, description)
      stdout, stderr, status = Open3.capture3("#{rails_command} #{command_suffix}")
      return stdout if status.success?

      abort("#{description} failed with status #{status.exitstatus}:\n#{stderr.empty? ? stdout : stderr}")
    end

    def route_manifest_has_devise?(manifest)
      path = File.expand_path(manifest)
      return false unless File.file?(path)

      payload = JSON.parse(File.read(path))
      contains_devise_declaration?(payload.fetch("declarations", []))
    rescue JSON::ParserError
      false
    end

    def contains_devise_declaration?(declarations)
      declarations.any? do |declaration|
        declaration["kind"] == "deviseFor" || contains_devise_declaration?(declaration.fetch("children", []))
      end
    end

    def write_route_extern_atomically(output, content)
      path = File.expand_path(output)
      root = HXRuby::Generators::Routes.infer_output_root(path)
      if File.exist?(path) && !HXRuby::Generators::Common.owned_file?(path, root)
        raise HXRuby::Generators::Error, "Refusing to overwrite non-RailsHx-owned file #{path}. Re-run with --force only if you intend to take ownership."
      end

      FileUtils.mkdir_p(File.dirname(path))
      tmp = File.join(File.dirname(path), ".#{File.basename(path)}.#{$$}.tmp")
      File.write(tmp, content)
      File.rename(tmp, path)
      HXRuby::Generators::Common.record_manifest_entry(root, path, content, kind: "route_extern", source: "hxruby:routes")
    ensure
      FileUtils.rm_f(tmp) if tmp
    end

    def compile_client_haxe(hxml)
      compile_haxe(hxml)
      rewrite_importmap_module_imports(
        ENV.fetch("HXRUBY_CLIENT_MODULE_ROOT", "app/javascript/railshx"),
        ENV.fetch("HXRUBY_CLIENT_IMPORT_ROOT", "railshx")
      )
    end

    def rails(args, env: {})
      sh(env.map { |key, value| "#{key}=#{value.to_s.shellescape}" }.concat([rails_command.shellescape, *args.map(&:shellescape)]).join(" "))
    end

    def rake_command
      ENV.fetch("RAKE", "bundle exec rake")
    end

    def start_with_watch
      compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml"))
      compile_client_haxe(ENV.fetch("HXRUBY_CLIENT_HXML", "build-client.hxml"))
      puts "[hxruby] Starting Rails server and RailsHx watchers. Press Ctrl-C to stop all processes."
      pids = [
        spawn_shell([rails_command, "server"].map(&:shellescape).join(" ")),
        spawn_shell("#{rake_command} hxruby:watch"),
        spawn_shell("#{rake_command} hxruby:watch:client"),
      ]
      wait_for_processes(pids)
    rescue Interrupt
      puts "\n[hxruby] Stopping Rails server and RailsHx watchers."
      pids&.each { |pid| stop_process_group(pid) }
    end

    def spawn_shell(command)
      puts command
      Process.spawn(command, pgroup: true)
    end

    def wait_for_processes(pids)
      Process.wait2(-1)
    ensure
      pids.each { |pid| stop_process_group(pid) }
      pids.each do |pid|
        Process.wait(pid)
      rescue Errno::ECHILD
        nil
      end
    end

    def stop_process_group(pid)
      pgid = Process.getpgid(pid)
      Process.kill("TERM", -pgid)
    rescue Errno::ESRCH, Errno::ECHILD
      nil
    end

    def production_env
      env = { "RAILS_ENV" => ENV.fetch("RAILS_ENV", "production") }
      env["SECRET_KEY_BASE_DUMMY"] = ENV.fetch("SECRET_KEY_BASE_DUMMY", "1")
      env
    end

    def rewrite_importmap_module_imports(module_root, import_root)
      root = File.expand_path(module_root)
      return unless Dir.exist?(root)

      Dir.glob(File.join(root, "**", "*.js")).each do |path|
        original = File.read(path)
        rewritten = original.gsub(/(from\s+["']|import\s+["']|import\s*\(\s*["'])(\.[^"']+\.js)(["'])/) do
          match = Regexp.last_match
          prefix = match[1]
          specifier = match[2]
          suffix = match[3]
          target = File.expand_path(specifier, File.dirname(path))
          relative_target = Pathname.new(target).relative_path_from(Pathname.new(root)).to_s.sub(/\.js\z/, "")
          "#{prefix}#{import_root}/#{relative_target}#{suffix}"
        end
        File.write(path, rewritten) if rewritten != original
      end
    end

    def watch_task(task_name)
      interval = ENV.fetch("HXRUBY_WATCH_INTERVAL", "1").to_f
      loop do
        Rake::Task[task_name].reenable
        Rake::Task[task_name].invoke
        sleep interval
      end
    end

    def truthy?(value)
      !value.nil? && !["", "0", "false", "no"].include?(value.downcase)
    end
  end
end

HXRuby::Tasks.install
