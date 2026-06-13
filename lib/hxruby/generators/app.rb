# frozen_string_literal: true

require "optparse"
require_relative "common"

module HXRuby
  module Generators
    class App
      include Common

      DEFAULTS = {
        output: ".",
        name: "RailsHxApp",
        source: "src_haxe",
        main: "Main",
        force: false,
      }.freeze

      def self.run(argv)
        new(parse(argv)).run
      end

      def self.parse(argv)
        options = DEFAULTS.dup
        OptionParser.new do |parser|
          parser.on("--output PATH") { |value| options[:output] = value }
          parser.on("--name NAME") { |value| options[:name] = value }
          parser.on("--source PATH") { |value| options[:source] = value }
          parser.on("--main CLASS") { |value| options[:main] = value }
          parser.on("--force") { options[:force] = true }
        end.parse!(argv)
        options
      end

      def initialize(options)
        @output_dir = File.expand_path(options.fetch(:output))
        @app_name = options.fetch(:name)
        @source_dir = options.fetch(:source)
        @main_class = options.fetch(:main)
        @force = options.fetch(:force)
      end

      def run
        write("build.hxml", render_build)
        write("build-client.hxml", render_client_build)
        write(File.join(@source_dir, "#{@main_class}.hx"), render_main)
        write(File.join(@source_dir, "client", "Boot.hx"), render_client_boot)
        write(File.join(@source_dir, "routes", "Routes.hx"), render_routes)
        write("app/javascript/application.js", render_application_js)
        write("app/assets/stylesheets/application.css", render_application_css)
        write("config/importmap.rb", render_importmap)
        write("lib/tasks/hxruby.rake", render_rake_task)
        write("Procfile.railshx.dev", render_procfile)
        write("bin/railshx-dev", render_dev_runner, executable: true)

        puts "[rails:app] Generated RailsHx app files in #{@output_dir}"
        puts "[rails:app] Next:"
        puts "  bundle exec rake hxruby:compile"
        puts "  bundle exec rake hxruby:compile:client"
        puts "  bin/railshx-dev"
      end

      private

      def write(relative_path, content, executable: false)
        Common.write_file(File.join(@output_dir, relative_path), content, force: @force, executable: executable)
      end

      def render_build
        [
          "-lib reflaxe.ruby",
          "-D ruby_output=.",
          "-D reflaxe_runtime",
          "-D reflaxe_ruby_rails",
          "-cp #{@source_dir}",
          "--macro reflaxe.ruby.CompilerBootstrap.Start()",
          "--macro reflaxe.ruby.CompilerInit.Start()",
          "-main #{@main_class}",
          "",
        ].join("\n")
      end

      def render_client_build
        [
          "-cp #{@source_dir}",
          "# Use `-cp path/to/reflaxe.ruby/std` when consuming RailsHx client std from an installed package.",
          "-main client.Boot",
          "-js app/javascript/railshx/app.js",
          "-D source-map",
          "--dce=full",
          "",
        ].join("\n")
      end

      def render_main
        [
          "class #{@main_class} {",
          "\tstatic function main() {",
          "\t\tSys.println(#{Common.haxe_string("#{@app_name} RailsHx compile")});",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_client_boot
        [
          "package client;",
          "",
          "import js.Browser;",
          "",
          "class Boot {",
          "\tpublic static function main():Void {",
          "\t\tBrowser.console.log(#{Common.haxe_string("#{@app_name} RailsHx client boot")});",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_routes
        [
          "package routes;",
          "",
          "// Run `bundle exec rake hxruby:gen:routes` after adding Rails routes.",
          "//",
          "// Demonstrates: the typed route-helper extern that will be regenerated from",
          "// Rails route output.",
          "// Type safety: generated helpers give Haxe compile-time arity checks instead",
          "// of route strings.",
          "// IntelliSense: editors should complete generated route helpers here after",
          "// route sync.",
          "// Ruby/Rails output: direct calls to Rails route helper methods.",
          '@:native("self")',
          "extern class Routes {",
          "\t// Generated route helpers will be written here.",
          "}",
          "",
        ].join("\n")
      end

      def render_rake_task
        [
          "begin",
          '  require "hxruby/tasks"',
          "rescue LoadError => error",
          '  warn "RailsHx tasks unavailable: #{error.message}"',
          '  warn "Add the hxruby gem or run with the repository checkout on RUBYLIB."',
          "end",
          "",
        ].join("\n")
      end

      def render_application_js
        [
          'import "@hotwired/turbo-rails"',
          'import "railshx/app"',
          "",
        ].join("\n")
      end

      def render_application_css
        [
          "/* RailsHx app stylesheet. Keep app-facing CSS here; generated HHX should emit structure. */",
          "body {",
          "  margin: 0;",
          "}",
          "",
        ].join("\n")
      end

      def render_importmap
        [
          'pin "application"',
          'pin "@hotwired/turbo-rails", to: "turbo.min.js"',
          'pin "railshx/app", to: "railshx/app.js"',
          "",
        ].join("\n")
      end

      def render_procfile
        [
          "rails: bundle exec rails server",
          "haxe: bundle exec rake hxruby:watch",
          "haxe_client: bundle exec rake hxruby:watch:client",
          "",
        ].join("\n")
      end

      def render_dev_runner
        [
          "#!/usr/bin/env bash",
          "set -euo pipefail",
          "",
          "if command -v foreman >/dev/null 2>&1; then",
          "  exec foreman start -f Procfile.railshx.dev",
          "fi",
          "",
          "if command -v overmind >/dev/null 2>&1; then",
          "  exec overmind start -f Procfile.railshx.dev",
          "fi",
          "",
          "echo \"No foreman/overmind found.\"",
          "echo \"Run these in separate terminals:\"",
          "echo \"  bundle exec rails server\"",
          "echo \"  bundle exec rake hxruby:watch\"",
          "echo \"  bundle exec rake hxruby:watch:client\"",
          "",
        ].join("\n")
      end
    end
  end
end
