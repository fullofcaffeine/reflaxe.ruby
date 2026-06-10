# frozen_string_literal: true

class HxException < StandardError
  attr_reader :value

  def initialize(value)
    @value = value
    super(value.to_s)
  end
end
