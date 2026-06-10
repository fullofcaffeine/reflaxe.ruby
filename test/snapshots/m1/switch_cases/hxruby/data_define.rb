# frozen_string_literal: true

class Data; end unless defined?(Data)

unless Data.respond_to?(:define)
  class << Data
    def define(*members)
      Struct.new(*members) do
        def deconstruct
          values
        end

        def deconstruct_keys(keys)
          members.each_with_object({}) do |member, out|
            out[member] = self[member] if keys.nil? || keys.include?(member)
          end
        end
      end
    end
  end
end
