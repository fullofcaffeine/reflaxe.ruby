# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../runtime/hxruby/core"
require_relative "../../runtime/hxruby/data_define"
require_relative "../../runtime/hxruby/hx_exception"

module Int; end unless defined?(Int)
module Float_; end unless defined?(Float_)
module Bool; end unless defined?(Bool)
module Dynamic; end unless defined?(Dynamic)
module TestEnumForTypeCheck
  Happy = Data.define(:__hx_tag, :__hx_index)
end

class TestClassForTypeCheck; end

class HXRubyRuntimeTest < Minitest::Test
  def test_stringify_matches_haxe_basics
    assert_equal "null", HXRuby.stringify(nil)
    assert_equal "true", HXRuby.stringify(true)
    assert_equal "false", HXRuby.stringify(false)
    assert_equal "[1, 2]", HXRuby.stringify([1, 2])
  end

  def test_number_and_string_helpers
    assert_equal 42, HXRuby.parse_int("42")
    assert_nil HXRuby.parse_int("nope")
    assert_in_delta 3.5, HXRuby.parse_float("3.5"), 0.0001
    assert HXRuby.parse_float("nope").nan?
    assert_equal "00FF", HXRuby.hex(255, 4)
    assert_equal "typed+ruby", HXRuby.url_encode("typed ruby")
    assert_equal "typed ruby", HXRuby.url_decode("typed+ruby")
    assert_equal 66, HXRuby.string_char_code_at("ABC", 1)
    assert_equal 0xD83D, HXRuby.string_char_code_at("😀", 0)
    assert_equal 0xDE00, HXRuby.string_char_code_at("😀", 1)
    assert_nil HXRuby.string_char_code_at("ABC", 99)
  end

  def test_data_define_compatibility_and_enum_metadata
    option = Data.define(:value, :__hx_tag, :__hx_index)
    some = option.new(41, "Some", 1)

    assert_equal [41, "Some", 1], some.deconstruct
    assert_equal({ value: 41, __hx_tag: "Some" }, some.deconstruct_keys([:value, :__hx_tag]))
    assert_equal "Some", HXRuby.enum_tag(some)
    assert_equal 1, HXRuby.enum_index(some)
  end

  def test_hx_exception_carries_any_haxe_value
    error = assert_raises(HxException) { raise HxException.new({ "message" => "boom" }) }

    assert_equal({ "message" => "boom" }, error.value)
    assert_equal "{\"message\"=>\"boom\"}", error.message
  end

  def test_is_of_type_matches_core_haxe_shapes
    assert HXRuby.is_of_type(1, Int)
    assert HXRuby.is_of_type(1, Float_)
    refute HXRuby.is_of_type(1.5, Int)
    assert HXRuby.is_of_type("ruby", String)
    assert HXRuby.is_of_type(true, Bool)
    assert HXRuby.is_of_type([1, 2], Array)
    assert HXRuby.is_of_type(TestClassForTypeCheck.new, TestClassForTypeCheck)
    assert HXRuby.is_of_type(TestEnumForTypeCheck::Happy.new("Happy", 0), TestEnumForTypeCheck)
    refute HXRuby.is_of_type(nil, Dynamic)
  end

  def test_math_helpers_preserve_haxe_shapes
    assert_equal 0, HXRuby.math_round(-0.5)
    assert_equal 1, HXRuby.math_round(0.5)
    assert_equal 3.0, HXRuby.math_unary(:sqrt, 9)
    assert HXRuby.math_nan?(HXRuby.math_unary(:sqrt, -1))
    assert HXRuby.math_nan?(Float::NAN)
    refute HXRuby.math_nan?(1)
  end
end
