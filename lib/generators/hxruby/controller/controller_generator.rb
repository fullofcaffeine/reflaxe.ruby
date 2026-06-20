# frozen_string_literal: true

require_relative "../base"
require "hxruby/generators/controller"

if defined?(Rails::Generators::Base)
  module Hxruby
    class ControllerGenerator < Rails::Generators::NamedBase
      include GeneratorSupport

      desc "Generate a typed RailsHx ActionController and optional HHX views"
      argument :actions, type: :array, default: [], banner: "index show create"
      class_option :output, type: :string, default: ".", desc: "Output root"
      class_option :haxe_dir, type: :string, default: "src_haxe/controllers", desc: "Haxe controller source directory"
      class_option :package, type: :string, default: "controllers", desc: "Haxe package for controller classes"
      class_option :templates, type: :boolean, default: false, desc: "Generate typed HHX view skeletons for actions"
      class_option :views_dir, type: :string, default: "src_haxe/views", desc: "Haxe view source directory"
      class_option :views_package, type: :string, default: "views", desc: "Haxe package for view classes"
      class_option :model, type: :string, desc: "Optional typed model class for index/create actions"
      class_option :fields, type: :string, default: "", desc: "Comma-separated model fields for generated strong params"
      class_option :routes, type: :string, default: "snippet", desc: "Route mode: haxe, snippet, rails, or none"
      class_option :force, type: :boolean, default: false, desc: "Overwrite non-owned files and take RailsHx ownership"

      def generate_controller
        args = [
          class_name,
          *actions,
          "--output", File.expand_path(hxruby_option(:output, "."), hxruby_destination_root),
          "--haxe-dir", hxruby_option(:haxe_dir, "src_haxe/controllers"),
          "--package", hxruby_option(:package, "controllers"),
          "--views-dir", hxruby_option(:views_dir, "src_haxe/views"),
          "--views-package", hxruby_option(:views_package, "views"),
          "--routes", hxruby_option(:routes, "snippet"),
        ]
        args += ["--model", hxruby_option(:model)] unless hxruby_option(:model).to_s.empty?
        args += ["--fields", hxruby_option(:fields, "")] unless hxruby_option(:fields, "").to_s.empty?
        args << "--templates" if hxruby_flag?(:templates)
        args << "--force" if hxruby_flag?(:force)
        HXRuby::Generators::Controller.run(args)
      end
    end
  end
end
