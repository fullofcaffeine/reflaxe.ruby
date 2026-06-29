require "rails"
require "active_record/railtie"
require "action_dispatch/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "propshaft"
require "importmap-rails"
require "turbo-rails"
require "devise"
require "devise/orm/active_record"

module HXRubyTodoapp
  class Application < Rails::Application
    config.load_defaults 7.0
    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
    config.paths.add "app/haxe_gen", eager_load: true
    config.assets.paths << Rails.root.join("app/javascript")
    config.action_controller.allow_forgery_protection = false
  end
end
