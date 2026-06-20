# frozen_string_literal: true

require_relative "../base"
require "hxruby/generators/template"

if defined?(Rails::Generators::Base)
  module Hxruby
    class TemplateGenerator < Rails::Generators::NamedBase
      include GeneratorSupport

      desc "Generate a typed RailsHx HHX template or partial source"
      class_option :output, type: :string, default: ".", desc: "Output root"
      class_option :haxe_dir, type: :string, default: "src_haxe/views", desc: "Haxe view source directory"
      class_option :package, type: :string, default: "views", desc: "Haxe package for view classes"
      class_option :locals, type: :string, default: "", desc: "Comma-separated typed locals, e.g. title:String,count:Int"
      class_option :force, type: :boolean, default: false, desc: "Overwrite non-owned files and take RailsHx ownership"

      def generate_template
        args = [
          file_path,
          "--output", File.expand_path(hxruby_option(:output, "."), hxruby_destination_root),
          "--haxe-dir", hxruby_option(:haxe_dir, "src_haxe/views"),
          "--package", hxruby_option(:package, "views"),
        ]
        args += ["--locals", hxruby_option(:locals, "")] unless hxruby_option(:locals, "").to_s.empty?
        args << "--force" if hxruby_flag?(:force)
        HXRuby::Generators::Template.run(args)
      end
    end
  end
end
