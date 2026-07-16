# frozen_string_literal: true

module HXRuby
  module Rbs
    # Parses the deliberately small deterministic RBS subset used by RubyHx.
    # A formal signature either maps completely to safe Haxe types or is
    # omitted as one review-marked method; unsupported pieces never widen an
    # otherwise typed extern to Dynamic.
    class SourceParser
      CONSTANT_PATH = "[A-Z][A-Za-z0-9_]*(?:::[A-Z][A-Za-z0-9_]*)*"
      TYPE_MAP = {
        "String" => "String",
        "Integer" => "Int",
        "int" => "Int",
        "Float" => "Float",
        "float" => "Float",
        "bool" => "Bool",
        "boolish" => "Bool",
        "Boolean" => "Bool",
        "Symbol" => "ruby.Symbol",
      }.freeze

      def initialize(path, source_label, strict: false)
        @path = path
        @source_label = source_label
        @strict = strict
        @source = File.read(path)
      end

      # Returns strict contract hashes consumed by both adoption and the
      # standalone extern renderer. Source order is retained here so existing
      # adoption output remains stable; canonical ordering belongs to the
      # standalone rendering boundary.
      def contracts
        out = []
        current = nil
        @source.each_line.with_index(1) do |line, line_number|
          stripped = line.strip
          next if stripped.empty? || stripped.start_with?("#")

          if (match = stripped.match(/\A(class|module)\s+(#{CONSTANT_PATH})\b/))
            if current
              raise Error, "Nested RBS declarations are outside the strict adoption subset in #{@path}:#{line_number}"
            end
            if @strict && !stripped.match?(/\A(?:class|module)\s+#{CONSTANT_PATH}\z/)
              raise Error, "Unsupported RBS declaration header in #{@path}:#{line_number}"
            end
            current = {
              constant_name: match[2],
              declaration_kind: match[1],
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
            raise Error, "Unmatched RBS end in #{@path}:#{line_number}" unless current

            current = nil
            next
          end
          unless current
            if @strict
              raise Error, "Unsupported top-level RBS declaration in #{@path}:#{line_number}"
            end
            next
          end

          method = parse_method(stripped, line_number)
          if stripped.start_with?("def ") && !method
            raise Error, "Unsupported RBS method declaration in #{@path}:#{line_number}"
          end
          if @strict && !method
            raise Error, "Unsupported RBS declaration in #{@path}:#{line_number}"
          end
          next unless method

          class_method = method.delete(:class_method)
          if method.fetch(:ruby_name) == "initialize" && !class_method
            current[:constructors] << method
          elsif class_method
            current[:class_methods] << method
          else
            current[:instance] << method
          end
        end
        raise Error, "Unterminated RBS declaration in #{@path}" if current

        out
      end

      private

      # Converts one method only when its complete positional signature is in
      # the reviewed subset. A partial conversion would make the generated
      # extern appear safer than the RBS evidence proves.
      def parse_method(line, line_number)
        header = line.match(/\Adef\s+(?:(self)\.)?([A-Za-z_][A-Za-z0-9_!?=]*)\s*:\s*(.*)\z/)
        return nil unless header

        ruby_name = header[2]
        class_method = !header[1].nil?
        signature = header[3]
        if signature.match?(/\)\s*->.*\|\s*\(/)
          return skipped_method(
            ruby_name,
            class_method,
            "overloaded RBS signatures at line #{line_number} are outside the strict subset; expose one reviewed signature in a hand-maintained contract."
          )
        end
        match = signature.match(/\A\((.*)\)\s*->\s*(.+)\z/)
        unless match
          return skipped_method(
            ruby_name,
            class_method,
            "signature at line #{line_number} is outside the strict positional RBS subset; use one `(args) -> return` signature."
          )
        end

        args, arg_issue = parse_args(match[1])
        if arg_issue
          return skipped_method(ruby_name, class_method, "#{arg_issue} (line #{line_number}).")
        end

        return_type = haxe_type(match[2], role: :return)
        unless return_type
          return skipped_method(
            ruby_name,
            class_method,
            "unsupported RBS return type at line #{line_number}; use a supported scalar, nilable scalar, Symbol, Array<T>, or void contract."
          )
        end
        if ruby_name == "initialize" && !class_method && return_type != "Void"
          return skipped_method(
            ruby_name,
            class_method,
            "constructor return type at line #{line_number} must be void."
          )
        end

        {
          ruby_name: ruby_name,
          class_method: class_method,
          args: args,
          complex: false,
          return_type: return_type,
          comment: "Inferred from strict deterministic RBS metadata.",
        }
      end

      def parse_args(raw)
        return [[], nil] if raw.strip.empty?

        parts = split_top_level(raw)
        return [nil, "unbalanced or complex RBS arguments"] unless parts

        args = []
        parts.each do |arg|
          token = arg.strip
          optional = token.start_with?("?")
          token = token.delete_prefix("?").strip
          match = token.match(/\A(.+?)\s+([A-Za-z_][A-Za-z0-9_]*)\z/)
          return [nil, "unsupported RBS positional argument"] unless match

          type = haxe_type(match[1], role: :parameter)
          unless type
            return [
              nil,
              "unsupported RBS parameter type for #{match[2]}; use a supported scalar, nilable scalar, Symbol, or Array<T> contract"
            ]
          end

          args << { name: match[2], optional: optional, type: type }
        end
        [args, nil]
      end

      def haxe_type(rbs_type, role:)
        raw = rbs_type.to_s.strip
        nilable = raw.end_with?("?")
        normalized = (nilable ? raw.delete_suffix("?") : raw).strip

        if role == :return && %w[void nil].include?(normalized)
          return nil if nilable
          return "Void"
        end

        mapped = TYPE_MAP[normalized]
        unless mapped
          array_match = normalized.match(/\AArray\[(.+)\]\z/)
          if array_match
            member_type = haxe_type(array_match[1], role: :value)
            mapped = "Array<#{member_type}>" if member_type && member_type != "Void"
          end
        end
        return nil unless mapped
        return mapped unless nilable

        "Null<#{mapped}>"
      end

      def skipped_method(ruby_name, class_method, reason)
        {
          ruby_name: ruby_name,
          class_method: class_method,
          skip_reason: reason,
        }
      end

      # RBS container types can nest. Split arguments only at the outermost
      # comma so a future supported generic cannot be misread as two method
      # parameters; unbalanced syntax is rejected as a whole method.
      def split_top_level(raw)
        out = []
        token = +""
        stack = []
        pairs = { "[" => "]", "(" => ")", "{" => "}", "<" => ">" }
        raw.each_char do |char|
          if pairs.key?(char)
            stack << pairs.fetch(char)
            token << char
          elsif pairs.value?(char)
            return nil unless stack.pop == char
            token << char
          elsif char == "," && stack.empty?
            out << token.strip
            token = +""
          else
            token << char
          end
        end
        return nil unless stack.empty?

        out << token.strip
        return nil if out.any?(&:empty?)

        out
      end
    end
  end
end
