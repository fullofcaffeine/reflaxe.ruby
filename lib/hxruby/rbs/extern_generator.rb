# frozen_string_literal: true

module HXRuby
  module Rbs
    # Selects one exact declaration from a checked app/repository-local RBS
    # source and renders it without writing. The explicit root and realpath
    # checks keep maintainer tooling from following a source symlink outside
    # the reviewed fixture or vendored signature tree.
    class ExternGenerator
      def initialize(
        root:,
        input:,
        constant_name:,
        package_name:,
        native_name: nil,
        haxe_class: nil,
        require_path: nil,
        source_label: nil
      )
        @root = checked_root(root)
        @input = checked_relative_path(input, "RBS input")
        @source_path = checked_source_path
        @constant_name = checked_constant_name(constant_name)
        @package_name = package_name
        @native_name = native_name
        @haxe_class = haxe_class
        @require_path = require_path
        @source_label = checked_relative_path(source_label || @input, "RBS source label")
      end

      # Re-parsing on each call is intentional: render output is a pure
      # function of the current checked source bytes and explicit options.
      def render
        contracts = SourceParser.new(@source_path, @source_label, strict: true).contracts
        duplicates = contracts.group_by { |contract| contract.fetch(:constant_name) }.select { |_name, entries| entries.length > 1 }
        unless duplicates.empty?
          raise Error, "RBS source contains duplicate declarations: #{duplicates.keys.sort.join(", ")}"
        end

        contract = contracts.find { |candidate| candidate.fetch(:constant_name) == @constant_name }
        unless contract
          available = contracts.map { |candidate| candidate.fetch(:constant_name) }.sort
          suffix = available.empty? ? "no supported declarations found" : "available: #{available.join(", ")}"
          raise Error, "RBS constant #{@constant_name} was not found in #{@input}; #{suffix}"
        end

        HaxeExternRenderer.new(
          contract: contract,
          package_name: @package_name,
          native_name: @native_name || @constant_name,
          haxe_class: @haxe_class,
          require_path: @require_path,
          canonical: true
        ).render
      end

      private

      def checked_root(value)
        root = File.expand_path(value.to_s)
        raise Error, "RBS root does not exist or is not a directory: #{value}" unless File.directory?(root)

        File.realpath(root)
      rescue Errno::EACCES, Errno::ELOOP, Errno::ENOENT => error
        raise Error, "Unsafe RBS root #{value}: #{error.message}"
      end

      def checked_source_path
        path = File.expand_path(@input, @root)
        unless path.start_with?("#{@root}#{File::SEPARATOR}")
          raise Error, "RBS input must stay inside the declared root"
        end
        raise Error, "RBS source does not exist: #{@input}" unless File.file?(path)

        real_path = File.realpath(path)
        unless real_path.start_with?("#{@root}#{File::SEPARATOR}")
          raise Error, "RBS input must resolve to a file inside the declared root"
        end
        real_path
      rescue Errno::EACCES, Errno::ELOOP, Errno::ENOENT => error
        raise Error, "Unsafe RBS input #{@input}: #{error.message}"
      end

      def checked_relative_path(value, label)
        raw = value.to_s.strip
        if raw.empty? || raw.start_with?("/", ".") || raw.include?("\\") || raw.include?("//")
          raise Error, "#{label} must be a safe forward-slash relative path"
        end
        segments = raw.split("/")
        if segments.any? { |segment| segment.empty? || segment == "." || segment == ".." }
          raise Error, "#{label} must be a safe forward-slash relative path"
        end
        unless raw.match?(/\A[A-Za-z0-9_][A-Za-z0-9_.\/-]*\z/)
          raise Error, "#{label} must be a safe forward-slash relative path"
        end
        raw
      end

      def checked_constant_name(value)
        constant = value.to_s.strip
        unless constant.match?(/\A[A-Z][A-Za-z0-9_]*(?:::[A-Z][A-Za-z0-9_]*)*\z/)
          raise Error, "RBS constant must be a safe Ruby constant path"
        end
        constant
      end
    end
  end
end
