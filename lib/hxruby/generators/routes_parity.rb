# frozen_string_literal: true

require "json"
require "optparse"
require_relative "../core"
require_relative "../generated/route_parity/ruby/native_hash"
require_relative "../generated/route_parity/hxruby/generators/routes/manifest_route"
require_relative "../generated/route_parity/hxruby/generators/routes/rails_route"
require_relative "../generated/route_parity/hxruby/generators/routes/parity_core"
require_relative "common"

module HXRuby
  module Generators
    class RoutesParity
      def self.run(argv, input: nil)
        new(parse(argv), input: input).run
      end

      def self.parse(argv)
        options = {
          manifest: ".railshx/routes.haxe.json",
          input: nil,
        }
        OptionParser.new do |parser|
          parser.on("--manifest PATH") { |value| options[:manifest] = value }
          parser.on("--input PATH") { |value| options[:input] = value }
        end.parse!(argv)
        options
      end

      def initialize(options, input: nil)
        @manifest_path = File.expand_path(options.fetch(:manifest))
        @input = input
        @input_path = options.fetch(:input)
      end

      def run
        raise Error, "Missing Haxe-owned route manifest #{@manifest_path}" unless File.file?(@manifest_path)

        manifest = JSON.parse(File.read(@manifest_path))
        routes = @input || (@input_path ? File.read(File.expand_path(@input_path)) : $stdin.read)
        errors = Hxruby::Generators::Routes::ParityCore.compare_manifest(manifest, routes)
        return if errors.empty?

        raise Error, "Haxe-owned route parity failed:\n- #{errors.join("\n- ")}"
      rescue JSON::ParserError => error
        raise Error, "Invalid Haxe-owned route manifest #{@manifest_path}: #{error.message}"
      end
    end
  end
end
