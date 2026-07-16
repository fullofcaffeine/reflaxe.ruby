# frozen_string_literal: true

module HXRuby
  # Owns the conservative, non-executing RBS contract pipeline shared by
  # RubyHx tooling. Unsupported signatures remain explicit omissions instead
  # of widening generated Haxe externs with an unchecked fallback type.
  module Rbs
    class Error < StandardError; end
  end
end

require_relative "rbs/source_parser"
require_relative "rbs/haxe_extern_renderer"
require_relative "rbs/extern_generator"
require_relative "rbs/cli"
