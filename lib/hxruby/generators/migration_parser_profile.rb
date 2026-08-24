# frozen_string_literal: true

module HXRuby
  module Generators
    # Defines the exact parser toolchain and admitted migration catalog.
    #
    # Prism makes security-sensitive source-admission decisions. Its exact
    # version is therefore a compiler pin, not an ordinary compatibility range.
    module MigrationParserProfile
      PRISM_VERSION = "1.9.0"
      RUBY_SYNTAX_VERSION = "3.3"
      PARSER_IDENTITY = "railshx-migration-prism-v1"
      CATALOG_IDENTITY = "railshx-migration-catalog-v1"
      COMPATIBILITY_PROFILE = "ActiveRecord::Migration[7.1]"
    end
  end
end
