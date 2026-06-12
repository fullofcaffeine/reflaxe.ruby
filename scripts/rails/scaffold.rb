#!/usr/bin/env ruby
# frozen_string_literal: true

require "hxruby/generators/scaffold"

begin
  HXRuby::Generators::Scaffold.run(ARGV)
rescue HXRuby::Generators::Error => error
  warn error.message
  exit 1
end
