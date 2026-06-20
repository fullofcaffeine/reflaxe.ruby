#!/usr/bin/env ruby
# frozen_string_literal: true

require "hxruby/generators/test"

begin
  HXRuby::Generators::Test.run(ARGV)
rescue HXRuby::Generators::Error => error
  warn error.message
  exit 1
end
