# frozen_string_literal: true

require "cgi"
require "uri"

module HXRuby
  module_function

  def stringify(value)
    case value
    when nil
      "null"
    when true
      "true"
    when false
      "false"
    when Array, Hash
      stable_inspect(value)
    else
      value.to_s
    end
  end

  def stable_inspect(value)
    case value
    when Array
      "[" + value.map { |entry| stable_inspect(entry) }.join(", ") + "]"
    when Hash
      "{" + value.map { |key, entry| "#{stable_inspect(key)}=>#{stable_inspect(entry)}" }.join(", ") + "}"
    else
      value.inspect
    end
  end

  def parse_int(value)
    Integer(value.to_s, 10)
  rescue ArgumentError, TypeError
    nil
  end

  def parse_float(value)
    Float(value.to_s)
  rescue ArgumentError, TypeError
    Float::NAN
  end

  def hex(value, digits = nil)
    out = (value.to_i & 0xffffffff).to_s(16).upcase
    digits.nil? ? out : out.rjust(digits.to_i, "0")
  end

  def url_encode(value)
    URI.encode_www_form_component(value.to_s)
  end

  def url_decode(value)
    CGI.unescape(value.to_s)
  end

  def is_of_type(value, type)
    return !value.nil? if haxe_type?(type, :Dynamic)
    return value.is_a?(Integer) if haxe_type?(type, :Int)
    return value.is_a?(Numeric) if haxe_type?(type, :Float_)
    return value == true || value == false if haxe_type?(type, :Bool)
    return value.is_a?(String) if type.equal?(String)
    return value.is_a?(Array) if type.equal?(Array)
    return value.is_a?(type) if type.is_a?(Class)
    return enum_value_of?(value, type) if type.is_a?(Module)

    false
  end

  def type_name(value)
    value.class.name || value.class.to_s
  end

  def enum_tag(value)
    value.respond_to?(:__hx_tag) ? value.__hx_tag : nil
  end

  def enum_index(value)
    value.respond_to?(:__hx_index) ? value.__hx_index : nil
  end

  def haxe_type?(type, name)
    Object.const_defined?(name, false) && type.equal?(Object.const_get(name, false))
  end

  def enum_value_of?(value, type)
    return false if value.nil? || type.name.nil? || !value.respond_to?(:__hx_tag)

    class_name = value.class.name
    !class_name.nil? && class_name.start_with?("#{type.name}::")
  end
end
