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
        }
        OptionParser.new do |parser|
          parser.on("--output PATH") { |value| options[:output] = value }
          parser.on("--package NAME") { |value| options[:package] = value }
          parser.on("--service NAME") { |value| options[:services].concat(Common.split_csv(value)) }
          parser.on("--template PATH") { |value| options[:templates].concat(Common.split_csv(value)) }
          parser.on("--locals FIELDS") { |value| options[:locals] = value }
          parser.on("--force") { options[:force] = true }
        end.parse!(argv)
        raise Error, "Provide at least one --service or --template boundary to adopt." if options[:services].empty? && options[:templates].empty?

        options
      end

      def initialize(options)
        @output_dir = File.expand_path(options.fetch(:output))
        @package_name = options.fetch(:package)
        @services = options.fetch(:services)
        @templates = options.fetch(:templates)
        @locals = parse_locals(options.fetch(:locals))
        @force = options.fetch(:force)
      end

      def run
        @services.each { |service| write_service(service) }
        @templates.each { |template| write_template(template) }
      end

      private

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
          "\tpublic static final template:Template<#{locals_name}> = Template.external(#{Common.haxe_string(template_path)});",
          "}",
          "",
        ]
        lines.join("\n")
      end
    end
  end
end
