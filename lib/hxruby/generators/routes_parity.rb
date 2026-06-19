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

        manifest = JSON.parse(File.read(@manifest_path))
        routes = @input || (@input_path ? File.read(File.expand_path(@input_path)) : $stdin.read)
        errors = Hxruby::Generators::Routes::ParityCore.compare_manifest(manifest, routes)
        errors.concat(validate_devise_mappings(manifest))
        return if errors.empty?

        raise Error, "Haxe-owned route parity failed:\n- #{errors.join("\n- ")}"
      rescue JSON::ParserError => error
        raise Error, "Invalid Haxe-owned route manifest #{@manifest_path}: #{error.message}"
      end

      private

      def validate_devise_mappings(manifest)
        declarations = devise_declarations(manifest.fetch("declarations", []))
        return [] if declarations.empty?

        unless @devise_facts_path
          return ["Devise route manifest entries require Devise mapping facts from a fresh Rails boot"]
        end

        facts = read_devise_facts
        mappings = facts.fetch("mappings", {})
        declarations.flat_map do |declaration|
          expected = declaration.fetch("expectedMapping", {})
          scope = expected.fetch("name", "").to_s
          mapping = mappings[scope]
          if mapping.nil?
            ["missing Devise mapping #{scope.inspect} for #{declaration_position(declaration)}"]
          else
            compare_devise_mapping(scope, expected, mapping, declaration)
          end
        end
      end

      def read_devise_facts
        path = File.expand_path(@devise_facts_path)
        JSON.parse(File.read(path))
      rescue Errno::ENOENT
        raise Error, "Missing Devise mapping facts #{path}"
      rescue JSON::ParserError => error
        raise Error, "Invalid Devise mapping facts #{path}: #{error.message}"
      end

      def devise_declarations(declarations)
        declarations.flat_map do |declaration|
          children = devise_declarations(declaration.fetch("children", []))
          declaration["kind"] == "deviseFor" ? [declaration, *children] : children
        end
      end

      def compare_devise_mapping(scope, expected, mapping, declaration)
        errors = []
        expected_class = expected.fetch("className", "").to_s
        expected_path = expected.fetch("path", "").to_s

        {
          "name" => scope,
          "className" => expected_class,
          "path" => expected_path,
          "scopedPath" => expected_path,
        }.each do |field, expected_value|
          actual_value = mapping[field].to_s
          next if actual_value == expected_value

          errors << "wrong Devise mapping #{scope.inspect} #{field} for #{declaration_position(declaration)}: expected #{expected_value.inspect}, saw #{actual_value.inspect}"
        end

        unless mapping["modelHasDevise"] == true
          errors << "Devise mapping #{scope.inspect} does not point at a model with Devise modules for #{declaration_position(declaration)}"
        end

        errors
      end

      def declaration_position(declaration)
        declaration.fetch("position", "unknown route position")
      end
    end
  end
end
