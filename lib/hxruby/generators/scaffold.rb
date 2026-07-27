# frozen_string_literal: true

require "optparse"
require_relative "common"
require_relative "controller"
require_relative "test_adapter"

module HXRuby
  module Generators
    class Scaffold
      def self.run(argv)
        new(parse(argv)).run
      end

      def self.parse(argv)
        options = {
          model: nil,
          output: ".",
          fields: "",
          validate: "",
          controller: false,
          routes: "haxe",
          tests: true,
          test_adapter: "minitest",
          hotwire: false,
          force: false,
        }
        OptionParser.new do |parser|
          parser.on("--model NAME") { |value| options[:model] = value }
          parser.on("--output PATH") { |value| options[:output] = value }
          parser.on("--fields FIELDS") { |value| options[:fields] = value }
          parser.on("--validate FIELDS") { |value| options[:validate] = value }
          parser.on("--controller") { options[:controller] = true }
          parser.on("--routes MODE", "Route mode: haxe, snippet, rails, or none") { |value| options[:routes] = value }
          parser.on("--test-adapter ADAPTER", "minitest, rspec, or auto") { |value| options[:test_adapter] = value }
          parser.on("--skip-tests") { options[:tests] = false }
          parser.on("--hotwire", "Generate a typed Rails/Turbo realtime resource contract") { options[:hotwire] = true }
          parser.on("--force") { options[:force] = true }
        end.parse!(argv)
        raise Error, "Missing required argument --model" unless options[:model]

        options
      end

      def initialize(options)
        @model_name = options.fetch(:model)
        @output_dir = File.expand_path(options.fetch(:output))
        @fields = parse_fields(options.fetch(:fields))
        @validations = Common.split_csv(options.fetch(:validate))
        @with_controller = options.fetch(:controller)
        @route_mode = validate_route_mode(options.fetch(:routes))
        @with_tests = options.fetch(:tests)
        @test_adapter = TestAdapter.resolve(options.fetch(:test_adapter), root: @output_dir)
        @with_hotwire = options.fetch(:hotwire)
        @force = options.fetch(:force)
        @table_name = Common.pluralize(Common.file_name(@model_name))
        @controller_name = "#{Common.pluralize(@model_name)}Controller"
        @migration_name = "Create#{Common.pluralize(@model_name)}"
        @resource_name = Common.file_name(@model_name)
        @controller_file = Common.file_name(@controller_name)
        validate_hotwire_options!
      end

      def run
        write("src_haxe/models/#{@model_name}.hx", render_model)
        write("src_haxe/migrations/#{@migration_name}.hx", render_migration)
        write_route_files
        write("test_haxe/models/#{scaffold_test_class}.hx", render_model_test) if @with_tests
        write("src_haxe/Main.hx", render_main)
        write("build.hxml", render_build)
        write_controller if @with_controller
        write_hotwire_files if @with_hotwire
      end

      private

      def validate_hotwire_options!
        return unless @with_hotwire

        raise Error, "--hotwire requires --controller so generated create/index actions own the broadcast and subscription" unless @with_controller
        if @with_tests && @test_adapter != "rails.minitest"
          raise Error, "--hotwire generated broadcast tests currently require --test-adapter minitest; use --skip-tests for an RSpec-owned test seam"
        end
      end

      def validate_route_mode(value)
        mode = value.to_s
        return mode if %w[haxe snippet rails none].include?(mode)

        raise Error, "Invalid --routes #{value.inspect}. Expected haxe, snippet, rails, or none."
      end

      def write_route_files
        case @route_mode
        when "haxe"
          if @with_controller
            write("src_haxe/routes/AppRoutes.hx", render_app_routes)
          end
          write("src_haxe/routes/Routes.hx", render_routes_placeholder)
        when "rails"
          write("src_haxe/routes/Routes.hx", render_routes)
        when "snippet"
          write("src_haxe/routes/Routes.hx", render_routes_placeholder)
          write("docs/railshx/routes_snippet.md", render_routes_snippet)
        when "none"
          # The caller owns route setup elsewhere.
        end
      end

      def parse_fields(raw)
        Common.split_csv(raw).map do |entry|
          name, type = entry.split(":", 2).map(&:strip)
          raise Error, "Invalid field #{entry.inspect}. Expected name:Type." if name.to_s.empty? || type.to_s.empty?

          { name: name, type: type }
        end
      end

      def write(relative_path, content)
        Common.write_file(
          File.join(@output_dir, relative_path),
          content,
          force: @force,
          root: @output_dir,
          kind: generator_kind(relative_path),
          source: "hxruby:scaffold"
        )
      end

      def generator_kind(relative_path)
        case relative_path
        when /\Asrc_haxe\/migrations\//
          "haxe_migration_source"
        when /\Atest_haxe\//
          "haxe_test_source"
        when /\Asrc_haxe\//
          "haxe_source"
        when "build.hxml", "hotwire-hooks.hxml"
          "haxe_build"
        else
          "scaffold"
        end
      end

      def render_model
        lines = [
          "package models;",
          "",
          "@:railsModel(\"#{@table_name}\")",
          "class #{@model_name} extends rails.active_record.Base<#{@model_name}> {",
        ]
        @fields.each do |field|
          lines << "\t@:railsColumn public var #{field.fetch(:name)}:#{field.fetch(:type)};"
        end
        @validations.each do |field_name|
          lines << ""
          lines << "\t@:validates({presence: true})"
          lines << "\tpublic var #{field_name}Validation:rails.ActiveRecord.Validation<String>;"
        end
        lines << "}"
        lines << ""
        lines.join("\n")
      end

      def write_controller
        Controller.run([
          @controller_name,
          "index",
          "create",
          "--output", @output_dir,
          "--model", @model_name,
          "--fields", @fields.map { |field| field.fetch(:name) }.join(","),
          "--routes", @route_mode,
          "--templates",
          ("--force" if @force),
        ].compact, hotwire: @with_hotwire)
      end

      def write_hotwire_files
        write("src_haxe/shared/#{hotwire_hooks_class}.hx", render_hotwire_hooks)
        write("src_haxe/shared/#{hotwire_contract_class}.hx", render_hotwire_contract)
        write("src_haxe/views/#{@table_name}/#{hotwire_row_view_class}.hx", render_hotwire_row_view)
        write("src_haxe/tools/Export#{@model_name}HotwireHooks.hx", render_hotwire_exporter)
        write("hotwire-hooks.hxml", render_hotwire_export_build)
        write("test_haxe/controllers/#{hotwire_test_class}.hx", render_hotwire_test) if @with_tests
      end

      def render_app_routes
        [
          "package routes;",
          "",
          "import controllers.#{@controller_name};",
          "import models.#{@model_name};",
          "import rails.macros.RoutesDsl.*;",
          "",
          "// Haxe-owned scaffold routes.",
          "//",
          "// Demonstrates: typed controller/action refs and model-derived resource",
          "// names. The compiler emits normal Rails config/routes.rb; run",
          "// `bundle exec rake hxruby:routes MODE=haxe-owned` after compiling to",
          "// regenerate typed route-helper externs from Rails output.",
          "@:railsRoutes",
          "class AppRoutes {",
          "\tstatic final routes = {",
          "\t\tresources(#{@model_name}, #{@controller_name}, {only: [index, create]});",
          "\t};",
          "}",
          "",
        ].join("\n")
      end

      def render_routes
        method_prefix = Common.pluralize(@model_name[0].downcase + @model_name[1..])
        [
          "package routes;",
          "",
          "// Generated by HXRuby::Generators::Scaffold.",
          "//",
          "// Demonstrates: scaffolded Rails route helpers exposed as typed Haxe externs.",
          "// Type safety: Haxe checks helper names and arity before Ruby/Rails runs.",
          "// IntelliSense: editors should complete the scaffolded path/url helpers.",
          "// Ruby/Rails output: direct calls to Rails route helper methods.",
          '@:native("self")',
          "extern class Routes {",
          "\t@:native(\"#{@table_name}_path\")",
          "\tpublic static function #{method_prefix}Path():String;",
          "",
          "\t@:native(\"#{@table_name}_url\")",
          "\tpublic static function #{method_prefix}Url():String;",
          "",
          "}",
          "",
        ].join("\n")
      end

      def render_routes_placeholder
        [
          "package routes;",
          "",
          "// Route helpers are generated from Rails output.",
          "//",
          "// Run `bundle exec rake hxruby:routes MODE=#{@route_mode == "haxe" ? "haxe-owned" : "rails-owned"}`",
          "// after Rails can evaluate the generated routes.",
          '@:native("self")',
          "extern class Routes {",
          "\t// Generated route helpers will be written here.",
          "}",
          "",
        ].join("\n")
      end

      def render_routes_snippet
        [
          "# RailsHx Scaffold Routes Snippet",
          "",
          "This scaffold was generated with `--routes=snippet`, so RailsHx did not",
          "create a Haxe-owned `src_haxe/routes/AppRoutes.hx` file or mutate",
          "`config/routes.rb`.",
          "",
          "## Haxe-owned",
          "",
          "Create `src_haxe/routes/AppRoutes.hx`:",
          "",
          "```haxe",
          "package routes;",
          "",
          "import controllers.#{@controller_name};",
          "import models.#{@model_name};",
          "import rails.macros.RoutesDsl.*;",
          "",
          "@:railsRoutes",
          "class AppRoutes {",
          "\tstatic final routes = {",
          "\t\tresources(#{@model_name}, #{@controller_name}, {only: [index, create]});",
          "\t};",
          "}",
          "```",
          "",
          "Then run `bundle exec rake hxruby:routes MODE=haxe-owned` after compile.",
          "",
          "## Rails-owned",
          "",
          "Add the route to `config/routes.rb` yourself:",
          "",
          "```ruby",
          "resources :#{@table_name}, only: [:index, :create]",
          "```",
          "",
          "Then run `bundle exec rake hxruby:routes MODE=rails-owned`.",
          "",
        ].join("\n")
      end

      def render_main
        imports = [
          ("import controllers.#{@controller_name};" if @with_controller),
          "import migrations.#{@migration_name};",
          "import models.#{@model_name};",
          ("import routes.AppRoutes;" if @route_mode == "haxe" && @with_controller),
          ("import test_haxe.models.#{scaffold_test_class};" if @with_tests),
          ("import test_haxe.controllers.#{hotwire_test_class};" if @with_hotwire && @with_tests),
        ].compact
        controller_line = @with_controller ? "\t\tvar controller:#{@controller_name} = null;\n\t\tSys.println(controller == null);" : ""
        routes_line = (@route_mode == "haxe" && @with_controller) ? "\t\tvar routes:Class<AppRoutes> = AppRoutes;\n\t\tSys.println(routes != null);" : ""
        test_line = @with_tests ? "\t\tvar modelTest:Class<#{scaffold_test_class}> = #{scaffold_test_class};\n\t\tSys.println(modelTest != null);" : ""
        hotwire_test_line = (@with_hotwire && @with_tests) ? "\t\tvar hotwireTest:Class<#{hotwire_test_class}> = #{hotwire_test_class};\n\t\tSys.println(hotwireTest != null);" : ""
        [
          *imports,
          "",
          "class Main {",
          "\tstatic function main() {",
          "\t\tvar model:#{@model_name} = null;",
          "\t\tvar migration:Class<#{@migration_name}> = #{@migration_name};",
          "\t\tSys.println(model == null);",
          "\t\tSys.println(migration != null);",
          controller_line,
          routes_line,
          test_line,
          hotwire_test_line,
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_model_test
        [
          "package test_haxe.models;",
          "",
          "import models.#{@model_name};",
          "import rails.test.Assert.*;",
          "import rails.test.Dsl.*;",
          "import rails.test.ModelTestCase;",
          "",
          "// Generated by HXRuby::Generators::Scaffold.",
          "// Demonstrates: Haxe-authored #{TestAdapter.framework_name(@test_adapter)} tests as the scaffold test source.",
          "// Type safety: the test references the generated model class directly,",
          "// so renames or package drift fail during Haxe compilation; the compiler",
          "// emits an ordinary test artifact under #{TestAdapter.output_root(@test_adapter)}.",
          TestAdapter.metadata_line(@test_adapter),
          "@:railsTest(\"#{scaffold_test_path}\")",
          "class #{scaffold_test_class} extends ModelTestCase {",
          "\t@:railsTests",
          "\tstatic function define():Void {",
          "\t\ttest(\"generated model relation is typed\", () -> {",
          "\t\t\tnotNil(#{@model_name}.all());",
          "\t\t});",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def scaffold_test_path
        "models/#{@resource_name}_haxe_#{TestAdapter.file_suffix(@test_adapter)}"
      end

      def scaffold_test_class
        "#{@model_name}#{TestAdapter.class_suffix(@test_adapter)}"
      end

      def render_migration
        [
          "package migrations;",
          "",
          "import models.#{@model_name};",
          "import rails.migration.Migration;",
          "",
          "@:railsMigration({",
          "\ttimestamp: \"20260101000000\",",
          "\tclassName: \"#{@migration_name}\",",
          "\tmodels: [\"models.#{@model_name}\"]",
          "})",
          "class #{@migration_name} extends Migration {",
          "\tstatic final model:Class<#{@model_name}> = #{@model_name};",
          "}",
          "",
        ].join("\n")
      end

      def render_build
        [
          "-D reflaxe_runtime",
          "-D reflaxe_ruby_rails",
          "-cp src_haxe",
          ("-cp ." if @with_tests),
          "-main Main",
          "",
        ].compact.join("\n")
      end

      def render_hotwire_hooks
        [
          "package shared;",
          "",
          "/**",
          "\tBrowser-safe selectors for the generated #{@model_name} realtime resource.",
          "",
          "\tThe macro derives typed accessors shared by HHX, Haxe browser code,",
          "\tand Playwright without importing the server-only row template.",
          "**/",
          "@:hotwireHooks",
          "class #{hotwire_hooks_class} {",
          "\tstatic final stream:#{@model_name}HotwireStream = \"#{@table_name}\";",
          "\tstatic final target:#{@model_name}HotwireDomId = \"#{@table_name}_list\";",
          "\tstatic final ready:#{@model_name}HotwireSelector = \"turbo-cable-stream-source[connected]\";",
          "}",
          "",
          "abstract #{@model_name}HotwireStream(String) from String to String {}",
          "abstract #{@model_name}HotwireDomId(String) from String to String {}",
          "abstract #{@model_name}HotwireSelector(String) from String to String {}",
          "",
        ].join("\n")
      end

      def render_hotwire_contract
        [
          "package shared;",
          "",
          "import models.#{@model_name};",
          "import rails.action_view.Template;",
          "import rails.turbo.TurboStreams;",
          "import shared.#{hotwire_hooks_class};",
          "import views.#{@table_name}.#{hotwire_row_view_class};",
          "import views.#{@table_name}.#{hotwire_row_view_class}.#{hotwire_row_locals};",
          "",
          "/**",
          "\tServer-side stream, target, template, and locals contract.",
          "",
          "\tGenerated controller actions call `broadcastCreated` only after",
          "\tActiveRecord confirms persistence; Rails receives an ordinary",
          "\tTurbo::StreamsChannel server-rendered partial broadcast.",
          "**/",
          "@:hotwireContract",
          "class #{hotwire_contract_class} {",
          "\tstatic final stream = #{hotwire_hooks_class}.streamName();",
          "\tstatic final target = #{hotwire_hooks_class}.targetId();",
          "\tstatic final row:Template<#{hotwire_row_locals}> = Template.of(#{hotwire_row_view_class});",
          "",
          "\tpublic static inline function rowLocals(#{@resource_name}:#{@model_name}):#{hotwire_row_locals} {",
          "\t\treturn {#{@resource_name}: #{@resource_name}};",
          "\t}",
          "",
          "\tpublic static inline function broadcastCreated(#{@resource_name}:#{@model_name}):Void {",
          "\t\tTurboStreams.broadcastPrependTo(streamName(), streamTarget(), rowTemplate(), rowLocals(#{@resource_name}));",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_hotwire_row_view
        value = @fields.first
        value_markup = value ? "<span>${locals.#{@resource_name}.#{value.fetch(:name)}}</span>" : "<span>Generated #{@model_name} row</span>"
        [
          "package views.#{@table_name};",
          "",
          "import models.#{@model_name};",
          "import rails.action_view.HtmlNode;",
          "",
          "typedef #{hotwire_row_locals} = {",
          "\tvar #{@resource_name}:#{@model_name};",
          "}",
          "",
          "/** Typed row partial reused for initial render and Turbo broadcasts. */",
          "@:railsTemplate(\"#{@table_name}/_#{@resource_name}\")",
          "@:railsTemplateAst(\"render\")",
          "class #{hotwire_row_view_class} {",
          "\tpublic static function render(locals:#{hotwire_row_locals}):HtmlNode {",
          "\t\treturn <li>#{value_markup}</li>;",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_hotwire_exporter
        [
          "package tools;",
          "",
          "import haxe.Json;",
          "import shared.#{hotwire_hooks_class};",
          "import StringTools;",
          "import sys.FileSystem;",
          "import sys.io.File;",
          "",
          "/** Exports the macro-derived selectors consumed by Playwright. */",
          "class Export#{@model_name}HotwireHooks {",
          "\tpublic static function main():Void {",
          "\t\tif (!FileSystem.exists(\"test\")) FileSystem.createDirectory(\"test\");",
          "\t\tif (!FileSystem.exists(\"test/e2e\")) FileSystem.createDirectory(\"test/e2e\");",
          "\t\tfinal path = \"test/e2e/#{@resource_name}_hotwire_hooks.ts\";",
          "\t\tfinal owner = \"// Generated from shared.#{hotwire_hooks_class}; do not edit.\";",
          "\t\t// The exporter may refresh its own artifact, but must not take over",
          "\t\t// an app-owned Playwright module at the deterministic output path.",
          "\t\tif (FileSystem.exists(path) && !StringTools.startsWith(File.getContent(path), owner))",
          "\t\t\tthrow \"Refusing to overwrite non-RailsHx-owned Hotwire hook export \" + path;",
          "\t\tFile.saveContent(path, [",
          "\t\t\towner,",
          "\t\t\t\"export const #{@resource_name}Hotwire = {\",",
          "\t\t\t\"  stream: \" + Json.stringify(#{hotwire_hooks_class}.streamName()) + \",\",",
          "\t\t\t\"  target: \" + Json.stringify(#{hotwire_hooks_class}.targetSelector()) + \",\",",
          "\t\t\t\"  ready: \" + Json.stringify(#{hotwire_hooks_class}.readySelector()),",
          "\t\t\t\"} as const\",",
          "\t\t\t\"\",",
          "\t\t].join(\"\\n\"));",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_hotwire_export_build
        [
          "-cp src_haxe",
          "-lib railshx.client",
          "--run tools.Export#{@model_name}HotwireHooks",
          "",
        ].join("\n")
      end

      def render_hotwire_test
        [
          "package test_haxe.controllers;",
          "",
          "import rails.test.ActionCableAssert.assertBroadcasts;",
          "import rails.test.Dsl.*;",
          "import rails.test.ModelTestCase;",
          "import rails.turbo.TurboStreams;",
          "import shared.#{hotwire_contract_class};",
          "",
          "/**",
          "\tVerifies the generated stream through Rails' native ActionCable helper.",
          "\tController behavior and the assertion share the same typed contract.",
          "**/",
          "@:railsTest(\"controllers/#{@resource_name}_hotwire_haxe_test\")",
          "class #{hotwire_test_class} extends ModelTestCase {",
          "\t@:railsTests",
          "\tstatic function define():Void {",
          "\t\ttest(\"generated Hotwire stream broadcasts\", () -> {",
          "\t\t\tassertBroadcasts(#{hotwire_contract_class}.streamName(), 1, () -> {",
          "\t\t\t\tTurboStreams.broadcastRemoveTo(#{hotwire_contract_class}.streamName(), #{hotwire_contract_class}.streamTarget());",
          "\t\t\t});",
          "\t\t});",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def hotwire_hooks_class
        "#{@model_name}HotwireHooks"
      end

      def hotwire_contract_class
        "#{@model_name}HotwireContract"
      end

      def hotwire_row_view_class
        "#{@model_name}RowView"
      end

      def hotwire_row_locals
        "#{@model_name}RowLocals"
      end

      def hotwire_test_class
        "#{@model_name}HotwireHaxeTest"
      end
    end
  end
end
