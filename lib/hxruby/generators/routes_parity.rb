# frozen_string_literal: true

require "optparse"
require_relative "../core"
require_relative "../generated/route_parity/ruby/native_hash_entry"
require_relative "../generated/route_parity/ruby/native_hash"
require_relative "../generated/route_parity/hxruby/generators/routes/devise_expected_field"
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
          devise_facts: nil,
        }
        OptionParser.new do |parser|
          parser.on("--manifest PATH") { |value| options[:manifest] = value }
          parser.on("--input PATH") { |value| options[:input] = value }
          parser.on("--devise-facts PATH") { |value| options[:devise_facts] = value }
        end.parse!(argv)
        options
      end

      def initialize(options, input: nil)
        @manifest_path = File.expand_path(options.fetch(:manifest))
        @input = input
        @input_path = options.fetch(:input)
        @devise_facts_path = options.fetch(:devise_facts)
      end

      def run
        raise Error, "Missing Haxe-owned route manifest #{@manifest_path}" unless File.file?(@manifest_path)
        raise Error, "Missing Devise mapping facts #{File.expand_path(@devise_facts_path)}" if @devise_facts_path && !File.file?(File.expand_path(@devise_facts_path))

        routes = @input || (@input_path ? File.read(File.expand_path(@input_path)) : $stdin.read)
        errors = Hxruby::Generators::Routes::ParityCore.compare_manifest_file(@manifest_path, routes, @devise_facts_path)
        return if errors.empty?

        raise Error, "Haxe-owned route parity failed:\n- #{errors.join("\n- ")}"
      rescue JSON::ParserError => error
        raise Error, "Invalid Haxe-owned route manifest or Devise mapping facts: #{error.message}"
      end
    end
  end
end
