# frozen_string_literal: true

require_relative "tasks"

if defined?(Rails::Railtie)
  module HXRuby
    class Railtie < Rails::Railtie
      rake_tasks do
        HXRuby::Tasks.install
      end
    end
  end
end
