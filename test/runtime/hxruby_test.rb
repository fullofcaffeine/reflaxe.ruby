# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../runtime/hxruby/core"
require_relative "../../runtime/hxruby/data_define"
require_relative "../../runtime/hxruby/hx_exception"

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
end
