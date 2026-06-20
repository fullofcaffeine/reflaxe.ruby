# frozen_string_literal: true

require "optparse"
require_relative "common"

module HXRuby
  module Generators
    class Controller
      PACKAGE_PATTERN = /\A[A-Za-z_][A-Za-z0-9_]*(?:[.][A-Za-z_][A-Za-z0-9_]*)*\z/
      ACTION_PATTERN = /\A[A-Za-z_][A-Za-z0-9_]*\z/

      def self.run(argv)
        new(parse(argv)).run
      end

      def self.parse(argv)
        options = {
          name: nil,
          actions: [],
          output: ".",
          haxe_dir: "src_haxe/controllers",
          package: "controllers",
          templates: false,
          views_dir: "src_haxe/views",
          views_package: "views",
          model: nil,
          fields: "",
          routes: "snippet",
          force: false,
        }
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: hxruby:controller NAME [action ...] [options]"
          opts.on("--output PATH") { |value| options[:output] = value }
          opts.on("--haxe-dir PATH") { |value| options[:haxe_dir] = value }
          opts.on("--package NAME") { |value| options[:package] = value }
          opts.on("--templates") { options[:templates] = true }
          opts.on("--views-dir PATH") { |value| options[:views_dir] = value }
          opts.on("--views-package NAME") { |value| options[:views_package] = value }
          opts.on("--model NAME") { |value| options[:model] = value }
          opts.on("--fields FIELDS") { |value| options[:fields] = value }
          opts.on("--routes MODE", "Route mode: haxe, snippet, rails, or none") { |value| options[:routes] = value }
          opts.on("--force") { options[:force] = true }
        end
        remaining = parser.parse!(argv)
        options[:name] = remaining.shift
        options[:actions] = remaining
        raise Error, "Missing required controller NAME" if options[:name].to_s.empty?

        options
      end

      def initialize(options)
        @controller_name = class_name(options.fetch(:name))
        @actions = normalize_actions(options.fetch(:actions))
        @output_dir = File.expand_path(options.fetch(:output))
        @haxe_dir = Common.safe_relative_path(options.fetch(:haxe_dir), label: "--haxe-dir")
        @package_name = options.fetch(:package)
        @with_templates = options.fetch(:templates)
        @views_dir = Common.safe_relative_path(options.fetch(:views_dir), label: "--views-dir")
        @views_package = options.fetch(:views_package)
        @model_name = options.fetch(:model)
        @fields = Common.split_csv(options.fetch(:fields))
        @route_mode = validate_route_mode(options.fetch(:routes))
        @force = options.fetch(:force)
        @resource_name = @model_name ? Common.file_name(@model_name) : nil
        @table_name = @model_name ? Common.pluralize(Common.file_name(@model_name)) : nil
        validate_static_options!
      end

      def run
        write(File.join(@haxe_dir, "#{@controller_name}.hx"), render_controller, kind: "haxe_controller_source")
        return unless @with_templates

        @actions.each do |action|
          write(
            File.join(@views_dir, controller_view_dir, "#{view_class(action)}.hx"),
            render_view(action),
            kind: "haxe_view_source"
          )
        end
      end

      private

      def validate_static_options!
        raise Error, "Controller name must be a safe Haxe class name" unless @controller_name.match?(/\A[A-Z][A-Za-z0-9_]*Controller\z/)
        raise Error, "--package must be a safe Haxe package" unless @package_name.match?(PACKAGE_PATTERN)
        raise Error, "--views-package must be a safe Haxe package" unless @views_package.match?(PACKAGE_PATTERN)
        if @model_name && !@model_name.match?(/\A[A-Z][A-Za-z0-9_]*\z/)
          raise Error, "--model must be a safe Haxe class name"
        end
        @fields.each do |field|
          raise Error, "--fields entries must be safe Haxe field names" unless field.match?(ACTION_PATTERN)
        end
      end

      def normalize_actions(actions)
        normalized = actions.map { |action| Common.haxe_identifier(action, fallback: "index") }
        normalized = ["index"] if normalized.empty?
        normalized.each do |action|
          raise Error, "Controller actions must be safe Haxe method names" unless action.match?(ACTION_PATTERN)
        end
        normalized.uniq
      end

      def class_name(raw)
        name = raw.to_s
        name = Common.class_name_from_path(name) unless name.match?(/\A[A-Z]/)
        name.end_with?("Controller") ? name : "#{name}Controller"
      end

      def validate_route_mode(value)
        mode = value.to_s
        return mode if %w[haxe snippet rails none].include?(mode)

        raise Error, "Invalid --routes #{value.inspect}. Expected haxe, snippet, rails, or none."
      end

      def write(relative_path, content, kind:)
        Common.write_file(
          File.join(@output_dir, relative_path),
          content,
          force: @force,
          root: @output_dir,
          kind: kind,
          source: "hxruby:controller"
        )
      end

      def render_controller
        imports = []
        imports << "import models.#{@model_name};" if @model_name
        imports << "import rails.macros.ParamsMacro;" if @model_name && @actions.include?("create")
        imports << "import rails.action_view.Template;" if @with_templates
        imports << "import rails.macros.ViewMacro;" if @with_templates
        imports << "import routes.Routes;" if @route_mode == "rails" && @actions.include?("create")
        @actions.each { |action| imports << "import #{@views_package}.#{controller_view_package}.#{view_class(action)};" } if @with_templates
        local_typedefs = @with_templates ? @actions.flat_map { |action| render_locals_typedef(action) } : []

        [
          "package #{@package_name};",
          "",
          *imports.sort,
          "",
          *local_typedefs,
          "// Generated by HXRuby::Generators::Controller.",
          "// Demonstrates: a typed RailsHx ActionController class that emits a",
          "// normal Rails controller. Add lifecycle hooks with",
          "// `static final lifecycle = { beforeAction(...); }` when needed.",
          "// Type safety: action names are Haxe methods; optional HHX views are",
          "// rendered through `Template.of(ViewClass)` so renamed/missing views fail",
          "// at Haxe compile time instead of becoming stale Rails strings.",
          "@:railsController",
          "class #{@controller_name} extends rails.action_controller.Base {",
          "\tstatic final lifecycle = [];",
          "",
          *@actions.flat_map { |action| render_action(action) },
          "}",
          "",
        ].join("\n")
      end

      def render_action(action)
        body = if @model_name && action == "index" && @with_templates
                 [
                   "\t\tvar #{@table_name} = #{@model_name}.all().toArray();",
                   "\t\tViewMacro.renderTemplate(this, (Template.of(#{view_class(action)}) : Template<#{locals_type(action)}>), {title: #{Common.haxe_string("#{@controller_name}##{action}")}, #{@table_name}: #{@table_name}});",
                 ]
               elsif @model_name && action == "index"
                 [
                   "\t\tvar #{@table_name} = #{@model_name}.all().toArray();",
                   "\t\trender({json: #{@table_name}});",
                 ]
               elsif @model_name && action == "create"
                 [
                   "\t\tvar attrs = ParamsMacro.requirePermit(this.params(), #{Common.haxe_string(@resource_name)}, [#{field_literals}]);",
                   "\t\tvar #{@resource_name} = #{@model_name}.create(attrs);",
                   redirect_line,
                 ]
               elsif @with_templates
                 ["\t\tViewMacro.renderTemplate(this, (Template.of(#{view_class(action)}) : Template<#{locals_type(action)}>), {title: #{Common.haxe_string("#{@controller_name}##{action}")}});"]
               else
                 ["\t\trender({plain: #{Common.haxe_string("#{@controller_name}##{action}")}});"]
               end

        [
          "\tpublic function #{action}() {",
          *body,
          "\t}",
          "",
        ]
      end

      def field_literals
        @fields.map { |field| Common.haxe_string(field) }.join(", ")
      end

      def redirect_line
        if @route_mode == "rails"
          method_prefix = Common.pluralize(@model_name[0].downcase + @model_name[1..])
          "\t\tredirectTo(Routes.#{method_prefix}Path());"
        else
          "\t\tredirectToOptions({action: \"index\"});"
        end
      end

      def render_view(action)
        body = if @model_name && action == "index"
                 render_model_index_view_body
               else
                 [
                   "\t\treturn <main class=\"railshx-generated-view\">",
                   "\t\t\t<h1>${locals.title}</h1>",
                   "\t\t\t<p>This view is authored in typed Rails HHX and emitted as Rails ERB.</p>",
                   "\t\t</main>;",
                 ]
               end
        [
          "package #{@views_package}.#{controller_view_package};",
          "",
          "import #{@package_name}.#{@controller_name}.#{locals_type(action)};",
          "import rails.action_view.HtmlNode;",
          "",
          "// Generated by HXRuby::Generators::Controller.",
          "// Demonstrates: typed Rails HHX as the source format for an ActionView",
          "// template. The compiler lowers this class to a normal Rails ERB",
          "// artifact at `app/views/#{template_path(action)}.html.erb`.",
          "@:railsTemplate(#{Common.haxe_string(template_path(action))})",
          "@:railsTemplateAst(\"render\")",
          "class #{view_class(action)} {",
          "\tpublic static function render(locals:#{locals_type(action)}):HtmlNode {",
          *body,
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_model_index_view_body
        row = if @fields.first
                "\t\t\t\t\t<li>\${#{@resource_name}.#{@fields.first}}</li>"
              else
                "\t\t\t\t\t<li>Generated #{@model_name} row</li>"
              end
        [
          "\t\treturn <main class=\"railshx-generated-view\">",
          "\t\t\t<h1>${locals.title}</h1>",
          "\t\t\t<p>This scaffold view receives typed #{@model_name} records from the controller.</p>",
          "\t\t\t<ul>",
          "\t\t\t\t<for \${#{@resource_name} in locals.#{@table_name}}>",
          row,
          "\t\t\t\t</for>",
          "\t\t\t</ul>",
          "\t\t</main>;",
        ]
      end

      def render_locals_typedef(action)
        fields = [
          "typedef #{locals_type(action)} = {",
          "\tvar title:String;",
        ]
        fields << "\tvar #{@table_name}:Array<#{@model_name}>;" if @model_name && action == "index"
        fields.concat([
          "}",
          "",
        ])
      end

      def controller_view_dir
        Common.file_name(@controller_name.delete_suffix("Controller"))
      end

      def controller_view_package
        Common.haxe_identifier(controller_view_dir)
      end

      def view_class(action)
        "#{Common.class_name_from_path(action)}View"
      end

      def locals_type(action)
        "#{Common.class_name_from_path(action)}Locals"
      end

      def template_path(action)
        "#{@package_name.tr('.', '/')}/#{controller_view_dir}/#{action}"
      end
    end
  end
end
