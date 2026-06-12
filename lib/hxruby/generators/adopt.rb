# frozen_string_literal: true

require "optparse"
require_relative "common"

module HXRuby
  module Generators
    class Adopt
      def self.run(argv)
        new(parse(argv)).run
      end

      def self.parse(argv)
        options = {
          output: ".",
          package: "interop",
          services: [],
          templates: [],
          locals: "",
          force: false,
          discover: false,
        }
        OptionParser.new do |parser|
          parser.on("--output PATH") { |value| options[:output] = value }
          parser.on("--package NAME") { |value| options[:package] = value }
          parser.on("--service NAME") { |value| options[:services].concat(Common.split_csv(value)) }
          parser.on("--template PATH") { |value| options[:templates].concat(Common.split_csv(value)) }
          parser.on("--locals FIELDS") { |value| options[:locals] = value }
          parser.on("--force") { options[:force] = true }
          parser.on("--discover") { options[:discover] = true }
        end.parse!(argv)
        if !options[:discover] && options[:services].empty? && options[:templates].empty?
          raise Error, "Provide at least one --service or --template boundary to adopt."
        end

        options
      end

      def initialize(options)
        @output_dir = File.expand_path(options.fetch(:output))
        @package_name = options.fetch(:package)
        @services = options.fetch(:services)
        @templates = options.fetch(:templates)
        @locals = parse_locals(options.fetch(:locals))
        @force = options.fetch(:force)
        @discover = options.fetch(:discover)
      end

      def run
        discover_boundaries if @discover
        @services.each { |service| write_service(service) }
        @templates.each { |template| write_template(template) }
      end

      private

      def discover_boundaries
        services = discover_services
        templates = discover_templates

        puts "[rails:adopt] Candidate Ruby constants:"
        services.each { |service| puts "  --service #{service}" }
        puts "  (none found)" if services.empty?

        puts "[rails:adopt] Candidate ERB templates:"
        templates.each { |template| puts "  --template #{template}" }
        puts "  (none found)" if templates.empty?
      end

      def discover_services
        service_files = Dir.glob(File.join(@output_dir, "app", "{models,services,helpers,components}", "**", "*.rb"))
        service_files.map do |path|
          content = File.read(path)
          content.scan(/^\s*(?:class|module)\s+([A-Z][A-Za-z0-9_:]*)/).flatten
        end.flatten.uniq.sort
      end

      def discover_templates
        view_root = File.join(@output_dir, "app", "views")
        Dir.glob(File.join(view_root, "**", "*.html.erb")).map do |path|
          relative = path.delete_prefix("#{view_root}/")
          relative = relative.sub(/\.html\.erb\z/, "")
          dirname = File.dirname(relative)
          basename = File.basename(relative).sub(/\A_/, "")
          dirname == "." ? basename : File.join(dirname, basename)
        end.uniq.sort
      end

      def parse_locals(raw)
        Common.split_csv(raw).map do |entry|
          name, type = entry.split(":", 2).map(&:strip)
          raise Error, "Invalid local #{entry.inspect}. Expected name:Type." if name.to_s.empty? || type.to_s.empty?

          { name: name, type: type }
        end
      end

      def write_service(native_name)
        haxe_class = native_name.split("::").last
        package = service_package(native_name)
        path = File.join(@output_dir, "src_haxe", Common.package_path(package), "#{haxe_class}.hx")
        Common.write_file(path, render_service(package, haxe_class, native_name), force: @force)
      end

      def service_package(native_name)
        modules = native_name.split("::")[0...-1].map { |part| Common.file_name(part) }
        [@package_name, *modules].reject(&:empty?).join(".")
      end

      def render_service(package, haxe_class, native_name)
        [
          "package #{package};",
          "",
          "// Rails-owned Ruby constant adopted through a typed Haxe extern.",
          "// Add method signatures here as the boundary stabilizes; keep raw Ruby out of Haxe app code.",
          "@:native(#{Common.haxe_string(native_name)})",
          "extern class #{haxe_class} {",
          "}",
          "",
        ].join("\n")
      end

      def write_template(template_path)
        haxe_class = "#{Common.class_name_from_path(template_path)}Template"
        locals_name = "#{Common.class_name_from_path(template_path)}Locals"
        package = "#{@package_name}.templates"
        path = File.join(@output_dir, "src_haxe", Common.package_path(package), "#{haxe_class}.hx")
        Common.write_file(path, render_template(package, haxe_class, locals_name, template_path), force: @force)
      end

      def render_template(package, haxe_class, locals_name, template_path)
        lines = [
          "package #{package};",
          "",
          "import rails.action_view.Template;",
          "",
          "typedef #{locals_name} = {",
        ]
        if @locals.empty?
          lines << "\t// Add typed locals expected by #{template_path}.html.erb."
        else
          @locals.each { |local| lines << "\tvar #{local.fetch(:name)}:#{local.fetch(:type)};" }
        end
        lines += [
          "}",
          "",
          "class #{haxe_class} {",
          "\tpublic static final template:Template<#{locals_name}> = Template.existing(#{Common.haxe_string(template_path)});",
          "}",
          "",
        ]
        lines.join("\n")
      end
    end
  end
end
