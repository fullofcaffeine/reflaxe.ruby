# frozen_string_literal: true

require_relative "../base"
require "hxruby/generators/model"

if defined?(Rails::Generators::Base)
  module Hxruby
    class ModelGenerator < Rails::Generators::NamedBase
      include GeneratorSupport

      desc "Generate a typed RailsHx ActiveRecord model and optional migration snapshot"
      argument :attributes, type: :array, default: [], banner: "field:type field:type"
      class_option :output, type: :string, default: ".", desc: "Output root"
      class_option :haxe_dir, type: :string, default: "src_haxe/models", desc: "Haxe model source directory"
      class_option :migration_dir, type: :string, default: "src_haxe/migrations", desc: "Haxe migration source directory"
      class_option :package, type: :string, default: "models", desc: "Haxe package for model classes"
      class_option :migration_package, type: :string, default: "migrations", desc: "Haxe package for migration classes"
      class_option :timestamp, type: :string, desc: "Rails migration timestamp"
      class_option :migration_version, type: :string, default: "7.1", desc: "ActiveRecord migration version"
      class_option :known_models, type: :string, default: "", desc: "Comma-separated Haxe model type paths for migration validation"
      class_option :validate, type: :array, default: [], desc: "Validation rules such as title,presence or email,uniqueness"
      class_option :skip_migration, type: :boolean, default: false, desc: "Generate only the typed Haxe model"
      class_option :pretend, type: :boolean, default: false, desc: "Print generated Haxe source instead of writing it"
      class_option :force, type: :boolean, default: false, desc: "Overwrite non-owned files and take RailsHx ownership"

      def generate_model
        args = [
          class_name,
          *attributes,
          "--output", File.expand_path(hxruby_option(:output, "."), hxruby_destination_root),
          "--haxe-dir", hxruby_option(:haxe_dir, "src_haxe/models"),
          "--migration-dir", hxruby_option(:migration_dir, "src_haxe/migrations"),
          "--package", hxruby_option(:package, "models"),
          "--migration-package", hxruby_option(:migration_package, "migrations"),
          "--migration-version", hxruby_option(:migration_version, "7.1"),
        ]
        args += ["--timestamp", hxruby_option(:timestamp)] unless hxruby_option(:timestamp).to_s.empty?
        args += ["--known-models", hxruby_option(:known_models, "")] unless hxruby_option(:known_models, "").to_s.empty?
        Array(hxruby_option(:validate, [])).each do |rule|
          args += ["--validate", rule]
        end
        args << "--skip-migration" if hxruby_flag?(:skip_migration)
        args << "--pretend" if hxruby_flag?(:pretend)
        args << "--force" if hxruby_flag?(:force)
        HXRuby::Generators::Model.run(args)
      end
    end
  end
end
