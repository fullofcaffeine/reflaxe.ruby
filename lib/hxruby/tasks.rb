# frozen_string_literal: true

require "rake"
require "shellwords"

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

        namespace :gen do
          desc "Generate RailsHx app/adoption files in a Rails app"
          task :app do
            args = []
            args += ["--name", ENV["NAME"]] if ENV["NAME"]
            args += ["--source", ENV["SOURCE"]] if ENV["SOURCE"]
            args += ["--main", ENV["MAIN"]] if ENV["MAIN"]
            args += ["--output", ENV["OUTPUT"]] if ENV["OUTPUT"]
            args << "--force" if truthy?(ENV["FORCE"])
            sh("#{node_script("app.js")} #{args.map(&:shellescape).join(" ")}")
          end

          desc "Generate Haxe route externs from Rails routes"
          task :routes do
            output = ENV.fetch("OUTPUT", "src_haxe/routes/Routes.hx")
            package_name = ENV.fetch("PACKAGE", "routes")
            class_name = ENV.fetch("CLASS", "Routes")
            sh("#{rails_command.shellescape} routes | #{node_script("generate-routes.js")} --output #{output.shellescape} --package #{package_name.shellescape} --class #{class_name.shellescape}")
          end

          desc "Generate a Rails-oriented Haxe model/controller scaffold"
          task :model do
            model = ENV["MODEL"] || abort("MODEL is required, for example: rake hxruby:gen:model MODEL=Todo FIELDS=title:String")
            args = ["--model", model]
            args += ["--fields", ENV["FIELDS"]] if ENV["FIELDS"]
            args += ["--validate", ENV["VALIDATE"]] if ENV["VALIDATE"]
            args += ["--output", ENV["OUTPUT"]] if ENV["OUTPUT"]
            args << "--controller" if truthy?(ENV["CONTROLLER"])
            sh("#{node_script("scaffold.js")} #{args.map(&:shellescape).join(" ")}")
          end
        end
      end

      @installed = true
    end

    def gem_root
      File.expand_path("../..", __dir__)
    end

    def node_command
      ENV.fetch("NODE", "node")
    end

    def rails_command
      ENV.fetch("RAILS", "bin/rails")
    end

    def node_script(name)
      [node_command, File.join(gem_root, "scripts", "rails", name)].map(&:shellescape).join(" ")
    end

    def compile_haxe(hxml)
      sh(["haxe", hxml].map(&:shellescape).join(" "))
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
