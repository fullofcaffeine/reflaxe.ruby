# frozen_string_literal: true

require_relative "../base"
require "hxruby/generators/mailer"

if defined?(Rails::Generators::Base)
  module Hxruby
    class MailerGenerator < Rails::Generators::NamedBase
      include GeneratorSupport

      desc "Generate a typed RailsHx ActionMailer, HHX templates, preview, and Haxe-authored Rails test"
      argument :mail_action, type: :string, default: "welcome", banner: "welcome"
      class_option :output, type: :string, default: ".", desc: "Output root"
      class_option :haxe_dir, type: :string, default: "src_haxe/mailers", desc: "Haxe mailer source directory"
      class_option :package, type: :string, default: "mailers", desc: "Haxe package for mailer classes"
      class_option :views_dir, type: :string, default: "src_haxe/views", desc: "Haxe view source directory"
      class_option :views_package, type: :string, default: "views", desc: "Haxe package for view classes"
      class_option :previews_dir, type: :string, default: "src_haxe/previews", desc: "Haxe preview source directory"
      class_option :previews_package, type: :string, default: "previews", desc: "Haxe package for preview classes"
      class_option :tests_dir, type: :string, default: "test_haxe/mailers", desc: "Haxe-authored Rails test source directory"
      class_option :tests_package, type: :string, default: "test_haxe.mailers", desc: "Haxe package for generated test classes"
      class_option :skip_preview, type: :boolean, default: false, desc: "Skip the Haxe-authored ActionMailer preview"
      class_option :skip_test, type: :boolean, default: false, desc: "Skip the Haxe-authored Rails/Minitest source"
      class_option :force, type: :boolean, default: false, desc: "Overwrite non-owned files and take RailsHx ownership"

      def generate_mailer
        args = [
          class_name,
          mail_action,
          "--output", File.expand_path(hxruby_option(:output, "."), hxruby_destination_root),
          "--haxe-dir", hxruby_option(:haxe_dir, "src_haxe/mailers"),
          "--package", hxruby_option(:package, "mailers"),
          "--views-dir", hxruby_option(:views_dir, "src_haxe/views"),
          "--views-package", hxruby_option(:views_package, "views"),
          "--previews-dir", hxruby_option(:previews_dir, "src_haxe/previews"),
          "--previews-package", hxruby_option(:previews_package, "previews"),
          "--tests-dir", hxruby_option(:tests_dir, "test_haxe/mailers"),
          "--tests-package", hxruby_option(:tests_package, "test_haxe.mailers"),
        ]
        args << "--skip-preview" if hxruby_flag?(:skip_preview)
        args << "--skip-test" if hxruby_flag?(:skip_test)
        args << "--force" if hxruby_flag?(:force)
        HXRuby::Generators::Mailer.run(args)
      end
    end
  end
end
