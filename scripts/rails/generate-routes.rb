#!/usr/bin/env ruby
# frozen_string_literal: true

require "hxruby/generators/routes"

begin
  HXRuby::Generators::Routes.run(ARGV)
rescue HXRuby::Generators::Error => error
  warn error.message
  exit 1
end
