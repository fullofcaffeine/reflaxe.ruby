# frozen_string_literal: true

# Runtime ABI for the Haxe map values returned by typed ActiveRecord grouping.
# Rails output intentionally suppresses compiler-owned std classes, so this file
# provides the complete public StringMap/IntMap behavior without asking Zeitwerk
# to load a generated Haxe std dependency graph. The compiler copies it only
# when grouped-count lowering constructs one of these map constants.
module HXRuby
  module NativeMap
    module ClassMethods
      def __hx_fields
        {
          instance: %w[clear copy data exists get iterator keyValueIterator keys remove set toString],
          static: []
        }
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    attr_accessor :data

    def initialize
      self.data = {}
    end

    def set(key, value)
      data[key] = value
    end

    def get(key)
      data[key]
    end

    def exists(key)
      data.key?(key)
    end

    def remove(key)
      return false unless data.key?(key)

      data.delete(key)
      true
    end

    def keys
      NativeIterator.new(data.keys)
    end

    def iterator
      NativeIterator.new(data.values)
    end

    def key_value_iterator
      NativeIterator.new(data.map { |key, value| KeyValueEntry.new(key, value) })
    end

    def copy
      duplicate = self.class.new
      duplicate.data.replace(data)
      duplicate
    end

    def to_string
      data.to_s
    end

    def clear
      data.clear
    end
  end
end

module Haxe
  const_set(:IMap, Module.new) unless const_defined?(:IMap, false)

  module Ds
    class StringMap
      include Haxe::IMap
      include HXRuby::NativeMap

      def self.__hx_name
        "haxe.ds.StringMap"
      end
    end

    class IntMap
      include Haxe::IMap
      include HXRuby::NativeMap

      def self.__hx_name
        "haxe.ds.IntMap"
      end
    end
  end
end
