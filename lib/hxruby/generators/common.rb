# frozen_string_literal: true

require "fileutils"
require "json"

module HXRuby
  module Generators
    module Common
      module_function

      def write_file(path, content, force: false, executable: false)
        if File.exist?(path) && !force
          raise Error, "Refusing to overwrite #{path}. Re-run with --force if intended."
        end

        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
        FileUtils.chmod(0o755, path) if executable
      end

      def haxe_string(value)
        JSON.generate(value.to_s)
      end

      def haxe_method_name(ruby_name)
        ruby_name.to_s.gsub(/_([a-z0-9])/) { Regexp.last_match(1).upcase }
      end

      def file_name(value)
        value.to_s
          .gsub(/([a-z0-9])([A-Z])/, "\\1_\\2")
          .gsub(/[-\s]+/, "_")
          .downcase
      end

      def class_name_from_path(value)
        value.to_s.split(/[\/_:-]/).reject(&:empty?).map { |part| part[0].upcase + part[1..] }.join
      end

      def pluralize(value)
        value.to_s.end_with?("s") ? value.to_s : "#{value}s"
      end

      def package_path(package_name)
        package_name.to_s.tr(".", "/")
      end

      def split_csv(value)
        value.to_s.split(",").map(&:strip).reject(&:empty?)
      end
    end

    class Error < StandardError; end
  end
end
