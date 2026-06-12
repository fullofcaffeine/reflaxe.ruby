class LegacyPriceFormatter
  def self.call(cents)
    "$#{format('%.2f', cents.to_f / 100)}"
  end

  def self.badge_label(kind, cents)
    "#{kind.upcase} priced by legacy Ruby at #{call(cents)}"
  end
end
