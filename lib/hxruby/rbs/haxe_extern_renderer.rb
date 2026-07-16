# frozen_string_literal: true

require "json"

module HXRuby
  module Rbs
    # Renders one strict RBS contract as a nominal Haxe extern. The standalone
    # path sorts methods for reproducible maintainer output; callers preserving
    # an established generated contract can explicitly retain source order.
    class HaxeExternRenderer
      HAXE_KEYWORDS = %w[
        abstract break case cast catch class continue default do dynamic else enum
        extends extern false final for function if implements import in inline
        interface macro new null operator overload override package private public
        return static super switch this throw true try typedef untyped using var
        while
      ].freeze

      def initialize(
        contract:,
        package_name:,
        native_name: nil,
        haxe_class: nil,
        require_path: nil,
        canonical: true,
        header_lines: nil
      )
        @contract = checked_contract(contract)
        @package_name = checked_package_name(package_name)
        @native_name = checked_native_name(native_name || @contract.fetch(:constant_name))
        @haxe_class = checked_haxe_class(haxe_class || @native_name.split("::").last)
        @require_path = checked_require_path(require_path)
        @canonical = canonical
        @header_lines = checked_header_lines(header_lines || default_header_lines)
      end

      # Produces canonical LF-terminated Haxe source and never writes files.
      # Keeping I/O outside the renderer makes ownership and path checks an
      # explicit responsibility of the CLI or generator that selected input.
      def render
        validate_canonical_contract if @canonical
        lines = [
          "package #{@package_name};",
          "",
          *@header_lines,
        ]
        lines << "@:rubyRequire(#{haxe_string(@require_path)})" if @require_path
        lines += [
          "@:native(#{haxe_string(@native_name)})",
          "extern class #{@haxe_class} {",
        ]
        ordered(@contract.fetch(:constructors)).each { |method| lines.concat(render_method(method, :constructor)) }
        ordered(@contract.fetch(:instance)).each { |method| lines.concat(render_method(method, :instance)) }
        ordered(@contract.fetch(:class_methods)).each { |method| lines.concat(render_method(method, :class_method)) }
        lines += ["}", ""]
        lines.join("\n")
      end

      private

      def checked_contract(contract)
        unless contract.is_a?(Hash) && contract[:source_kind] == "rbs"
          raise Error, "Haxe extern rendering requires one strict RBS contract"
        end

        %i[constant_name declaration_kind source_label constructors instance class_methods].each do |key|
          raise Error, "RBS contract is missing #{key}" unless contract.key?(key)
        end
        contract
      end

      def checked_package_name(value)
        package = value.to_s.strip
        unless package.match?(/\A[a-z][A-Za-z0-9_]*(?:\.[a-z][A-Za-z0-9_]*)*\z/)
          raise Error, "Haxe package must contain safe lower-case-leading dotted segments"
        end
        package
      end

      def checked_native_name(value)
        native_name = value.to_s.strip
        unless native_name.match?(/\A[A-Z][A-Za-z0-9_]*(?:::[A-Z][A-Za-z0-9_]*)*\z/)
          raise Error, "RBS native constant must be a safe Ruby constant path"
        end
        native_name
      end

      def checked_haxe_class(value)
        haxe_class = value.to_s.strip
        unless haxe_class.match?(/\A[A-Z][A-Za-z0-9_]*\z/) && !HAXE_KEYWORDS.include?(haxe_class)
          raise Error, "Generated Haxe class must be a safe upper-case-leading identifier"
        end
        haxe_class
      end

      def checked_require_path(value)
        return nil if value.nil?

        require_path = value.to_s.strip
        if require_path.empty? || require_path.start_with?("/", ".") || require_path.include?("\\") || require_path.split("/").include?("..")
          raise Error, "Ruby require path must be a safe logical library path"
        end
        unless require_path.match?(/\A[A-Za-z0-9_][A-Za-z0-9_.\/-]*\z/)
          raise Error, "Ruby require path must be a safe logical library path"
        end
        require_path
      end

      def checked_header_lines(lines)
        unless lines.is_a?(Array) && lines.all? { |line| line.is_a?(String) && line.start_with?("// ") && !line.match?(/[\r\n]/) }
          raise Error, "Generated RBS header lines must be single-line Haxe comments"
        end
        lines
      end

      def default_header_lines
        [
          "// Generated from #{@contract.fetch(:source_label)}.",
          "// Generated from deterministic RBS metadata.",
          "// Unsupported or incomplete signatures are omitted with review markers; no broad fallback type is synthesized.",
        ]
      end

      def ordered(methods)
        return methods unless @canonical

        methods.sort_by do |method|
          args = method.fetch(:args, []).map do |arg|
            [arg.fetch(:name), arg.fetch(:type), arg.fetch(:optional) ? 1 : 0]
          end
          [method.fetch(:ruby_name), args, method.fetch(:return_type, ""), canonical_skip_reason(method.fetch(:skip_reason, ""))]
        end
      end

      def render_method(method, kind)
        if method[:skip_reason]
          return [
            "\t// Review required: skipped #{method.fetch(:ruby_name)}: #{canonical_skip_reason(method.fetch(:skip_reason))}",
          ]
        end
        if method.fetch(:complex)
          raise Error, "Strict RBS contract unexpectedly contains a complex method: #{method.fetch(:ruby_name)}"
        end

        args = method.fetch(:args).map do |arg|
          prefix = arg.fetch(:optional) ? "?" : ""
          "#{prefix}#{haxe_identifier(haxe_method_name(arg.fetch(:name)), fallback: "arg")}:#{arg.fetch(:type)}"
        end
        case kind
        when :constructor
          [
            "\t// #{method.fetch(:comment, "Inferred from strict deterministic RBS metadata.")}",
            "\tpublic function new(#{args.join(", ")}):Void;",
          ]
        when :class_method
          function_lines(method, "public static function", args)
        else
          function_lines(method, "public function", args)
        end
      end

      def function_lines(method, access, args)
        ruby_name = method.fetch(:ruby_name)
        haxe_name = rendered_method_name(ruby_name)
        lines = ["\t// #{method.fetch(:comment, "Inferred from strict deterministic RBS metadata.")}"]
        lines << "\t@:native(#{haxe_string(ruby_name)})" if haxe_name != ruby_name
        lines << "\t#{access} #{haxe_name}(#{args.join(", ")}):#{method.fetch(:return_type)};"
        lines
      end

      # Source locations help app adoption review, but they are not part of a
      # canonical signature. Standalone output removes only those line-number
      # fragments so an order-only source edit cannot perturb reviewed bytes.
      def canonical_skip_reason(reason)
        return reason unless @canonical

        reason.gsub(/\s+at line \d+/, "").gsub(/\s+\(line \d+\)/, "")
      end

      def validate_canonical_contract
        constructors = @contract.fetch(:constructors).reject { |method| method[:skip_reason] }
        if constructors.length > 1
          raise Error, "Strict RBS contract contains multiple generated constructors"
        end
        validate_method_group(@contract.fetch(:instance), "instance")
        validate_method_group(@contract.fetch(:class_methods), "class")
        if @contract.fetch(:declaration_kind) == "module" &&
            (!constructors.empty? || @contract.fetch(:instance).any? { |method| !method[:skip_reason] })
          raise Error, "Strict RBS modules can generate only self methods; instance mixin contracts require manual curation"
        end
      end

      def validate_method_group(methods, label)
        emitted = methods.reject { |method| method[:skip_reason] }
        names = emitted.map { |method| rendered_method_name(method.fetch(:ruby_name)) }
        duplicates = names.tally.select { |_name, count| count > 1 }.keys.sort
        unless duplicates.empty?
          raise Error, "Strict RBS contract has #{label} Haxe member collisions: #{duplicates.join(", ")}"
        end

        emitted.each do |method|
          args = method.fetch(:args).map do |arg|
            haxe_identifier(haxe_method_name(arg.fetch(:name)), fallback: "arg")
          end
          collisions = args.tally.select { |_name, count| count > 1 }.keys.sort
          next if collisions.empty?

          raise Error, "Strict RBS method #{method.fetch(:ruby_name)} has Haxe argument collisions: #{collisions.join(", ")}"
        end
      end

      def rendered_method_name(ruby_name)
        raw = haxe_method_name(ruby_name)
        @canonical ? haxe_identifier(raw, fallback: "method") : raw
      end

      def haxe_string(value)
        JSON.generate(value.to_s)
      end

      def haxe_method_name(ruby_name)
        ruby_name.to_s
          .sub(/[!?=]\z/, "")
          .gsub(/_([a-z0-9])/) { Regexp.last_match(1).upcase }
      end

      def haxe_identifier(value, fallback: "value")
        name = value.to_s.gsub(/[^A-Za-z0-9_]/, "_")
        name = fallback if name.empty?
        name = "_#{name}" unless name.match?(/\A[A-Za-z_]/)
        HAXE_KEYWORDS.include?(name) ? "#{name}Value" : name
      end
    end
  end
end
