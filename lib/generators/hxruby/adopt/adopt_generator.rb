# frozen_string_literal: true

require_relative "../base"
require "hxruby/generators/adopt"

if defined?(Rails::Generators::Base)
  module Hxruby
    class AdoptGenerator < Rails::Generators::Base
      include GeneratorSupport

      desc "Adopt existing Rails Ruby/ERB boundaries through typed Haxe wrappers"
      class_option :service, type: :string, desc: "Ruby constant(s) to wrap, comma-separated"
      class_option :template, type: :string, desc: "Rails template path(s) to wrap, comma-separated"
      class_option :locals, type: :string, default: "", desc: "Template locals as name:Type,name:Type"
      class_option :package, type: :string, default: "interop", desc: "Haxe package for generated wrappers"
      class_option :output, type: :string, default: ".", desc: "Output root"
      class_option :force, type: :boolean, default: false, desc: "Overwrite existing wrapper files"
      class_option :discover, type: :boolean, default: false, desc: "Print candidate Ruby/ERB boundaries without writing guessed wrappers"

      def adopt_boundaries
        args = [
          "--output", File.expand_path(hxruby_option(:output, "."), hxruby_destination_root),
          "--package", hxruby_option(:package, "interop"),
        ]
        args += ["--service", hxruby_option(:service)] if hxruby_option(:service)
        args += ["--template", hxruby_option(:template)] if hxruby_option(:template)
        args += ["--locals", hxruby_option(:locals, "")] unless hxruby_option(:locals, "").to_s.empty?
        args << "--force" if hxruby_flag?(:force)
        args << "--discover" if hxruby_flag?(:discover)
        HXRuby::Generators::Adopt.run(args)
      end
    end
  end
end
