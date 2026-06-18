# frozen_string_literal: true

require "json"
require "optparse"
require_relative "common"

module HXRuby
  module Generators
    class RoutesParity
      VERB_PATTERN = /\A(?:GET|POST|PATCH|PUT|DELETE|OPTIONS|HEAD)(?:\|(?:GET|POST|PATCH|PUT|DELETE|OPTIONS|HEAD))*\z/

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
        routes = parse_routes(@input || (@input_path ? File.read(File.expand_path(@input_path)) : $stdin.read))
        expected = flatten_manifest(manifest.fetch("declarations"))
        errors = compare(expected, routes)
        return if errors.empty?

        raise Error, "Haxe-owned route parity failed:\n- #{errors.join("\n- ")}"
      rescue JSON::ParserError => error
        raise Error, "Invalid Haxe-owned route manifest #{@manifest_path}: #{error.message}"
      end

      private

      def parse_routes(input)
        routes = []
        previous_prefix = nil
        input.each_line do |raw_line|
          parsed = parse_route_line(raw_line, previous_prefix)
          previous_prefix = parsed.fetch(:prefix) if parsed && !parsed.fetch(:prefix).to_s.empty?
          next unless parsed

          parsed.fetch(:verbs).each do |verb|
            route = parsed.dup
            route.delete(:verbs)
            route[:verb] = verb
            routes << route
          end
        end
        routes
      end

      def parse_route_line(raw_line, previous_prefix)
        line = raw_line.strip
        return nil if line.empty? || line.start_with?("Prefix ")

        tokens = line.split(/\s+/)
        verb_index = tokens.index { |token| route_verb?(token) }
        return parse_mount_line(tokens) unless verb_index

        uri = tokens[verb_index + 1]
        target = tokens[verb_index + 2]
        return nil unless uri&.start_with?("/")

        raw_prefix = tokens[0...verb_index].join("_")
        prefix = raw_prefix.empty? ? previous_prefix : raw_prefix
        return nil if prefix.to_s.empty?

        {
          prefix: prefix,
          verbs: tokens[verb_index].split("|").map(&:downcase),
          path: normalize_rails_uri(uri),
          target: target,
        }
      end

      def parse_mount_line(tokens)
        return nil unless tokens.length >= 2

        prefix = tokens[0]
        uri = tokens[1]
        return nil unless uri&.start_with?("/")

        { prefix: prefix, verbs: [nil], path: normalize_rails_uri(uri), target: nil }
      end

      def route_verb?(token)
        token.match?(VERB_PATTERN)
      end

      def normalize_rails_uri(uri)
        uri.gsub(/\(\.:format\)/, "")
      end

      def flatten_manifest(declarations, context = { path: "" })
        declarations.flat_map { |decl| flatten_decl(decl, context) }
      end

      def flatten_decl(decl, context)
        kind = decl.fetch("kind")
        case kind
        when "root"
          [expected_route(decl, name: "root", verb: "get", path: "/", target: decl.fetch("target"))]
        when "verb"
          [expected_route(decl, name: decl["name"], verb: decl.fetch("verb"), path: joined_path(context.fetch(:path), decl.fetch("path")), target: decl.fetch("target"))]
        when "match"
          decl.fetch("verbs").map do |verb|
            expected_route(decl, name: decl["name"], verb: verb, path: joined_path(context.fetch(:path), decl.fetch("path")), target: decl.fetch("target"))
          end
        when "mount"
          [expected_route(decl, name: decl["name"], verb: nil, path: joined_path(context.fetch(:path), decl.fetch("path")), target: nil)]
        when "rawRuby"
          [{ opaque: true, position: decl["position"] }]
        when "scope", "namespace"
          next_context = context.merge(path: joined_path(context.fetch(:path), kind == "namespace" ? decl.fetch("name") : decl.fetch("path")))
          flatten_manifest(decl.fetch("children", []), next_context)
        when "defaults", "constraints", "controller"
          flatten_manifest(decl.fetch("children", []), context)
        when "resources", "resource", "collection", "member"
          []
        else
          []
        end
      end

      def expected_route(decl, name:, verb:, path:, target:)
        {
          name: name,
          verb: verb,
          path: path,
          target: target,
          position: decl["position"],
        }
      end

      def joined_path(prefix, path)
        pieces = [prefix, path].compact.map(&:to_s).reject(&:empty?)
        return "/" if pieces.empty?

        "/" + pieces.map { |piece| piece.sub(%r{\A/+}, "").sub(%r{/+\z}, "") }.reject(&:empty?).join("/")
      end

      def compare(expected, routes)
        expected.flat_map { |route| compare_route(route, routes) }
      end

      def compare_route(expected, routes)
        return ["opaque raw Haxe-owned route at #{expected[:position]} cannot be parity-checked; replace it with typed route declarations or keep Rails-owned routes"] if expected[:opaque]

        exact = routes.find { |route| route_matches?(expected, route) }
        return [] if exact

        diagnostics = []
        if expected[:name]
          named = routes.select { |route| route[:prefix] == expected[:name] }
          diagnostics << wrong_verb(expected, named) if named.any? && named.none? { |route| route[:verb] == expected[:verb] }
          diagnostics << wrong_path(expected, named) if named.any? && named.any? { |route| route[:verb] == expected[:verb] } && named.none? { |route| route[:path] == expected[:path] }
        end
        same_path_verb = routes.select { |route| route[:path] == expected[:path] && route[:verb] == expected[:verb] }
        diagnostics << wrong_target(expected, same_path_verb) if expected[:target] && same_path_verb.any? && same_path_verb.none? { |route| route[:target] == expected[:target] }
        return diagnostics.compact unless diagnostics.compact.empty?

        ["missing Haxe-owned route #{format_expected(expected)}"]
      end

      def route_matches?(expected, route)
        (!expected[:name] || route[:prefix] == expected[:name]) &&
          route[:verb] == expected[:verb] &&
          route[:path] == expected[:path] &&
          (!expected[:target] || route[:target] == expected[:target])
      end

      def wrong_verb(expected, routes)
        "wrong verb for route #{expected[:name]}: expected #{expected[:verb].to_s.upcase}, saw #{routes.map { |route| route[:verb].to_s.upcase }.uniq.join(", ")}"
      end

      def wrong_path(expected, routes)
        "wrong path for route #{expected[:name]}: expected #{expected[:path]}, saw #{routes.map { |route| route[:path] }.uniq.join(", ")}"
      end

      def wrong_target(expected, routes)
        "wrong target for route #{expected[:path]} #{expected[:verb].to_s.upcase}: expected #{expected[:target]}, saw #{routes.map { |route| route[:target] }.uniq.join(", ")}"
      end

      def format_expected(expected)
        [expected[:name], expected[:verb]&.upcase, expected[:path], expected[:target]].compact.join(" ")
      end
    end
  end
end
