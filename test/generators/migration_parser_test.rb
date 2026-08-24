# frozen_string_literal: true

ENV["MT_NO_PLUGINS"] = "1"

require "digest"
require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"
require_relative "../../lib/hxruby/generators/migration_parser"
require_relative "../../lib/hxruby/generators/migration_source_reader"

class HXRubyMigrationParserTest < Minitest::Test
  SAFE_RELATIVE_PATH = "db/migrate/20260824000000_add_status_to_widgets.rb"
  SAFE_SOURCE = [
    "# Historical reason retained in Rails-owned source.",
    "class AddStatusToWidgets < ActiveRecord::Migration[7.1]",
    "  def change",
    '    add_column :widgets, :status, :string, default: "pending", null: false',
    '    add_index :widgets, :status, name: "index_widgets_on_status"',
    "  end",
    "end",
    "",
  ].join("\n").freeze
  PRISM_WAS_EAGERLY_LOADED = Object.const_defined?(:Prism)

  def setup
    @tmp = Dir.mktmpdir("hxruby-migration-parser.")
    @root = File.join(@tmp, "app")
    FileUtils.mkdir_p(File.join(@root, "db", "migrate"))
    @reader = internal_constant(:MigrationSourceReader).new(@root)
    @parser = internal_constant(:MigrationParser)
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def test_real_rails_bundle_uses_the_exact_parser_profile
    skip "The focused parser gate does not load Rails." unless ENV["REQUIRE_RAILS"] == "1"

    require "rails"
    support = JSON.parse(File.read(File.expand_path("../../lib/hxruby/support_matrix.json", __dir__)))
    assert_equal support.fetch("railsHx").fetch("verifiedRuntime").fetch("railsVersion"), Rails.gem_version.to_s

    write_source(SAFE_RELATIVE_PATH, SAFE_SOURCE)
    candidate = @parser.parse(@reader.read(SAFE_RELATIVE_PATH))
    assert_equal "1.9.0", candidate.parser_version
    assert_equal 2, candidate.operations.length
  end

  def test_valid_tracer_builds_the_manually_expected_immutable_candidate
    refute PRISM_WAS_EAGERLY_LOADED, "requiring the parser must not load Prism before selected parsing"
    write_source(SAFE_RELATIVE_PATH, SAFE_SOURCE)
    tree_before = tree_snapshot

    candidate = @parser.parse(@reader.read(SAFE_RELATIVE_PATH))

    assert_equal SAFE_RELATIVE_PATH, candidate.source_path
    assert_equal Digest::SHA256.hexdigest(SAFE_SOURCE.b), candidate.source_sha256
    assert_equal "20260824000000", candidate.timestamp
    assert_equal "AddStatusToWidgets", candidate.class_name
    assert_equal "ActiveRecord::Migration[7.1]", candidate.compatibility_profile
    assert_equal "railshx-migration-prism-v1", candidate.parser_identity
    assert_equal "1.9.0", candidate.parser_version
    assert_equal "3.3", candidate.ruby_syntax_version
    assert_equal "railshx-migration-catalog-v1", candidate.catalog_identity
    assert_equal 1, candidate.comment_count
    assert_equal "Ruby line comments are omitted from generated Haxe.", candidate.comment_omission_notice
    assert_equal expected_candidate_id, candidate.candidate_id

    column, index = candidate.operations
    assert_equal "MigrationAdoptedAddColumn", short_class_name(column)
    assert_equal "widgets", column.table
    assert_equal "status", column.column
    assert_equal "pending", column.default_value
    assert_equal false, column.nullable
    assert_equal source_slice(column.source_span), 'add_column :widgets, :status, :string, default: "pending", null: false'

    assert_equal "MigrationAdoptedAddIndex", short_class_name(index)
    assert_equal "widgets", index.table
    assert_equal "status", index.column
    assert_equal "index_widgets_on_status", index.name
    assert_equal source_slice(index.source_span), 'add_index :widgets, :status, name: "index_widgets_on_status"'

    assert candidate.frozen?
    assert candidate.operations.frozen?
    assert candidate.operations.all?(&:frozen?)
    assert candidate.operations.all? { |operation| operation.source_span.frozen? }
    assert candidate.source_path.frozen?
    assert_raises(FrozenError) { candidate.operations << column }
    assert_raises(FrozenError) { candidate.source_path << ".changed" }
    refute_respond_to candidate, :generated_haxe_sha256
    refute_respond_to candidate, :generated_ruby_sha256
    assert_equal tree_before, tree_snapshot
  end

  def test_catalog_accepts_repeated_operations_and_preserves_either_order
    relative = "db/migrate/20260824000001_reorder_status_on_widgets.rb"
    source = [
      "class ReorderStatusOnWidgets < ActiveRecord::Migration[7.1]",
      "  def change",
      '    add_index :widgets, :status, name: "index_widgets_on_status"',
      "    add_column :widgets, :status, :string",
      '    add_index :widgets, :legacy_status, name: "index_widgets_on_legacy_status"',
      "  end",
      "end",
      "",
    ].join("\n")
    write_source(relative, source)

    candidate = @parser.parse(@reader.read(relative))

    assert_equal(
      %w[MigrationAdoptedAddIndex MigrationAdoptedAddColumn MigrationAdoptedAddIndex],
      candidate.operations.map { |operation| short_class_name(operation) }
    )
    assert_equal %w[status status legacy_status], candidate.operations.map(&:column)
  end

  def test_hostile_top_level_code_is_rejected_without_execution_or_a_candidate
    marker = File.join(@root, "EXECUTED")
    relative = "db/migrate/20260824000002_unsafe_migration.rb"
    source = [
      'File.write("EXECUTED", "bad")',
      "class UnsafeMigration < ActiveRecord::Migration[7.1]",
      "  def change",
      "    add_column :widgets, :status, :string",
      "  end",
      "end",
      "",
    ].join("\n")
    write_source(relative, source)

    error = assert_raises(internal_constant(:MigrationParserError)) do
      @parser.parse(@reader.read(relative))
    end

    assert_equal "top_level_structure", error.diagnostic.code
    assert_equal relative, error.diagnostic.relative_path
    assert_equal 1, error.diagnostic.span.start_line
    assert_equal 0, error.diagnostic.span.start_column
    refute_path_exists marker
  end

  def test_static_percent_strings_and_parenthesized_calls_remain_literal_forms
    relative = "db/migrate/20260824000003_add_code_to_widgets.rb"
    source = [
      "class AddCodeToWidgets < ActiveRecord::Migration[7.1]",
      "  def change",
      "    add_column(:widgets, :code, :string, default: %q(pending), null: true)",
      "    add_index(:widgets, :code, name: %q(index_widgets_on_code))",
      "  end",
      "end",
      "",
    ].join("\n")
    write_source(relative, source)

    candidate = @parser.parse(@reader.read(relative))

    assert_equal "pending", candidate.operations[0].default_value
    assert_equal true, candidate.operations[0].nullable
    assert_equal "index_widgets_on_code", candidate.operations[1].name
  end

  def test_validated_bytes_survive_source_deletion_without_a_parser_reopen
    write_source(SAFE_RELATIVE_PATH, SAFE_SOURCE)
    validated = @reader.read(SAFE_RELATIVE_PATH)
    File.delete(File.join(@root, SAFE_RELATIVE_PATH))

    candidate = @parser.parse(validated)

    assert_equal Digest::SHA256.hexdigest(SAFE_SOURCE.b), candidate.source_sha256
    assert_equal 2, candidate.operations.length
  end

  def test_multibyte_diagnostic_columns_are_zero_based_byte_columns
    relative = "db/migrate/20260824000004_add_label_to_widgets.rb"
    source = [
      "class AddLabelToWidgets < ActiveRecord::Migration[7.1]",
      "  def change",
      '    add_column :widgets, :label, :string, default: "é", unknown: true',
      "  end",
      "end",
      "",
    ].join("\n")
    write_source(relative, source)

    error = assert_parse_error(relative, "unknown_option")
    line = source.lines.fetch(2)

    assert_equal 3, error.diagnostic.span.start_line
    assert_equal line.b.index("unknown:"), error.diagnostic.span.start_column
    assert_equal source.b.index("unknown:"), error.diagnostic.span.start_byte
  end

  def test_crlf_operation_spans_slice_the_original_bytes
    relative = "db/migrate/20260824000005_add_note_to_widgets.rb"
    source = [
      "class AddNoteToWidgets < ActiveRecord::Migration[7.1]",
      "  def change",
      "    add_column :widgets, :note, :string",
      "  end",
      "end",
      "",
    ].join("\r\n")
    write_source(relative, source)

    operation = @parser.parse(@reader.read(relative)).operations.fetch(0)

    assert_equal "add_column :widgets, :note, :string", source.byteslice(operation.source_span.start_byte...operation.source_span.end_byte)
    assert_equal 3, operation.source_span.start_line
    assert_equal 4, operation.source_span.start_column
  end

  def test_reader_returns_one_frozen_digest_bound_value
    write_source(SAFE_RELATIVE_PATH, SAFE_SOURCE)

    validated = @reader.read(SAFE_RELATIVE_PATH)

    assert validated.frozen?
    assert validated.relative_path.frozen?
    assert validated.basename.frozen?
    assert validated.source.frozen?
    assert validated.sha256.frozen?
    assert_equal SAFE_SOURCE.bytesize, validated.byte_size
    assert_equal Digest::SHA256.hexdigest(validated.source.b), validated.sha256
  end

  def test_reader_accepts_exact_limit_and_rejects_one_extra_byte
    reader_class = internal_constant(:MigrationSourceReader)
    base = [
      "class NearLimitMigration < ActiveRecord::Migration[7.1]",
      "  def change",
      "    add_column :widgets, :near_limit, :string",
      "  end",
      "end",
      "",
    ].join("\n")
    relative = "db/migrate/20260824000006_near_limit_migration.rb"
    padding_size = reader_class::MAX_SOURCE_BYTES - base.bytesize - 2
    exact_source = "##{'x' * padding_size}\n#{base}"
    write_source(relative, exact_source)

    validated = @reader.read(relative)

    assert_equal reader_class::MAX_SOURCE_BYTES, validated.byte_size
    assert_equal 1, @parser.parse(validated).operations.length

    File.binwrite(File.join(@root, relative), exact_source + "x")
    error = assert_raises(HXRuby::Generators::Error) { @reader.read(relative) }
    assert_includes error.message, "exceeds the 1048576-byte migration source limit"
  end

  def test_reader_rejects_nul_and_invalid_utf8_before_parsing
    relative = "db/migrate/20260824000007_invalid_bytes.rb"
    write_source(relative, "class Invalid\0Bytes\nend\n")
    nul = assert_raises(HXRuby::Generators::Error) { @reader.read(relative) }
    assert_includes nul.message, "contains a NUL byte"

    File.binwrite(File.join(@root, relative), [0x63, 0x6c, 0x61, 0x73, 0x73, 0x20, 0xff, 0x0a].pack("C*"))
    invalid = assert_raises(HXRuby::Generators::Error) { @reader.read(relative) }
    assert_includes invalid.message, "is not valid UTF-8"
  end

  def test_reader_rejects_unsafe_selected_paths_before_opening
    [
      "",
      SAFE_RELATIVE_PATH.delete_prefix("db/"),
      "/#{SAFE_RELATIVE_PATH}",
      "db/migrate/../#{File.basename(SAFE_RELATIVE_PATH)}",
      "db/migrate/nested/#{File.basename(SAFE_RELATIVE_PATH)}",
      "db\\migrate\\#{File.basename(SAFE_RELATIVE_PATH)}",
      "db/migrate/20260824000000_bad__name.rb",
      "db/migrate/20260824000000_bad_name_.rb",
    ].each do |relative|
      error = assert_raises(HXRuby::Generators::Error) { @reader.read(relative) }
      assert_includes error.message, "must match db/migrate"
    end
  end

  def test_reader_rejects_leaf_links_hard_links_and_non_regular_entries
    outside = File.join(@tmp, "outside.rb")
    File.write(outside, SAFE_SOURCE)

    symlink_relative = "db/migrate/20260824000008_linked_migration.rb"
    File.symlink(outside, File.join(@root, symlink_relative))
    symlink_error = assert_raises(HXRuby::Generators::Error) { @reader.read(symlink_relative) }
    assert_includes symlink_error.message, "one regular file with no links"

    hardlink_relative = "db/migrate/20260824000009_hard_linked_migration.rb"
    File.link(outside, File.join(@root, hardlink_relative))
    hardlink_error = assert_raises(HXRuby::Generators::Error) { @reader.read(hardlink_relative) }
    assert_includes hardlink_error.message, "one regular file with no links"

    directory_relative = "db/migrate/20260824000010_directory_migration.rb"
    FileUtils.mkdir_p(File.join(@root, directory_relative))
    directory_error = assert_raises(HXRuby::Generators::Error) { @reader.read(directory_relative) }
    assert_includes directory_error.message, "one regular file with no links"
  end

  def test_reader_rejects_linked_database_ancestors
    outside_db = File.join(@tmp, "outside_db")
    FileUtils.mkdir_p(File.join(outside_db, "migrate"))
    linked_root = File.join(@tmp, "linked_app")
    FileUtils.mkdir_p(linked_root)
    File.symlink(outside_db, File.join(linked_root, "db"))
    reader = internal_constant(:MigrationSourceReader).new(linked_root)

    error = assert_raises(HXRuby::Generators::Error) { reader.read(SAFE_RELATIVE_PATH) }

    assert_includes error.message, "db must be a real directory and not a symbolic link"
  end

  def test_exact_parser_version_mismatch_has_one_stable_diagnostic
    script = <<~'RUBY'
      require "digest"
      require "fileutils"
      require "tmpdir"
      module Prism
        VERSION = "0.0.0"
      end
      $LOADED_FEATURES << "prism.rb"
      require "hxruby/generators/migration_parser"
      require "hxruby/generators/migration_source_reader"
      root = Dir.mktmpdir("hxruby-prism-mismatch.")
      begin
        relative = "db/migrate/20260824000000_add_status_to_widgets.rb"
        FileUtils.mkdir_p(File.join(root, "db", "migrate"))
        File.write(File.join(root, relative), "class AddStatusToWidgets < ActiveRecord::Migration[7.1]\n  def change\n    add_column :widgets, :status, :string\n  end\nend\n")
        reader = HXRuby::Generators.const_get(:MigrationSourceReader, false).new(root)
        parser = HXRuby::Generators.const_get(:MigrationParser, false)
        error_class = HXRuby::Generators.const_get(:MigrationParserError, false)
        begin
          parser.parse(reader.read(relative))
          abort "parser accepted mismatched Prism"
        rescue error_class => error
          abort error.message unless error.diagnostic.code == "parser_version"
          puts error.diagnostic.code
        end
      ensure
        FileUtils.rm_rf(root)
      end
    RUBY

    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby,
      "-I",
      File.expand_path("../../lib", __dir__),
      "-e",
      script
    )

    assert status.success?, stderr
    assert_equal "parser_version\n", stdout
  end

  def test_plain_hxruby_load_does_not_eagerly_load_prism
    script = 'require "hxruby"; abort "Prism loaded" if Object.const_defined?(:Prism); puts "lazy"'
    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby,
      "-I",
      File.expand_path("../../lib", __dir__),
      "-e",
      script
    )

    assert status.success?, stderr
    assert_equal "lazy\n", stdout
  end

  def test_parser_source_has_no_file_or_execution_escape
    parser_source = File.read(File.expand_path("../../lib/hxruby/generators/migration_parser.rb", __dir__))

    refute_match(/Prism[.]parse_file|File[.](?:read|binread|open)|Kernel[.](?:eval|load)|class_eval|module_eval/, parser_source)
    refute_includes parser_source, "RubyCompiler"
    refute_includes parser_source, "MigrationOperation.hx"
  end

  def test_private_cases_match_the_existing_haxe_operation_and_compiler_contract
    operation_source = File.read(File.expand_path("../../std/rails/migration/MigrationOperation.hx", __dir__))
    compiler_source = File.read(File.expand_path("../../src/reflaxe/ruby/RubyCompiler.hx", __dir__))

    assert_includes operation_source, "AddColumn(table:String, name:String, column:MigrationColumn);"
    assert_includes operation_source, "StringColumn(options:ColumnOptions<String>);"
    assert_includes operation_source, "AddIndex(table:String, column:String, options:IndexOptions);"
    assert_includes compiler_source, 'case "AddColumn" if (args.length == 3):'
    assert_includes compiler_source, 'case "AddIndex" if (args.length == 3):'
    assert_includes compiler_source, '"default: "'
    assert_includes compiler_source, '"null: "'
    assert_includes compiler_source, '"name: "'
  end

  def test_pinned_parser_terminates_on_deep_and_high_token_inputs
    deep_relative = "db/migrate/20260824000011_deep_migration.rb"
    deep_source = "(" * 4_000 + "true" + ")" * 4_000
    write_source(deep_relative, deep_source)
    deep_error = assert_raises(internal_constant(:MigrationParserError)) do
      @parser.parse(@reader.read(deep_relative))
    end
    assert_includes %w[source_too_deep syntax_error top_level_structure], deep_error.diagnostic.code

    token_relative = "db/migrate/20260824000012_token_migration.rb"
    write_source(token_relative, (["unknown_call"] * 10_000).join("\n") + "\n")
    token_error = assert_raises(internal_constant(:MigrationParserError)) do
      @parser.parse(@reader.read(token_relative))
    end
    assert_equal "top_level_structure", token_error.diagnostic.code
  end

  REJECTED_PROGRAMS = {
    "unknown SQL call" => [
      ["execute \"UPDATE widgets SET status = 'bad'\""],
      "unknown_call",
    ],
    "unknown helper call" => [["copy_status"], "unknown_call"],
    "receiver call" => [["self.add_column :widgets, :status, :string"], "receiver_call"],
    "branch" => [["if true", "  add_column :widgets, :status, :string", "end"], "unsupported_statement"],
    "block" => [["add_column(:widgets, :status, :string) { raise \"bad\" }"], "receiver_call"],
    "computed table" => [["add_column table_name, :status, :string"], "symbol_literal"],
    "array column" => [["add_index :widgets, [:status], name: \"index_widgets_on_status\""], "symbol_literal"],
    "wrong column type" => [["add_column :widgets, :status, :text"], "column_type"],
    "interpolated default" => [['add_column :widgets, :status, :string, default: "#{danger}"'], "string_literal"],
    "string computation" => [["add_column :widgets, :status, :string, default: \"a\" + \"b\""], "string_literal"],
    "unknown option" => [["add_column :widgets, :status, :string, limit: 20"], "unknown_option"],
    "duplicate option" => [["add_column :widgets, :status, :string, null: false, null: true"], "parser_warning"],
    "non Boolean null" => [["add_column :widgets, :status, :string, null: nil"], "boolean_literal"],
    "keyword splat" => [["add_column :widgets, :status, :string, **options"], "keyword_option"],
    "positional option hash" => [["add_column :widgets, :status, :string, { default: \"pending\" }"], "keyword_options"],
    "hash rocket option" => [["add_index :widgets, :status, { :name => \"index_widgets_on_status\" }"], "keyword_options"],
    "missing index name" => [["add_index :widgets, :status"], "add_index_arguments"],
    "extra index argument" => [["add_index :widgets, :status, name: \"index_widgets_on_status\", unique: true"], "unknown_option"],
    "unsafe database name" => [["add_column :bad__table, :status, :string"], "database_name"],
    "semantic NUL" => [['add_column :widgets, :status, :string, default: "\u0000"'], "string_nul"],
  }.freeze

  REJECTED_PROGRAMS.each do |label, (statements, code)|
    define_method("test_rejects_#{label.gsub(/[^a-z0-9]+/i, "_")}") do
      relative = "db/migrate/20260824010000_rejected_migration.rb"
      source = migration_source("RejectedMigration", statements)
      write_source(relative, source)

      error = assert_parse_error(relative, code)

      assert_operator error.diagnostic.span.start_byte, :>=, 0
      assert_operator error.diagnostic.span.end_byte, :>=, error.diagnostic.span.start_byte
    end
  end

  def self.fixture_source(class_name, statements)
    [
      "class #{class_name} < ActiveRecord::Migration[7.1]",
      "  def change",
      *statements.map { |statement| "    #{statement}" },
      "  end",
      "end",
      "",
    ].join("\n")
  end

  REJECTED_COMPLETE_FILES = {
    "second class" => [
      fixture_source("RejectedMigration", ["add_column :widgets, :status, :string"]) + "class ExtraMigration; end\n",
      "top_level_structure",
    ],
    "namespaced class" => [
      "class Admin::RejectedMigration < ActiveRecord::Migration[7.1]\n  def change\n    add_column :widgets, :status, :string\n  end\nend\n",
      "class_structure",
    ],
    "wrong class name" => [fixture_source("WrongName", ["add_column :widgets, :status, :string"]), "class_name_mismatch"],
    "wrong superclass" => [
      fixture_source("RejectedMigration", ["add_column :widgets, :status, :string"]).sub("ActiveRecord::Migration[7.1]", "ActiveRecord::Migration[7.10]"),
      "migration_superclass",
    ],
    "missing superclass" => [
      fixture_source("RejectedMigration", ["add_column :widgets, :status, :string"]).sub(" < ActiveRecord::Migration[7.1]", ""),
      "migration_superclass",
    ],
    "parameterized change" => [
      fixture_source("RejectedMigration", ["add_column :widgets, :status, :string"]).sub("def change", "def change(value)"),
      "change_method",
    ],
    "extra method" => [
      "class RejectedMigration < ActiveRecord::Migration[7.1]\n  def change\n    add_column :widgets, :status, :string\n  end\n  def helper\n  end\nend\n",
      "class_body",
    ],
    "empty change" => [fixture_source("RejectedMigration", []), "empty_change"],
    "syntax error" => ["class RejectedMigration < ActiveRecord::Migration[7.1\n", "syntax_error"],
    "shebang" => ["#!/usr/bin/env ruby\n" + fixture_source("RejectedMigration", ["add_column :widgets, :status, :string"]), "shebang"],
    "magic comment" => ["# frozen_string_literal: true\n" + fixture_source("RejectedMigration", ["add_column :widgets, :status, :string"]), "magic_comment"],
    "byte order mark" => ["\uFEFF" + fixture_source("RejectedMigration", ["add_column :widgets, :status, :string"]), "byte_order_mark"],
    "semicolon" => [fixture_source("RejectedMigration", ["add_column :widgets, :status, :string; add_index :widgets, :status, name: \"index_widgets_on_status\""]), "semicolon"],
    "heredoc" => [
      fixture_source("RejectedMigration", ["add_column :widgets, :status, :string, default: <<~TEXT", "  pending", "TEXT"]),
      "heredoc",
    ],
    "embedded document" => [
      "=begin\nnot an admitted line comment\n=end\n" + fixture_source("RejectedMigration", ["add_column :widgets, :status, :string"]),
      "embedded_document",
    ],
    "data section" => [
      fixture_source("RejectedMigration", ["add_column :widgets, :status, :string"]) + "__END__\nnot ruby\n",
      "data_section",
    ],
  }.freeze

  REJECTED_COMPLETE_FILES.each do |label, (source, code)|
    define_method("test_rejects_complete_file_with_#{label.gsub(/[^a-z0-9]+/i, "_")}") do
      relative = "db/migrate/20260824020000_rejected_migration.rb"
      write_source(relative, source)

      assert_parse_error(relative, code)
    end
  end

  private

  def internal_constant(name)
    HXRuby::Generators.const_get(name, false)
  end

  def write_source(relative, source)
    path = File.join(@root, relative)
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, source)
  end

  def migration_source(class_name, statements)
    self.class.fixture_source(class_name, statements)
  end

  def assert_parse_error(relative, expected_code)
    error = assert_raises(internal_constant(:MigrationParserError)) do
      @parser.parse(@reader.read(relative))
    end
    assert_equal expected_code, error.diagnostic.code
    assert_equal relative, error.diagnostic.relative_path
    error
  end

  def source_slice(span)
    SAFE_SOURCE.byteslice(span.start_byte...span.end_byte)
  end

  def short_class_name(value)
    value.class.name.split("::").last
  end

  def expected_candidate_id
    canonical = JSON.generate([
      1,
      SAFE_RELATIVE_PATH,
      Digest::SHA256.hexdigest(SAFE_SOURCE.b),
      "railshx-migration-prism-v1",
      "railshx-migration-catalog-v1",
    ])
    Digest::SHA256.hexdigest(canonical)
  end

  def tree_snapshot
    Dir.glob(File.join(@root, "**", "*"), File::FNM_DOTMATCH)
      .reject { |path| [".", ".."].include?(File.basename(path)) }
      .sort
      .map do |path|
        relative = path.delete_prefix("#{@root}/")
        File.file?(path) ? "file:#{relative}:#{Digest::SHA256.file(path).hexdigest}" : "directory:#{relative}"
      end
  end
end
