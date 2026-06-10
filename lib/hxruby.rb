# frozen_string_literal: true

require_relative "hxruby/version"
require_relative "hxruby/core"
require_relative "hxruby/data_define"
require_relative "hxruby/hx_exception"
require_relative "hxruby/railtie" if defined?(Rails::Railtie)
