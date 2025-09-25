# frozen_string_literal: true

# Common datatype checks shared across lists.
#
# Implementations follow the spec’s informal definitions:
# - ZK: arbitrary UTF‑8 string (already scrubbed by the stream layer)
# - Zahl: integer (only digits)
# - Betrag: monetary amount in the form `x,yy`
# - Einzelstrecke: distance (1..25000) or 0 where permitted

module Dsv7
  class Validator
    module WkTypeChecksCommon
      def check_zk(_name, _index, _val, _line_number, _opts = nil)
        # any string (already UTF-8 scrubbed); nothing to do
      end

      def check_zahl(name, idx, val, line_number, _opts = nil)
        return if val.match?(/^\d+$/)

        add_error(invalid_zahl_error(name, idx, val, line_number))
      end

      def check_betrag(name, idx, val, line_number, _opts = nil)
        return if val.match?(/^\d+,\d{2}$/)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Betrag '#{val}' (expected x,yy) " \
          "(line #{line_number})"
        )
      end

      def check_einzelstrecke(name, idx, val, line_number, _opts = nil)
        return add_error(invalid_zahl_error(name, idx, val, line_number)) unless val.match?(/^\d+$/)

        n = val.to_i
        return if n.zero? || (1..25_000).cover?(n)

        add_error(
          "Element #{name}, attribute #{idx}: Einzelstrecke out of range '#{val}' " \
          "(allowed 1..25000 or 0) (line #{line_number})"
        )
      end

      def invalid_zahl_error(name, idx, val, line_number)
        "Element #{name}, attribute #{idx}: invalid Zahl '#{val}' (line #{line_number})"
      end
    end
  end
end
