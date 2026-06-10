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
    else
      value.to_s
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

  def type_name(value)
    value.class.name || value.class.to_s
  end

  def enum_tag(value)
    value.respond_to?(:__hx_tag) ? value.__hx_tag : nil
  end

  def enum_index(value)
    value.respond_to?(:__hx_index) ? value.__hx_index : nil
  end
end
