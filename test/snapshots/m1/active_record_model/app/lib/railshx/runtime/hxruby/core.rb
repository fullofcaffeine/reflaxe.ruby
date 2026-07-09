# frozen_string_literal: true

module HXRuby
  class NativeIterator
    def initialize(values)
      @values = values
      @index = 0
    end

    def has_next
      @index < @values.length
    end

    def next_
      value = @values[@index]
      @index += 1
      value
    end
  end

  class KeyValueEntry
    attr_reader :key, :value

    def initialize(key, value)
      @key = key
      @value = value
    end
  end

  RUBY_MATH_UNARY = {
    sin: ::Math.method(:sin),
    cos: ::Math.method(:cos),
    tan: ::Math.method(:tan),
    asin: ::Math.method(:asin),
    acos: ::Math.method(:acos),
    atan: ::Math.method(:atan),
    log: ::Math.method(:log),
    sqrt: ::Math.method(:sqrt)
  }.freeze
  RUBY_MATH_BINARY = {
    atan2: ::Math.method(:atan2)
  }.freeze
  RUBY_RESERVED_METHOD_NAMES = %w[
    BEGIN END alias and begin break case class def defined? do else elsif end
    ensure false for if in module next nil not or redo rescue retry return self
    super then true undef unless until when while yield
  ].freeze

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
      return enum_string(value) if value.respond_to?(:__hx_tag)
      return value.to_string if value.respond_to?(:to_string)

      value.to_s
    end
  end

  def enum_string(value)
    tag = enum_tag(value)
    params = enum_parameters(value)
    return tag.to_s if params.empty?

    "#{tag}(#{params.map { |param| stringify(param) }.join(",")})"
  end

  def stable_inspect(value)
    case value
    when Array
      "[" + value.map { |entry| stringify(entry) }.join(",") + "]"
    when Hash
      "{" + value.map { |key, entry| "#{stable_inspect(key)}=>#{stable_inspect(entry)}" }.join(", ") + "}"
    else
      value.inspect
    end
  end

  def parse_int(value)
    return nil if value.nil?

    match = /\A[ \t\n\v\f\r]*([+-]?)(?:(?:0[xX]([0-9a-fA-F]+))|([0-9]+))/.match(value.to_s)
    return nil if match.nil?

    sign = match[1] == "-" ? -1 : 1
    digits = match[2] || match[3]
    base = match[2].nil? ? 10 : 16
    sign * digits.to_i(base)
  end

  def parse_float(value)
    return Float::NAN if value.nil?

    match = /\A[ \t\n\v\f\r]*[+-]?(?:(?:[0-9]+\.[0-9]*)|(?:\.[0-9]+)|(?:[0-9]+))(?:[eE][+-]?[0-9]+)?/.match(value.to_s)
    return Float::NAN if match.nil?

    match[0].to_f
  end

  def string_substr(value, position, count = nil)
    string = value.to_s
    total_units = string.each_char.sum { |char| char.ord > 0xffff ? 2 : 1 }
    start = position.to_i
    start = total_units + start if start.negative?
    start = 0 if start.negative?
    return "" if start >= total_units

    finish = nil
    unless count.nil?
      count_units = count.to_i
      finish = count_units.negative? ? total_units + count_units : start + count_units
    end
    return "" if !finish.nil? && finish <= start

    out = +""
    offset = 0
    string.each_char do |char|
      units = char.ord > 0xffff ? 2 : 1
      next_offset = offset + units
      out << char if next_offset > start && (finish.nil? || offset < finish)
      offset = next_offset
    end
    out
  end

  def string_char_at(value, position)
    index = position.to_i
    return "" if index.negative?

    value.to_s.each_char.with_index do |char, offset|
      return char if offset == index
    end
    ""
  end

  def string_char_code_at(value, position)
    target = position.to_i
    return nil if target.negative?

    offset = 0
    value.to_s.each_char do |char|
      code = char.ord
      if code > 0xffff
        high = 0xd800 + ((code - 0x10000) >> 10)
        low = 0xdc00 + ((code - 0x10000) & 0x3ff)
        return high if offset == target
        return low if offset + 1 == target

        offset += 2
      else
        return code if offset == target

        offset += 1
      end
    end
    nil
  end

  def string_index_of(value, search, start = 0)
    string = value.to_s
    needle = search.to_s
    index = start.to_i
    index = 0 if index.negative?
    return [index, string.length].min if needle.empty?

    found = string.index(needle, index)
    found.nil? ? -1 : found
  end

  def string_last_index_of(value, search, start = nil)
    string = value.to_s
    needle = search.to_s
    index = start.nil? ? string.length : [start.to_i, string.length].min
    index = 0 if index.negative?
    return index if needle.empty?

    found = string.rindex(needle, index)
    found.nil? ? -1 : found
  end

  def string_split(value, delimiter)
    string = value.to_s
    separator = delimiter.to_s
    return string.each_char.to_a if separator.empty?

    string.split(separator, -1)
  end

  def string_substring(value, start_pos, end_pos = nil)
    string = value.to_s
    length = string.length
    start_index = start_pos.to_i
    finish_index = end_pos.nil? ? length : end_pos.to_i
    start_index = 0 if start_index.negative?
    finish_index = 0 if finish_index.negative?

    if start_index > finish_index
      start_index, finish_index = finish_index, start_index
    end

    start_index = length if start_index > length
    finish_index = length if finish_index > length
    string[start_index...finish_index] || ""
  end

  def string_compare(value, other)
    left_units = string_utf16_units(value.to_s)
    right_units = string_utf16_units(other.to_s)
    limit = [left_units.length, right_units.length].min
    index = 0

    while index < limit
      left = left_units[index]
      right = right_units[index]
      return -1 if left < right
      return 1 if left > right

      index += 1
    end

    return -1 if left_units.length < right_units.length
    return 1 if left_units.length > right_units.length
    0
  end

  def string_utf16_units(value)
    units = []
    value.each_char do |char|
      code = char.ord
      if code > 0xffff
        units << (0xd800 + ((code - 0x10000) >> 10))
        units << (0xdc00 + ((code - 0x10000) & 0x3ff))
      else
        units << code
      end
    end
    units
  end

  def string_utf16_key_value_units(value)
    string_utf16_units(value).each_with_index.map { |code, index| KeyValueEntry.new(index, code) }
  end

  def native_iterator(values)
    NativeIterator.new(values)
  end

  def iterator(values)
    return values.iterator if values.respond_to?(:iterator)

    native_iterator(values)
  end

  def string_tools_is_space(value, position)
    code = string_char_code_at(value, position)
    (code && code > 8 && code < 14) || code == 32
  end

  def string_tools_lpad(value, pad, length)
    out = value.to_s
    fill = pad.to_s
    return out if fill.empty?

    out = fill + out while string_utf16_units(out).length < length.to_i
    out
  end

  def string_tools_rpad(value, pad, length)
    out = value.to_s
    fill = pad.to_s
    return out if fill.empty?

    out += fill while string_utf16_units(out).length < length.to_i
    out
  end

  def string_tools_fast_code_at(value, position)
    string_char_code_at(value, position) || 0
  end

  def string_tools_is_eof(value)
    value.nil? || value == 0
  end

  def array_join(array, separator)
    array.map { |entry| stringify(entry) }.join(separator.to_s)
  end

  def array_key_value_entries(array)
    array.each_with_index.map { |value, index| KeyValueEntry.new(index, value) }
  end

  def key_value_iterator(value)
    return NativeIterator.new(array_key_value_entries(value)) if value.is_a?(Array)
    return value.key_value_iterator if value.respond_to?(:key_value_iterator)

    raise NoMethodError, "undefined keyValueIterator for #{value.inspect}"
  end

  def array_contents_match?(expected, actual)
    return false unless expected.is_a?(Array) && actual.is_a?(Array)

    normalized_actual = actual.dup
    normalized_actual.pop while normalized_actual.length > expected.length && normalized_actual[-1].nil?
    expected == normalized_actual
  end

  def array_slice(array, position, end_position = nil)
    length = array.length
    start = normalize_array_boundary(position, length)
    finish = end_position.nil? ? length : normalize_array_boundary(end_position, length)
    return [] if start > length || finish <= start

    array[start...finish] || []
  end

  def array_sort(array, comparator)
    array.sort! { |left, right| comparator.call(left, right) }
    nil
  end

  def array_splice(array, position, remove_length)
    count = remove_length.to_i
    return [] if count.negative?

    length = array.length
    start = normalize_array_boundary(position, length)
    return [] if start > length || count.zero?

    count = [count, length - start].min
    removed = array[start, count] || []
    array.slice!(start, count)
    removed
  end

  def array_insert(array, position, value)
    length = array.length
    index = position.to_i
    index = length + index if index.negative?
    index = 0 if index.negative?
    index = length if index > length
    array.insert(index, value)
    nil
  end

  def array_remove(array, value)
    index = array.index(value)
    return false if index.nil?

    array.delete_at(index)
    true
  end

  def array_index_of(array, value, from_index = nil)
    length = array.length
    start = from_index.nil? ? 0 : from_index.to_i
    start = length + start if start.negative?
    start = 0 if start.negative?
    return -1 if start >= length

    index = start
    while index < length
      return index if array[index] == value

      index += 1
    end
    -1
  end

  def array_last_index_of(array, value, from_index = nil)
    length = array.length
    start = if from_index.nil?
      length - 1
    else
      raw = from_index.to_i
      raw.negative? ? length + raw : [raw, length - 1].min
    end
    return -1 if start.negative?

    index = start
    while index >= 0
      return index if array[index] == value

      index -= 1
    end
    -1
  end

  def array_map(array, mapper)
    array.map { |entry| mapper.call(entry) }
  end

  def array_filter(array, predicate)
    array.select { |entry| predicate.call(entry) }
  end

  def array_resize(array, size)
    target = size.to_i
    if target < array.length
      array.slice!(target, array.length - target)
    else
      array << nil while array.length < target
    end
    nil
  end

  def normalize_array_boundary(position, length)
    index = position.to_i
    index = length + index if index.negative?
    index.negative? ? 0 : index
  end

  def math_min(left, right)
    return Float::NAN if math_nan?(left) || math_nan?(right)

    left < right ? left : right
  end

  def math_max(left, right)
    return Float::NAN if math_nan?(left) || math_nan?(right)

    left > right ? left : right
  end

  def math_unary(method, value)
    result = RUBY_MATH_UNARY.fetch(method).call(value)
    %i[sin cos tan asin acos atan].include?(method) ? math_canonicalize(result) : result
  rescue Math::DomainError
    Float::NAN
  end

  def math_binary(method, left, right)
    result = RUBY_MATH_BINARY.fetch(method).call(left, right)
    method == :atan2 ? math_canonicalize(result) : result
  rescue Math::DomainError
    Float::NAN
  end

  def math_pow(value, exponent)
    result = value**exponent
    result.is_a?(Complex) ? Float::NAN : result
  rescue Math::DomainError
    Float::NAN
  end

  def math_divide(left, right)
    left.to_f / right.to_f
  end

  def math_round(value)
    (value + 0.5).floor
  end

  def math_fround(value)
    return value if math_nan?(value) || value.infinite?

    math_round(value).to_f
  end

  def math_ffloor(value)
    return value if math_nan?(value) || value.infinite?

    value.floor.to_f
  end

  def math_fceil(value)
    return value if math_nan?(value) || value.infinite?

    value.ceil.to_f
  end

  def math_nan?(value)
    value.respond_to?(:nan?) && value.nan?
  end

  def math_canonicalize(value)
    return value unless value.is_a?(Numeric)

    epsilon = 1.0e-12
    return 0.0 if value.abs < epsilon
    return 1.0 if (value - 1.0).abs < epsilon
    return -1.0 if (value + 1.0).abs < epsilon

    value
  end

  def is_of_type(value, type)
    return !value.nil? if haxe_type?(type, :Dynamic)
    return value.is_a?(Integer) if haxe_type?(type, :Int)
    return value.is_a?(Numeric) if haxe_type?(type, :Float_)
    return value == true || value == false if haxe_type?(type, :Bool)
    return value.is_a?(String) if type.equal?(String)
    return value.is_a?(Array) if type.equal?(Array)
    return value.is_a?(type) if type.is_a?(Class)
    return value.is_a?(type) if type.is_a?(Module) && !type.respond_to?(:__hx_constructs)
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

  def enum_parameters(value)
    return [] if value.nil? || !value.class.respond_to?(:members)

    value.class.members.reject { |name| name == :__hx_tag || name == :__hx_index }.map { |name| value.public_send(name) }
  end

  def enum_eq(left, right)
    left == right
  end

  def type_get_class(value)
    return nil if value.nil? || value.respond_to?(:__hx_tag)
    return String if value.is_a?(String)
    return Array if value.is_a?(Array)

    value.class
  end

  def type_get_enum(value)
    enum_module(value)
  end

  def type_get_super_class(type)
    return nil unless type.is_a?(Class)

    parent = type.superclass
    parent == Object || parent == BasicObject ? nil : parent
  end

  def type_class_name(type)
    type_name_for(type)
  end

  def type_enum_name(type)
    type_name_for(type)
  end

  def type_resolve_class(name)
    constant = resolve_haxe_constant(name)
    constant.is_a?(Class) ? constant : nil
  end

  def type_resolve_enum(name)
    constant = resolve_haxe_constant(name)
    constant.is_a?(Module) && !constant.is_a?(Class) ? constant : nil
  end

  def type_create_instance(type, args)
    return nil unless type.is_a?(Class)

    type.new(*(args || []))
  end

  def type_create_empty_instance(type)
    return nil unless type.is_a?(Class)

    type.allocate
  end

  def type_create_enum(type, constructor, params = nil)
    entry = enum_constructs(type).find { |item| item[:name] == constructor.to_s }
    create_enum_from_entry(type, entry, params)
  end

  def type_create_enum_index(type, index, params = nil)
    entry = enum_constructs(type).find { |item| item[:index] == index.to_i }
    create_enum_from_entry(type, entry, params)
  end

  def type_instance_fields(_type)
    return [] unless _type.is_a?(Class)

    _type.public_instance_methods(false).map(&:to_s).reject { |name| name.end_with?("=") }.sort
  end

  def type_class_fields(_type)
    return [] unless _type.respond_to?(:singleton_methods)

    _type.singleton_methods(false).map(&:to_s).reject { |name| name.end_with?("=") || name.start_with?("__hx_") }.sort
  end

  def type_enum_constructs(type)
    enum_constructs(type).map { |item| item[:name] }
  end

  def type_all_enums(type)
    enum_constructs(type)
      .select { |item| item[:arity].zero? }
      .map { |item| type.public_send(item[:method]) }
  end

  def reflect_has_field(object, field)
    source_name = field.to_s
    return object.key?(source_name) || object.key?(source_name.to_sym) if object.is_a?(Hash)
    return false if object.nil?

    name = reflect_member_name(object, source_name)
    object.respond_to?(name) || object.respond_to?(:"#{name}=") || object.instance_variable_defined?(:"@#{name}")
  end

  def reflect_field(object, field)
    source_name = field.to_s
    return hash_field(object, source_name) if object.is_a?(Hash)
    return nil if object.nil?

    name = reflect_member_name(object, source_name)
    ivar = :"@#{name}"
    return object.instance_variable_get(ivar) if object.instance_variable_defined?(ivar)
    return object.method(name) if object.respond_to?(name)

    nil
  rescue NameError
    nil
  end

  def reflect_set_field(object, field, value)
    source_name = field.to_s
    if object.is_a?(Hash)
      object[source_name] = value
      return value
    end
    return value if object.nil?

    name = reflect_member_name(object, source_name)
    setter = :"#{name}="
    object.respond_to?(setter) ? object.public_send(setter, value) : object.instance_variable_set(:"@#{name}", value)
    value
  end

  def reflect_get_property(object, field)
    name = reflect_member_name(object, field)
    getter = "get_#{name}"
    return object.public_send(getter) if !object.is_a?(Hash) && object&.respond_to?(getter)

    reflect_field(object, name)
  end

  def reflect_set_property(object, field, value)
    name = reflect_member_name(object, field)
    setter = "set_#{name}"
    if !object.is_a?(Hash) && object&.respond_to?(setter)
      object.public_send(setter, value)
    else
      reflect_set_field(object, name, value)
    end
    value
  end

  def reflect_call_method(_object, function, args)
    return nil unless function.respond_to?(:call)

    function.call(*(args || []))
  end

  def reflect_fields(object)
    return [] if object.nil?
    return object.keys.map(&:to_s).sort if object.is_a?(Hash)

    names = object.public_methods(false).map(&:to_s).reject { |name| name.end_with?("=") || name.start_with?("__hx_") }
    names.concat(object.instance_variables.map { |ivar| ivar.to_s.delete_prefix("@") })
    names.uniq.sort
  end

  def reflect_is_function(value)
    value.respond_to?(:call)
  end

  def reflect_compare(left, right)
    return 0 if left.nil? && right.nil?
    return 1 if left.nil?
    return -1 if right.nil?
    return 0 if left == right

    compared = left <=> right if left.respond_to?(:<=>)
    return compared unless compared.nil?

    left.object_id < right.object_id ? -1 : 1
  end

  def reflect_compare_methods(left, right)
    return false if left.nil? || right.nil?

    left == right
  end

  def reflect_is_object(value)
    return false if value.nil? || value == true || value == false
    return false if value.is_a?(Numeric) || value.respond_to?(:__hx_tag)

    value.is_a?(Hash) || value.is_a?(Array) || value.is_a?(Class) || value.is_a?(Module) || !reflect_is_function(value)
  end

  def reflect_is_enum_value(value)
    !value.nil? && value.respond_to?(:__hx_tag)
  end

  def reflect_delete_field(object, field)
    source_name = field.to_s
    if object.is_a?(Hash)
      if object.key?(source_name)
        object.delete(source_name)
        return true
      end
      symbol = source_name.to_sym
      if object.key?(symbol)
        object.delete(symbol)
        return true
      end

      return false
    end
    return false if object.nil?

    name = reflect_member_name(object, source_name)
    ivar = :"@#{name}"
    if object.instance_variable_defined?(ivar)
      object.remove_instance_variable(ivar)
      return true
    end
    false
  end

  def reflect_copy(object)
    return nil if object.nil?
    return object.dup if object.is_a?(Hash)

    copy = {}
    reflect_fields(object).each { |field| copy[field] = reflect_field(object, field) }
    copy
  end

  def reflect_make_var_args(function)
    ->(*args) { function.call(args) }
  end

  def reflect_member_name(object, field)
    source_name = field.to_s
    return source_name unless haxe_reflection_receiver?(object)

    reflect_ruby_method_name(source_name)
  end

  def haxe_reflection_receiver?(object)
    object.respond_to?(:__hx_name) || object.class.respond_to?(:__hx_name)
  end

  # Mirrors RubyNaming.toMethodName for dynamic strings crossing Reflect's
  # Haxe-owned object boundary. Hash keys and native Ruby objects stay exact.
  def reflect_ruby_method_name(name)
    source = name.to_s.delete("`")
    return "initialize" if source == "new"

    snake = source
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\\1_\\2')
      .gsub(/([a-z0-9])([A-Z])/, '\\1_\\2')
      .downcase
    identifier = snake
      .gsub(/[^a-z0-9_]/, "_")
      .gsub(/_+/, "_")
      .sub(/\A_+/, "")
      .sub(/_+\z/, "")
    identifier = "hx_method" if identifier.empty?
    identifier = "hx_#{identifier}" if identifier.match?(/\A[0-9]/)
    RUBY_RESERVED_METHOD_NAMES.include?(identifier) ? "#{identifier}_" : identifier
  end

  def typeof(value)
    return ValueType.t_null if value.nil?
    return ValueType.t_bool if value == true || value == false
    return ValueType.t_int if value.is_a?(Integer)
    return ValueType.t_float if value.is_a?(Numeric)
    return ValueType.t_function if value.respond_to?(:call)
    return ValueType.t_class(type_get_class(value)) if type_get_class(value)
    return ValueType.t_enum(type_get_enum(value)) if type_get_enum(value)

    ValueType.t_object
  end

  def hash_field(hash, name)
    return hash[name] if hash.key?(name)

    symbol = name.to_sym
    hash.key?(symbol) ? hash[symbol] : nil
  end

  def haxe_type?(type, name)
    Object.const_defined?(name, false) && type.equal?(Object.const_get(name, false))
  end

  def enum_value_of?(value, type)
    return false if value.nil? || type.name.nil? || !value.respond_to?(:__hx_tag)

    class_name = value.class.name
    !class_name.nil? && class_name.start_with?("#{type.name}::")
  end

  def enum_module(value)
    return nil if value.nil? || !value.respond_to?(:__hx_tag)

    class_name = value.class.name
    return nil if class_name.nil? || !class_name.include?("::")

    resolve_constant_path(class_name.split("::")[0...-1])
  end

  def type_name_for(type)
    return nil if type.nil?
    return "String" if type.equal?(String)
    return "Array" if type.equal?(Array)
    return "Int" if haxe_type?(type, :Int)
    return "Float" if haxe_type?(type, :Float_)
    return "Bool" if haxe_type?(type, :Bool)
    return type.__hx_name if type.respond_to?(:__hx_name)

    type.name&.gsub("::", ".")
  end

  def resolve_haxe_constant(name)
    return nil if name.nil?

    resolve_constant_path(name.to_s.split(".").map { |part| haxe_constant_part(part) })
  end

  def resolve_constant_path(parts)
    parts.reduce(Object) do |scope, part|
      return nil unless scope.const_defined?(part, false)

      scope.const_get(part, false)
    end
  rescue NameError
    nil
  end

  def haxe_constant_part(part)
    return part if part.nil? || part.empty?

    part[0].upcase + part[1..]
  end

  def enum_constructs(type)
    return [] unless type.respond_to?(:__hx_constructs)

    type.__hx_constructs
  end

  def create_enum_from_entry(type, entry, params)
    return nil if type.nil? || entry.nil?

    type.public_send(entry[:method], *(params || []))
  end
end
