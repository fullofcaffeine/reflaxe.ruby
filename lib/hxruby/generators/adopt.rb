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
          write: nil,
          locals: "",
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
          parser.on("--write WHAT") { |value| options[:write] = value }
          parser.on("--locals FIELDS") { |value| options[:locals] = value }
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
        if !options[:discover] && options[:services].empty? && options[:templates].empty? && options[:extension_sources].empty? && options[:gems].empty?
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
        @write_mode = options.fetch(:write)
        @locals = parse_locals(options.fetch(:locals))
        @force = options.fetch(:force)
        @discover = options.fetch(:discover)
      end

      def run
        discover_boundaries if @discover
        discover_gems if @discover && @gems.any?
        write_gem_contracts if @write_mode == "contracts"
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
          puts "    modules: #{scope.fetch(:modules).join(", ")}"
          puts "    schema: #{scope.fetch(:schema_status)}"
          scope.fetch(:helpers).each { |helper| puts "    helper: #{helper}" }
        end
        puts "  diagnostics: none"
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
        end
        write_owned(File.join(@output_dir, "docs", "railshx", "gems", "devise.md"), render_devise_doc(inventory), kind: "docs")
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
        resources = content.scan(/\bdevise_for\s+:(#{ruby_identifier_pattern})\b/).flatten
        raise Error, "Cannot adopt Devise: no literal devise_for scopes found in config/routes.rb." if resources.empty?

        duplicates = resources.tally.select { |_resource, count| count > 1 }.keys
        raise Error, "Cannot adopt Devise: ambiguous duplicate devise_for scope(s): #{duplicates.join(", ")}." if duplicates.any?

        resources.map do |resource|
          scope = singular_resource_name(resource)
          {
            scope: scope,
            route_resource: resource,
            model: Common.class_name_from_path(scope),
          }
        end
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
        {
          version: 1,
          kind: "devise_diagnostics",
          gem: inventory.fetch(:name),
          status: "ok",
          diagnostics: [],
        }
      end

      def render_devise_auth_contract(scope)
        class_name = "#{scope.fetch(:model)}Auth"
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
          "\tpublic static final scope:DeviseScope<#{scope.fetch(:model)}> = DeviseScope.of(ScopeName.named(#{Common.haxe_string(scope.fetch(:scope))}), RouteResource.named(#{Common.haxe_string(scope.fetch(:route_resource))}), #{scope.fetch(:model)});",
          "",
          "\tpublic static final authenticate:AuthFilter<#{scope.fetch(:model)}> = Auth.require(scope);",
          "",
          "\tpublic static inline function current(controller:Base):Null<#{scope.fetch(:model)}> {",
          "\t\treturn Auth.current(controller, scope);",
          "\t}",
          "",
          "\tpublic static inline function currentRequired(controller:Base):#{scope.fetch(:model)} {",
          "\t\treturn Auth.currentRequired(controller, scope);",
          "\t}",
          "",
          "\tpublic static inline function signedIn(controller:Base):Bool {",
          "\t\treturn Auth.signedIn(controller, scope);",
          "\t}",
          "",
          "\tpublic static inline function signIn(controller:Base, resource:#{scope.fetch(:model)}):Void {",
          "\t\tAuth.signIn(controller, scope, resource);",
          "\t}",
          "",
          "\tpublic static inline function signOut(controller:Base):Void {",
          "\t\tAuth.signOut(controller, scope);",
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
