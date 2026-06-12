# frozen_string_literal: true

require_relative "../base"
require "hxruby/generators/routes"

if defined?(Rails::Generators::Base)
  module Hxruby
    class RoutesGenerator < Rails::Generators::Base
      include GeneratorSupport

      desc "Generate typed Haxe Rails route helper externs"
      class_option :output, type: :string, default: "src_haxe/routes/Routes.hx", desc: "Output Haxe extern path"
      class_option :package, type: :string, default: "routes", desc: "Haxe package for route externs"
      class_option :class_name, type: :string, default: "Routes", desc: "Haxe route extern class name"
      class_option :input, type: :string, desc: "Read routes from a file instead of running rails routes"

      def generate_routes
        input_path = hxruby_option(:input)
        input = input_path ? File.read(File.expand_path(input_path, hxruby_destination_root)) : read_rails_routes
        HXRuby::Generators::Routes.run([
          "--output", File.expand_path(hxruby_option(:output, "src_haxe/routes/Routes.hx"), hxruby_destination_root),
          "--package", hxruby_option(:package, "routes"),
          "--class", hxruby_option(:class_name, "Routes"),
        ], input: input)
      end

      private

      def read_rails_routes
        IO.popen("#{hxruby_rails_command} routes", chdir: hxruby_destination_root, &:read)
      end
    end
  end
end
