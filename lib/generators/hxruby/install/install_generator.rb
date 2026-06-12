# frozen_string_literal: true

require_relative "../base"
require "hxruby/generators/app"

if defined?(Rails::Generators::Base)
  module Hxruby
    class InstallGenerator < Rails::Generators::Base
      include GeneratorSupport

      desc "Install RailsHx compile/watch files into a Rails app"
      argument :app_name, type: :string, required: false
      class_option :source, type: :string, default: "src_haxe", desc: "Haxe source directory"
      class_option :main, type: :string, default: "Main", desc: "Haxe server main class"
      class_option :force, type: :boolean, default: false, desc: "Overwrite existing generated files"

      def install_railshx
        args = [
          "--output", hxruby_destination_root,
          "--name", hxruby_app_name,
          "--source", hxruby_option(:source, "src_haxe"),
          "--main", hxruby_option(:main, "Main"),
        ]
        args << "--force" if hxruby_flag?(:force)
        HXRuby::Generators::App.run(args)
      end
    end
  end
end
