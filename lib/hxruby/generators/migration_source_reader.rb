# frozen_string_literal: true

require "digest"
require_relative "common"

module HXRuby
  module Generators
    ValidatedMigrationSource = Data.define(:relative_path, :basename, :source, :byte_size, :sha256)
    private_constant :ValidatedMigrationSource

    # Owns the one bounded file read shared by migration inventory and parsing.
    #
    # The returned value contains the exact bytes that produced its digest.
    # Later stages cannot reopen the path and silently parse different content.
    class MigrationSourceReader
      MAX_SOURCE_BYTES = 1024 * 1024
      NAME_SEGMENT = "[a-z][a-z0-9]*"
      FILE_NAME_PATTERN = /\A(?<timestamp>[0-9]{14})_(?<name>#{NAME_SEGMENT}(?:_#{NAME_SEGMENT})*)[.]rb\z/
      RELATIVE_PATH_PATTERN = /\Adb\/migrate\/(?<basename>[^\/]+)\z/

      def initialize(output_dir)
        @output_dir = File.expand_path(output_dir)
        @database_root = File.join(@output_dir, "db")
        @migration_root = File.join(@database_root, "migrate")
      end

      # Returns validated sources for the report-only inventory. An absent
      # migration directory remains an empty inventory, as before extraction.
      def inventory_sources
        return [] unless File.exist?(@database_root) || File.symlink?(@database_root)

        assert_real_directory!(@database_root, "db", "Migration inventory")
        return [] unless File.exist?(@migration_root) || File.symlink?(@migration_root)

        prepare_migration_root!("Migration inventory")
        Dir.children(@migration_root)
          .select { |name| name.end_with?(".rb") }
          .sort
          .map { |name| read_path("db/migrate/#{name}", "Migration inventory", validate_filename: false) }
      rescue SystemCallError => error
        raise Error, "Unable to inventory db/migrate safely: #{error.message}"
      end

      # Reads one explicitly selected top-level migration. Invalid names fail
      # before any descriptor is opened or parser dependency is loaded.
      def read(relative_path)
        relative = relative_path.to_s
        match = RELATIVE_PATH_PATTERN.match(relative)
        unless match && FILE_NAME_PATTERN.match?(match[:basename])
          raise Error,
            "Migration parser input #{relative.inspect} must match db/migrate/<14-digit timestamp>_<segmented snake case>.rb."
        end

        prepare_roots!("Migration parser")
        read_path(relative, "Migration parser", validate_filename: true)
      rescue SystemCallError => error
        raise Error, "Unable to read migration parser input #{relative.inspect} safely: #{error.message}"
      end

      private

      def prepare_roots!(label)
        assert_real_directory!(@database_root, "db", label)
        prepare_migration_root!(label)
      end

      def prepare_migration_root!(label)
        assert_real_directory!(@migration_root, "db/migrate", label)
        @migration_root_real = File.realpath(@migration_root)
      end

      def assert_real_directory!(path, relative, label)
        stat = File.lstat(path)
        return if stat.directory? && !stat.symlink?

        raise Error, "#{label} path #{relative} must be a real directory and not a symbolic link."
      end

      def read_path(relative, label, validate_filename:)
        basename = File.basename(relative)
        if validate_filename && !FILE_NAME_PATTERN.match?(basename)
          raise Error, "#{label} input #{relative} has an invalid migration filename."
        end
        unless relative == "db/migrate/#{basename}"
          raise Error, "#{label} input #{relative} must be one top-level file under db/migrate."
        end
        unless File.const_defined?(:NOFOLLOW)
          raise Error, "#{label} input #{relative} requires File::NOFOLLOW on this platform."
        end

        path = File.join(@output_dir, relative)
        listed_before = File.lstat(path)
        assert_regular_unlinked!(listed_before, relative, label)

        File.open(path, File::RDONLY | File::NOFOLLOW) do |file|
          opened_before = file.stat
          listed_open = File.lstat(path)
          resolved_open = File.realpath(path)
          assert_same_file!(listed_before, listed_open, opened_before, resolved_open, relative, label)
          assert_size!(opened_before.size, relative, label)

          bytes = file.read(MAX_SOURCE_BYTES + 1)
          assert_size!(bytes.bytesize, relative, label)

          opened_after = file.stat
          listed_after = File.lstat(path)
          resolved_after = File.realpath(path)
          assert_same_file!(listed_before, listed_after, opened_after, resolved_after, relative, label)
          unless stable_during_read?(opened_before, opened_after)
            raise Error, "#{label} input #{relative} changed while RailsHx read it."
          end

          build_source(relative, basename, bytes, label)
        end
      rescue Errno::ELOOP, Errno::EMLINK
        raise Error, regular_file_error(label, relative)
      rescue SystemCallError => error
        raise Error, "Unable to read #{label.downcase} input #{relative} safely: #{error.message}"
      end

      def assert_regular_unlinked!(stat, relative, label)
        return if stat.file? && !stat.symlink? && stat.nlink == 1

        raise Error, regular_file_error(label, relative)
      end

      def assert_same_file!(listed_before, listed_now, opened, resolved, relative, label)
        unless listed_now.file? && !listed_now.symlink? && listed_now.nlink == 1 && opened.file? && opened.nlink == 1 &&
            same_identity?(listed_before, listed_now) && same_identity?(listed_now, opened) && inside_migration_root?(resolved)
          raise Error, regular_file_error(label, relative)
        end
      end

      def same_identity?(left, right)
        left.dev == right.dev && left.ino == right.ino
      end

      def stable_during_read?(before, after)
        same_identity?(before, after) && before.size == after.size && before.mtime == after.mtime && before.ctime == after.ctime
      end

      def assert_size!(size, relative, label)
        return if size <= MAX_SOURCE_BYTES

        limit_name = label == "Migration inventory" ? "migration inventory" : "migration source"
        raise Error, "#{label} input #{relative} exceeds the #{MAX_SOURCE_BYTES}-byte #{limit_name} limit."
      end

      def regular_file_error(label, relative)
        if label == "Migration inventory"
          "Migration inventory input #{relative} must be a regular file and not a symbolic link."
        else
          "Migration parser input #{relative} must be one regular file with no links."
        end
      end

      def build_source(relative, basename, bytes, label)
        raise Error, "#{label} input #{relative} contains a NUL byte." if bytes.include?("\0")

        source = bytes.dup.force_encoding(Encoding::UTF_8)
        raise Error, "#{label} input #{relative} is not valid UTF-8." unless source.valid_encoding?

        immutable_source = source.freeze
        ValidatedMigrationSource.new(
          relative_path: relative.dup.freeze,
          basename: basename.dup.freeze,
          source: immutable_source,
          byte_size: immutable_source.bytesize,
          sha256: Digest::SHA256.hexdigest(immutable_source.b).freeze
        )
      end

      def inside_migration_root?(path)
        path == @migration_root_real || path.start_with?("#{@migration_root_real}#{File::SEPARATOR}")
      end
    end

    private_constant :MigrationSourceReader
  end
end
