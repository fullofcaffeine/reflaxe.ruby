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
        routes: "haxe",
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
          parser.on("--routes MODE", "Route mode: haxe, snippet, rails, or none") { |value| options[:routes] = value }
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
        @route_mode = validate_route_mode(options.fetch(:routes))
        @force = options.fetch(:force)
      end

      def run
        write("build.hxml", render_build)
        write("build-client.hxml", render_client_build)
        write(".haxerc", render_haxerc)
        write("AGENTS.md", render_agents)
        write("haxe_libraries/genes.hxml", render_genes_hxml)
        write("haxe_libraries/helder.set.hxml", render_helder_set_hxml)
        write(File.join(@source_dir, "#{@main_class}.hx"), render_main)
        write(File.join(@source_dir, "client", "Boot.hx"), render_client_boot)
        write(File.join(@source_dir, "controllers", "HomeController.hx"), render_home_controller)
        write(File.join(@source_dir, "views", "ApplicationLayoutView.hx"), render_application_layout_view)
        write(File.join(@source_dir, "views", "HomeIndexView.hx"), render_home_index_view)
        write_route_files
        write("docs/railshx/gem_layers.md", render_gem_layers_doc)
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

      def validate_route_mode(value)
        mode = value.to_s
        return mode if %w[haxe snippet rails none].include?(mode)

        raise Error, "Invalid --routes #{value.inspect}. Expected haxe, snippet, rails, or none."
      end

      def write_route_files
        case @route_mode
        when "haxe"
          write(File.join(@source_dir, "routes", "AppRoutes.hx"), render_app_routes)
          write(File.join(@source_dir, "routes", "Routes.hx"), render_routes)
        when "rails"
          write(File.join(@source_dir, "routes", "Routes.hx"), render_routes)
        when "snippet"
          write(File.join(@source_dir, "routes", "Routes.hx"), render_routes)
          write("docs/railshx/routes.md", render_routes_snippet)
        when "none"
          # Deliberately leave route source/helper files alone. This is useful
          # for apps that already have a separate route ownership policy.
        end
      end

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
        when /\Ahaxe_libraries\//
          "haxe_dependency"
        when ".haxerc"
          "haxe_config"
        when /\Aapp\/javascript\//
          "client_js"
        when /\Aapp\/assets\//
          "asset"
        when /\Aconfig\//
          "rails_config"
        when /\Adocs\//
          "docs"
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
          "-cp ${HXRUBY_GEM_ROOT}/std",
          "# HXRUBY_GEM_ROOT is set by the generated rake tasks so client code can",
          "# consume typed RailsHx/Turbo/Async std helpers from the packaged gem.",
          "# Genes emits split ES modules that Rails can serve through importmap/Propshaft.",
          "# The generated haxe_libraries/genes.hxml points at the packaged hxruby root.",
          "-lib genes",
          "-D js-es=6",
          "--macro genes.Generator.use()",
          "--macro addMetadata('@:genes.disableNativeAccessors', 'haxe.Exception')",
          "-main client.Boot",
          "-js app/javascript/railshx/app.js",
          "-D source-map",
          "-D js-unflatten",
          "--dce=full",
          "",
        ].join("\n")
      end

      def render_haxerc
        [
          "{",
          '  "version": "4.3.7",',
          '  "resolveLibs": "scoped"',
          "}",
          "",
        ].join("\n")
      end

      def render_agents
        [
          "# RailsHx App Agent Instructions",
          "",
          "This Rails app uses RailsHx: Haxe/HHX is the typed source for generated Ruby, ERB, routes, migrations, and client JavaScript where this app has explicitly chosen Haxe ownership. Rails still owns runtime tasks such as `bin/rails db:migrate`, `bin/rails test`, Zeitwerk, ActionCable, Turbo, and assets.",
          "",
          "## Development Loop",
          "",
          "- Prefer `bundle exec rake hxruby:start` for a one-command compile-and-run loop.",
          "- Prefer `bundle exec rake hxruby:start:watch` while editing Haxe/HHX/Haxe JS.",
          "- Run `bundle exec rake hxruby:compile`, `bundle exec rake hxruby:compile:client`, `bundle exec rake hxruby:gen:routes`, and Rails tests before landing changes that affect generated artifacts.",
          "- Generated Rails files are build output unless they are explicitly Rails-owned adoption files. Do not hand-edit generated `app/haxe_gen/**`, generated HHX ERB, generated importmap client modules, or RailsHx-owned migration artifacts.",
          "",
          "## RailsHx Authoring Rules",
          "",
          "- Author RailsHx-owned templates as typed HHX, not raw ERB strings. Existing Rails-owned ERB may be consumed through typed adoption contracts.",
          "- Prefer typed refs over strings: route helpers, model fields, params keys, template refs, Turbo stream names/targets, DOM hooks, and generated selectors should come from Haxe constants/macros where available.",
          "- Keep generated Ruby/Rails output recognizable to Rails developers: ordinary controllers, models, migrations, route helpers, templates, Turbo Streams, ActionCable, and tests.",
          "- If a classic Rails/Hotwire app would not need custom JavaScript, timers, manual fetches, post-render repair hooks, or duplicate client-side templates for a behavior, RailsHx should not need them either. Add or improve the typed RailsHx wrapper around the Rails primitive instead.",
          "- For realtime DOM updates, prefer the normal Hotwire shape: render current state on page load, subscribe with typed HHX such as `<turbo_stream_from stream=${...} />`, and broadcast server-rendered typed partials through `TurboStreams.broadcast*To(...)`. Use Haxe JS `Consumer.subscribe(...)` only for custom non-DOM protocols or genuinely client-owned behavior.",
          "- Do not duplicate the same UI in HHX and Haxe JS string/DOM builders. If Rails can render the row/panel partial, broadcast or render that partial.",
          "",
          "## Scope Rule",
          "",
          "- Put future agent guidance in the narrowest inherited `AGENTS.md`: app-specific RailsHx workflow here, upstream compiler/framework rules in the `reflaxe.ruby` repo, and library-specific client/compiler guidance in the relevant dependency docs.",
          "",
        ].join("\n")
      end

      def render_genes_hxml
        [
          "# RailsHx vendors Genes so generated apps get readable ES module output",
          "# without adding a second JavaScript bundler. `hxruby` rake tasks set",
          "# HXRUBY_GEM_ROOT before invoking Haxe.",
          "-cp ${HXRUBY_GEM_ROOT}/vendor/genes/src",
          "-lib helder.set",
          "-D genes=0.4.14",
          "",
        ].join("\n")
      end

      def render_helder_set_hxml
        [
          '# @install: lix --silent download "haxelib:/helder.set#0.3.1" into helder.set/0.3.1/haxelib',
          "-cp ${HAXE_LIBCACHE}/helder.set/0.3.1/haxelib/src",
          "-D helder.set=0.3.1",
          "",
        ].join("\n")
      end

      def render_main
        imports = [
          "import controllers.HomeController;",
          "import views.ApplicationLayoutView;",
          "import views.HomeIndexView;",
        ]
        imports << "import routes.AppRoutes;" if @route_mode == "haxe"
        route_lines = if @route_mode == "haxe"
                        [
                          "\t\tvar routes:Class<AppRoutes> = AppRoutes;",
                          "\t\tSys.println(routes != null);",
                        ]
                      else
                        [
                          "\t\t// Routes are #{@route_mode}-owned for this generated app.",
                        ]
                      end
        [
          *imports,
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
          "\t\tvar layout:Class<ApplicationLayoutView> = ApplicationLayoutView;",
          "\t\tvar home:Class<HomeIndexView> = HomeIndexView;",
          "\t\tSys.println(controller == null);",
          *route_lines,
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
          "import reflaxe.js.Async;",
          "import reflaxe.js.Async.await;",
          "",
          "// Generated RailsHx client entrypoint.",
          "//",
          "// Demonstrates: typed Haxe-authored browser code compiled through Genes",
          "// into Rails importmap-friendly ES modules. `@:async` is read by Genes",
          "// and `await(...)` lowers to native JavaScript `await`, so this remains",
          "// ordinary browser/Turbo code rather than a RailsHx runtime.",
          "class Boot {",
          "\tpublic static function main():Void {",
          "\t\tBrowser.console.log(#{Common.haxe_string("#{@app_name} RailsHx client boot")});",
          "\t\treadySoon();",
          "\t}",
          "",
          "\t@:async",
          "\tstatic function readySoon():Void {",
          "\t\tawait(Async.delay(50));",
          "\t\tBrowser.document.documentElement.setAttribute(\"data-railshx-client\", \"ready\");",
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

      def render_routes_snippet
        [
          "# RailsHx Routes Snippet",
          "",
          "This app was generated with `--routes=snippet`, so RailsHx did not",
          "create `#{File.join(@source_dir, "routes", "AppRoutes.hx")}` or mutate",
          "`config/routes.rb`.",
          "",
          "Choose one route source of truth:",
          "",
          "## Haxe-owned",
          "",
          "Create `#{File.join(@source_dir, "routes", "AppRoutes.hx")}`:",
          "",
          "```haxe",
          "package routes;",
          "",
          "import controllers.HomeController;",
          "import rails.macros.RoutesDsl.*;",
          "",
          "@:railsRoutes",
          "class AppRoutes {",
          "\tstatic final routes = {",
          "\t\troot(to(HomeController, index));",
          "\t};",
          "}",
          "```",
          "",
          "Then run:",
          "",
          "```bash",
          "bundle exec rake hxruby:compile",
          "bundle exec rake hxruby:routes MODE=haxe-owned",
          "```",
          "",
          "## Rails-owned",
          "",
          "Add the route to `config/routes.rb` yourself:",
          "",
          "```ruby",
          "Rails.application.routes.draw do",
          "  root \"home#index\"",
          "end",
          "```",
          "",
          "Then run:",
          "",
          "```bash",
          "bundle exec rake hxruby:routes MODE=rails-owned",
          "```",
          "",
        ].join("\n")
      end

      def render_gem_layers_doc
        [
          "# RailsHx Gem Layers",
          "",
          "Use this file as the app-local template for wrapping installed Ruby/Rails gems with typed Haxe contracts.",
          "",
          "Rails and Bundler still own gem installation and runtime behavior. RailsHx should own only the typed Haxe layer around that gem: externs, mixin/patch contracts, macros, route/helper contracts, tests, and docs.",
          "",
          "## Workflow",
          "",
          "1. Install and configure the Ruby gem normally.",
          "",
          "   ```bash",
          "   bundle add devise",
          "   bin/rails generate devise:install",
          "   bin/rails generate devise User",
          "   ```",
          "",
          "2. Run a deterministic inventory before asking an LLM for help.",
          "",
          "   ```bash",
          "   bin/rails generate hxruby:adopt --gem devise --discover",
          "   bin/rails generate hxruby:adopt --gem devise --write contracts",
          "   ```",
          "",
          "   Capture what RailsHx can prove mechanically: gem version/path, public constants, RBS/YARD signatures, source-defined modules/methods, Rails routes, generated migrations, initializers, model concerns, controller helpers, and test helpers.",
          "",
          "3. Emit or maintain a conservative Haxe skeleton under `src_haxe/interop/gems/<gem_name>`.",
          "",
          "   ```haxe",
          "   package interop.gems.devise;",
          "",
          "   // App-local typed contract around Devise. Keep uncertain APIs marked",
          "   // with TODO/review comments instead of pretending they are safe.",
          "   extern class DeviseHelpers {",
          "     public static function authenticateUser(controller:rails.action_controller.Base):Void;",
          "   }",
          "   ```",
          "",
          "4. Ask an LLM only after the deterministic skeleton exists.",
          "",
          "   Give it this file, the generated `docs/railshx/gems/<gem>.md` inventory, the gem docs/source, and the RailsHx docs for extension contracts/gem layers. Ask it for a patch that follows RailsHx patterns, not for unchecked dynamic code.",
          "",
          "5. Validate the result.",
          "",
          "   ```bash",
          "   bundle exec rake hxruby:compile",
          "   bundle exec rake hxruby:gen:routes",
          "   bin/rails test",
          "   ```",
          "",
          "## Rules",
          "",
          "- Deterministic metadata wins over LLM guesses.",
          "- Missing or unsafe gem paths should fail closed.",
          "- Generated Haxe should compile before it is trusted.",
          "- Uncertain APIs should stay review-marked, not silently become `Dynamic`.",
          "- Popular layers such as Devise can graduate into reusable packages like `devisehx` or `hxruby-devise`; app-local contracts are still useful for project-specific policy.",
          "",
          "See the upstream RailsHx guide: https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/docs/railshx-gem-layers.md",
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
          'pin_all_from "app/javascript/railshx", under: "railshx"',
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
