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
        if !options[:discover] && options[:services].empty? && options[:templates].empty? && options[:extension_sources].empty?
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
        @locals = parse_locals(options.fetch(:locals))
        @force = options.fetch(:force)
        @discover = options.fetch(:discover)
      end

      def run
        discover_boundaries if @discover
        @services.each { |service| write_service(service) }
        @templates.each { |template| write_template(template) }
        @extension_sources.each { |source| write_extension_contracts(source) }
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
          raise Error, "Invalid local name #{name.inspect}. Expected a safe Haxe field identifier." unless safe_haxe_identifier?(name)
          raise Error, "Invalid local type #{type.inspect}. Expected a safe Haxe type reference." unless safe_haxe_type?(type)

          { name: name, type: type }
        end
      end

      def write_service(native_name)
        haxe_class = native_name.split("::").last
        package = service_package(native_name)
        path = File.join(@output_dir, "src_haxe", Common.package_path(package), "#{haxe_class}.hx")
        Common.write_file(path, render_service(package, haxe_class, native_name, service_contract(native_name)), force: @force)
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
        Common.write_file(path, render_template(package, haxe_class, locals_name, safe_template_path), force: @force)
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
        Common.write_file(path, render_extension_contract(package, haxe_class, module_name, source_label, methods, kind), force: @force)
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
