# frozen_string_literal: true

require "optparse"
require_relative "common"
require_relative "migration"

module HXRuby
  module Generators
    class Model
      ATTRIBUTE_PATTERN = /\A([A-Za-z_][A-Za-z0-9_]*):([^:]+)(?::(.+))?\z/
      PACKAGE_PATTERN = /\A[A-Za-z_][A-Za-z0-9_]*(?:[.][A-Za-z_][A-Za-z0-9_]*)*\z/

      def self.run(argv)
        new(parse(argv)).run
      end

      def self.parse(argv)
        options = {
          name: nil,
          attributes: [],
          output: ".",
          haxe_dir: "src_haxe/models",
          migration_dir: "src_haxe/migrations",
          package: "models",
          migration_package: "migrations",
          timestamp: nil,
          migration_version: "7.1",
          known_models: "",
          validate: [],
          skip_migration: false,
          pretend: false,
          force: false,
        }
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: hxruby:model NAME [field:type ...] [options]"
          opts.on("--output PATH") { |value| options[:output] = value }
          opts.on("--haxe-dir PATH") { |value| options[:haxe_dir] = value }
          opts.on("--migration-dir PATH") { |value| options[:migration_dir] = value }
          opts.on("--package NAME") { |value| options[:package] = value }
          opts.on("--migration-package NAME") { |value| options[:migration_package] = value }
          opts.on("--timestamp VALUE") { |value| options[:timestamp] = value }
          opts.on("--migration-version VALUE") { |value| options[:migration_version] = value }
          opts.on("--known-models LIST") { |value| options[:known_models] = value }
          opts.on("--validate RULE") { |value| options[:validate] << value }
          opts.on("--skip-migration") { options[:skip_migration] = true }
          opts.on("--pretend") { options[:pretend] = true }
          opts.on("--force") { options[:force] = true }
        end
        remaining = parser.parse!(argv)
        options[:name] = remaining.shift
        options[:attributes] = remaining
        raise Error, "Missing required model NAME" if options[:name].to_s.empty?

        options
      end

      def initialize(options)
        @model_name = class_name(options.fetch(:name))
        @attributes = options.fetch(:attributes).map { |entry| parse_attribute(entry) }
        @output_dir = File.expand_path(options.fetch(:output))
        @haxe_dir = Common.safe_relative_path(options.fetch(:haxe_dir), label: "--haxe-dir")
        @migration_dir = Common.safe_relative_path(options.fetch(:migration_dir), label: "--migration-dir")
        @package_name = options.fetch(:package)
        @migration_package = options.fetch(:migration_package)
        @timestamp = options.fetch(:timestamp)
        @migration_version = options.fetch(:migration_version)
        @known_models = Common.split_csv(options.fetch(:known_models))
        @validations = options.fetch(:validate).map { |entry| parse_validation(entry) }
        @skip_migration = options.fetch(:skip_migration)
        @pretend = options.fetch(:pretend)
        @force = options.fetch(:force)
        @table_name = Common.pluralize(Common.file_name(@model_name))
        validate_static_options!
      end

      def run
        model_source = render_model
        model_relative_path = File.join(@haxe_dir, "#{@model_name}.hx")

        if @pretend
          puts "# #{model_relative_path}"
          puts model_source
          unless @skip_migration
            puts
            Migration.run(migration_args + ["--pretend"])
          end
          return
        end

        Common.write_file(
          File.join(@output_dir, model_relative_path),
          model_source,
          force: @force,
          root: @output_dir,
          kind: "haxe_model_source",
          source: "hxruby:model"
        )
        Migration.run(migration_args) unless @skip_migration
      end

      private

      def validate_static_options!
        raise Error, "Model name must be a safe Haxe class name" unless @model_name.match?(/\A[A-Z][A-Za-z0-9_]*\z/)
        raise Error, "--package must be a safe Haxe package" unless @package_name.match?(PACKAGE_PATTERN)
        raise Error, "--migration-package must be a safe Haxe package" unless @migration_package.match?(PACKAGE_PATTERN)
        raise Error, "--migration-version must look like 7.1 or 8.1" unless @migration_version.match?(/\A[0-9]+[.][0-9]+\z/)
        if @timestamp && !@timestamp.match?(/\A[0-9]{14}\z/)
          raise Error, "--timestamp must be a 14-digit Rails migration timestamp"
        end
        @known_models.each do |model|
          raise Error, "--known-models entries must be Haxe type paths" unless model.match?(PACKAGE_PATTERN)
        end
        @validations.each do |validation|
          unless @attributes.any? { |attribute| attribute.fetch(:name) == validation.fetch(:field) }
            raise Error, "--validate target #{validation.fetch(:field)} must match a generated attribute"
          end
        end
      end

      def render_model
        lines = [
          "package #{@package_name};",
          "",
          "// Generated by HXRuby::Generators::Model.",
          "// Type safety: Rails fields, references, associations, and validations",
          "// are represented as typed Haxe metadata before Ruby/Rails runs.",
          "@:railsModel(#{Common.haxe_string(@table_name)})",
          "@:railsTimestamps",
          "class #{@model_name} extends rails.active_record.Base<#{@model_name}> {",
        ]
        @attributes.each do |attribute|
          lines.concat(render_attribute(attribute))
        end
        @validations.each do |validation|
          lines << ""
          lines << "\t@:validates(#{validation_options(validation)})"
          lines << "\tpublic var #{validation.fetch(:field)}Validation:rails.ActiveRecord.Validation<#{field_type_for(attribute_named(validation.fetch(:field)), validation: true)}>;"
        end
        lines << "}"
        lines << ""
        lines.join("\n")
      end

      def render_attribute(attribute)
        if reference_attribute?(attribute)
          render_reference(attribute)
        else
          [
            "",
            "\t@:railsColumn#{column_metadata(attribute)}",
            "\tpublic var #{attribute.fetch(:name)}:#{field_type_for(attribute)};",
          ]
        end
      end

      def render_reference(attribute)
        target = class_name(attribute.fetch(:name))
        foreign_key = "#{attribute.fetch(:name)}Id"
        foreign_key_attribute = attribute.merge(name: foreign_key, type: "integer", nullable: attribute.fetch(:nullable))
        [
          "",
          "\t@:railsColumn#{column_metadata(foreign_key_attribute)}",
          "\tpublic var #{foreign_key}:#{attribute.fetch(:nullable) ? "Null<Int>" : "Int"};",
          "",
          "\t@:belongsTo({foreignKey: #{Common.haxe_string(foreign_key)}, optional: #{attribute.fetch(:nullable) ? "true" : "false"}})",
          "\tpublic var #{attribute.fetch(:name)}:rails.ActiveRecord.BelongsTo<#{target}>;",
        ]
      end

      def migration_args
        args = [
          "Create#{Common.pluralize(@model_name)}",
          *@attributes.map { |attribute| attribute.fetch(:raw) },
          "--output", @output_dir,
          "--haxe-dir", @migration_dir,
          "--package", @migration_package,
          "--migration-version", @migration_version,
        ]
        args += ["--timestamp", @timestamp] if @timestamp
        args += ["--known-models", @known_models.join(",")] unless @known_models.empty?
        args << "--force" if @force
        args
      end

      def parse_attribute(entry)
        match = ATTRIBUTE_PATTERN.match(entry.to_s)
        raise Error, "Invalid attribute #{entry.inspect}. Expected field:type, field:type!, or field:type:index." unless match

        raw_name = match[1]
        raw_type = match[2]
        nullable = true
        if raw_type.end_with?("!")
          raw_type = raw_type.delete_suffix("!")
          nullable = false
        end
        type, type_options = parse_type(raw_type)
        modifiers = match[3].to_s.split(":").map(&:strip).reject(&:empty?)
        name = Common.haxe_identifier(raw_name)
        {
          raw: entry.to_s,
          name: name,
          ruby_name: Common.file_name(raw_name),
          type: type,
          type_options: type_options,
          nullable: nullable,
          index: modifiers.any? { |modifier| %w[index uniq unique].include?(modifier) },
          unique: modifiers.any? { |modifier| %w[uniq unique].include?(modifier) },
        }
      end

      def parse_type(raw_type)
        normalized = raw_type.to_s.strip.downcase
        case normalized
        when /\Adecimal\{([0-9]+),([0-9]+)\}\z/
          ["decimal", { precision: Regexp.last_match(1).to_i, scale: Regexp.last_match(2).to_i }]
        when /\Areferences(?:\{polymorphic\})?\z/, /\Abelongs_to(?:\{polymorphic\})?\z/
          ["references", { polymorphic: normalized.include?("polymorphic") }]
        when "string", "text", "integer", "int", "boolean", "bool", "float", "decimal"
          [normalized, {}]
        else
          raise Error, "Unsupported model attribute type #{raw_type.inspect}"
        end
      end

      def parse_validation(entry)
        field, kind = entry.to_s.split(",", 2).map(&:strip)
        raise Error, "Invalid validation #{entry.inspect}. Expected field,presence or field,uniqueness." if field.to_s.empty? || kind.to_s.empty?
        unless %w[presence uniqueness].include?(kind)
          raise Error, "Unsupported validation #{kind.inspect}. Supported validations: presence, uniqueness."
        end

        { field: Common.haxe_identifier(field), kind: kind }
      end

      def column_metadata(attribute)
        options = []
        options << "nullable: false" unless attribute.fetch(:nullable)
        options << "dbType: #{Common.haxe_string("decimal")}" if attribute.fetch(:type) == "decimal"
        options << "dbType: #{Common.haxe_string("text")}" if attribute.fetch(:type) == "text"
        options << "index: true" if attribute.fetch(:index) && !reference_attribute?(attribute)
        options << "unique: true" if attribute.fetch(:unique) && !reference_attribute?(attribute)
        return "" if options.empty?

        "({#{options.join(", ")}})"
      end

      def validation_options(validation)
        "{#{validation.fetch(:kind)}: true}"
      end

      def field_type_for(attribute, validation: false)
        base = case attribute.fetch(:type)
        when "string", "text"
          "String"
        when "integer", "int"
          "Int"
        when "boolean", "bool"
          "Bool"
        when "float", "decimal"
          "Float"
        else
          "Dynamic"
        end
        return base if validation || !attribute.fetch(:nullable)

        "Null<#{base}>"
      end

      def attribute_named(name)
        @attributes.find { |attribute| attribute.fetch(:name) == name }
      end

      def reference_attribute?(attribute)
        attribute.fetch(:type) == "references"
      end

      def class_name(value)
        value.to_s.split(/[_\-\s]/).reject(&:empty?).map { |part| part[0].upcase + part[1..] }.join
      end
    end
  end
end
