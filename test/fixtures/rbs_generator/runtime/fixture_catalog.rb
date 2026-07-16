# frozen_string_literal: true

# Runtime peer for the generated extern fixture. It stays ordinary Ruby so the
# smoke test proves the generated Haxe dispatches directly to native methods.
class FixtureCatalog
  def initialize(prefix = "item")
    @prefix = prefix
  end

  def label_for(key, count = 1)
    "#{@prefix}:#{key}:#{count}"
  end

  def maybe_label(key)
    key && "#{@prefix}:#{key}"
  end

  def nested_rows(rows)
    rows
  end

  def empty?
    false
  end

  def self.normalize(value)
    value.strip.downcase
  end
end
