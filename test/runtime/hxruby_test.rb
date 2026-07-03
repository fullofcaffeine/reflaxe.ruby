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
  def self.__hx_constructs
    [{ name: "Happy", index: 0, method: :happy, arity: 0 }]
  end

  Happy = Data.define(:__hx_tag, :__hx_index)
end

class TestClassForTypeCheck; end

module TestInterfaceForTypeCheck; end

class TestInterfaceImplementor
  include TestInterfaceForTypeCheck
end

class TestClassWithToString
  def to_string
    "TestClassWithToString.toString()"
  end
end

class TestReflectBox
  attr_accessor :label

  def initialize(label)
    @label = label
  end

  def get_label
    "get:#{label}"
  end

  def set_label(value)
    self.label = "set:#{value}"
  end

  def describe(prefix)
    "#{prefix}:#{label}"
  end

  def ping
    "pong:#{label}"
  end
end

class TestReflectStatics
  def self.answer
    42
  end
end

class HXRubyRuntimeTest < Minitest::Test
  def test_stringify_matches_haxe_basics
    assert_equal "null", HXRuby.stringify(nil)
    assert_equal "true", HXRuby.stringify(true)
    assert_equal "false", HXRuby.stringify(false)
    assert_equal "[1,2]", HXRuby.stringify([1, 2])
    assert_equal "TestClassWithToString.toString()", HXRuby.stringify(TestClassWithToString.new)
    assert_equal "Happy", HXRuby.stringify(TestEnumForTypeCheck::Happy.new("Happy", 0))
  end

  def test_number_and_string_helpers
    assert_equal 42, HXRuby.parse_int("42")
    assert_equal 100, HXRuby.parse_int("100x123")
    assert_equal 23, HXRuby.parse_int("23e2")
    assert_equal 16, HXRuby.parse_int("0x10z")
    assert_equal(-160, HXRuby.parse_int("-0xa0"))
    assert_equal 0, HXRuby.parse_int("0b10")
    assert_nil HXRuby.parse_int("nope")
    assert_in_delta 3.5, HXRuby.parse_float("3.5"), 0.0001
    assert_in_delta 100.0, HXRuby.parse_float("100x123"), 0.0001
    assert_in_delta 5.3, HXRuby.parse_float("5.3 1"), 0.0001
    assert_in_delta 6.0, HXRuby.parse_float("6e"), 0.0001
    assert HXRuby.parse_float("nope").nan?
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
    assert HXRuby.string_tools_is_space(" a", 0)
    refute HXRuby.string_tools_is_space(" a", 1)
    assert_equal "--hi", HXRuby.string_tools_lpad("hi", "-", 4)
    assert_equal "hi--", HXRuby.string_tools_rpad("hi", "-", 4)
    assert_equal "hi", HXRuby.string_tools_lpad("hi", "", 4)
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

  def test_iterator_prefers_haxe_iterator_and_wraps_native_arrays
    native = HXRuby.iterator([7])
    assert native.has_next
    assert_equal 7, native.next_
    refute native.has_next

    haxe_like = Struct.new(:iterator).new(:kept)
    assert_equal :kept, HXRuby.iterator(haxe_like)
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
    assert HXRuby.is_of_type(TestInterfaceImplementor.new, TestInterfaceForTypeCheck)
    assert HXRuby.is_of_type(TestEnumForTypeCheck::Happy.new("Happy", 0), TestEnumForTypeCheck)
    refute HXRuby.is_of_type(nil, Dynamic)
  end

  def test_reflect_hash_fields_and_copy
    object = { "name" => "ruby", count: nil }

    assert HXRuby.reflect_has_field(object, "name")
    assert HXRuby.reflect_has_field(object, "count")
    assert_equal "ruby", HXRuby.reflect_field(object, "name")
    assert_nil HXRuby.reflect_field(object, "count")

    HXRuby.reflect_set_field(object, "name", "haxe")
    assert_equal "haxe", HXRuby.reflect_field(object, "name")
    assert_equal %w[count name], HXRuby.reflect_fields(object)

    copy = HXRuby.reflect_copy(object)
    HXRuby.reflect_set_field(copy, "name", "ruby")
    assert_equal "haxe", HXRuby.reflect_field(object, "name")
    assert_equal "ruby", HXRuby.reflect_field(copy, "name")

    assert HXRuby.reflect_delete_field(object, "count")
    refute HXRuby.reflect_has_field(object, "count")
    refute HXRuby.reflect_delete_field(object, "missing")
  end

  def test_reflect_object_fields_properties_and_methods
    box = TestReflectBox.new("typed")

    assert HXRuby.reflect_has_field(box, "label")
    assert_equal "typed", HXRuby.reflect_field(box, "label")
    HXRuby.reflect_set_field(box, "label", "updated")
    assert_equal "get:updated", HXRuby.reflect_get_property(box, "label")
    HXRuby.reflect_set_property(box, "label", "property")
    assert_equal "set:property", box.label
    assert_equal "box:set:property", HXRuby.reflect_call_method(box, HXRuby.reflect_field(box, "describe"), ["box"])
    assert_equal "pong:set:property", HXRuby.reflect_call_method(box, HXRuby.reflect_field(box, "ping"), [])
    assert_includes HXRuby.reflect_fields(box), "describe"
  end

  def test_reflect_predicates_and_type_field_lists
    box = TestReflectBox.new("typed")
    method = HXRuby.reflect_field(box, "describe")
    var_args = HXRuby.reflect_make_var_args(->(values) { values.sum })

    assert_equal 6, var_args.call(1, 2, 3)
    assert HXRuby.reflect_is_function(var_args)
    assert_operator HXRuby.reflect_compare(1, 2), :<, 0
    assert HXRuby.reflect_compare_methods(method, HXRuby.reflect_field(box, "describe"))
    assert HXRuby.reflect_is_object(box)
    refute HXRuby.reflect_is_object("no")
    assert HXRuby.reflect_is_enum_value(TestEnumForTypeCheck::Happy.new("Happy", 0))
    assert_includes HXRuby.type_instance_fields(TestReflectBox), "describe"
    assert_includes HXRuby.type_class_fields(TestReflectStatics), "answer"
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
