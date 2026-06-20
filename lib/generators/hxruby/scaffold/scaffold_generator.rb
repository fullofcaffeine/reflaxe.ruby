# frozen_string_literal: true

require_relative "../base"
require "hxruby/generators/scaffold"

if defined?(Rails::Generators::Base)
  module Hxruby
    class ScaffoldGenerator < Rails::Generators::NamedBase
      include GeneratorSupport

      desc "Generate a RailsHx Haxe model/controller/migration scaffold"
      argument :attributes, type: :array, default: [], banner: "field:Type field:Type"
      class_option :validate, type: :string, default: "", desc: "Comma-separated fields with presence validation"
      class_option :controller, type: :boolean, default: false, desc: "Generate a typed controller scaffold"
      class_option :routes, type: :string, default: "haxe", desc: "Route mode: haxe, snippet, rails, or none"
      class_option :skip_tests, type: :boolean, default: false, desc: "Skip generated Haxe-authored Rails test stubs"
      class_option :output, type: :string, default: ".", desc: "Output root"
      class_option :force, type: :boolean, default: false, desc: "Overwrite non-owned files and take RailsHx ownership"

      def generate_scaffold
        args = [
          "--model", class_name,
          "--fields", attributes.join(","),
          "--output", File.expand_path(hxruby_option(:output, "."), hxruby_destination_root),
        ]
        args += ["--validate", hxruby_option(:validate, "")] unless hxruby_option(:validate, "").to_s.empty?
        args += ["--routes", hxruby_option(:routes, "haxe")]
        args << "--controller" if hxruby_flag?(:controller)
        args << "--skip-tests" if hxruby_flag?(:skip_tests)
        args << "--force" if hxruby_flag?(:force)
        HXRuby::Generators::Scaffold.run(args)
      end
    end
  end
end
