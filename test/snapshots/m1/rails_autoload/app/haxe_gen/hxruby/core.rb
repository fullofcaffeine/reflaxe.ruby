# frozen_string_literal: true

require "cgi"
require "uri"

module HXRuby
  RUBY_MATH_UNARY = {
    sin: ::Math.method(:sin),
    cos: ::Math.method(:cos),
    tan: ::Math.method(:tan),
    asin: ::Math.method(:asin),
    acos: ::Math.method(:acos),
    atan: ::Math.method(:atan),
    exp: ::Math.method(:exp),
    log: ::Math.method(:log),
    sqrt: ::Math.method(:sqrt)
  }.freeze
  RUBY_MATH_BINARY = {
    atan2: ::Math.method(:atan2)
  }.freeze

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

  def array_concat(array, other)
    array + other
  end

  def active_record_projection(rows, keys)
    rows.map do |row|
      values = row.is_a?(Array) ? row : [row]
      keys.each_with_index.each_with_object({}) do |(key, index), out|
        out[key.to_s] = values[index]
      end
    end
  end

  def array_join(array, separator)
    array.map { |entry| stringify(entry) }.join(separator.to_s)
  end

  def array_push(array, value)
    array << value
    array.length
  end

  def array_reverse(array)
    array.reverse!
    nil
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

  def array_contains(array, value)
    array.include?(value)
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

  def array_copy(array)
    array.dup
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
    RUBY_MATH_UNARY.fetch(method).call(value)
  rescue Math::DomainError
    Float::NAN
  end

  def math_binary(method, left, right)
    RUBY_MATH_BINARY.fetch(method).call(left, right)
  rescue Math::DomainError
    Float::NAN
  end

  def math_pow(value, exponent)
    result = value**exponent
    result.is_a?(Complex) ? Float::NAN : result
  rescue Math::DomainError
    Float::NAN
  end

  def math_round(value)
    (value + 0.5).floor
  end

  def math_nan?(value)
    value.respond_to?(:nan?) && value.nan?
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
    []
  end

  def type_class_fields(_type)
    []
  end

  def type_enum_constructs(type)
    enum_constructs(type).map { |item| item[:name] }
  end

  def type_all_enums(type)
    enum_constructs(type)
      .select { |item| item[:arity].zero? }
      .map { |item| type.public_send(item[:method]) }
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
