# frozen_string_literal: true

class HxException < StandardError
  attr_reader :value, :native

  # Haxe's `catch (error:haxe.Exception)` is a wildcard catch whose binding
  # must expose the haxe.Exception API even when Ruby raised a native error.
  # Keep compiler carriers intact; otherwise adapt the native error without
  # losing the object that an explicit Haxe rethrow must raise again.
  def self.caught(error)
    return error if error.is_a?(HxException)

    new(error, native: error)
  end

  # Haxe can throw any value, but Ruby can raise only exception objects. Keep
  # an existing native error intact, and unwrap a haxe.Exception wildcard
  # adapter back to its original native error. Explicit rethrows therefore
  # preserve identity, cause, and the original backtrace.
  def self.wrap(value)
    return value.native if value.is_a?(HxException)
    return value if value.is_a?(StandardError)

    new(value)
  end

  def initialize(value, native: nil)
    @value = value
    @native = native || self
    super(exception_message(value))
    set_backtrace(native.backtrace) if native&.backtrace
  end

  # Haxe property access lowers `error.message` to `get_message()`. Ruby's
  # StandardError already owns the underlying message; this bridge keeps the
  # typed haxe.Exception surface structural without monkey-patching Ruby.
  def get_message
    message
  end

  private

  def exception_message(value)
    return value.message if value.is_a?(StandardError)

    defined?(HXRuby) ? HXRuby.stringify(value) : value.to_s
  end
end
