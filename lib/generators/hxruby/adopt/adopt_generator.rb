# frozen_string_literal: true

require_relative "../base"
require "hxruby/generators/adopt"

if defined?(Rails::Generators::Base)
  module Hxruby
    class AdoptGenerator < Rails::Generators::Base
      include GeneratorSupport

      desc "Adopt existing Rails Ruby/ERB boundaries through typed Haxe wrappers"
      class_option :service, type: :string, desc: "Ruby constant(s) to wrap, comma-separated"
      class_option :service_source, type: :string, desc: "Ruby source file(s) to inspect for selected service signatures, comma-separated"
      class_option :rbs, type: :string, desc: "RBS file(s) to inspect for selected service signatures, comma-separated"
      class_option :template, type: :string, desc: "Rails template path(s) to wrap, comma-separated"
      class_option :extension_source, type: :string, desc: "Ruby source file(s) to inspect for module extension contracts, comma-separated"
      class_option :extension_module, type: :string, desc: "Ruby module name(s) to generate from extension source, comma-separated"
      class_option :gem, type: :string, desc: "Bundler-installed gem name(s) to inventory/adopt, comma-separated"
      class_option :schema, type: :boolean, default: false, desc: "Adopt typed ActiveRecord model contracts from db/schema.rb"
      class_option :models, type: :string, desc: "Schema model name(s) to generate, comma-separated"
      class_option :from, type: :string, default: "db/schema.rb", desc: "Schema file to adopt from"
      class_option :allow_dynamic, type: :boolean, default: false, desc: "Allow review-marked Dynamic fields for unsupported DB column types"
      class_option :write, type: :string, desc: "Write mode for gem adoption; currently supports contracts"
      class_option :devise_hhx_views, type: :boolean, default: false, desc: "With --gem devise --write contracts, generate Devise HHX view skeletons"
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
        args += ["--service-source", hxruby_option(:service_source)] if hxruby_option(:service_source)
        args += ["--rbs", hxruby_option(:rbs)] if hxruby_option(:rbs)
        args += ["--template", hxruby_option(:template)] if hxruby_option(:template)
        args += ["--extension-source", hxruby_option(:extension_source)] if hxruby_option(:extension_source)
        args += ["--extension-module", hxruby_option(:extension_module)] if hxruby_option(:extension_module)
        args += ["--gem", hxruby_option(:gem)] if hxruby_option(:gem)
        args << "--schema" if hxruby_flag?(:schema)
        args += ["--models", hxruby_option(:models)] if hxruby_option(:models)
        args += ["--from", hxruby_option(:from, "db/schema.rb")] if hxruby_option(:from, "db/schema.rb") != "db/schema.rb"
        args << "--allow-dynamic" if hxruby_flag?(:allow_dynamic)
        args += ["--write", hxruby_option(:write)] if hxruby_option(:write)
        args << "--devise-hhx-views" if hxruby_flag?(:devise_hhx_views)
        args += ["--locals", hxruby_option(:locals, "")] unless hxruby_option(:locals, "").to_s.empty?
        args << "--force" if hxruby_flag?(:force)
        args << "--discover" if hxruby_flag?(:discover)
        HXRuby::Generators::Adopt.run(args)
      end
    end
  end
end
