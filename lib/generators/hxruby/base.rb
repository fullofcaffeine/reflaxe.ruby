# frozen_string_literal: true

begin
  require "rails/generators"
rescue LoadError
  # Test environments can provide a small Rails::Generators stub.
end

module Hxruby
  module GeneratorSupport
    def hxruby_destination_root
      if respond_to?(:destination_root) && destination_root
        destination_root
      else
        Dir.pwd
      end
    end

    def hxruby_option(name, default = nil)
      if options.respond_to?(:[])
        options[name.to_s] || options[name.to_sym] || default
      else
        default
      end
    end

    def hxruby_flag?(name)
      value = hxruby_option(name, false)
      value == true || value.to_s == "true" || value.to_s == "1"
    end

    def hxruby_app_name(default = "RailsHxApp")
      explicit = respond_to?(:app_name) ? app_name : nil
      return explicit unless explicit.to_s.empty?

      if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
        app_class = Rails.application.class
        return app_class.module_parent_name if app_class.respond_to?(:module_parent_name)
      end

      default
    end

    def hxruby_rails_command
      bin_rails = File.join(hxruby_destination_root, "bin", "rails")
      File.exist?(bin_rails) ? bin_rails : "rails"
    end
  end
end
