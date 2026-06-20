# frozen_string_literal: true

require_relative "../base"
require "hxruby/generators/test"

if defined?(Rails::Generators::Base)
  module Hxruby
    class TestGenerator < Rails::Generators::NamedBase
      include GeneratorSupport

      desc "Generate a Haxe-authored Rails/Minitest source using @:railsTests"
      class_option :type, type: :string, default: nil, desc: "Test type: model or request"
      class_option :output, type: :string, default: ".", desc: "Output root"
      class_option :haxe_dir, type: :string, default: "test_haxe", desc: "Haxe test source directory"
      class_option :package, type: :string, default: "test_haxe", desc: "Haxe package for test classes"
      class_option :description, type: :string, default: nil, desc: "Initial Rails test description"
      class_option :force, type: :boolean, default: false, desc: "Overwrite non-owned files and take RailsHx ownership"

      def generate_test
        args = [
          file_path,
          "--output", File.expand_path(hxruby_option(:output, "."), hxruby_destination_root),
          "--haxe-dir", hxruby_option(:haxe_dir, "test_haxe"),
          "--package", hxruby_option(:package, "test_haxe"),
        ]
        args += ["--type", hxruby_option(:type)] if hxruby_option(:type)
        args += ["--description", hxruby_option(:description)] if hxruby_option(:description)
        args << "--force" if hxruby_flag?(:force)
        HXRuby::Generators::Test.run(args)
      end
    end
  end
end
