# frozen_string_literal: true

require "ripper"
require_relative "common"
require_relative "migration_source_reader"

module HXRuby
  module Generators
    # Reads Rails migration files as bounded source data and reports syntax facts.
    # It never loads or evaluates a migration. A later parser owns translation.
    class MigrationInventory
      MAX_SOURCE_BYTES = MigrationSourceReader::MAX_SOURCE_BYTES
      FILE_NAME_PATTERN = MigrationSourceReader::FILE_NAME_PATTERN
      MAGIC_COMMENT_PATTERN = /\A[ \t]*#(?:!|(?=[^\r\n]*(?:coding|encoding)[ \t]*[:=])|[ \t]*frozen_string_literal[ \t]*:)/i
      ADMITTED_CALLS = %w[add_column add_index].freeze

      def initialize(output_dir)
        @output_dir = File.expand_path(output_dir)
        @source_reader = MigrationSourceReader.new(@output_dir)
      end

      def inventory
        entries = @source_reader.inventory_sources.map { |source| inspect_file(source) }
        timestamps = collisions(entries, :timestamp)
        classes = collisions(entries, :classes)
        {
          files: entries,
          timestamp_collisions: timestamps,
          class_collisions: classes,
        }
      end

      private

      def inspect_file(source)
        relative = source.relative_path
        path = File.join(@output_dir, relative)
        facts = SourceFacts.new(source.source, source.basename).facts
        {
          file: relative,
          timestamp: facts.fetch(:timestamp),
          classes: facts.fetch(:classes),
          owner: owned_source?(path, source.source) ? "railshx" : "rails",
          sha256: source.sha256,
          migration_version: facts.fetch(:migration_version),
          transaction: facts.fetch(:transaction),
          body_form: facts.fetch(:body_form),
          first_unsupported: facts.fetch(:first_unsupported),
          comment_count: facts.fetch(:comment_count),
        }
      end

      def owned_source?(path, source)
        first_line = source.each_line.first.to_s.strip
        first_line.start_with?(Common::GENERATED_HEADER) || Common.manifest_owned?(@output_dir, path)
      end

      def collisions(entries, field)
        grouped = Hash.new { |hash, key| hash[key] = [] }
        entries.each do |entry|
          Array(entry.fetch(field)).compact.each { |value| grouped[value] << entry.fetch(:file) }
        end
        grouped.select { |_value, paths| paths.length > 1 }
      end

      # Extracts report-only facts from Ripper's syntax tree. It recognizes the
      # narrow tracer shape but does not create MigrationOperation values.
      class SourceFacts
        def initialize(source, file_name)
          @source = source
          @file_name = file_name
          @unsupported = []
        end

        def facts
          file_match = FILE_NAME_PATTERN.match(@file_name)
          add_unsupported("filename", 0, 0) unless file_match
          add_magic_comment
          add_unsupported_lexical_forms

          tree = begin
            Ripper.sexp(@source)
          rescue SystemStackError
            add_unsupported("syntax_too_deep", 1, 0)
            return result(file_match, [], nil, "default", "invalid")
          end
          unless tree
            syntax = SyntaxProbe.new(@source)
            syntax.parse
            line, column = syntax.error_location || [1, 0]
            add_unsupported("syntax_error", line, column)
            return result(file_match, [], nil, "default", "invalid")
          end

          classes, transaction, body_form, migration_version = inspect_program(tree)
          expected_class = camelize(file_match[:name]) if file_match
          class_entry = classes.first
          if expected_class && class_entry && class_entry.fetch(:name) != expected_class
            add_unsupported("class_name_mismatch", *class_entry.fetch(:location))
          end
          result(file_match, classes.map { |entry| entry.fetch(:name) }, migration_version, transaction, body_form)
        end

        private

        def result(file_match, classes, migration_version, transaction, body_form)
          first = @unsupported.min_by { |entry| [entry.fetch(:line), entry.fetch(:column), entry.fetch(:kind)] }
          {
            timestamp: file_match && file_match[:timestamp],
            classes: classes,
            migration_version: migration_version,
            transaction: transaction,
            body_form: body_form,
            first_unsupported: first ? "#{first.fetch(:kind)}@#{first.fetch(:line)}:#{first.fetch(:column)}" : "none",
            comment_count: tokens.count { |token| token[1] == :on_comment },
          }
        end

        def inspect_program(tree)
          statements = tree[0] == :program ? Array(tree[1]) : []
          class_nodes = statements.select { |node| node.is_a?(Array) && node[0] == :class }
          statements.each do |node|
            add_node_unsupported(node, node&.[](0) == :class ? "extra_class" : top_level_kind(node)) unless node.equal?(class_nodes.first)
          end
          add_unsupported("missing_class", 1, 0) if class_nodes.empty?
          return [[], "default", "missing", nil] if class_nodes.empty?

          class_node = class_nodes.first
          class_entries = class_nodes.filter_map { |node| class_identity(node[1]) }
          class_token = plain_class_token(class_node[1])
          add_node_unsupported(class_node[1], "namespaced_class") unless class_token
          migration_version = migration_version(class_node[2])
          add_node_unsupported(class_node[2], "migration_superclass") unless migration_version == "7.1"
          transaction, body_form = inspect_class_body(class_node[3])
          [class_entries, transaction, body_form, migration_version]
        end

        def inspect_class_body(body)
          statements = body.is_a?(Array) && body[0] == :bodystmt ? Array(body[1]) : []
          add_node_unsupported(body, "class_rescue_or_ensure") if body.is_a?(Array) && body[2..4].any?
          methods = []
          transaction = "default"
          statements.each do |statement|
            if disable_transaction_call?(statement)
              transaction = "disabled"
              add_node_unsupported(statement, "disable_ddl_transaction")
              next
            end
            if statement.is_a?(Array) && statement[0] == :def
              methods << statement
              inspect_method(statement)
            else
              add_node_unsupported(statement, statement_kind(statement))
            end
          end
          names = methods.filter_map { |method| token_text(method[1]) }
          body_form = if names == ["change"]
            "change"
          elsif names.sort == %w[down up] && names.length == 2
            "up_down"
          elsif names.empty?
            "empty"
          else
            "other"
          end
          methods.each do |method|
            name = token_text(method[1])
            add_node_unsupported(method[1], "method_#{name || "unknown"}") unless name == "change"
          end
          [transaction, body_form]
        end

        def inspect_method(method)
          params = method[2]
          add_node_unsupported(params, "method_parameters") unless empty_params?(params)
          body = method[3]
          statements = body.is_a?(Array) && body[0] == :bodystmt ? Array(body[1]) : []
          add_node_unsupported(body, "method_rescue_or_ensure") if body.is_a?(Array) && body[2..4].any?
          statements.each { |statement| inspect_operation_statement(statement) }
        end

        def inspect_operation_statement(statement)
          call_name, call_kind = bare_call(statement)
          unless call_name
            add_node_unsupported(statement, call_kind || statement_kind(statement))
            return
          end
          add_node_unsupported(statement, "call_#{call_name}") unless ADMITTED_CALLS.include?(call_name)
        end

        def bare_call(node)
          return [nil, statement_kind(node)] unless node.is_a?(Array)

          call = case node[0]
          when :command
            node[1]
          when :method_add_arg
            target = node[1]
            return [nil, "receiver_call"] unless target.is_a?(Array) && target[0] == :fcall

            target[1]
          else
            return [nil, statement_kind(node)]
          end
          [token_text(call), nil]
        end

        def disable_transaction_call?(node)
          node.is_a?(Array) && node[0] == :method_add_arg &&
            node[1].is_a?(Array) && node[1][0] == :fcall && token_text(node[1][1]) == "disable_ddl_transaction!" &&
            node[2] == []
        end

        def migration_version(node)
          return nil unless node.is_a?(Array) && node[0] == :aref

          constant = node[1]
          args = node[2]
          return nil unless active_record_migration?(constant)
          return nil unless args.is_a?(Array) && args[0] == :args_add_block && Array(args[1]).length == 1

          version = args[1][0]
          version[1] if version.is_a?(Array) && version[0] == :@float
        end

        def active_record_migration?(node)
          node.is_a?(Array) && node[0] == :const_path_ref &&
            node[1].is_a?(Array) && node[1][0] == :var_ref && token_text(node[1][1]) == "ActiveRecord" &&
            token_text(node[2]) == "Migration"
        end

        def plain_class_token(node)
          return nil unless node.is_a?(Array) && node[0] == :const_ref

          token = node[1]
          token if token.is_a?(Array) && token[0] == :@const
        end

        def class_identity(node)
          parts = []
          first_location = nil
          current = node
          loop do
            case current&.[](0)
            when :const_path_ref
              token = current[2]
              return nil unless token.is_a?(Array) && token[0] == :@const

              parts.unshift(token[1])
              current = current[1]
            when :const_ref, :top_const_ref, :var_ref
              token = current[1]
              return nil unless token.is_a?(Array) && token[0] == :@const

              parts.unshift(token[1])
              first_location = token[2]
              break
            else
              return nil
            end
          end
          { name: parts.join("::"), location: first_location }
        end

        def empty_params?(node)
          node == [:params, nil, nil, nil, nil, nil, nil, nil]
        end

        def token_text(node)
          node[1] if node.is_a?(Array) && node[0].to_s.start_with?("@")
        end

        def add_magic_comment
          @source.each_line.take(2).each_with_index do |line, index|
            next unless line.match?(MAGIC_COMMENT_PATTERN)

            add_unsupported(line.lstrip.start_with?("#!") ? "shebang" : "magic_comment", index + 1, line.index("#") || 0)
            break
          end
        end

        def add_unsupported_lexical_forms
          tokens.each do |token|
            kind = case token[1]
            when :on___end__ then "data_section"
            when :on_embdoc_beg then "block_comment"
            when :on_heredoc_beg then "heredoc"
            end
            add_unsupported(kind, *token[0]) if kind
          end
        end

        def tokens
          @tokens ||= Ripper.lex(@source)
        end

        def camelize(name)
          name.split("_").map(&:capitalize).join
        end

        def top_level_kind(node)
          node.is_a?(Array) && node[0] == :module ? "module" : statement_kind(node)
        end

        def statement_kind(node)
          return "unknown" unless node.is_a?(Array)
          return "receiver_call" if %i[command_call call].include?(node[0])
          if node[0] == :method_add_arg && node[1].is_a?(Array) && %i[call command_call].include?(node[1][0])
            return "receiver_call"
          end

          node[0].to_s
        end

        def add_node_unsupported(node, kind)
          line, column = location(node) || [1, 0]
          add_unsupported(kind, line, column)
        end

        def add_unsupported(kind, line, column)
          @unsupported << { kind: kind, line: line, column: column }
        end

        def location(node)
          stack = [node]
          until stack.empty?
            current = stack.pop
            next unless current.is_a?(Array)
            return current[2] if current[0].to_s.start_with?("@") && current[2].is_a?(Array)

            current.reverse_each { |child| stack << child if child.is_a?(Array) }
          end
          nil
        end

        class SyntaxProbe < Ripper
          attr_reader :error_location

          def on_parse_error(_message)
            @error_location ||= [lineno, column]
          end
        end
      end
    end
  end
end
