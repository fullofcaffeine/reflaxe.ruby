# frozen_string_literal: true

require "optparse"
require_relative "common"

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
          force: false,
        }
        OptionParser.new do |parser|
          parser.on("--model NAME") { |value| options[:model] = value }
          parser.on("--output PATH") { |value| options[:output] = value }
          parser.on("--fields FIELDS") { |value| options[:fields] = value }
          parser.on("--validate FIELDS") { |value| options[:validate] = value }
          parser.on("--controller") { options[:controller] = true }
          parser.on("--routes MODE", "Route mode: haxe, snippet, rails, or none") { |value| options[:routes] = value }
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
        @force = options.fetch(:force)
        @table_name = Common.pluralize(Common.file_name(@model_name))
        @controller_name = "#{Common.pluralize(@model_name)}Controller"
        @migration_name = "Create#{Common.pluralize(@model_name)}"
        @resource_name = Common.file_name(@model_name)
        @controller_file = Common.file_name(@controller_name)
      end

      def run
        write("src_haxe/models/#{@model_name}.hx", render_model)
        write("src_haxe/migrations/#{@migration_name}.hx", render_migration)
        write_route_files
        write("src_haxe/Main.hx", render_main)
        write("build.hxml", render_build)
        write("src_haxe/controllers/#{@controller_name}.hx", render_controller) if @with_controller
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
        when /\Asrc_haxe\//
          "haxe_source"
        when "build.hxml"
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

      def render_controller
        permitted = @fields.map { |field| Common.haxe_string(field.fetch(:name)) }.join(", ")
        redirect_line = if @route_mode == "rails"
                          method_prefix = Common.pluralize(@model_name[0].downcase + @model_name[1..])
                          "\t\tredirectTo(Routes.#{method_prefix}Path());"
                        else
                          "\t\tredirectToOptions({action: \"index\"});"
                        end
        [
          "package controllers;",
          "",
          "import models.#{@model_name};",
          "import rails.macros.ParamsMacro;",
          ("import routes.Routes;" if @route_mode == "rails"),
          "",
          "@:railsController",
          "class #{@controller_name} extends rails.action_controller.Base {",
          "\tstatic final lifecycle = [];",
          "",
          "\tpublic function index() {",
          "\t\tvar #{@table_name} = #{@model_name}.where({});",
          "\t\trender({json: #{@table_name}});",
          "\t}",
          "",
          "\tpublic function create() {",
          "\t\tvar attrs = ParamsMacro.requirePermit(this.params(), #{Common.haxe_string(@resource_name)}, [#{permitted}]);",
          "\t\tvar #{@resource_name} = #{@model_name}.create(attrs);",
          redirect_line,
          "\t}",
          "}",
          "",
        ].compact.join("\n")
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
        ].compact
        controller_line = @with_controller ? "\t\tvar controller:#{@controller_name} = null;\n\t\tSys.println(controller == null);" : ""
        routes_line = (@route_mode == "haxe" && @with_controller) ? "\t\tvar routes:Class<AppRoutes> = AppRoutes;\n\t\tSys.println(routes != null);" : ""
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
          "\t}",
          "}",
          "",
        ].join("\n")
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
          "-main Main",
          "",
        ].join("\n")
      end
    end
  end
end
