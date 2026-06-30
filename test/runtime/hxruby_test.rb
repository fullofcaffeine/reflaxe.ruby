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
    assert_equal "ab", HXRuby.string_substr("abcd", 0, 2)
    assert_equal "abc", HXRuby.string_substr("abcd", 0, -1)
    assert_equal "", HXRuby.string_substr("abcd", 0, -9)
    assert_equal "B", HXRuby.string_char_at("ABC", 1)
    assert_equal "", HXRuby.string_char_at("ABC", -1)
    assert_equal "", HXRuby.string_char_at("ABC", 99)
    assert_equal 66, HXRuby.string_char_code_at("ABC", 1)
    assert_equal 0xD83D, HXRuby.string_char_code_at("😀", 0)
    assert_equal 0xDE00, HXRuby.string_char_code_at("😀", 1)
    assert_nil HXRuby.string_char_code_at("ABC", 99)
    assert_equal 3, HXRuby.string_index_of("abcabc", "a", 1)
    assert_equal 3, HXRuby.string_index_of("abc", "", 3)
    assert_equal -1, HXRuby.string_index_of("abc", "z")
    assert_equal 3, HXRuby.string_last_index_of("abcabc", "a")
    assert_equal 0, HXRuby.string_last_index_of("abcabc", "a", 2)
    assert_equal -1, HXRuby.string_last_index_of("abc", "z")
    assert_equal ["a", "b", ""], HXRuby.string_split("a,b,", ",")
    assert_equal ["a", "b"], HXRuby.string_split("ab", "")
    assert_equal "bc", HXRuby.string_substring("abcd", 1, 3)
    assert_equal "bc", HXRuby.string_substring("abcd", 3, 1)
    assert_equal "ab", HXRuby.string_substring("abcd", -2, 2)
    assert_equal(-1, HXRuby.string_compare("a", "b"))
    assert_equal 1, HXRuby.string_compare("𠜎zя", "abя")
    assert_equal 1, HXRuby.string_compare("\uFF61", "\u{10002}")
  end

  def test_string_tools_helpers
    assert_equal "&lt;a href=&quot;x&quot;&gt;&#039;y&#039;&amp;&lt;/a&gt;", HXRuby.html_escape("<a href=\"x\">'y'&</a>", true)
    assert_equal "<a href=\"x\">'y'&</a>", HXRuby.html_unescape("&lt;a href=&quot;x&quot;&gt;&#039;y&#039;&amp;&lt;/a&gt;")
    assert HXRuby.string_tools_is_space(" a", 0)
    refute HXRuby.string_tools_is_space(" a", 1)
    assert_equal "--hi", HXRuby.string_tools_lpad("hi", "-", 4)
    assert_equal "hi--", HXRuby.string_tools_rpad("hi", "-", 4)
    assert_equal "hi", HXRuby.string_tools_lpad("hi", "", 4)
    assert_equal "axbxc", HXRuby.string_tools_replace("abc", "", "x")
    assert_equal "axa", HXRuby.string_tools_replace("abba", "bb", "x")
    assert_equal "\\1", HXRuby.string_tools_replace("a", "a", "\\1")
    assert_equal 0xD83D, HXRuby.string_tools_fast_code_at("😀", 0)
    assert_equal 0, HXRuby.string_tools_fast_code_at("A", 99)
    assert HXRuby.string_tools_is_eof(nil)
    assert HXRuby.string_tools_is_eof(0)
    refute HXRuby.string_tools_is_eof(65)
  end

  def test_native_iterator_and_key_value_entries
    iterator = HXRuby.native_iterator([10, 20])

    assert iterator.has_next
    assert_equal 10, iterator.next_
    assert iterator.has_next
    assert_equal 20, iterator.next_
    refute iterator.has_next

    entries = HXRuby.string_utf16_key_value_units("zя𠜎")
    assert_equal [0, 1, 2, 3], entries.map(&:key)
    assert_equal [122, 1103, 55_361, 57_102], entries.map(&:value)
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
    assert_equal 0.0, HXRuby.math_unary(:sin, Math::PI)
    assert_equal 0.0, HXRuby.math_unary(:cos, Math::PI / 2)
    assert_equal(-1.0, HXRuby.math_unary(:sin, Math::PI * 3 / 2))
    assert HXRuby.math_nan?(HXRuby.math_unary(:sqrt, -1))
    assert HXRuby.math_nan?(Float::NAN)
    refute HXRuby.math_nan?(1)
    assert_in_delta 0.5, HXRuby.math_divide(1, 2), 0.0001
    assert_equal Float::INFINITY, HXRuby.math_divide(1, 0)
    assert_equal(-Float::INFINITY, HXRuby.math_divide(-1, 0))
    assert HXRuby.math_nan?(HXRuby.math_divide(0, 0))
    assert_equal Float::INFINITY, HXRuby.math_fround(Float::INFINITY)
    assert_equal(-Float::INFINITY, HXRuby.math_ffloor(-Float::INFINITY))
    assert HXRuby.math_nan?(HXRuby.math_fceil(Float::NAN))
    assert_equal 2.0, HXRuby.math_fround(1.5)
  end
end
