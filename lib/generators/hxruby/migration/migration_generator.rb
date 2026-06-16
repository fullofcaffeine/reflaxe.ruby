# frozen_string_literal: true

require_relative "../base"
require "hxruby/generators/migration"

if defined?(Rails::Generators::Base)
  module Hxruby
    class MigrationGenerator < Rails::Generators::NamedBase
      include GeneratorSupport

      desc "Generate a RailsHx Haxe migration snapshot"
      argument :attributes, type: :array, default: [], banner: "field:type field:type"
      class_option :output, type: :string, default: ".", desc: "Output root"
      class_option :haxe_dir, type: :string, default: "src_haxe/migrations", desc: "Haxe migration source directory"
      class_option :package, type: :string, default: "migrations", desc: "Haxe package for migration classes"
      class_option :timestamp, type: :string, desc: "Rails migration timestamp"
      class_option :migration_version, type: :string, default: "7.1", desc: "ActiveRecord migration version"
      class_option :known_models, type: :string, default: "", desc: "Comma-separated Haxe model type paths for compile-time validation"
      class_option :external_table, type: :array, default: [], desc: "Rails-owned table names allowed for this migration"
      class_option :from_schema, type: :string, desc: "Schema file used to justify existing table access"
      class_option :pretend, type: :boolean, default: false, desc: "Print generated Haxe source instead of writing it"
      class_option :force, type: :boolean, default: false, desc: "Overwrite non-owned Haxe source and take RailsHx ownership"

      def generate_migration
        args = [
          class_name,
          *attributes,
          "--output", File.expand_path(hxruby_option(:output, "."), hxruby_destination_root),
          "--haxe-dir", hxruby_option(:haxe_dir, "src_haxe/migrations"),
          "--package", hxruby_option(:package, "migrations"),
          "--migration-version", hxruby_option(:migration_version, "7.1"),
        ]
        args += ["--timestamp", hxruby_option(:timestamp)] unless hxruby_option(:timestamp).to_s.empty?
        args += ["--known-models", hxruby_option(:known_models, "")] unless hxruby_option(:known_models, "").to_s.empty?
        Array(hxruby_option(:external_table, [])).each do |table|
          args += ["--external-table", table]
        end
        args += ["--from-schema", hxruby_option(:from_schema)] unless hxruby_option(:from_schema).to_s.empty?
        args << "--pretend" if hxruby_flag?(:pretend)
        args << "--force" if hxruby_flag?(:force)
        HXRuby::Generators::Migration.run(args)
      end
    end
  end
end
