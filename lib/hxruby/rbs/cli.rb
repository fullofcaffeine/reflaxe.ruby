# frozen_string_literal: true

require "optparse"

module HXRuby
  module Rbs
    # Provides the maintainer-facing stdout-only entrypoint. Output ownership is
    # deliberately left to the caller so this strict converter cannot silently
    # replace a curated public facade or an app-owned Haxe file.
    class CLI
      def self.run(argv, stdout: $stdout)
        options = parse(argv)
        if options.key?(:help)
          stdout.write(options.fetch(:help))
          return
        end
        output = ExternGenerator.new(**options).render
        stdout.write(output)
      end

      def self.parse(argv)
        options = {}
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: generate-rbs-extern --root PATH --input FILE --constant NAME --package NAME [options]"
          opts.on("--root PATH", "Canonical root containing the reviewed RBS source") { |value| options[:root] = value }
          opts.on("--input FILE", "Safe relative RBS path inside --root") { |value| options[:input] = value }
          opts.on("--constant NAME", "Exact RBS constant to render") { |value| options[:constant_name] = value }
          opts.on("--package NAME", "Generated Haxe package") { |value| options[:package_name] = value }
          opts.on("--native NAME", "Ruby native constant override") { |value| options[:native_name] = value }
          opts.on("--class NAME", "Generated Haxe class-name override") { |value| options[:haxe_class] = value }
          opts.on("--require PATH", "Logical Ruby require path") { |value| options[:require_path] = value }
          opts.on("--source-label PATH", "Stable reviewed source label for generated comments") { |value| options[:source_label] = value }
          opts.on("-h", "--help", "Show this checked stdout-only contract") { options[:help] = opts.to_s }
        end
        parser.parse!(argv)
        unless argv.empty?
          raise Error, "Unexpected positional arguments: #{argv.join(" ")}"
        end
        return options if options.key?(:help)

        {
          root: "--root",
          input: "--input",
          constant_name: "--constant",
          package_name: "--package",
        }.each do |key, flag|
          raise Error, "Missing required option #{flag}" unless options.key?(key)
        end
        options
      rescue OptionParser::ParseError => error
        raise Error, error.message
      end

      private_class_method :parse
    end
  end
end
