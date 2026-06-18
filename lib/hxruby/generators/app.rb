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
        rails_output_root: "app/haxe_gen",
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
          parser.on("--rails-output-root PATH") { |value| options[:rails_output_root] = value }
          parser.on("--force") { options[:force] = true }
        end.parse!(argv)
        options
      end

      def initialize(options)
        @output_dir = File.expand_path(options.fetch(:output))
        @app_name = options.fetch(:name)
        @source_dir = options.fetch(:source)
        @main_class = options.fetch(:main)
        @rails_output_root = Common.safe_relative_path(options.fetch(:rails_output_root), label: "--rails-output-root")
        @force = options.fetch(:force)
      end

      def run
        write("build.hxml", render_build)
        write("build-client.hxml", render_client_build)
        write(File.join(@source_dir, "#{@main_class}.hx"), render_main)
        write(File.join(@source_dir, "client", "Boot.hx"), render_client_boot)
        write(File.join(@source_dir, "controllers", "HomeController.hx"), render_home_controller)
        write(File.join(@source_dir, "views", "ApplicationLayoutView.hx"), render_application_layout_view)
        write(File.join(@source_dir, "views", "HomeIndexView.hx"), render_home_index_view)
        write(File.join(@source_dir, "routes", "AppRoutes.hx"), render_app_routes)
        write(File.join(@source_dir, "routes", "Routes.hx"), render_routes)
        write("app/javascript/application.js", render_application_js)
        write("app/assets/stylesheets/application.css", render_application_css)
        write("config/importmap.rb", render_importmap)
        write("lib/tasks/hxruby.rake", render_rake_task)
        write("Procfile.railshx.dev", render_procfile)
        write("bin/railshx-dev", render_dev_runner, executable: true)
        write("bin/railshx-prod", render_prod_runner, executable: true)

        puts "[rails:app] Generated RailsHx app files in #{@output_dir}"
        puts "[rails:app] Next:"
        puts "  bundle exec rake hxruby:start"
        puts "  bundle exec rake hxruby:start:watch"
        puts "  bundle exec rake hxruby:gen:routes"
        puts "  bin/railshx-dev"
        puts "  bin/railshx-prod"
      end

      private

      def write(relative_path, content, executable: false)
        Common.write_file(
          File.join(@output_dir, relative_path),
          content,
          force: @force,
          executable: executable,
          root: @output_dir,
          kind: generator_kind(relative_path),
          source: "hxruby:install"
        )
      end

      def generator_kind(relative_path)
        case relative_path
        when /\A#{Regexp.escape(@source_dir)}\//
          "haxe_source"
        when /\Aapp\/javascript\//
          "client_js"
        when /\Aapp\/assets\//
          "asset"
        when /\Aconfig\//
          "rails_config"
        when /\Alib\/tasks\//
          "rake_task"
        when /\Abin\//
          "bin_script"
        else
          "app_scaffold"
        end
      end

      def render_build
        [
          "-lib reflaxe.ruby",
          "-D ruby_output=.",
          "-D reflaxe_runtime",
          "-D reflaxe_ruby_rails",
          @rails_output_root == "app/haxe_gen" ? nil : "-D reflaxe_ruby_rails_output_root=#{@rails_output_root}",
          "-cp #{@source_dir}",
          "--macro reflaxe.ruby.CompilerBootstrap.Start()",
          "--macro reflaxe.ruby.CompilerInit.Start()",
          "-main #{@main_class}",
          "",
        ].compact.join("\n")
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
          "import controllers.HomeController;",
          "import routes.AppRoutes;",
          "import views.ApplicationLayoutView;",
          "import views.HomeIndexView;",
          "",
          "// RailsHx compile sentinel.",
          "//",
          "// The generated app starts with a real typed Rails graph instead of an",
          "// empty Haxe project: a controller, layout, HHX view, and Haxe-owned",
          "// routes. Keeping these classes referenced here means renames fail during",
          "// Haxe compilation before Rails can receive stale generated artifacts.",
          "class #{@main_class} {",
          "\tstatic function main() {",
          "\t\tvar controller:HomeController = null;",
          "\t\tvar routes:Class<AppRoutes> = AppRoutes;",
          "\t\tvar layout:Class<ApplicationLayoutView> = ApplicationLayoutView;",
          "\t\tvar home:Class<HomeIndexView> = HomeIndexView;",
          "\t\tSys.println(controller == null);",
          "\t\tSys.println(routes != null);",
          "\t\tSys.println(layout != null);",
          "\t\tSys.println(home != null);",
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

      def render_home_controller
        [
          "package controllers;",
          "",
          "import rails.action_view.Template;",
          "import rails.macros.ViewMacro;",
          "import views.ApplicationLayoutView;",
          "import views.HomeIndexView;",
          "",
          "typedef HomeIndexLocals = {",
          "\tvar appName:String;",
          "}",
          "",
          "// Generated RailsHx home controller.",
          "//",
          "// Demonstrates: typed ActionController authoring, typed template locals,",
          "// and a typed layout reference. Rails receives normal controller Ruby.",
          "// Type safety: renaming `HomeIndexView`, changing `HomeIndexLocals`, or",
          "// removing the `index` action breaks Haxe compilation before routes/render",
          "// calls can drift.",
          "@:railsController",
          "class HomeController extends rails.action_controller.Base {",
          "\tstatic final lifecycle = [];",
          "",
          "\tpublic function index():Void {",
          "\t\tViewMacro.renderTemplateWithLayout(this, (Template.of(HomeIndexView) : Template<HomeIndexLocals>), {",
          "\t\t\tappName: #{Common.haxe_string(@app_name)}",
          "\t\t}, Template.layout(ApplicationLayoutView));",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_application_layout_view
        [
          "package views;",
          "",
          "import rails.action_view.HtmlNode;",
          "",
          "// Generated RailsHx layout authored as typed HHX.",
          "//",
          "// Demonstrates: Rails layout helpers as Haxe inline markup instead of",
          "// hand-written ERB. The compiler emits `app/views/layouts/application.html.erb`.",
          "@:railsTemplate(\"layouts/application\")",
          "@:railsTemplateAst(\"render\")",
          "class ApplicationLayoutView {",
          "\tpublic static function render():HtmlNode {",
          "\t\treturn <>",
          "\t\t\t<doctype_html />",
          "\t\t\t<html>",
          "\t\t\t\t<head>",
          "\t\t\t\t\t<title>#{@app_name}</title>",
          "\t\t\t\t\t<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\" />",
          "\t\t\t\t\t<csrf_meta_tags />",
          "\t\t\t\t\t<csp_meta_tag />",
          "\t\t\t\t\t<stylesheet_link_tag name=\"application\" data-turbo-track=\"reload\" />",
          "\t\t\t\t\t<javascript_importmap_tags />",
          "\t\t\t\t</head>",
          "\t\t\t\t<body>",
          "\t\t\t\t\t<rails_yield />",
          "\t\t\t\t</body>",
          "\t\t\t</html>",
          "\t\t</>;",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_home_index_view
        [
          "package views;",
          "",
          "import controllers.HomeController.HomeIndexLocals;",
          "import rails.action_view.HtmlNode;",
          "",
          "// Generated RailsHx home page authored as typed HHX.",
          "//",
          "// Demonstrates: inline Rails HHX with typed locals. `locals.appName` is",
          "// checked by Haxe and emitted as normal ERB inside the generated template.",
          "@:railsTemplate(\"controllers/home/index\")",
          "@:railsTemplateAst(\"render\")",
          "class HomeIndexView {",
          "\tpublic static function render(locals:HomeIndexLocals):HtmlNode {",
          "\t\treturn <main class=\"railshx-home\">",
          "\t\t\t<section class=\"railshx-card\">",
          "\t\t\t\t<p class=\"railshx-eyebrow\">RailsHx starter</p>",
          "\t\t\t\t<h1>${locals.appName} is running from typed Haxe.</h1>",
          "\t\t\t\t<p>",
          "\t\t\t\t\tEdit <code>src_haxe/views/HomeIndexView.hx</code>, keep",
          "\t\t\t\t\t<code>bundle exec rake hxruby:start:watch</code> running, and refresh Rails.",
          "\t\t\t\t</p>",
          "\t\t\t</section>",
          "\t\t</main>;",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_app_routes
        [
          "package routes;",
          "",
          "import controllers.HomeController;",
          "import rails.macros.RoutesDsl.*;",
          "",
          "// Haxe-owned Rails routes.",
          "//",
          "// This emits ordinary `config/routes.rb`; route helper externs still come",
          "// from Rails route output via `bundle exec rake hxruby:gen:routes`.",
          "@:railsRoutes",
          "class AppRoutes {",
          "\tstatic final routes = {",
          "\t\troot(to(HomeController, index));",
          "\t};",
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
          "/* RailsHx app stylesheet. Keep app-facing CSS here; generated HHX owns structure. */",
          ":root {",
          "  --railshx-bg: #f6f3eb;",
          "  --railshx-ink: #14211d;",
          "  --railshx-accent: #f9733f;",
          "}",
          "",
          "body {",
          "  margin: 0;",
          "  min-height: 100vh;",
          "  background: radial-gradient(circle at 80% 15%, #fff0d8 0, transparent 28rem), var(--railshx-bg);",
          "  color: var(--railshx-ink);",
          "  font-family: ui-serif, Georgia, Cambria, \"Times New Roman\", serif;",
          "}",
          "",
          ".railshx-home {",
          "  min-height: 100vh;",
          "  display: grid;",
          "  place-items: center;",
          "  padding: 3rem;",
          "}",
          "",
          ".railshx-card {",
          "  max-width: 44rem;",
          "  padding: 3rem;",
          "  border: 1px solid rgba(20, 33, 29, 0.14);",
          "  border-radius: 2rem;",
          "  background: rgba(255, 255, 255, 0.82);",
          "  box-shadow: 0 2rem 5rem rgba(20, 33, 29, 0.12);",
          "}",
          "",
          ".railshx-eyebrow {",
          "  color: var(--railshx-accent);",
          "  font: 700 0.78rem/1.2 ui-sans-serif, system-ui, sans-serif;",
          "  letter-spacing: 0.12em;",
          "  text-transform: uppercase;",
          "}",
          "",
          ".railshx-card h1 {",
          "  margin: 0.25rem 0 1rem;",
          "  font-size: clamp(2.5rem, 7vw, 5rem);",
          "  line-height: 0.9;",
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
          "echo \"Falling back to the built-in RailsHx dev loop.\"",
          "exec bundle exec rake hxruby:start:watch",
          "",
        ].join("\n")
      end

      def render_prod_runner
        [
          "#!/usr/bin/env bash",
          "set -euo pipefail",
          "",
          "export RAILS_ENV=\"${RAILS_ENV:-production}\"",
          "export SECRET_KEY_BASE_DUMMY=\"${SECRET_KEY_BASE_DUMMY:-1}\"",
          "",
          "exec bundle exec rake hxruby:production",
          "",
        ].join("\n")
      end
    end
  end
end
