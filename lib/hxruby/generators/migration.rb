# frozen_string_literal: true

require "optparse"
require_relative "common"

module HXRuby
  module Generators
    class Migration
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
          haxe_dir: "src_haxe/migrations",
          package: "migrations",
          timestamp: nil,
          migration_version: "7.1",
          known_models: "",
          external_tables: [],
          from_schema: nil,
          pretend: false,
          force: false,
        }
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: hxruby:migration NAME [field:type ...] [options]"
          opts.on("--output PATH") { |value| options[:output] = value }
          opts.on("--haxe-dir PATH") { |value| options[:haxe_dir] = value }
          opts.on("--package NAME") { |value| options[:package] = value }
          opts.on("--timestamp VALUE") { |value| options[:timestamp] = value }
          opts.on("--migration-version VALUE") { |value| options[:migration_version] = value }
          opts.on("--known-models LIST") { |value| options[:known_models] = value }
          opts.on("--external-table TABLE") { |value| options[:external_tables] += Common.split_csv(value) }
          opts.on("--from-schema [PATH]") { |value| options[:from_schema] = value || "db/schema.rb" }
          opts.on("--pretend") { options[:pretend] = true }
          opts.on("--force") { options[:force] = true }
        end
        remaining = parser.parse!(argv)
        options[:name] = remaining.shift
        options[:attributes] = remaining
        raise Error, "Missing required migration NAME" if options[:name].to_s.empty?

        options
      end

      def initialize(options)
        @name = class_name(options.fetch(:name))
        @attributes = options.fetch(:attributes).map { |entry| parse_attribute(entry) }
        @output_dir = File.expand_path(options.fetch(:output))
        @haxe_dir = Common.safe_relative_path(options.fetch(:haxe_dir), label: "--haxe-dir")
        @package_name = options.fetch(:package)
        @timestamp = options.fetch(:timestamp) || Time.now.utc.strftime("%Y%m%d%H%M%S")
        @migration_version = options.fetch(:migration_version)
        @known_models = Common.split_csv(options.fetch(:known_models))
        @external_tables = options.fetch(:external_tables).map { |table| safe_table_name(table, "--external-table") }
        @from_schema = options.fetch(:from_schema)
        @pretend = options.fetch(:pretend)
        @force = options.fetch(:force)
        validate_static_options!
      end

      def run
        plan = migration_plan
        source = render_migration(plan)
        relative_path = File.join(@haxe_dir, "#{@name}.hx")
        validate_existing_migrations!(relative_path, plan)

        if @pretend
          puts "# #{relative_path}"
          puts source
          return
        end

        Common.write_file(
          File.join(@output_dir, relative_path),
          source,
          force: @force,
          root: @output_dir,
          kind: "haxe_migration_source",
          source: "hxruby:migration"
        )
      end

      private

      def validate_static_options!
        raise Error, "Migration name must be a safe Ruby/Haxe class name" unless @name.match?(/\A[A-Z][A-Za-z0-9_]*\z/)
        raise Error, "--timestamp must be a 14-digit Rails migration timestamp" unless @timestamp.match?(/\A[0-9]{14}\z/)
        raise Error, "--migration-version must look like 7.1 or 8.1" unless @migration_version.match?(/\A[0-9]+[.][0-9]+\z/)
        raise Error, "--package must be a safe Haxe package" unless @package_name.match?(PACKAGE_PATTERN)

        if @from_schema
          schema_path = File.expand_path(@from_schema, @output_dir)
          Common.assert_inside_root!(schema_path, @output_dir)
          raise Error, "--from-schema must point to an existing schema file" unless File.file?(schema_path)
        end

        @known_models.each do |model|
          raise Error, "--known-models entries must be Haxe type paths" unless model.match?(PACKAGE_PATTERN)
        end
      end

      def migration_plan
        case @name
        when /\ACreate(.+)\z/
          create_table_plan(Regexp.last_match(1))
        when /\AAdd(.+?)To(.+)\z/
          alter_table_plan("add", Regexp.last_match(2))
        when /\ARemove(.+?)From(.+)\z/
          alter_table_plan("remove", Regexp.last_match(2))
        when /\AAdd(.+?)RefTo(.+)\z/
          reference_name = Common.file_name(Regexp.last_match(1)).sub(/_ref\z/, "")
          alter_table_plan("add", Regexp.last_match(2), default_attributes: ["#{reference_name}:references"])
        else
          raise Error, "Unsupported migration name #{@name}. Use CreateTableName, AddFieldToTable, RemoveFieldFromTable, or AddUserRefToTodos style names."
        end
      end

      def create_table_plan(raw_table)
        table = safe_table_name(Common.file_name(raw_table), "table")
        raise Error, "Create migrations require at least one attribute" if @attributes.empty?

        {
          table: table,
          mode: "create",
          operations: [[
            "CreateTable(#{Common.haxe_string(table)}, {",
            "\t\t\tcolumns: [",
            *@attributes.flat_map { |attribute| create_table_items(attribute) },
            "\t\t\t],",
            "\t\t\ttimestamps: true",
            "\t\t})",
          ].join("\n")],
        }
      end

      def alter_table_plan(mode, raw_table, default_attributes: nil)
        table = safe_table_name(Common.file_name(raw_table), "table")
        attrs = default_attributes ? default_attributes.map { |entry| parse_attribute(entry) } : @attributes
        raise Error, "#{mode.capitalize} migrations require at least one attribute" if attrs.empty?

        operations = attrs.flat_map do |attribute|
          case mode
          when "add"
            add_operations(table, attribute)
          when "remove"
            remove_operations(table, attribute)
          else
            raise Error, "Unsupported alter mode #{mode}"
          end
        end
        {
          table: table,
          mode: mode,
          operations: operations,
        }
      end

      def add_operations(table, attribute)
        if reference_attribute?(attribute)
          ["AddReference(#{Common.haxe_string(table)}, #{Common.haxe_string(attribute.fetch(:name))}, #{reference_options(attribute)})"]
        else
          lines = ["AddColumn(#{Common.haxe_string(table)}, #{Common.haxe_string(attribute.fetch(:column))}, #{column_constructor(attribute)})"]
          lines << "AddIndex(#{Common.haxe_string(table)}, #{Common.haxe_string(attribute.fetch(:column))}, #{index_options(attribute)})" if attribute.fetch(:index)
          lines
        end
      end

      def remove_operations(table, attribute)
        up = if reference_attribute?(attribute)
          "RemoveReference(#{Common.haxe_string(table)}, #{Common.haxe_string(attribute.fetch(:name))}, #{reference_options(attribute)})"
        else
          "RemoveColumn(#{Common.haxe_string(table)}, #{Common.haxe_string(attribute.fetch(:column))})"
        end
        down = if reference_attribute?(attribute)
          "AddReference(#{Common.haxe_string(table)}, #{Common.haxe_string(attribute.fetch(:name))}, #{reference_options(attribute)})"
        else
          "AddColumn(#{Common.haxe_string(table)}, #{Common.haxe_string(attribute.fetch(:column))}, #{column_constructor(attribute)})"
        end
        ["Reversible([#{up}], [#{down}])"]
      end

      def create_table_items(attribute)
        item = if reference_attribute?(attribute)
          "Reference(#{Common.haxe_string(attribute.fetch(:name))}, #{reference_options(attribute)})"
        else
          "Column(#{Common.haxe_string(attribute.fetch(:column))}, #{column_constructor(attribute)})"
        end
        lines = ["\t\t\t\t#{item},"]
        if attribute.fetch(:index) && !reference_attribute?(attribute)
          lines << "\t\t\t\tIndex([#{Common.haxe_string(attribute.fetch(:column))}], #{index_options(attribute)}),"
        end
        lines
      end

      def render_migration(plan)
        metadata = [
          "\ttimestamp: #{Common.haxe_string(@timestamp)}",
          "\tclassName: #{Common.haxe_string(@name)}",
          "\tversion: #{Common.haxe_string(@migration_version)}",
        ]
        unless @known_models.empty?
          metadata << "\tknownModels: [#{@known_models.map { |model| Common.haxe_string(model) }.join(", ")}]"
        end
        external_tables = effective_external_tables(plan)
        unless external_tables.empty?
          metadata << "\texternalTables: [#{external_tables.map { |table| Common.haxe_string(table) }.join(", ")}]"
        end
        metadata << "\tmodels: []" if @known_models.empty? && external_tables.empty?

        lines = [
          "package #{@package_name};",
          "",
          "import rails.migration.Migration;",
          "import rails.migration.MigrationOperation;",
          "import rails.migration.MigrationOperation.*;",
          "import rails.migration.MigrationOperation.CreateTableItem;",
          "",
          "// Generated by HXRuby::Generators::Migration.",
          "// Type safety: attributes are converted into typed MigrationOperation values",
          "// and the compiler lowers them to ordinary ActiveRecord migration calls.",
          "@:railsMigration({",
          metadata.join(",\n"),
          "})",
          "class #{@name} extends Migration {",
          "\tpublic static final operations:Array<MigrationOperation> = [",
        ]
        lines.concat(plan.fetch(:operations).map.with_index do |operation, index|
          suffix = index == plan.fetch(:operations).length - 1 ? "" : ","
          "\t\t#{operation}#{suffix}"
        end)
        lines << "\t];"
        lines << "}"
        lines << ""
        lines.join("\n")
      end

      def effective_external_tables(plan)
        return @external_tables if plan.fetch(:mode) == "create"
        return @external_tables unless @external_tables.empty?
        return [] unless @known_models.empty?
        return [] if @from_schema

        [plan.fetch(:table)]
      end

      def validate_existing_migrations!(relative_path, plan)
        haxe_path = File.expand_path(relative_path, @output_dir)
        scan_root = File.expand_path(@haxe_dir, @output_dir)
        if Dir.exist?(scan_root)
          Dir.glob(File.join(scan_root, "**", "*.hx")).each do |path|
            next if File.expand_path(path) == haxe_path

            content = File.read(path)
            raise Error, "Migration timestamp #{@timestamp} is already used by #{path}" if content.include?("timestamp: #{Common.haxe_string(@timestamp)}")
            raise Error, "Migration className #{@name} is already used by #{path}" if content.include?("className: #{Common.haxe_string(@name)}")
          end
        end

        ruby_path = File.join(@output_dir, "db", "migrate", "#{@timestamp}_#{Common.file_name(@name)}.rb")
        if File.exist?(ruby_path) && !@force && !Common.owned_file?(ruby_path, @output_dir)
          raise Error, "Refusing to generate migration because db/migrate/#{@timestamp}_#{Common.file_name(@name)}.rb already exists and is not RailsHx-owned."
        end

        Dir.glob(File.join(@output_dir, "db", "migrate", "*.rb")).sort.each do |path|
          next if File.expand_path(path) == File.expand_path(ruby_path) && (@force || Common.owned_file?(path, @output_dir))

          basename = File.basename(path)
          if basename.start_with?("#{@timestamp}_")
            raise Error, "Migration timestamp #{@timestamp} is already used by #{Common.relative_path(@output_dir, path)}"
          end

          classes = File.read(path).scan(/^\s*class\s+([A-Z][A-Za-z0-9_:]*)\s*</).flatten
          if classes.include?(@name)
            raise Error, "Migration class #{@name} is already used by #{Common.relative_path(@output_dir, path)}"
          end
        end
      end

      def parse_attribute(entry)
        match = ATTRIBUTE_PATTERN.match(entry.to_s)
        raise Error, "Invalid attribute #{entry.inspect}. Expected field:type, field:type!, or field:type:index." unless match

        raw_name = match[1]
        raw_type = match[2]
        raw_modifiers = match[3].to_s.split(":")
        nullable = true
        if raw_type.end_with?("!")
          raw_type = raw_type.delete_suffix("!")
          nullable = false
        end
        type, type_options = parse_type(raw_type)
        modifiers = raw_modifiers.map(&:strip).reject(&:empty?)
        {
          name: Common.haxe_identifier(raw_name),
          column: safe_column_name(Common.file_name(raw_name), "attribute"),
          type: type,
          type_options: type_options,
          nullable: nullable,
          index: modifiers.any? { |modifier| modifier == "index" || modifier == "uniq" || modifier == "unique" },
          unique: modifiers.any? { |modifier| modifier == "uniq" || modifier == "unique" },
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
          raise Error, "Unsupported migration attribute type #{raw_type.inspect}"
        end
      end

      def column_constructor(attribute)
        options = column_options(attribute)
        case attribute.fetch(:type)
        when "string"
          "StringColumn(#{options})"
        when "text"
          "TextColumn(#{options})"
        when "integer", "int"
          "IntegerColumn(#{options})"
        when "boolean", "bool"
          "BooleanColumn(#{options})"
        when "float"
          "FloatColumn(#{options})"
        when "decimal"
          "DecimalColumn(#{decimal_options(attribute)})"
        else
          raise Error, "Unsupported column type #{attribute.fetch(:type)}"
        end
      end

      def column_options(attribute)
        options = []
        options << "nullable: false" unless attribute.fetch(:nullable)
        "{#{options.join(", ")}}"
      end

      def decimal_options(attribute)
        options = []
        options << "nullable: false" unless attribute.fetch(:nullable)
        type_options = attribute.fetch(:type_options)
        options << "precision: #{type_options.fetch(:precision)}" if type_options[:precision]
        options << "scale: #{type_options.fetch(:scale)}" if type_options[:scale]
        "{#{options.join(", ")}}"
      end

      def reference_options(attribute)
        options = []
        options << "nullable: false" unless attribute.fetch(:nullable)
        options << "foreignKey: true"
        options << "polymorphic: true" if attribute.fetch(:type_options)[:polymorphic]
        "{#{options.join(", ")}}"
      end

      def index_options(attribute)
        attribute.fetch(:unique) ? "{unique: true}" : "{}"
      end

      def reference_attribute?(attribute)
        attribute.fetch(:type) == "references"
      end

      def safe_table_name(value, label)
        safe = Common.file_name(value)
        raise Error, "#{label} must be a safe Rails table name" unless safe.match?(/\A[a-z][a-z0-9_]*\z/)

        safe
      end

      def safe_column_name(value, label)
        safe = Common.file_name(value)
        raise Error, "#{label} must be a safe Rails column name" unless safe.match?(/\A[a-z][a-z0-9_]*\z/)

        safe
      end

      def class_name(value)
        value.to_s.split(/[_\-\s]/).reject(&:empty?).map { |part| part[0].upcase + part[1..] }.join
      end
    end
  end
end
