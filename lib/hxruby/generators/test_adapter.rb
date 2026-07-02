# frozen_string_literal: true

require_relative "common"

module HXRuby
  module Generators
    module TestAdapter
      CANONICAL = {
        "minitest" => "rails.minitest",
        "rails.minitest" => "rails.minitest",
        "rspec" => "rails.rspec",
        "rails.rspec" => "rails.rspec",
      }.freeze

      module_function

      def resolve(value, root:)
        requested = value.to_s.strip
        requested = "minitest" if requested.empty?
        return detect(root) if requested == "auto"
        return CANONICAL.fetch(requested) if CANONICAL.key?(requested)

        raise Error, "Test adapter must be minitest, rails.minitest, rspec, rails.rspec, or auto"
      end

      def detect(root)
        expanded = File.expand_path(root)
        return "rails.rspec" if File.file?(File.join(expanded, "spec", "rails_helper.rb"))
        return "rails.rspec" if File.file?(File.join(expanded, "spec", "spec_helper.rb"))

        %w[Gemfile Gemfile.lock].each do |name|
          path = File.join(expanded, name)
          return "rails.rspec" if File.file?(path) && File.read(path).include?("rspec-rails")
        end

        "rails.minitest"
      end

      def rspec?(adapter)
        adapter == "rails.rspec"
      end

      def metadata_line(adapter)
        rspec?(adapter) ? '@:railsTestAdapter("rails.rspec")' : nil
      end

      def framework_name(adapter)
        rspec?(adapter) ? "Rails/RSpec" : "Rails/Minitest"
      end

      def output_root(adapter)
        rspec?(adapter) ? "spec/generated" : "test/generated"
      end

      def file_suffix(adapter)
        rspec?(adapter) ? "spec" : "test"
      end

      def class_suffix(adapter)
        rspec?(adapter) ? "HaxeSpec" : "HaxeTest"
      end
    end
  end
end
