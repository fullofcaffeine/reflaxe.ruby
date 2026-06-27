# frozen_string_literal: true

require "optparse"
require "ripper"
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
          service_sources: [],
          rbs_sources: [],
          templates: [],
          extension_sources: [],
          extension_modules: [],
          gems: [],
          schema: false,
          schema_models: [],
          schema_from: "db/schema.rb",
          allow_dynamic: false,
          migrations: false,
          write: nil,
          locals: "",
          devise_hhx_views: false,
          force: false,
          discover: false,
        }
        OptionParser.new do |parser|
          parser.on("--output PATH") { |value| options[:output] = value }
          parser.on("--package NAME") { |value| options[:package] = value }
          parser.on("--service NAME") { |value| options[:services].concat(Common.split_csv(value)) }
          parser.on("--service-source PATH") { |value| options[:service_sources].concat(Common.split_csv(value)) }
          parser.on("--rbs PATH") { |value| options[:rbs_sources].concat(Common.split_csv(value)) }
          parser.on("--template PATH") { |value| options[:templates].concat(Common.split_csv(value)) }
          parser.on("--extension-source PATH") { |value| options[:extension_sources].concat(Common.split_csv(value)) }
          parser.on("--extension-module NAME") { |value| options[:extension_modules].concat(Common.split_csv(value)) }
          parser.on("--gem NAME") { |value| options[:gems].concat(Common.split_csv(value)) }
          parser.on("--schema") { options[:schema] = true }
          parser.on("--models LIST") { |value| options[:schema_models].concat(Common.split_csv(value)) }
          parser.on("--from PATH") { |value| options[:schema_from] = value }
          parser.on("--allow-dynamic") { options[:allow_dynamic] = true }
          parser.on("--migrations") { options[:migrations] = true }
          parser.on("--write WHAT") { |value| options[:write] = value }
          parser.on("--locals FIELDS") { |value| options[:locals] = value }
          parser.on("--devise-hhx-views") { options[:devise_hhx_views] = true }
          parser.on("--force") { options[:force] = true }
          parser.on("--discover") { options[:discover] = true }
        end.parse!(argv)
        if options[:services].empty? && options[:service_sources].any?
          raise Error, "--service-source requires at least one explicit --service constant."
        end
        if options[:services].empty? && options[:rbs_sources].any?
          raise Error, "--rbs requires at least one explicit --service constant."
        end
        if options[:gems].any? && !options[:discover] && options[:write] != "contracts"
          raise Error, "--gem requires --discover or --write contracts."
        end
        if options[:write] && options[:write] != "contracts"
          raise Error, "--write only supports contracts for gem adoption."
        end
        if options[:schema_models].any? && !options[:schema]
          raise Error, "--models is only supported with --schema adoption."
        end
        if options[:schema] && !options[:discover] && options[:schema_models].empty?
          raise Error, "--schema requires --discover or --models ModelName[,OtherModel]."
        end
        if options[:migrations] && !options[:discover]
          raise Error, "--migrations is a discover-only adoption report; use --migrations --discover."
        end
        if !options[:discover] && options[:services].empty? && options[:templates].empty? && options[:extension_sources].empty? && options[:gems].empty? && !options[:schema] && !options[:migrations]
          raise Error, "Provide at least one --service, --template, or --extension-source boundary to adopt."
        end

        options
      end

      def initialize(options)
        @output_dir = File.expand_path(options.fetch(:output))
        @package_name = checked_package_name(options.fetch(:package))
        @services = options.fetch(:services).map { |service| checked_constant_path(service, "--service") }
        @service_sources = options.fetch(:service_sources)
        @rbs_sources = options.fetch(:rbs_sources)
        @templates = options.fetch(:templates).map { |template| checked_template_path(template) }
        @extension_sources = options.fetch(:extension_sources)
        @extension_modules = options.fetch(:extension_modules).map { |mod| checked_constant_path(mod, "--extension-module") }
        @gems = options.fetch(:gems).map { |gem_name| checked_gem_name(gem_name) }
        @schema = options.fetch(:schema)
        @schema_models = options.fetch(:schema_models).map { |model| checked_schema_model_name(model) }
        @schema_from = options.fetch(:schema_from)
        @allow_dynamic = options.fetch(:allow_dynamic)
        @migrations = options.fetch(:migrations)
        @write_mode = options.fetch(:write)
        @locals = parse_locals(options.fetch(:locals))
        @devise_hhx_views = options.fetch(:devise_hhx_views)
        @force = options.fetch(:force)
        @discover = options.fetch(:discover)
      end

      def run
        discover_boundaries if @discover
        discover_gems if @discover && @gems.any?
        discover_schema if @discover && @schema
        discover_migrations if @discover && @migrations
        write_gem_contracts if @write_mode == "contracts"
        write_schema_models if @schema && @schema_models.any?
        @services.each { |service| write_service(service) }
        @templates.each { |template| write_template(template) }
        @extension_sources.each { |source| write_extension_contracts(source) }
      end

      private

      def discover_boundaries
        return if @gems.any? && @services.empty? && @templates.empty? && @extension_sources.empty?

        services = discover_services
        templates = discover_templates

        puts "[rails:adopt] Candidate Ruby constants:"
        services.each { |service| puts "  --service #{service}" }
        puts "  (none found)" if services.empty?

        puts "[rails:adopt] Candidate ERB templates:"
        templates.each { |template| puts "  --template #{template}" }
        puts "  (none found)" if templates.empty?
      end

      def discover_gems
        @gems.each do |gem_name|
          if devise_gem?(gem_name)
            print_devise_inventory(devise_inventory(gem_name))
            next
          end

          inventory = gem_inventory(gem_name)
          puts "[rails:adopt:gem] #{inventory.fetch(:name)} #{inventory.fetch(:version)}"
          puts "  source files: #{inventory.fetch(:ruby_files).length}"
          if inventory.fetch(:constants).empty?
            puts "  constants: (none found)"
          else
            inventory.fetch(:constants).each { |constant| puts "  constant: #{constant}" }
          end
          puts "  next: bin/rails generate hxruby:adopt --gem #{gem_name} --write contracts"
        end
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

      def discover_schema
        inventory = schema_inventory
        puts "[rails:adopt:schema] #{relative_output_path(schema_path)}"
        inventory.fetch(:tables).each do |table|
          puts "  table: #{table.fetch(:name)} -> models.#{table.fetch(:model)}"
          puts "    columns: #{table.fetch(:columns).length}"
          puts "    timestamps: #{table.fetch(:timestamps)}"
          table.fetch(:columns).each do |column|
            column.fetch(:review_notes).each { |note| puts "    review: #{note}" }
          end
          table.fetch(:indexes).each do |index|
            puts "    index: #{index.fetch(:columns).join(",")}#{index.fetch(:unique) ? " unique" : ""}"
          end
          table.fetch(:foreign_keys).each do |foreign_key|
            puts "    foreign_key: #{foreign_key.fetch(:column)} -> #{foreign_key.fetch(:to_table)}"
          end
          table.fetch(:review_notes).each { |note| puts "    review: #{note}" }
        end
        puts "  (no tables found)" if inventory.fetch(:tables).empty?
        puts "  next: bin/rails generate hxruby:adopt --schema --models #{inventory.fetch(:tables).map { |table| table.fetch(:model) }.join(",")}"
      end

      def discover_migrations
        inventory = migration_inventory
        puts "[rails:adopt:migrations] db/migrate"
        inventory.fetch(:files).each do |migration|
          classes = migration.fetch(:classes)
          class_label = classes.empty? ? "unknown" : classes.join(",")
          puts "  migration: #{migration.fetch(:timestamp) || "no_timestamp"} #{migration.fetch(:file)} class=#{class_label} owner=#{migration.fetch(:owner)}"
        end
        puts "  (no migrations found)" if inventory.fetch(:files).empty?
        inventory.fetch(:timestamp_collisions).each do |timestamp, files|
          puts "  collision: duplicate timestamp #{timestamp}: #{files.join(", ")}"
        end
        inventory.fetch(:class_collisions).each do |class_name, files|
          puts "  collision: duplicate class #{class_name}: #{files.join(", ")}"
        end
        puts "  next: prefer --schema adoption for current model contracts; Rails-owned historical migrations are not translated."
      end

      def parse_locals(raw)
        Common.split_csv(raw).map do |entry|
          name, type = entry.split(":", 2).map(&:strip)
          raise Error, "Invalid local #{entry.inspect}. Expected name:Type." if name.to_s.empty? || type.to_s.empty?
          raise Error, "Invalid local name #{name.inspect}. Expected a safe Haxe field identifier." unless safe_haxe_identifier?(name)
          raise Error, "Invalid local type #{type.inspect}. Expected a safe Haxe type reference." unless safe_haxe_type?(type)

          { name: name, type: type }
        end
      end

      def write_service(native_name)
        haxe_class = native_name.split("::").last
        package = service_package(native_name)
        path = File.join(@output_dir, "src_haxe", Common.package_path(package), "#{haxe_class}.hx")
        write_owned(path, render_service(package, haxe_class, native_name, service_contract(native_name)), kind: "haxe_adopted_service")
      end

      def service_package(native_name)
        modules = native_name.split("::")[0...-1].map { |part| Common.file_name(part) }
        [@package_name, *modules].reject(&:empty?).join(".")
      end

      def render_service(package, haxe_class, native_name, contract = nil)
        lines = [
          "package #{package};",
          "",
          "// Rails-owned Ruby constant adopted through a typed Haxe extern.",
        ]
        if contract
          lines += [
            "// Generated from #{contract.fetch(:source_label)}.",
          ]
          if contract.fetch(:source_kind, "ruby_source") == "rbs"
            lines += [
              "// Generated from deterministic RBS metadata.",
              "// TODO: Review any Dynamic placeholders from unsupported or application-specific RBS types.",
            ]
          else
            lines += [
              "// Review required: Ruby source does not carry complete Haxe type metadata.",
              "// Replace Dynamic placeholders with precise types as this boundary stabilizes.",
            ]
          end
        else
          lines << "// Add method signatures here as the boundary stabilizes; keep raw Ruby out of Haxe app code."
        end
        lines += [
          "@:native(#{Common.haxe_string(native_name)})",
          "extern class #{haxe_class} {",
        ]
        if contract
          contract.fetch(:constructors).each { |method| lines.concat(render_service_method(method, :constructor)) }
          contract.fetch(:instance).each { |method| lines.concat(render_service_method(method, :instance)) }
          contract.fetch(:class_methods).each { |method| lines.concat(render_service_method(method, :class_method)) }
        end
        lines += [
          "}",
          "",
        ]
        lines.join("\n")
      end

      def service_contract(native_name)
        return nil if @service_sources.empty? && @rbs_sources.empty?

        contracts = rbs_contracts + service_source_contracts
        contract = contracts.find { |candidate| candidate.fetch(:constant_name) == native_name }
        raise Error, "Service #{native_name} not found in --service-source/--rbs file(s)." unless contract

        contract
      end

      def service_source_contracts
        @service_source_contracts ||= @service_sources.flat_map do |source|
          source_path = checked_input_file(source, "--service-source")
          raise Error, "Service source does not exist: #{source}" unless File.file?(source_path)

          ServiceSourceParser.new(source_path, relative_output_path(source_path)).contracts
        end
      end

      def rbs_contracts
        @rbs_contracts ||= @rbs_sources.flat_map do |source|
          source_path = checked_input_file(source, "--rbs")
          raise Error, "RBS source does not exist: #{source}" unless File.file?(source_path)

          RbsSourceParser.new(source_path, relative_output_path(source_path)).contracts
        end
      end

      def render_service_method(method, kind)
        if method.fetch(:complex)
          return [
            "\t// TODO: #{method.fetch(:ruby_name)} uses splat, keyword, block, or post arguments and needs manual typing.",
          ]
        end

        args = method.fetch(:args).map do |arg|
          prefix = arg.fetch(:optional) ? "?" : ""
          "#{prefix}#{Common.haxe_identifier(Common.haxe_method_name(arg.fetch(:name)), fallback: "arg")}:#{arg.fetch(:type)}"
        end
        case kind
        when :constructor
          [
            "\t// Inferred from Ruby initialize; tighten argument types after review.",
            "\tpublic function new(#{args.join(", ")}):Void;",
          ]
        when :class_method
          inferred_function_lines(method, "public static function", args)
        else
          inferred_function_lines(method, "public function", args)
        end
      end

      def inferred_function_lines(method, access, args)
        ruby_name = method.fetch(:ruby_name)
        haxe_name = Common.haxe_method_name(ruby_name)
        return_type = method.fetch(:return_type, "Dynamic")
        lines = [
          "\t// #{method.fetch(:comment, "Inferred from Ruby source; tighten Dynamic types after review.")}",
        ]
        lines << "\t@:native(#{Common.haxe_string(ruby_name)})" if haxe_name != ruby_name
        lines << "\t#{access} #{haxe_name}(#{args.join(", ")}):#{return_type};"
        lines
      end

      def write_template(template_path)
        safe_template_path = checked_template_path(template_path)
        haxe_class = "#{Common.class_name_from_path(safe_template_path)}Template"
        locals_name = "#{Common.class_name_from_path(safe_template_path)}Locals"
        package = "#{@package_name}.templates"
        path = File.join(@output_dir, "src_haxe", Common.package_path(package), "#{haxe_class}.hx")
        write_owned(path, render_template(package, haxe_class, locals_name, safe_template_path), kind: "haxe_adopted_template")
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

      def write_extension_contracts(source)
        source_path = checked_input_file(source, "--extension-source")
        raise Error, "Extension source does not exist: #{source}" unless File.file?(source_path)

        contracts = ExtensionSourceParser.new(source_path).contracts
        if @extension_modules.any?
          contracts = contracts.select { |contract| @extension_modules.include?(contract.fetch(:module_name)) }
          missing = @extension_modules - contracts.map { |contract| contract.fetch(:module_name) }
          raise Error, "Extension module(s) not found in #{source}: #{missing.join(", ")}" if missing.any?
        end
        raise Error, "No Ruby modules with adoptable methods found in #{source}" if contracts.empty?

        package = "#{@package_name}.extensions"
        source_label = relative_output_path(source_path)
        contracts.each do |contract|
          write_extension_contract(package, source_label, contract, :instance)
          write_extension_contract(package, source_label, contract, :class_methods)
        end
      end

      def relative_output_path(path)
        path.delete_prefix("#{@output_dir}/")
      end

      def checked_package_name(value)
        package = value.to_s.strip
        unless package.match?(/\A[a-z_][A-Za-z0-9_]*(?:\.[a-z_][A-Za-z0-9_]*)*\z/)
          raise Error, "--package must be a safe Haxe package path"
        end
        package
      end

      def checked_constant_path(value, label)
        constant = value.to_s.strip
        unless constant.match?(/\A[A-Z][A-Za-z0-9_]*(?:::[A-Z][A-Za-z0-9_]*)*\z/)
          raise Error, "#{label} must be a safe Ruby constant path"
        end
        constant
      end

      def checked_template_path(value)
        Common.safe_relative_path(value, label: "--template")
      end

      def checked_gem_name(value)
        name = value.to_s.strip
        unless name.match?(/\A[a-zA-Z0-9_.-]+\z/)
          raise Error, "--gem must be a safe Bundler gem name"
        end
        name
      end

      def checked_schema_model_name(value)
        model = value.to_s.strip
        unless model.match?(/\A[A-Z][A-Za-z0-9_]*\z/)
          raise Error, "--models entries must be safe Haxe/Ruby model class names"
        end
        model
      end

      def checked_input_file(value, label)
        path = File.expand_path(value, @output_dir)
        unless path == @output_dir || path.start_with?("#{@output_dir}#{File::SEPARATOR}")
          raise Error, "#{label} must stay inside the generator output/app root"
        end
        path
      end

      def safe_haxe_identifier?(value)
        name = value.to_s
        name.match?(/\A[A-Za-z_][A-Za-z0-9_]*\z/) && !Common.haxe_keywords.include?(name)
      end

      def safe_haxe_type?(value)
        type = value.to_s
        type.match?(/\A[A-Za-z_][A-Za-z0-9_.]*(?:<\s*[A-Za-z_][A-Za-z0-9_.]*(?:\s*,\s*[A-Za-z_][A-Za-z0-9_.]*)*\s*>)?\z/)
      end

      def write_extension_contract(package, source_label, contract, kind)
        methods = contract.fetch(kind)
        return if methods.empty?

        module_name = contract.fetch(:module_name)
        suffix = kind == :instance ? "Instance" : "ClassMethods"
        haxe_class = "#{Common.class_name_from_path(module_name)}#{suffix}"
        path = File.join(@output_dir, "src_haxe", Common.package_path(package), "#{haxe_class}.hx")
        write_owned(path, render_extension_contract(package, haxe_class, module_name, source_label, methods, kind), kind: "haxe_adopted_extension")
      end

      def write_owned(path, content, kind:)
        Common.write_file(path, content, force: @force, root: @output_dir, kind: kind, source: "hxruby:adopt")
      end

      def write_schema_models
        inventory = schema_inventory
        by_model = inventory.fetch(:tables).to_h { |table| [table.fetch(:model), table] }
        missing = @schema_models.reject { |model| by_model.key?(model) }
        raise Error, "--schema --models requested model(s) not found in #{relative_output_path(schema_path)}: #{missing.join(", ")}" if missing.any?

        @schema_models.each do |model|
          table = by_model.fetch(model)
          path = File.join(@output_dir, "src_haxe", "models", "#{model}.hx")
          write_owned(path, render_schema_model(table), kind: "haxe_adopted_schema_model")
        end
      end

      def render_schema_model(table)
        lines = [
          "package models;",
          "",
          "// Rails-owned table adopted from #{relative_output_path(schema_path)}.",
          "// Runtime owner: Rails/database schema. Haxe owner: typed contract for",
          "// queries, params, templates, and gradual migration into RailsHx.",
          "@:railsModel(#{Common.haxe_string(table.fetch(:name))})",
        ]
        lines << "@:railsTimestamps" if table.fetch(:timestamps)
        lines += [
          "class #{table.fetch(:model)} extends rails.active_record.Base<#{table.fetch(:model)}> {",
          "\t@:railsColumn({primaryKey: true, dbType: \"bigint\"})",
          "\tpublic var id:Int;",
        ]
        table.fetch(:columns).each do |column|
          next if column.fetch(:timestamp_column)
          next if column.fetch(:name) == "id"

          lines << ""
          column.fetch(:review_notes).each { |note| lines << "\t// TODO: #{note}" }
          lines << "\t@:railsColumn#{schema_column_metadata(column)}"
          lines << "\tpublic var #{column.fetch(:haxe_name)}:#{column.fetch(:haxe_type)};"
        end
        table.fetch(:review_notes).each do |note|
          lines << ""
          lines << "\t// TODO: #{note}"
        end
        lines << "}"
        lines << ""
        lines.join("\n")
      end

      def schema_column_metadata(column)
        options = []
        options << "nullable: false" unless column.fetch(:nullable)
        options << "dbType: #{Common.haxe_string(column.fetch(:rails_type))}" if column.fetch(:db_type)
        options << "defaultValue: #{column.fetch(:default_haxe)}" if column.fetch(:default_haxe)
        options << "index: true" if column.fetch(:index)
        options << "unique: true" if column.fetch(:unique)
        return "" if options.empty?

        "({#{options.join(", ")}})"
      end

      def schema_inventory
        @schema_inventory ||= SchemaParser.new(schema_path, allow_dynamic: @allow_dynamic).inventory
      end

      def schema_path
        @schema_path ||= checked_input_file(@schema_from, "--schema --from")
      end

      def migration_inventory
        root = File.join(@output_dir, "db", "migrate")
        files = Dir.exist?(root) ? Dir.glob(File.join(root, "*.rb")).sort : []
        timestamps = Hash.new { |hash, key| hash[key] = [] }
        classes = Hash.new { |hash, key| hash[key] = [] }
        entries = files.map do |path|
          relative = relative_output_path(path)
          timestamp = File.basename(path)[/\A([0-9]{14})_/, 1]
          body = File.read(path)
          class_names = body.scan(/^\s*class\s+([A-Z][A-Za-z0-9_:]*)\s*</).flatten
          timestamps[timestamp] << relative if timestamp
          class_names.each { |class_name| classes[class_name] << relative }
          {
            file: relative,
            timestamp: timestamp,
            classes: class_names,
            owner: Common.owned_file?(path, @output_dir) ? "railshx" : "rails",
          }
        end
        {
          files: entries,
          timestamp_collisions: timestamps.select { |_timestamp, paths| paths.length > 1 },
          class_collisions: classes.select { |_class_name, paths| paths.length > 1 },
        }
      end

      def write_gem_contracts
        @gems.each do |gem_name|
          if devise_gem?(gem_name)
            write_devise_contracts(gem_name)
            next
          end

          inventory = gem_inventory(gem_name)
          package = "#{@package_name}.gems.#{Common.file_name(gem_name).tr("-", "_")}"
          gem_dir = File.join(@output_dir, "src_haxe", Common.package_path(package))
          write_owned(File.join(gem_dir, "GemLayer.hx"), render_gem_layer(package, inventory), kind: "haxe_adopted_gem_layer")
          write_owned(File.join(@output_dir, "docs", "railshx", "gems", "#{Common.file_name(gem_name)}.md"), render_gem_layer_doc(inventory), kind: "docs")
          gem_service_contracts(inventory).each do |contract|
            native_name = contract.fetch(:constant_name)
            next if native_name.to_s.empty?

            haxe_class = native_name.split("::").last
            write_owned(
              File.join(gem_dir, "#{haxe_class}.hx"),
              render_service(package, haxe_class, native_name, contract.merge(source_label: "Bundler gem #{gem_name}")),
              kind: "haxe_adopted_gem_contract"
            )
          end
        end
      end

      def gem_inventory(gem_name)
        spec = resolve_bundler_gem(gem_name)
        gem_root = File.expand_path(spec.full_gem_path)
        raise Error, "Bundler gem #{gem_name} has an unsafe or missing path." unless File.directory?(gem_root)

        ruby_files = Dir.glob(File.join(gem_root, "lib", "**", "*.rb")).sort
        constants = ruby_files.flat_map { |path| GemSourceInventory.new(path).constants }.uniq.sort
        {
          name: spec.name,
          version: spec.version.to_s,
          ruby_files: ruby_files,
          constants: constants,
        }
      end

      def resolve_bundler_gem(gem_name)
        gemfile = File.join(@output_dir, "Gemfile")
        raise Error, "Cannot adopt gem #{gem_name}: Gemfile not found in #{@output_dir}." unless File.file?(gemfile)

        require "bundler"
        lockfile = File.join(@output_dir, "Gemfile.lock")
        specs = nil
        Dir.chdir(@output_dir) do
          definition = Bundler::Definition.build(gemfile, File.file?(lockfile) ? lockfile : nil, nil)
          specs = definition.specs
        end
        spec = specs.find { |candidate| candidate.name == gem_name }
        raise Error, "Gem #{gem_name} is not installed in the app bundle. Add it to Gemfile and run bundle install." unless spec

        spec
      rescue Bundler::BundlerError => error
        raise Error, "Unable to inspect Bundler gem #{gem_name}: #{error.message}"
      end

      def gem_service_contracts(inventory)
        inventory.fetch(:ruby_files).flat_map do |source_path|
          ServiceSourceParser.new(source_path, "Bundler gem #{inventory.fetch(:name)}").contracts
        rescue Error
          []
        end
      end

      def render_gem_layer(package, inventory)
        [
          "package #{package};",
          "",
          "// RailsHx generated this app-local gem layer from deterministic Bundler metadata.",
          "// Runtime ownership stays with the Ruby gem; this class only records the",
          "// reviewed Haxe contract boundary for application code and tooling.",
          "// Review required: generated externs may contain Dynamic placeholders when",
          "// Ruby source/RBS did not prove a precise Haxe type.",
          "class GemLayer {",
          "\tpublic static inline final gemName:String = #{Common.haxe_string(inventory.fetch(:name))};",
          "\tpublic static inline final version:String = #{Common.haxe_string(inventory.fetch(:version))};",
          "\tpublic static inline final reviewRequired:Bool = true;",
          "}",
          "",
        ].join("\n")
      end

      def render_gem_layer_doc(inventory)
        [
          "# RailsHx Gem Layer: #{inventory.fetch(:name)}",
          "",
          "- Gem: `#{inventory.fetch(:name)}`",
          "- Version: `#{inventory.fetch(:version)}`",
          "- Metadata source: Bundler app Gemfile plus parsed Ruby source files.",
          "- Runtime owner: the Ruby gem and Bundler.",
          "- Haxe owner: app-local reviewed extern/contracts under `src_haxe/#{Common.package_path(@package_name)}/gems/#{Common.file_name(inventory.fetch(:name)).tr("-", "_")}`.",
          "",
          "## Constants Found",
          "",
          *(inventory.fetch(:constants).empty? ? ["- None found."] : inventory.fetch(:constants).map { |constant| "- `#{constant}`" }),
          "",
          "## Review Checklist",
          "",
          "- Replace any generated `Dynamic` placeholders with precise Haxe types where the app relies on that API.",
          "- Keep runtime setup in Ruby/Rails: Gemfile, initializers, migrations, routes, and gem generators.",
          "- Run `bundle exec rake hxruby:compile`, Rails tests, route parity, and browser/runtime gates relevant to this gem.",
          "- Treat LLM-generated edits as reviewable patches; do not remove TODO/review markers without deterministic coverage.",
          "",
        ].join("\n")
      end

      def devise_gem?(gem_name)
        gem_name == "devise"
      end

      def print_devise_inventory(inventory)
        puts "[rails:adopt:devise] #{inventory.fetch(:name)} #{inventory.fetch(:version_string)}"
        inventory.fetch(:scopes).each do |scope|
          puts "  scope: #{scope.fetch(:scope)} model=#{scope.fetch(:model)} resource=#{scope.fetch(:route_resource)}"
          puts "    route authorable: #{scope.fetch(:route_authorable)}"
          puts "    route reason: #{scope.fetch(:route_authorability_reason)}" unless scope.fetch(:route_authorable)
          puts "    modules: #{scope.fetch(:modules).join(", ")}"
          puts "    schema: #{scope.fetch(:schema_status)}"
          scope.fetch(:helpers).each { |helper| puts "    helper: #{helper}" }
        end
        diagnostics = devise_diagnostics(inventory).fetch(:diagnostics)
        if diagnostics.empty?
          puts "  diagnostics: none"
        else
          diagnostics.each { |diagnostic| puts "  diagnostic: #{diagnostic.fetch(:message)}" }
        end
        puts "  next: bin/rails generate hxruby:adopt --gem devise --write contracts"
      end

      def write_devise_contracts(gem_name)
        inventory = devise_inventory(gem_name)
        base_dir = File.join(@output_dir, ".railshx", "gems", "devise")
        write_owned(File.join(base_dir, "inventory.json"), JSON.pretty_generate(inventory) + "\n", kind: "devise_inventory")
        write_owned(File.join(base_dir, "diagnostics.json"), JSON.pretty_generate(devise_diagnostics(inventory)) + "\n", kind: "devise_diagnostics")
        inventory.fetch(:scopes).each do |scope|
          class_name = "#{scope.fetch(:model)}Auth"
          write_owned(
            File.join(@output_dir, "src_haxe", "app", "auth", "#{class_name}.hx"),
            render_devise_auth_contract(scope),
            kind: "devise_auth_contract"
          )
          write_devise_hhx_views(scope) if @devise_hhx_views
        end
        write_owned(File.join(@output_dir, "docs", "railshx", "gems", "devise.md"), render_devise_doc(inventory), kind: "docs")
      end

      def write_devise_hhx_views(scope)
        model = scope.fetch(:model)
        view_dir = File.join(@output_dir, "src_haxe", "views", "devise", scope.fetch(:route_resource))
        write_owned(
          File.join(view_dir, "SessionsNewView.hx"),
          render_devise_sessions_new_view(scope),
          kind: "devise_hhx_view"
        )
        if scope.fetch(:modules).include?("registerable")
          write_owned(
            File.join(view_dir, "RegistrationsNewView.hx"),
            render_devise_registrations_new_view(scope),
            kind: "devise_hhx_view"
          )
        end
        if scope.fetch(:modules).include?("recoverable")
          write_owned(
            File.join(view_dir, "PasswordsNewView.hx"),
            render_devise_passwords_new_view(scope),
            kind: "devise_hhx_view"
          )
          write_owned(
            File.join(view_dir, "PasswordsEditView.hx"),
            render_devise_passwords_edit_view(scope),
            kind: "devise_hhx_view"
          )
        end
        if scope.fetch(:modules).include?("confirmable")
          write_owned(
            File.join(view_dir, "ConfirmationsNewView.hx"),
            render_devise_confirmations_new_view(scope),
            kind: "devise_hhx_view"
          )
        end
        if scope.fetch(:modules).include?("lockable")
          write_owned(
            File.join(view_dir, "UnlocksNewView.hx"),
            render_devise_unlocks_new_view(scope),
            kind: "devise_hhx_view"
          )
        end
        puts "[rails:adopt:devise] wrote HHX view skeletons for #{model}; compile Haxe to emit Rails ERB artifacts."
      end

      def devise_inventory(gem_name)
        base = gem_inventory(gem_name)
        scopes = parse_devise_routes.map do |route_scope|
          modules = parse_devise_modules(route_scope.fetch(:model))
          schema = parse_devise_schema(route_scope.fetch(:route_resource), modules)
          {
            scope: route_scope.fetch(:scope),
            route_resource: route_scope.fetch(:route_resource),
            model: route_scope.fetch(:model),
            table: route_scope.fetch(:route_resource),
            route_authorable: route_scope.fetch(:route_authorable),
            route_authorability_reason: route_scope.fetch(:route_authorability_reason),
            modules: modules,
            helpers: devise_helpers(route_scope.fetch(:scope)),
            schema_status: schema.fetch(:status),
            schema_columns: schema.fetch(:columns),
            required_columns: schema.fetch(:required_columns),
          }
        end
        {
          version: 1,
          kind: "devise_inventory",
          name: base.fetch(:name),
          version_string: base.fetch(:version),
          ruby_files: base.fetch(:ruby_files).length,
          constants: base.fetch(:constants),
          scopes: scopes,
        }
      end

      def parse_devise_routes
        routes_path = File.join(@output_dir, "config", "routes.rb")
        raise Error, "Cannot adopt Devise: config/routes.rb not found in #{@output_dir}." unless File.file?(routes_path)

        content = File.read(routes_path)
        declarations = extract_devise_route_declarations(content, routes_path)
        raise Error, "Cannot adopt Devise: no literal devise_for scopes found in config/routes.rb." if declarations.empty?

        duplicates = declarations.map { |declaration| declaration.fetch(:resource) }.tally.select { |_resource, count| count > 1 }.keys
        raise Error, "Cannot adopt Devise: ambiguous duplicate devise_for scope(s): #{duplicates.join(", ")}." if duplicates.any?

        declarations.map do |declaration|
          resource = declaration.fetch(:resource)
          scope = singular_resource_name(resource)
          {
            scope: scope,
            route_resource: resource,
            model: Common.class_name_from_path(scope),
            route_authorable: declaration.fetch(:route_authorable),
            route_authorability_reason: declaration.fetch(:route_authorability_reason),
          }
        end
      end

      # Devise route declarations are Ruby DSL calls, so this uses Ripper tokens
      # rather than regex. The MVP deliberately authorizes only plain top-level
      # `devise_for :users` / `devise_for "users"`; richer Rails-owned route
      # shapes still generate typed auth contracts but cannot be re-emitted by
      # Haxe-owned routes until DeviseHx supports that exact semantic subset.
      def extract_devise_route_declarations(content, routes_path)
        sexp = Ripper.sexp(content)
        raise Error, "Cannot adopt Devise: #{relative_output_path(routes_path)} is not parseable Ruby." unless sexp

        declarations = []
        depth = 0
        draw_depth = nil
        ripper_tokens_by_line(content).sort.each do |_line, tokens|
          line_depth = depth
          draw_depth ||= line_depth + 1 if rails_routes_draw_line?(tokens) && token_count(tokens, :on_kw, "do").positive?

          tokens.each_with_index do |token, index|
            next unless token.fetch(:type) == :on_ident && token.fetch(:text) == "devise_for"

            parsed = parse_devise_for_tokens(tokens, index)
            next unless parsed

            reason = nil
            if draw_depth.nil?
              reason = "existing devise_for is outside Rails.application.routes.draw; keep this route Rails-owned"
            elsif line_depth != draw_depth
              reason = "existing devise_for is nested in another routes block or scope; keep this route Rails-owned"
            elsif parsed.fetch(:has_block)
              reason = "existing devise_for uses a block; keep this route Rails-owned"
            elsif parsed.fetch(:has_options)
              reason = "existing devise_for uses unsupported options; keep this route Rails-owned"
            end

            declarations << {
              resource: parsed.fetch(:resource),
              route_authorable: reason.nil?,
              route_authorability_reason: reason || "",
            }
          end

          depth += token_count(tokens, :on_kw, "do")
          depth += token_count(tokens, :on_lbrace, "{")
          depth -= token_count(tokens, :on_kw, "end")
          depth -= token_count(tokens, :on_rbrace, "}")
          depth = 0 if depth.negative?
        end
        declarations
      end

      def ripper_tokens_by_line(content)
        Ripper.lex(content).each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |((line, column), type, text, _state), by_line|
          next if %i[on_sp on_ignored_sp on_nl on_ignored_nl on_comment].include?(type)

          by_line[line] << { type: type, text: text, column: column }
        end
      end

      def rails_routes_draw_line?(tokens)
        tokens.map { |token| token.fetch(:text) }.join.include?("Rails.application.routes.draw")
      end

      def token_count(tokens, type, text)
        tokens.count { |token| token.fetch(:type) == type && token.fetch(:text) == text }
      end

      def parse_devise_for_tokens(tokens, index)
        cursor = index + 1
        cursor += 1 if tokens[cursor]&.fetch(:type) == :on_lparen
        resource, resource_end = parse_devise_resource(tokens, cursor)
        return nil unless resource

        remaining = tokens[(resource_end + 1)..] || []
        remaining = remaining.reject { |token| token.fetch(:type) == :on_rparen }
        has_block = remaining.any? do |token|
          token.fetch(:type) == :on_kw && token.fetch(:text) == "do"
        end
        has_options = remaining.any? do |token|
          next false if token.fetch(:type) == :on_kw && %w[do end].include?(token.fetch(:text))
          next false if %i[on_lbrace on_rbrace].include?(token.fetch(:type))

          true
        end
        {
          resource: resource,
          has_block: has_block,
          has_options: has_options,
        }
      end

      def parse_devise_resource(tokens, cursor)
        token = tokens[cursor]
        return [nil, cursor] unless token

        if token.fetch(:type) == :on_symbeg && token.fetch(:text) == ":"
          name = tokens[cursor + 1]
          return [nil, cursor] unless name && %i[on_ident on_const].include?(name.fetch(:type))
          return [name.fetch(:text), cursor + 1]
        end

        if token.fetch(:type) == :on_tstring_beg
          pieces = []
          index = cursor + 1
          while tokens[index] && tokens[index].fetch(:type) != :on_tstring_end
            return [nil, cursor] unless tokens[index].fetch(:type) == :on_tstring_content

            pieces << tokens[index].fetch(:text)
            index += 1
          end
          return [nil, cursor] unless tokens[index]
          return [pieces.join, index]
        end

        [nil, cursor]
      end

      def parse_devise_modules(model_name)
        model_path = File.join(@output_dir, "app", "models", "#{Common.file_name(model_name)}.rb")
        raise Error, "Devise scope #{Common.file_name(model_name)} maps to missing model file #{relative_output_path(model_path)}." unless File.file?(model_path)

        content = File.read(model_path)
        declarations = content.scan(/\bdevise\s+([^\n]+)/).flatten
        raise Error, "Devise model #{model_name} must contain a literal devise :module declaration." if declarations.empty?

        modules = declarations.flat_map { |declaration| declaration.scan(/:(#{ruby_identifier_pattern})\b/).flatten }.uniq
        raise Error, "Devise model #{model_name} did not expose any literal Devise modules." if modules.empty?

        modules
      end

      def parse_devise_schema(table_name, modules)
        schema_path = File.join(@output_dir, "db", "schema.rb")
        raise Error, "Cannot adopt Devise: db/schema.rb not found in #{@output_dir}." unless File.file?(schema_path)

        content = File.read(schema_path)
        block = content[/^\s*create_table\s+["']#{Regexp.escape(table_name)}["'][\s\S]*?^\s*end\b/m]
        raise Error, "Cannot adopt Devise: db/schema.rb does not contain table #{table_name.inspect}." unless block

        columns = block.scan(/^\s*t\.(#{ruby_identifier_pattern})\s+["'](#{ruby_identifier_pattern})["']/).map do |type, name|
          { name: name, type: type }
        end
        column_names = columns.map { |column| column.fetch(:name) }
        required_columns = devise_required_columns(modules)
        missing_columns = required_columns - column_names
        if missing_columns.any?
          raise Error, "Cannot adopt Devise: table #{table_name} is missing required column(s): #{missing_columns.join(", ")}."
        end

        {
          status: "ok",
          columns: columns.sort_by { |column| column.fetch(:name) },
          required_columns: required_columns.sort,
        }
      end

      def devise_required_columns(modules)
        modules.flat_map do |mod|
          case mod
          when "database_authenticatable"
            %w[email encrypted_password]
          when "recoverable"
            %w[reset_password_token reset_password_sent_at]
          when "rememberable"
            %w[remember_created_at]
          when "confirmable"
            %w[confirmation_token confirmed_at confirmation_sent_at]
          when "lockable"
            %w[failed_attempts unlock_token locked_at]
          when "trackable"
            %w[sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip]
          else
            []
          end
        end.uniq
      end

      def devise_helpers(scope)
        [
          "authenticate_#{scope}!",
          "current_#{scope}",
          "#{scope}_signed_in?",
        ]
      end

      def devise_diagnostics(inventory)
        diagnostics = inventory.fetch(:scopes).filter_map do |scope|
          next if scope.fetch(:route_authorable)

          {
            level: "warning",
            code: "devise_route_not_authorable",
            scope: scope.fetch(:scope),
            message: scope.fetch(:route_authorability_reason),
          }
        end
        {
          version: 1,
          kind: "devise_diagnostics",
          gem: inventory.fetch(:name),
          status: diagnostics.empty? ? "ok" : "review",
          diagnostics: diagnostics,
        }
      end

      def render_devise_auth_contract(scope)
        class_name = "#{scope.fetch(:model)}Auth"
        route_authorable = scope.fetch(:route_authorable)
        route_meta = [
          "\t\tschema: 1,",
          "\t\trouteAuthorable: #{route_authorable},",
          "\t\tresource: #{Common.haxe_string(scope.fetch(:route_resource))},",
          "\t\tmappingScope: #{Common.haxe_string(scope.fetch(:scope))},",
          "\t\trubyClass: #{Common.haxe_string(scope.fetch(:model))},",
          "\t\thaxeModel: #{Common.haxe_string("models.#{scope.fetch(:model)}")}",
        ]
        unless route_authorable
          route_meta[-1] = "#{route_meta[-1]},"
          route_meta << "\t\treason: #{Common.haxe_string(scope.fetch(:route_authorability_reason))}"
        end
        [
          "package app.auth;",
          "",
          "import devisehx.Auth;",
          "import devisehx.AuthFilter;",
          "import devisehx.DeviseScope;",
          "import devisehx.RouteResource;",
          "import devisehx.ScopeName;",
          "import models.#{scope.fetch(:model)};",
          "import rails.action_controller.Base;",
          "",
          "// Generated by DeviseHx from deterministic Bundler, route, model, and schema metadata.",
          "// Runtime ownership stays with Devise/Rails; this class is an app-local typed",
          "// contract that gives Haxe completion for the concrete Devise scope helpers.",
          "final class #{class_name} {",
          "\t@:deviseHxRoute({",
          *route_meta,
          "\t})",
          "\tpublic static final scope:DeviseScope<#{scope.fetch(:model)}> = DeviseScope.of(ScopeName.named(#{Common.haxe_string(scope.fetch(:scope))}), RouteResource.named(#{Common.haxe_string(scope.fetch(:route_resource))}), #{scope.fetch(:model)});",
          "",
          "\t@:deviseHxAuthFilter({schema: 1, mappingScope: #{Common.haxe_string(scope.fetch(:scope))}})",
          "\tpublic static final authenticate:AuthFilter<#{scope.fetch(:model)}> = Auth.require(scope);",
          "",
          "\t@:deviseHxHelper({schema: 1, kind: \"current\", mappingScope: #{Common.haxe_string(scope.fetch(:scope))}})",
          "\tpublic static inline function current(controller:Base):Null<#{scope.fetch(:model)}> {",
          "\t\treturn Auth.current(controller, scope);",
          "\t}",
          "",
          "\t@:deviseHxHelper({schema: 1, kind: \"currentRequired\", mappingScope: #{Common.haxe_string(scope.fetch(:scope))}})",
          "\tpublic static inline function currentRequired(controller:Base):#{scope.fetch(:model)} {",
          "\t\treturn Auth.currentRequired(controller, scope);",
          "\t}",
          "",
          "\t@:deviseHxHelper({schema: 1, kind: \"signedIn\", mappingScope: #{Common.haxe_string(scope.fetch(:scope))}})",
          "\tpublic static inline function signedIn(controller:Base):Bool {",
          "\t\treturn Auth.signedIn(controller, scope);",
          "\t}",
          "",
          "\t@:deviseHxHelper({schema: 1, kind: \"signIn\", mappingScope: #{Common.haxe_string(scope.fetch(:scope))}})",
          "\tpublic static inline function signIn(controller:Base, resource:#{scope.fetch(:model)}):Void {",
          "\t\tAuth.signIn(controller, scope, resource);",
          "\t}",
          "",
          "\t@:deviseHxHelper({schema: 1, kind: \"signOut\", mappingScope: #{Common.haxe_string(scope.fetch(:scope))}})",
          "\tpublic static inline function signOut(controller:Base):Void {",
          "\t\tAuth.signOut(controller, scope);",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_devise_sessions_new_view(scope)
        model = scope.fetch(:model)
        auth_class = "#{model}Auth"
        route_resource = scope.fetch(:route_resource)
        [
          "package views.devise.#{route_resource};",
          "",
          "import app.auth.#{auth_class};",
          "import devisehx.hhx.AuthLinks;",
          "import devisehx.hhx.DeviseFormFields;",
          "import models.#{model};",
          "import rails.action_view.FlashMessages;",
          "import rails.action_view.HtmlNode;",
          "",
          "typedef SessionsNewLocals = {",
          "\tvar resource:#{model};",
          "}",
          "",
          "// Generated DeviseHx HHX session view skeleton.",
          "// Devise/Rails still owns authentication runtime behavior; this Haxe file",
          "// owns the typed template source and compiles to app/views/devise/sessions/new.html.erb.",
          "// Type safety: AuthLinks.sessionPath validates #{auth_class}.scope metadata,",
          "// DeviseFormFields lowers checked Haxe refs to Devise's Rails form keys,",
          "// and FlashMessages reads ordinary Rails flash without authoring raw ERB.",
          "@:railsTemplate(\"devise/sessions/new\")",
          "@:railsTemplateAst(\"render\")",
          "class SessionsNewView {",
          "\tpublic static function render(locals:SessionsNewLocals):HtmlNode {",
          "\t\treturn <main class=\"devisehx-auth-shell\">",
          "\t\t\t<section class=\"devisehx-auth-card\">",
          "\t\t\t\t<span class=\"eyebrow\">DeviseHx session</span>",
          "\t\t\t\t<h1>Sign in</h1>",
          "\t\t\t\t<p>Devise owns Warden and password verification; RailsHx owns this typed HHX source.</p>",
          "\t\t\t\t<if ${FlashMessages.hasMessage()}>",
          "\t\t\t\t\t<div class=${\"devisehx-flash is-\" + FlashMessages.kind()} role=\"alert\">",
          "\t\t\t\t\t\t${FlashMessages.message()}",
          "\t\t\t\t\t</div>",
          "\t\t\t\t</if>",
          "\t\t\t\t<form_with url=${AuthLinks.sessionPath(#{auth_class}.scope)} scope=\"#{scope.fetch(:scope)}\" local class=\"devisehx-auth-form\">",
          "\t\t\t\t\t<div>",
          "\t\t\t\t\t\t<field_label name=${DeviseFormFields.email}>Email</field_label>",
          "\t\t\t\t\t\t<email_field name=${DeviseFormFields.email} autocomplete=\"email\" required />",
          "\t\t\t\t\t</div>",
          "\t\t\t\t\t<div>",
          "\t\t\t\t\t\t<field_label name=${DeviseFormFields.password}>Password</field_label>",
          "\t\t\t\t\t\t<password_field name=${DeviseFormFields.password} autocomplete=\"current-password\" required />",
          "\t\t\t\t\t</div>",
          "\t\t\t\t\t<submit type=\"submit\">Sign in</submit>",
          "\t\t\t\t</form_with>",
          "\t\t\t\t<devise_sign_up_link scope=${#{auth_class}.scope} class=\"devisehx-secondary-link\">Create an account</devise_sign_up_link>",
          "\t\t\t</section>",
          "\t\t</main>;",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_devise_registrations_new_view(scope)
        model = scope.fetch(:model)
        auth_class = "#{model}Auth"
        route_resource = scope.fetch(:route_resource)
        [
          "package views.devise.#{route_resource};",
          "",
          "import app.auth.#{auth_class};",
          "import devisehx.hhx.AuthLinks;",
          "import devisehx.hhx.DeviseErrors;",
          "import devisehx.hhx.DeviseFormFields;",
          "import models.#{model};",
          "import rails.action_view.HtmlNode;",
          "",
          "typedef RegistrationsNewLocals = {",
          "\tvar resource:#{model};",
          "}",
          "",
          "// Generated DeviseHx HHX registration view skeleton.",
          "// The compiler checks that DeviseErrors receives a DeviseResource<#{model}>",
          "// and DeviseFormFields emits Rails' expected snake_case form keys.",
          "@:railsTemplate(\"devise/registrations/new\")",
          "@:railsTemplateAst(\"render\")",
          "class RegistrationsNewView {",
          "\tpublic static function render(locals:RegistrationsNewLocals):HtmlNode {",
          "\t\treturn <main class=\"devisehx-auth-shell\">",
          "\t\t\t<section class=\"devisehx-auth-card\">",
          "\t\t\t\t<span class=\"eyebrow\">DeviseHx registration</span>",
          "\t\t\t\t<h1>Create your account</h1>",
          "\t\t\t\t<if ${DeviseErrors.hasAny(locals.resource)}>",
          "\t\t\t\t\t<section class=\"devisehx-errors\" aria-label=\"Registration errors\">",
          "\t\t\t\t\t\t<strong>${DeviseErrors.count(locals.resource)}</strong>",
          "\t\t\t\t\t\t<ul>",
          "\t\t\t\t\t\t\t<for ${message in DeviseErrors.fullMessages(locals.resource)}>",
          "\t\t\t\t\t\t\t\t<li>${message}</li>",
          "\t\t\t\t\t\t\t</for>",
          "\t\t\t\t\t\t</ul>",
          "\t\t\t\t\t</section>",
          "\t\t\t\t</if>",
          "\t\t\t\t<form_with url=${AuthLinks.registrationPath(#{auth_class}.scope)} scope=\"#{scope.fetch(:scope)}\" local class=\"devisehx-auth-form\">",
          "\t\t\t\t\t<div>",
          "\t\t\t\t\t\t<field_label name=${DeviseFormFields.email}>Email</field_label>",
          "\t\t\t\t\t\t<email_field name=${DeviseFormFields.email} autocomplete=\"email\" required />",
          "\t\t\t\t\t</div>",
          "\t\t\t\t\t<div>",
          "\t\t\t\t\t\t<field_label name=${DeviseFormFields.password}>Password</field_label>",
          "\t\t\t\t\t\t<password_field name=${DeviseFormFields.password} autocomplete=\"new-password\" required />",
          "\t\t\t\t\t</div>",
          "\t\t\t\t\t<div>",
          "\t\t\t\t\t\t<field_label name=${DeviseFormFields.passwordConfirmation}>Confirm password</field_label>",
          "\t\t\t\t\t\t<password_field name=${DeviseFormFields.passwordConfirmation} autocomplete=\"new-password\" required />",
          "\t\t\t\t\t</div>",
          "\t\t\t\t\t<submit type=\"submit\">Create account</submit>",
          "\t\t\t\t</form_with>",
          "\t\t\t\t<devise_sign_in_link scope=${#{auth_class}.scope} class=\"devisehx-secondary-link\">Already have an account?</devise_sign_in_link>",
          "\t\t\t</section>",
          "\t\t</main>;",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_devise_passwords_new_view(scope)
        model = scope.fetch(:model)
        auth_class = "#{model}Auth"
        route_resource = scope.fetch(:route_resource)
        [
          "package views.devise.#{route_resource};",
          "",
          "import app.auth.#{auth_class};",
          "import devisehx.hhx.AuthLinks;",
          "import devisehx.hhx.DeviseErrors;",
          "import devisehx.hhx.DeviseFormFields;",
          "import models.#{model};",
          "import rails.action_view.HtmlNode;",
          "",
          "typedef PasswordsNewLocals = {",
          "\tvar resource:#{model};",
          "}",
          "",
          "// Generated DeviseHx HHX password reset request view skeleton.",
          "// Recoverable remains Devise-owned at runtime; this view only gives Haxe",
          "// authors typed route helpers, typed field refs, typed resource errors, and HHX source.",
          "@:railsTemplate(\"devise/passwords/new\")",
          "@:railsTemplateAst(\"render\")",
          "class PasswordsNewView {",
          "\tpublic static function render(locals:PasswordsNewLocals):HtmlNode {",
          "\t\treturn <main class=\"devisehx-auth-shell\">",
          "\t\t\t<section class=\"devisehx-auth-card\">",
          "\t\t\t\t<span class=\"eyebrow\">DeviseHx password reset</span>",
          "\t\t\t\t<h1>Reset your password</h1>",
          "\t\t\t\t<p>Devise sends reset instructions; RailsHx keeps the form action and errors typed.</p>",
          "\t\t\t\t<if ${DeviseErrors.hasAny(locals.resource)}>",
          "\t\t\t\t\t<section class=\"devisehx-errors\" aria-label=\"Password reset errors\">",
          "\t\t\t\t\t\t<ul>",
          "\t\t\t\t\t\t\t<for ${message in DeviseErrors.fullMessages(locals.resource)}>",
          "\t\t\t\t\t\t\t\t<li>${message}</li>",
          "\t\t\t\t\t\t\t</for>",
          "\t\t\t\t\t\t</ul>",
          "\t\t\t\t\t</section>",
          "\t\t\t\t</if>",
          "\t\t\t\t<form_with url=${AuthLinks.passwordPath(#{auth_class}.scope)} scope=\"#{scope.fetch(:scope)}\" local class=\"devisehx-auth-form\">",
          "\t\t\t\t\t<div>",
          "\t\t\t\t\t\t<field_label name=${DeviseFormFields.email}>Email</field_label>",
          "\t\t\t\t\t\t<email_field name=${DeviseFormFields.email} autocomplete=\"email\" required />",
          "\t\t\t\t\t</div>",
          "\t\t\t\t\t<submit type=\"submit\">Send reset instructions</submit>",
          "\t\t\t\t</form_with>",
          "\t\t\t\t<devise_sign_in_link scope=${#{auth_class}.scope} class=\"devisehx-secondary-link\">Back to sign in</devise_sign_in_link>",
          "\t\t\t</section>",
          "\t\t</main>;",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_devise_passwords_edit_view(scope)
        model = scope.fetch(:model)
        auth_class = "#{model}Auth"
        route_resource = scope.fetch(:route_resource)
        [
          "package views.devise.#{route_resource};",
          "",
          "import app.auth.#{auth_class};",
          "import devisehx.hhx.AuthLinks;",
          "import devisehx.hhx.DeviseErrors;",
          "import devisehx.hhx.DeviseFormFields;",
          "import models.#{model};",
          "import rails.action_view.HtmlNode;",
          "",
          "typedef PasswordsEditLocals = {",
          "\tvar resource:#{model};",
          "}",
          "",
          "// Generated DeviseHx HHX password edit view skeleton.",
          "// The typed `locals.resource.resetPasswordToken` value comes from the",
          "// recoverable schema column and lowers to Devise's conventional",
          "// `reset_password_token` hidden form key in the generated Rails ERB.",
          "@:railsTemplate(\"devise/passwords/edit\")",
          "@:railsTemplateAst(\"render\")",
          "class PasswordsEditView {",
          "\tpublic static function render(locals:PasswordsEditLocals):HtmlNode {",
          "\t\treturn <main class=\"devisehx-auth-shell\">",
          "\t\t\t<section class=\"devisehx-auth-card\">",
          "\t\t\t\t<span class=\"eyebrow\">DeviseHx password reset</span>",
          "\t\t\t\t<h1>Choose a new password</h1>",
          "\t\t\t\t<if ${DeviseErrors.hasAny(locals.resource)}>",
          "\t\t\t\t\t<section class=\"devisehx-errors\" aria-label=\"Password update errors\">",
          "\t\t\t\t\t\t<strong>${DeviseErrors.count(locals.resource)}</strong>",
          "\t\t\t\t\t\t<ul>",
          "\t\t\t\t\t\t\t<for ${message in DeviseErrors.fullMessages(locals.resource)}>",
          "\t\t\t\t\t\t\t\t<li>${message}</li>",
          "\t\t\t\t\t\t\t</for>",
          "\t\t\t\t\t\t</ul>",
          "\t\t\t\t\t</section>",
          "\t\t\t\t</if>",
          "\t\t\t\t<form_with url=${AuthLinks.passwordPath(#{auth_class}.scope)} scope=\"#{scope.fetch(:scope)}\" method=\"patch\" local class=\"devisehx-auth-form\">",
          "\t\t\t\t\t<hidden_field name=${DeviseFormFields.resetPasswordToken} value=${locals.resource.resetPasswordToken} />",
          "\t\t\t\t\t<div>",
          "\t\t\t\t\t\t<field_label name=${DeviseFormFields.password}>New password</field_label>",
          "\t\t\t\t\t\t<password_field name=${DeviseFormFields.password} autocomplete=\"new-password\" required />",
          "\t\t\t\t\t</div>",
          "\t\t\t\t\t<div>",
          "\t\t\t\t\t\t<field_label name=${DeviseFormFields.passwordConfirmation}>Confirm new password</field_label>",
          "\t\t\t\t\t\t<password_field name=${DeviseFormFields.passwordConfirmation} autocomplete=\"new-password\" required />",
          "\t\t\t\t\t</div>",
          "\t\t\t\t\t<submit type=\"submit\">Change password</submit>",
          "\t\t\t\t</form_with>",
          "\t\t\t</section>",
          "\t\t</main>;",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_devise_confirmations_new_view(scope)
        model = scope.fetch(:model)
        auth_class = "#{model}Auth"
        route_resource = scope.fetch(:route_resource)
        [
          "package views.devise.#{route_resource};",
          "",
          "import app.auth.#{auth_class};",
          "import devisehx.hhx.AuthLinks;",
          "import devisehx.hhx.DeviseErrors;",
          "import devisehx.hhx.DeviseFormFields;",
          "import models.#{model};",
          "import rails.action_view.HtmlNode;",
          "",
          "typedef ConfirmationsNewLocals = {",
          "\tvar resource:#{model};",
          "}",
          "",
          "// Generated DeviseHx HHX confirmation request view skeleton.",
          "// Confirmable remains Devise-owned at runtime; RailsHx owns the checked",
          "// HHX source, typed Devise route helper, typed field refs, and typed resource error block.",
          "@:railsTemplate(\"devise/confirmations/new\")",
          "@:railsTemplateAst(\"render\")",
          "class ConfirmationsNewView {",
          "\tpublic static function render(locals:ConfirmationsNewLocals):HtmlNode {",
          "\t\treturn <main class=\"devisehx-auth-shell\">",
          "\t\t\t<section class=\"devisehx-auth-card\">",
          "\t\t\t\t<span class=\"eyebrow\">DeviseHx confirmation</span>",
          "\t\t\t\t<h1>Resend confirmation instructions</h1>",
          "\t\t\t\t<p>Devise owns confirmation tokens; RailsHx keeps this request form typed.</p>",
          "\t\t\t\t<if ${DeviseErrors.hasAny(locals.resource)}>",
          "\t\t\t\t\t<section class=\"devisehx-errors\" aria-label=\"Confirmation errors\">",
          "\t\t\t\t\t\t<ul>",
          "\t\t\t\t\t\t\t<for ${message in DeviseErrors.fullMessages(locals.resource)}>",
          "\t\t\t\t\t\t\t\t<li>${message}</li>",
          "\t\t\t\t\t\t\t</for>",
          "\t\t\t\t\t\t</ul>",
          "\t\t\t\t\t</section>",
          "\t\t\t\t</if>",
          "\t\t\t\t<form_with url=${AuthLinks.confirmationPath(#{auth_class}.scope)} scope=\"#{scope.fetch(:scope)}\" local class=\"devisehx-auth-form\">",
          "\t\t\t\t\t<div>",
          "\t\t\t\t\t\t<field_label name=${DeviseFormFields.email}>Email</field_label>",
          "\t\t\t\t\t\t<email_field name=${DeviseFormFields.email} autocomplete=\"email\" required />",
          "\t\t\t\t\t</div>",
          "\t\t\t\t\t<submit type=\"submit\">Resend confirmation</submit>",
          "\t\t\t\t</form_with>",
          "\t\t\t\t<devise_sign_in_link scope=${#{auth_class}.scope} class=\"devisehx-secondary-link\">Back to sign in</devise_sign_in_link>",
          "\t\t\t</section>",
          "\t\t</main>;",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_devise_unlocks_new_view(scope)
        model = scope.fetch(:model)
        auth_class = "#{model}Auth"
        route_resource = scope.fetch(:route_resource)
        [
          "package views.devise.#{route_resource};",
          "",
          "import app.auth.#{auth_class};",
          "import devisehx.hhx.AuthLinks;",
          "import devisehx.hhx.DeviseErrors;",
          "import devisehx.hhx.DeviseFormFields;",
          "import models.#{model};",
          "import rails.action_view.HtmlNode;",
          "",
          "typedef UnlocksNewLocals = {",
          "\tvar resource:#{model};",
          "}",
          "",
          "// Generated DeviseHx HHX unlock request view skeleton.",
          "// Lockable account state stays in Devise/Rails; this checked HHX view",
          "// emits the ordinary `user_unlock_path` request form with typed field refs.",
          "@:railsTemplate(\"devise/unlocks/new\")",
          "@:railsTemplateAst(\"render\")",
          "class UnlocksNewView {",
          "\tpublic static function render(locals:UnlocksNewLocals):HtmlNode {",
          "\t\treturn <main class=\"devisehx-auth-shell\">",
          "\t\t\t<section class=\"devisehx-auth-card\">",
          "\t\t\t\t<span class=\"eyebrow\">DeviseHx unlock</span>",
          "\t\t\t\t<h1>Resend unlock instructions</h1>",
          "\t\t\t\t<p>Devise owns lock/unlock semantics; RailsHx keeps the route and errors typed.</p>",
          "\t\t\t\t<if ${DeviseErrors.hasAny(locals.resource)}>",
          "\t\t\t\t\t<section class=\"devisehx-errors\" aria-label=\"Unlock errors\">",
          "\t\t\t\t\t\t<ul>",
          "\t\t\t\t\t\t\t<for ${message in DeviseErrors.fullMessages(locals.resource)}>",
          "\t\t\t\t\t\t\t\t<li>${message}</li>",
          "\t\t\t\t\t\t\t</for>",
          "\t\t\t\t\t\t</ul>",
          "\t\t\t\t\t</section>",
          "\t\t\t\t</if>",
          "\t\t\t\t<form_with url=${AuthLinks.unlockPath(#{auth_class}.scope)} scope=\"#{scope.fetch(:scope)}\" local class=\"devisehx-auth-form\">",
          "\t\t\t\t\t<div>",
          "\t\t\t\t\t\t<field_label name=${DeviseFormFields.email}>Email</field_label>",
          "\t\t\t\t\t\t<email_field name=${DeviseFormFields.email} autocomplete=\"email\" required />",
          "\t\t\t\t\t</div>",
          "\t\t\t\t\t<submit type=\"submit\">Resend unlock instructions</submit>",
          "\t\t\t\t</form_with>",
          "\t\t\t\t<devise_sign_in_link scope=${#{auth_class}.scope} class=\"devisehx-secondary-link\">Back to sign in</devise_sign_in_link>",
          "\t\t\t</section>",
          "\t\t</main>;",
          "\t}",
          "}",
          "",
        ].join("\n")
      end

      def render_devise_doc(inventory)
        lines = [
          "# DeviseHx Adoption",
          "",
          "- Gem: `#{inventory.fetch(:name)}`",
          "- Version: `#{inventory.fetch(:version_string)}`",
          "- Runtime owner: Devise, Warden, Rails routes, Rails controllers, and Bundler.",
          "- Haxe owner: app-local typed auth contracts under `src_haxe/app/auth`.",
          "",
          "DeviseHx does not replace Devise. It records deterministic app metadata and emits typed Haxe contracts that call normal Rails/Devise helpers.",
          "",
          "## Scopes",
          "",
        ]
        inventory.fetch(:scopes).each do |scope|
          lines += [
            "### #{scope.fetch(:model)}",
            "",
            "- Scope: `#{scope.fetch(:scope)}`",
            "- Route resource: `#{scope.fetch(:route_resource)}`",
            "- Modules: `#{scope.fetch(:modules).join("`, `")}`",
            "- Schema status: `#{scope.fetch(:schema_status)}`",
            "- Generated contract: `app.auth.#{scope.fetch(:model)}Auth`",
            "- Typed helpers: `current`, `currentRequired`, `signedIn`, `signIn`, `signOut`, `authenticate`.",
            "",
          ]
        end
        lines += [
          "## Review Checklist",
          "",
          "- Keep Devise installation, initializer, migrations, and route macros in Rails unless a later Haxe-owned route slice explicitly takes ownership.",
          "- Run `bundle exec rake hxruby:routes` after changing Devise routes so route externs keep using Rails as the helper oracle.",
          "- Run `bundle exec rake hxruby:compile` and Rails request/browser tests after changing auth boundaries.",
          "- Treat missing/dynamic Devise metadata as a generator failure or explicit unsafe seam, not as `Dynamic` app code.",
          "",
        ]
        lines.join("\n")
      end

      def singular_resource_name(resource)
        name = resource.to_s
        return "#{name[0...-3]}y" if name.end_with?("ies")
        return name[0...-1] if name.end_with?("s")

        name
      end

      def ruby_identifier_pattern
        "[A-Za-z_][A-Za-z0-9_]*"
      end

      class SchemaParser
        COLUMN_TYPE_MAP = {
          "string" => ["String", false],
          "text" => ["String", true],
          "integer" => ["Int", false],
          "bigint" => ["Int", true],
          "boolean" => ["Bool", false],
          "float" => ["Float", false],
          "decimal" => ["Float", true],
          "datetime" => ["Date", true],
          "date" => ["Date", true],
          "time" => ["Date", true],
        }.freeze

        def initialize(path, allow_dynamic:)
          @path = path
          @allow_dynamic = allow_dynamic
          raise Error, "Schema file does not exist: #{path}" unless File.file?(path)

          @source = File.read(path)
        end

        def inventory
          tables = parse_tables
          foreign_keys = parse_foreign_keys
          tables.each do |table|
            table_foreign_keys = foreign_keys.fetch(table.fetch(:name), [])
            table[:foreign_keys] = table_foreign_keys
            table_foreign_keys.each do |foreign_key|
              table[:review_notes] << "Foreign key #{foreign_key.fetch(:column)} points to #{foreign_key.fetch(:to_table)}; association inference is intentionally review-only in this adoption slice."
            end
          end
          {
            version: 1,
            source: @path,
            tables: tables,
          }
        end

        private

        def parse_tables
          @source.scan(/^\s*create_table\s+["']([^"']+)["'][^\n]*do\s+\|t\|([\s\S]*?)^\s*end\b/m).map do |name, body|
            indexes = parse_indexes(body)
            columns = parse_columns(body, indexes)
            timestamps = columns.any? { |column| column.fetch(:name) == "created_at" } &&
              columns.any? { |column| column.fetch(:name) == "updated_at" }
            {
              name: name,
              model: class_name(singular(name)),
              columns: columns,
              indexes: indexes,
              foreign_keys: [],
              timestamps: timestamps,
              review_notes: [],
            }
          end
        end

        def parse_columns(body, indexes)
          body.lines.filter_map do |line|
            match = line.match(/^\s*t[.](\w+)\s+["']([^"']+)["'](.*)$/)
            next unless match

            rails_type = match[1]
            name = match[2]
            options = match[3]
            if reference_type?(rails_type)
              reference_column(name, rails_type, options, indexes)
            else
              scalar_column(name, rails_type, options, indexes)
            end
          end
        end

        def scalar_column(name, rails_type, options, indexes)
          type = haxe_type(rails_type)
          nullable = !options.match?(/\bnull:\s*false\b/)
          default_haxe = default_literal(options)
          single_column_indexes = indexes.select { |index| index.fetch(:columns) == [name] }
          {
            name: name,
            haxe_name: haxe_identifier(name),
            rails_type: rails_type,
            haxe_type: nullable ? "Null<#{type.fetch(:haxe)}>" : type.fetch(:haxe),
            nullable: nullable,
            default_haxe: default_haxe,
            db_type: type.fetch(:db_type),
            index: single_column_indexes.any?,
            unique: single_column_indexes.any? { |index| index.fetch(:unique) },
            timestamp_column: %w[created_at updated_at].include?(name),
            review_notes: review_notes_for_column(name, rails_type, type, options),
          }
        end

        def reference_column(name, rails_type, options, indexes)
          column_name = name.end_with?("_id") ? name : "#{name}_id"
          nullable = !options.match?(/\bnull:\s*false\b/)
          single_column_indexes = indexes.select { |index| index.fetch(:columns) == [column_name] }
          explicit_index = bool_option(options, "index")
          {
            name: column_name,
            haxe_name: haxe_identifier(column_name),
            rails_type: "bigint",
            haxe_type: nullable ? "Null<Int>" : "Int",
            nullable: nullable,
            default_haxe: nil,
            db_type: true,
            index: explicit_index.nil? ? single_column_indexes.any? : explicit_index,
            unique: single_column_indexes.any? { |index| index.fetch(:unique) },
            timestamp_column: false,
            review_notes: [
              "Reference #{name} from t.#{rails_type} generated #{column_name}; add a typed association after reviewing the target model.",
              ("Reference #{name} declares foreign_key: true; verify the target table before adding belongsTo metadata." if bool_option(options, "foreign_key")),
            ].compact,
          }
        end

        def parse_indexes(body)
          body.lines.filter_map do |line|
            match = line.match(/^\s*t[.]index\s+\[([^\]]+)\](.*)$/)
            next unless match

            columns = match[1].scan(/["']([^"']+)["']/).flatten
            next if columns.empty?

            {
              columns: columns,
              unique: match[2].match?(/\bunique:\s*true\b/),
            }
          end
        end

        def parse_foreign_keys
          @source.scan(/^\s*add_foreign_key\s+["']([^"']+)["'],\s+["']([^"']+)["'](.*)$/).each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(from, to, options), by_table|
            column = options[/\bcolumn:\s+["']([^"']+)["']/, 1] || "#{singular(to)}_id"
            by_table[from] << { column: column, to_table: to }
          end
        end

        def haxe_type(rails_type)
          mapped = COLUMN_TYPE_MAP[rails_type]
          return { haxe: mapped[0], db_type: mapped[1] } if mapped
          if @allow_dynamic
            return { haxe: "Dynamic", db_type: true, dynamic: true }
          end

          raise Error, "Unsupported schema column type #{rails_type.inspect} in #{@path}; pass --allow-dynamic to generate reviewed Dynamic fields."
        end

        def default_literal(options)
          raw = options[/\bdefault:\s+([^,]+)(?:,|\z)/, 1]&.strip
          return nil unless raw
          return nil if raw.start_with?("->")
          return raw if %w[true false nil].include?(raw)
          return raw if raw.match?(/\A-?[0-9]+(?:[.][0-9]+)?\z/)
          string = raw[/\A["'](.*)["']\z/, 1]
          return JSON.generate(string) if string

          nil
        end

        def review_notes_for_column(name, rails_type, type, options)
          notes = []
          notes << "Column #{name} used unsupported type #{rails_type}; generated Dynamic because --allow-dynamic was explicit." if type[:dynamic]
          precision = int_option(options, "precision")
          scale = int_option(options, "scale")
          notes << "Column #{name} declares decimal precision #{precision} and scale #{scale}; RailsHx preserves dbType now, but typed precision/scale metadata is a follow-up." if precision || scale
          notes << "Column #{name} looks like a foreign key; add a typed association after reviewing the target model." if name.end_with?("_id")
          notes
        end

        def reference_type?(rails_type)
          rails_type == "references" || rails_type == "belongs_to"
        end

        def bool_option(options, name)
          match = options.match(/\b#{Regexp.escape(name)}:\s*(true|false)\b/)
          return nil unless match

          match[1] == "true"
        end

        def int_option(options, name)
          value = options[/\b#{Regexp.escape(name)}:\s*([0-9]+)/, 1]
          value&.to_i
        end

        def haxe_identifier(value)
          Common.haxe_identifier(Common.haxe_method_name(value))
        end

        def class_name(value)
          value.to_s.split("_").map { |part| part[0].upcase + part[1..] }.join
        end

        def singular(value)
          name = value.to_s
          return "#{name[0...-3]}y" if name.end_with?("ies")
          return name[0...-1] if name.end_with?("s")

          name
        end
      end

      class GemSourceInventory
        def initialize(path)
          @path = path
          @source = File.read(path)
        end

        def constants
          sexp = Ripper.sexp(@source)
          raise Error, "Unable to parse gem source: #{@path}" unless sexp

          collect_constants(sexp)
        rescue Errno::ENOENT
          raise Error, "Gem source disappeared while reading #{@path}"
        end

        private

        def collect_constants(node, namespace = [])
          return [] unless node.is_a?(Array)

          out = []
          if node[0] == :class || node[0] == :module
            constant_name = const_name(node[1], namespace)
            out << constant_name unless constant_name.empty?
            body_node = node[0] == :class ? node[3] : node[2]
            body_statements(body_node).each do |statement|
              out.concat(collect_constants(statement, constant_name.split("::")))
            end
            return out
          end

          node.each { |child| out.concat(collect_constants(child, namespace)) if child.is_a?(Array) }
          out
        end

        def const_name(node, namespace)
          case node&.[](0)
          when :const_ref
            [*namespace, node[1][1]].join("::")
          when :const_path_ref
            [const_name(node[1], namespace), node[2][1]].reject(&:empty?).join("::")
          else
            ""
          end
        end

        def body_statements(node)
          return [] unless node&.[](0) == :bodystmt

          node[1].is_a?(Array) ? node[1].compact.reject { |item| item == :void_stmt || item&.[](0) == :void_stmt } : []
        end
      end

      def render_extension_contract(package, haxe_class, module_name, source_label, methods, kind)
        type_kind = kind == :instance ? "interface" : "class"
        lines = [
          "package #{package};",
          "",
          "// Generated by HXRuby::Generators::Adopt from #{source_label}.",
          "// Review required: Ruby source does not carry Haxe return/argument types.",
          "// Replace Dynamic placeholders with precise types as this boundary stabilizes.",
          "@:rubyMixin({module: #{Common.haxe_string(module_name)}})",
          "extern #{type_kind} #{haxe_class} {",
        ]
        methods.each do |method|
          lines.concat(render_extension_method(method, kind))
        end
        lines += [
          "}",
          "",
        ]
        lines.join("\n")
      end

      def render_extension_method(method, kind)
        if method.fetch(:complex)
          return [
            "\t// Skipped #{method.fetch(:ruby_name)}: splat, keyword, block, or post arguments need manual typing.",
          ]
        end

        ruby_name = method.fetch(:ruby_name)
        haxe_name = Common.haxe_method_name(ruby_name)
        args = method.fetch(:args).map do |arg|
          prefix = arg.fetch(:optional) ? "?" : ""
          "#{prefix}#{Common.haxe_identifier(Common.haxe_method_name(arg.fetch(:name)), fallback: "arg")}:Dynamic"
        end
        access = kind == :instance ? "public function" : "public static function"
        lines = [
          "\t// Inferred from Ruby source; tighten Dynamic types after review.",
        ]
        lines << "\t@:native(#{Common.haxe_string(ruby_name)})" if haxe_name != ruby_name
        lines << "\t#{access} #{haxe_name}(#{args.join(", ")}):Dynamic;"
        lines
      end

      class ServiceSourceParser
        def initialize(path, source_label)
          @path = path
          @source_label = source_label
          @source = File.read(path)
        end

        def contracts
          sexp = Ripper.sexp(@source)
          raise Error, "Unable to parse Ruby service source: #{@path}" unless sexp

          out = []
          collect_constants(sexp).each do |contract|
            next if contract.fetch(:constructors).empty? && contract.fetch(:instance).empty? && contract.fetch(:class_methods).empty?

            out << contract
          end
          out
        end

        private

        def collect_constants(node, namespace = [])
          return [] unless node.is_a?(Array)

          out = []
          if node[0] == :class || node[0] == :module
            constant_name = const_name(node[1], namespace)
            body_node = node[0] == :class ? node[3] : node[2]
            body = body_statements(body_node)
            contract = {
              constant_name: constant_name,
              source_label: @source_label,
              constructors: [],
              instance: [],
              class_methods: [],
            }
            body.each do |statement|
              case statement&.[](0)
              when :def
                method = method_info(statement)
                if method.fetch(:ruby_name) == "initialize"
                  contract[:constructors] << method
                else
                  contract[:instance] << method
                end
              when :defs
                method = singleton_method_info(statement)
                contract[:class_methods] << method if method
              when :class, :module
                out.concat(collect_constants(statement, namespace + constant_name.split("::")))
              end
            end
            out << contract
            return out
          end

          node.each { |child| out.concat(collect_constants(child, namespace)) if child.is_a?(Array) }
          out
        end

        def const_name(node, namespace)
          case node&.[](0)
          when :const_ref
            [*namespace, node[1][1]].join("::")
          when :const_path_ref
            [const_name(node[1], namespace), node[2][1]].reject(&:empty?).join("::")
          else
            ""
          end
        end

        def body_statements(node)
          return [] unless node&.[](0) == :bodystmt

          node[1].is_a?(Array) ? node[1].compact.reject { |item| item == :void_stmt || item&.[](0) == :void_stmt } : []
        end

        def method_info(node)
          {
            ruby_name: node[1][1],
            return_type: "Dynamic",
            **params_info(node[2]),
          }
        end

        def singleton_method_info(node)
          target = node[1]
          return nil unless target&.[](0) == :var_ref && target[1]&.[](1) == "self"

          {
            ruby_name: node[3][1],
            return_type: "Dynamic",
            **params_info(node[4]),
          }
        end

        def params_info(node)
          params = node
          params = node[1] if node&.[](0) == :paren
          return { args: [], complex: false } unless params&.[](0) == :params

          required = params[1] || []
          optional = params[2] || []
          rest = params[3]
          post = params[4]
          keywords = params[5]
          keyword_rest = params[6]
          block = params[7]
          args = required.map { |arg| { name: arg[1], optional: false, type: "Dynamic" } }
          args += optional.map do |arg|
            { name: arg[0][1], optional: true, type: inferred_default_type(arg[1]) }
          end
          complex = !!rest || !!post || !!keywords || !!keyword_rest || !!block
          { args: args, complex: complex }
        end

        def inferred_default_type(node)
          case node&.[](0)
          when :string_literal
            "String"
          when :var_ref
            case node[1]&.[](1)
            when "true", "false"
              "Bool"
            else
              "Dynamic"
            end
          when :@int
            "Int"
          when :@float
            "Float"
          else
            "Dynamic"
          end
        end
      end

      class RbsSourceParser
        TYPE_MAP = {
          "String" => "String",
          "Integer" => "Int",
          "int" => "Int",
          "Float" => "Float",
          "float" => "Float",
          "bool" => "Bool",
          "boolish" => "Bool",
          "Boolean" => "Bool",
          "void" => "Void",
          "nil" => "Void",
          "untyped" => "Dynamic",
          "Object" => "Dynamic",
        }.freeze

        def initialize(path, source_label)
          @path = path
          @source_label = source_label
          @source = File.read(path)
        end

        def contracts
          out = []
          current = nil
          @source.each_line.with_index(1) do |line, line_number|
            stripped = line.strip
            next if stripped.empty? || stripped.start_with?("#")

            if (match = stripped.match(/\A(?:class|module)\s+([A-Z][A-Za-z0-9_:]*)\b/))
              current = {
                constant_name: match[1],
                source_label: @source_label,
                source_kind: "rbs",
                constructors: [],
                instance: [],
                class_methods: [],
              }
              out << current
              next
            end
            if stripped == "end"
              current = nil
              next
            end
            next unless current

            method = parse_method(stripped, line_number)
            next unless method

            if method.fetch(:ruby_name) == "initialize"
              current[:constructors] << method
            elsif method.delete(:class_method)
              current[:class_methods] << method
            else
              current[:instance] << method
            end
          end
          out
        end

        private

        def parse_method(line, line_number)
          match = line.match(/\Adef\s+(?:(self)\.)?([A-Za-z_][A-Za-z0-9_!?=]*)\s*:\s*\((.*)\)\s*->\s*([A-Za-z0-9_:?\[\]]+)\z/)
          return nil unless match

          {
            ruby_name: match[2],
            class_method: !match[1].nil?,
            args: parse_args(match[3], line_number),
            complex: false,
            return_type: haxe_type(match[4]),
            comment: "Inferred from RBS metadata; review Dynamic placeholders.",
          }
        end

        def parse_args(raw, line_number)
          return [] if raw.strip.empty?

          raw.split(",").map do |arg|
            token = arg.strip
            optional = token.start_with?("?")
            token = token.delete_prefix("?").strip
            match = token.match(/\A([A-Za-z0-9_:?\[\]]+)\s+([A-Za-z_][A-Za-z0-9_]*)\z/)
            raise Error, "Unsupported RBS argument in #{@path}:#{line_number}: #{arg}" unless match

            { name: match[2], optional: optional, type: haxe_type(match[1]) }
          end
        end

        def haxe_type(rbs_type)
          normalized = rbs_type.to_s.delete_suffix("?")
          TYPE_MAP.fetch(normalized, "Dynamic")
        end
      end

      class ExtensionSourceParser
        def initialize(path)
          @path = path
          @source = File.read(path)
        end

        def contracts
          sexp = Ripper.sexp(@source)
          raise Error, "Unable to parse Ruby extension source: #{@path}" unless sexp

          out = []
          collect_modules(sexp).each do |contract|
            next if contract.fetch(:instance).empty? && contract.fetch(:class_methods).empty?

            out << contract
          end
          out
        end

        private

        def collect_modules(node, namespace = [])
          return [] unless node.is_a?(Array)

          out = []
          if node[0] == :module
            module_name = const_name(node[1], namespace)
            body = body_statements(node[2])
            contract = {
              module_name: module_name,
              instance: [],
              class_methods: [],
            }
            body.each do |statement|
              case statement&.[](0)
              when :def
                contract[:instance] << method_info(statement)
              when :defs
                method = singleton_method_info(statement)
                contract[:class_methods] << method if method
              when :module
                nested_name = const_name(statement[1], namespace + module_name.split("::"))
                if nested_name == "#{module_name}::ClassMethods"
                  body_statements(statement[2]).each do |nested_statement|
                    contract[:class_methods] << method_info(nested_statement) if nested_statement&.[](0) == :def
                  end
                else
                  out.concat(collect_modules(statement, namespace + module_name.split("::")))
                end
              end
            end
            out << contract
            return out
          end

          node.each { |child| out.concat(collect_modules(child, namespace)) if child.is_a?(Array) }
          out
        end

        def const_name(node, namespace)
          case node&.[](0)
          when :const_ref
            [*namespace, node[1][1]].join("::")
          when :const_path_ref
            [const_name(node[1], namespace), node[2][1]].reject(&:empty?).join("::")
          else
            ""
          end
        end

        def body_statements(node)
          return [] unless node&.[](0) == :bodystmt

          node[1].is_a?(Array) ? node[1].compact.reject { |item| item == :void_stmt || item&.[](0) == :void_stmt } : []
        end

        def method_info(node)
          {
            ruby_name: node[1][1],
            **params_info(node[2]),
          }
        end

        def singleton_method_info(node)
          target = node[1]
          return nil unless target&.[](0) == :var_ref && target[1]&.[](1) == "self"

          {
            ruby_name: node[3][1],
            **params_info(node[4]),
          }
        end

        def params_info(node)
          params = node
          params = node[1] if node&.[](0) == :paren
          return { args: [], complex: false } unless params&.[](0) == :params

          required = params[1] || []
          optional = params[2] || []
          rest = params[3]
          post = params[4]
          keywords = params[5]
          keyword_rest = params[6]
          block = params[7]
          args = required.map { |arg| { name: arg[1], optional: false } }
          args += optional.map { |arg| { name: arg[0][1], optional: true } }
          complex = !!rest || !!post || !!keywords || !!keyword_rest || !!block
          { args: args, complex: complex }
        end
      end
    end
  end
end
