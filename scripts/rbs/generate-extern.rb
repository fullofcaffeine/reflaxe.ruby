#!/usr/bin/env ruby
# frozen_string_literal: true

require "hxruby/rbs"

begin
  HXRuby::Rbs::CLI.run(ARGV)
rescue HXRuby::Rbs::Error => error
  warn error.message
  exit 1
end
