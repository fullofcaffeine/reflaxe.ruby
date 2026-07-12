# Handwritten Ruby consumer of the Haxe-owned callable library. This is kept as
# a real Ruby fixture so ordinary Ruby block/keyword syntax remains an executable
# public compatibility contract rather than a generated-string assertion.
require "callable_api"

puts CallableApi.direct(4) { |value| value * 3 }
captured = CallableApi.capture { |value| value + 10 }
puts captured.call(5)
puts CallableApi.forward(6) { |value| value * 2 }
puts CallableApi.optional(7)
puts CallableApi.optional(7) { |value| value + 1 }
puts CallableApi.decorate("ruby", prefix: "from-", suffix: "!") { |value| value.upcase }
