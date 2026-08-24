# frozen_string_literal: true

require "digest"
require "json"
require_relative "common"
require_relative "migration_parser_profile"
require_relative "migration_source_reader"

module HXRuby
  module Generators
    MigrationSourceSpan = Data.define(
      :start_byte,
      :end_byte,
      :start_line,
      :start_column,
      :end_line,
      :end_column
    )
    MigrationDiagnostic = Data.define(:code, :relative_path, :message, :span)
    MigrationAdoptedAddColumn = Data.define(:table, :column, :default_value, :nullable, :source_span)
    MigrationAdoptedAddIndex = Data.define(:table, :column, :name, :source_span)
    MigrationCandidate = Data.define(
      :source_path,
      :source_sha256,
      :timestamp,
      :class_name,
      :compatibility_profile,
      :operations,
      :comment_count,
      :comment_omission_notice,
      :parser_identity,
      :parser_version,
      :ruby_syntax_version,
      :catalog_identity,
      :candidate_id
    )

    class MigrationParserError < Error
      attr_reader :diagnostic

      def initialize(diagnostic)
        @diagnostic = diagnostic
        span = diagnostic.span
        super(
          "Migration parser rejected #{diagnostic.relative_path} at " \
            "#{span.start_line}:#{span.start_column} [#{diagnostic.code}]: #{diagnostic.message}"
        )
      end
    end

    # Converts one validated migration source into a closed immutable candidate.
    # It never opens a path, executes Ruby, or retains a Prism object.
    class MigrationParser
      SAFE_DATABASE_NAME = /\A[a-z][a-z0-9]*(?:_[a-z][a-z0-9]*)*\z/
      COMMENT_OMISSION_NOTICE = "Ruby line comments are omitted from generated Haxe."
      CANDIDATE_ID_VERSION = 1
      REJECTED_TOKEN_TYPES = {
        SEMICOLON: ["semicolon", "Semicolons are outside the initial migration grammar."],
        HEREDOC_START: ["heredoc", "Heredoc strings are outside the initial migration grammar."],
        EMBDOC_BEGIN: ["embedded_document", "Embedded document comments are outside the initial migration grammar."],
        __END__: ["data_section", "Ruby data sections are outside the initial migration grammar."],
      }.freeze

      def self.parse(validated_source)
        new(validated_source).parse
      end

      def initialize(validated_source)
        unless validated_source.is_a?(ValidatedMigrationSource)
          raise ArgumentError, "MigrationParser requires ValidatedMigrationSource input."
        end

        @validated = validated_source
        @source = validated_source.source
        @relative_path = validated_source.relative_path
      end

      def parse
        prism = load_prism!
        result = begin
          prism.parse_lex(@source, version: MigrationParserProfile::RUBY_SYNTAX_VERSION)
        rescue SystemStackError
          reject_without_location!("source_too_deep", "The migration source is too deeply nested to parse safely.")
        end

        reject_syntax_errors!(result) unless result.success?
        program, tokens = result.value
        policy_diagnostics = lexical_diagnostics(result, tokens)

        class_name = nil
        operations = nil
        structural_error = begin
          class_node = validate_program!(program)
          class_name = validate_class_identity!(class_node)
          validate_superclass!(class_node.superclass)
          method_node = validate_change_method!(class_node)
          operations = validate_operations!(method_node)
          nil
        rescue MigrationParserError => error
          error
        end

        policy_diagnostics << structural_error.diagnostic if structural_error
        reject_diagnostic!(earliest(policy_diagnostics)) unless policy_diagnostics.empty?

        build_candidate(class_name, operations, result.comments.length)
      end

      private

      def load_prism!
        require "rubygems"
        gem "prism", "= #{MigrationParserProfile::PRISM_VERSION}"
        require "prism"
        unless Prism::VERSION == MigrationParserProfile::PRISM_VERSION
          reject_without_location!(
            "parser_version",
            "RailsHx requires Prism #{MigrationParserProfile::PRISM_VERSION}, but #{Prism::VERSION} is active."
          )
        end
        Prism
      rescue Gem::LoadError, LoadError => error
        reject_without_location!(
          "parser_unavailable",
          "RailsHx requires the exact prism gem #{MigrationParserProfile::PRISM_VERSION}: #{error.message}"
        )
      end

      def reject_syntax_errors!(result)
        error = result.errors.min_by { |entry| [entry.location.start_offset, entry.message] }
        reject_location!("syntax_error", error.message, error.location)
      end

      def lexical_diagnostics(result, tokens)
        diagnostics = []
        if @source.b.start_with?("\xEF\xBB\xBF".b)
          diagnostics << diagnostic("byte_order_mark", "A UTF-8 byte-order mark is outside the migration grammar.", byte_span(0, 3))
        end
        if @source.start_with?("#!")
          line_end = @source.index("\n") || @source.bytesize
          diagnostics << diagnostic("shebang", "A shebang is outside the migration grammar.", byte_span(0, line_end))
        end
        result.magic_comments.each do |comment|
          diagnostics << diagnostic(
            "magic_comment",
            "Ruby magic comments are outside the migration grammar.",
            byte_span(comment.key_loc.start_offset, comment.value_loc.end_offset)
          )
        end
        result.warnings.each do |warning|
          diagnostics << diagnostic("parser_warning", warning.message, span(warning.location))
        end
        tokens.each do |token, _state|
          rejection = REJECTED_TOKEN_TYPES[token.type]
          diagnostics << diagnostic(rejection[0], rejection[1], span(token.location)) if rejection
        end
        diagnostics
      end

      def validate_program!(program)
        unless program.is_a?(Prism::ProgramNode) && program.locals.empty? && program.statements.is_a?(Prism::StatementsNode)
          reject_location!("program_structure", "The file must contain one top-level migration class.", program.location)
        end

        body = program.statements.body
        unless body.length == 1 && body.first.is_a?(Prism::ClassNode)
          offending = if body.empty?
            program.location
          elsif body.first.is_a?(Prism::ClassNode)
            body.fetch(1).location
          else
            body.first.location
          end
          reject_location!("top_level_structure", "The file must contain only one top-level migration class.", offending)
        end
        body.first
      end

      def validate_class_identity!(class_node)
        constant = class_node.constant_path
        unless class_node.locals.empty? && class_node.class_keyword_loc&.slice == "class" &&
            constant.is_a?(Prism::ConstantReadNode)
          reject_location!("class_structure", "The migration class must be one unnamespaced constant.", class_node.location)
        end

        file_match = MigrationSourceReader::FILE_NAME_PATTERN.match(@validated.basename)
        expected = file_match[:name].split("_").map { |part| part[0].upcase + part[1..] }.join
        actual = constant.name.to_s
        unless actual == expected && constant.location.slice == expected
          reject_location!(
            "class_name_mismatch",
            "The migration class must be #{expected}, as derived from #{@validated.basename}.",
            constant.location
          )
        end
        actual.freeze
      end

      def validate_superclass!(node)
        valid = node.is_a?(Prism::CallNode) && node.location.slice == MigrationParserProfile::COMPATIBILITY_PROFILE &&
          node.receiver.is_a?(Prism::ConstantPathNode) && node.receiver.location.slice == "ActiveRecord::Migration" &&
          node.receiver.parent.is_a?(Prism::ConstantReadNode) && node.receiver.parent.name == :ActiveRecord &&
          node.receiver.name == :Migration && node.receiver.delimiter_loc&.slice == "::" &&
          node.call_operator_loc.nil? && node.name == :[] && node.opening_loc&.slice == "[" &&
          node.closing_loc&.slice == "]" && node.equal_loc.nil? && node.block.nil? &&
          node.arguments.is_a?(Prism::ArgumentsNode) && node.arguments.arguments.length == 1 &&
          node.arguments.arguments.first.is_a?(Prism::FloatNode) && node.arguments.arguments.first.location.slice == "7.1"
        return if valid

        message = "The migration superclass must be exactly #{MigrationParserProfile::COMPATIBILITY_PROFILE}."
        if node
          reject_location!("migration_superclass", message, node.location)
        else
          reject_without_location!("migration_superclass", message)
        end
      end

      def validate_change_method!(class_node)
        body = class_node.body
        statements = body.is_a?(Prism::StatementsNode) ? body.body : []
        unless statements.length == 1 && statements.first.is_a?(Prism::DefNode)
          offending = statements.find { |entry| !entry.is_a?(Prism::DefNode) } || statements[1] || body || class_node
          reject_location!("class_body", "The migration class must contain only one change method.", offending.location)
        end

        method_node = statements.first
        valid = method_node.name == :change && method_node.name_loc.slice == "change" && method_node.receiver.nil? &&
          method_node.parameters.nil? && method_node.locals.empty? && method_node.def_keyword_loc.slice == "def" &&
          method_node.operator_loc.nil? && method_node.lparen_loc.nil? && method_node.rparen_loc.nil? &&
          method_node.equal_loc.nil? && method_node.end_keyword_loc&.slice == "end"
        unless valid
          reject_location!(
            "change_method",
            "The migration class must contain one parameterless instance method named change.",
            method_node.location
          )
        end
        method_node
      end

      def validate_operations!(method_node)
        body = method_node.body
        statements = body.is_a?(Prism::StatementsNode) ? body.body : []
        if statements.empty?
          reject_location!("empty_change", "The change method must contain at least one admitted migration operation.", method_node.location)
        end

        statements.map { |statement| validate_operation!(statement) }.freeze
      end

      def validate_operation!(node)
        unless node.is_a?(Prism::CallNode)
          reject_location!("unsupported_statement", "Only receiverless migration operation calls are permitted.", node.location)
        end
        unless receiverless_call?(node)
          reject_location!("receiver_call", "Migration operation calls must not have a receiver, block, assignment, or safe-navigation operator.", node.location)
        end

        case node.name
        when :add_column then validate_add_column!(node)
        when :add_index then validate_add_index!(node)
        else
          reject_location!("unknown_call", "The initial catalog does not admit #{node.name}.", node.message_loc)
        end
      end

      def receiverless_call?(node)
        delimiters = if node.opening_loc.nil? && node.closing_loc.nil?
          true
        else
          node.opening_loc&.slice == "(" && node.closing_loc&.slice == ")"
        end
        node.receiver.nil? && node.call_operator_loc.nil? && node.equal_loc.nil? && node.block.nil? && delimiters
      end

      def validate_add_column!(call)
        arguments = argument_values!(call)
        unless [3, 4].include?(arguments.length)
          reject_location!(
            "add_column_arguments",
            "add_column requires table, column, :string, and optional default or null keywords.",
            call.location
          )
        end

        table = database_symbol!(arguments[0], "add_column table")
        column = database_symbol!(arguments[1], "add_column column")
        type = symbol_value!(arguments[2], "add_column type")
        unless type == "string"
          reject_location!("column_type", "The initial catalog admits only the :string column type.", arguments[2].location)
        end

        options = arguments.length == 4 ? keyword_options!(arguments[3], %w[default null], "add_column") : {}
        default_value = options.key?("default") ? string_value!(options.fetch("default"), "add_column default") : nil
        nullable = options.key?("null") ? boolean_value!(options.fetch("null"), "add_column null") : nil

        MigrationAdoptedAddColumn.new(
          table: table,
          column: column,
          default_value: default_value,
          nullable: nullable,
          source_span: span(call.location)
        )
      end

      def validate_add_index!(call)
        arguments = argument_values!(call)
        unless arguments.length == 3
          reject_location!(
            "add_index_arguments",
            "add_index requires one table, one column, and one literal name keyword.",
            call.location
          )
        end

        table = database_symbol!(arguments[0], "add_index table")
        column = database_symbol!(arguments[1], "add_index column")
        options = keyword_options!(arguments[2], ["name"], "add_index")
        unless options.key?("name")
          reject_location!("missing_index_name", "add_index requires the literal name keyword.", arguments[2].location)
        end
        name_node = options.fetch("name")
        name = string_value!(name_node, "add_index name")
        unless SAFE_DATABASE_NAME.match?(name)
          reject_location!("database_name", "add_index name must use segmented snake case.", name_node.location)
        end

        MigrationAdoptedAddIndex.new(
          table: table,
          column: column,
          name: name,
          source_span: span(call.location)
        )
      end

      def argument_values!(call)
        unless call.arguments.is_a?(Prism::ArgumentsNode)
          reject_location!("missing_arguments", "Migration operation calls require literal arguments.", call.location)
        end
        call.arguments.arguments
      end

      def database_symbol!(node, label)
        value = symbol_value!(node, label)
        unless SAFE_DATABASE_NAME.match?(value)
          reject_location!("database_name", "#{label} must use segmented snake case.", node.location)
        end
        value
      end

      def symbol_value!(node, label)
        valid = node.is_a?(Prism::SymbolNode) && node.opening_loc&.slice == ":" && node.closing_loc.nil? &&
          node.value_loc.slice == node.unescaped && node.location.slice == ":#{node.unescaped}"
        unless valid
          reject_location!("symbol_literal", "#{label} must be one plain symbol literal.", node.location)
        end
        immutable_string(node.unescaped)
      end

      def keyword_options!(node, admitted, label)
        unless node.is_a?(Prism::KeywordHashNode)
          reject_location!("keyword_options", "#{label} options must use literal keyword labels.", node.location)
        end

        options = {}
        node.elements.each do |element|
          unless element.is_a?(Prism::AssocNode) && element.operator_loc.nil?
            reject_location!("keyword_option", "#{label} options must use literal keyword labels.", element.location)
          end
          key_node = element.key
          valid_key = key_node.is_a?(Prism::SymbolNode) && key_node.opening_loc.nil? &&
            key_node.closing_loc&.slice == ":" && key_node.value_loc.slice == key_node.unescaped
          unless valid_key
            reject_location!("keyword_option", "#{label} options must use plain keyword labels.", key_node.location)
          end

          key = key_node.unescaped
          unless admitted.include?(key)
            reject_location!("unknown_option", "#{label} does not admit the #{key} option.", key_node.location)
          end
          if options.key?(key)
            reject_location!("duplicate_option", "#{label} contains the #{key} option more than once.", key_node.location)
          end
          options[key] = element.value
        end
        options
      end

      def string_value!(node, label)
        unless node.is_a?(Prism::StringNode)
          reject_location!("string_literal", "#{label} must be one static string literal.", node.location)
        end
        if node.unescaped.include?("\0")
          reject_location!("string_nul", "#{label} must not contain a NUL value.", node.location)
        end
        immutable_string(node.unescaped)
      end

      def boolean_value!(node, label)
        return true if node.is_a?(Prism::TrueNode)
        return false if node.is_a?(Prism::FalseNode)

        reject_location!("boolean_literal", "#{label} must be the literal true or false value.", node.location)
      end

      def build_candidate(class_name, operations, comment_count)
        file_match = MigrationSourceReader::FILE_NAME_PATTERN.match(@validated.basename)
        candidate_id = Digest::SHA256.hexdigest(JSON.generate([
          CANDIDATE_ID_VERSION,
          @relative_path,
          @validated.sha256,
          MigrationParserProfile::PARSER_IDENTITY,
          MigrationParserProfile::CATALOG_IDENTITY,
        ])).freeze

        MigrationCandidate.new(
          source_path: @relative_path,
          source_sha256: @validated.sha256,
          timestamp: immutable_string(file_match[:timestamp]),
          class_name: class_name,
          compatibility_profile: MigrationParserProfile::COMPATIBILITY_PROFILE.dup.freeze,
          operations: operations,
          comment_count: comment_count,
          comment_omission_notice: COMMENT_OMISSION_NOTICE.dup.freeze,
          parser_identity: MigrationParserProfile::PARSER_IDENTITY.dup.freeze,
          parser_version: MigrationParserProfile::PRISM_VERSION.dup.freeze,
          ruby_syntax_version: MigrationParserProfile::RUBY_SYNTAX_VERSION.dup.freeze,
          catalog_identity: MigrationParserProfile::CATALOG_IDENTITY.dup.freeze,
          candidate_id: candidate_id
        )
      end

      def immutable_string(value)
        value.to_s.dup.freeze
      end

      def span(location)
        MigrationSourceSpan.new(
          start_byte: location.start_offset,
          end_byte: location.end_offset,
          start_line: location.start_line,
          start_column: location.start_column,
          end_line: location.end_line,
          end_column: location.end_column
        )
      end

      def byte_span(start_byte, end_byte)
        start_location = source_position(start_byte)
        end_location = source_position(end_byte)
        MigrationSourceSpan.new(
          start_byte: start_byte,
          end_byte: end_byte,
          start_line: start_location[0],
          start_column: start_location[1],
          end_line: end_location[0],
          end_column: end_location[1]
        )
      end

      def source_position(byte_offset)
        prefix = @source.b.byteslice(0, byte_offset)
        line = prefix.count("\n") + 1
        line_start = prefix.rindex("\n")
        [line, line_start ? prefix.bytesize - line_start - 1 : prefix.bytesize]
      end

      def diagnostic(code, message, source_span)
        MigrationDiagnostic.new(
          code: code.to_s.dup.freeze,
          relative_path: @relative_path,
          message: message.to_s.dup.freeze,
          span: source_span
        )
      end

      def earliest(diagnostics)
        diagnostics.min_by { |entry| [entry.span.start_byte, entry.code] }
      end

      def reject_location!(code, message, location)
        reject_diagnostic!(diagnostic(code, message, span(location)))
      end

      def reject_without_location!(code, message)
        reject_diagnostic!(diagnostic(code, message, byte_span(0, 0)))
      end

      def reject_diagnostic!(value)
        raise MigrationParserError, value
      end
    end

    private_constant :MigrationSourceSpan
    private_constant :MigrationDiagnostic
    private_constant :MigrationAdoptedAddColumn
    private_constant :MigrationAdoptedAddIndex
    private_constant :MigrationCandidate
    private_constant :MigrationParser
    private_constant :MigrationParserError
  end
end
