# frozen_string_literal: true

require "rake"
require "shellwords"
require "hxruby/generators/adopt"
require "hxruby/generators/app"
require "hxruby/generators/routes"
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
            compile_haxe(ENV.fetch("HXRUBY_CLIENT_HXML", "build-client.hxml"))
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

        desc "Compile RailsHx server/client artifacts and start Rails. Use WATCH=1 for server + watchers"
        task :start, [:mode] do |_task, args|
          if truthy?(ENV["WATCH"]) || args[:mode] == "watch"
            start_with_watch
          else
            compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml"))
            compile_haxe(ENV.fetch("HXRUBY_CLIENT_HXML", "build-client.hxml"))
            rails(["server"])
          end
        end

        namespace :start do
          desc "Compile RailsHx server/client artifacts, then run Rails and Haxe watchers together"
          task :watch do
            start_with_watch
          end
        end

        desc "Generate Haxe route externs from Rails routes"
        task :routes do
          Rake::Task["hxruby:gen:routes"].invoke
        end

        desc "Compile RailsHx server/client artifacts and run production Rails checks"
        task :production do
          compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml"))
          compile_haxe(ENV.fetch("HXRUBY_CLIENT_HXML", "build-client.hxml"))
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
            routes = IO.popen("#{rails_command} routes", &:read)
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
      sh(["haxe", hxml].map(&:shellescape).join(" "))
    end

    def rails(args, env: {})
      sh(env.map { |key, value| "#{key}=#{value.to_s.shellescape}" }.concat([rails_command.shellescape, *args.map(&:shellescape)]).join(" "))
    end

    def rake_command
      ENV.fetch("RAKE", "bundle exec rake")
    end

    def start_with_watch
      compile_haxe(ENV.fetch("HXRUBY_HXML", "build.hxml"))
      compile_haxe(ENV.fetch("HXRUBY_CLIENT_HXML", "build-client.hxml"))
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
