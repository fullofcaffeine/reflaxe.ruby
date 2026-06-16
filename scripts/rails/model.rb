#!/usr/bin/env ruby
# frozen_string_literal: true

require "hxruby/generators/model"

begin
  HXRuby::Generators::Model.run(ARGV)
rescue HXRuby::Generators::Error => error
  warn error.message
  exit 1
end
