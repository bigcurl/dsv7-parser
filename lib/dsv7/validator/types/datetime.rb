# frozen_string_literal: true

require 'date'

module Dsv7
  class Validator
    ##
    # Date and time datatype checks.
    #
    # Enforces textual formats before validating value ranges:
    # - Datum:    TT.MM.JJJJ (validated via Date.strptime)
    # - Uhrzeit:  HH:MM      (0..23, 0..59)
    # - Zeit:     HH:MM:SS,hh (0..23, 0..59, 0..59, 0..99)
    #
    # @see specification/dsv7/dsv7_specification.md Date/time formats
    # @api private
    module WkTypeChecksDateTime
      private

      def check_datum(name, idx, val, line_number, _opts = nil)
        return add_error(datum_format_error(name, idx, val, line_number)) unless
          val.match?(/^\d{2}\.\d{2}\.\d{4}$/)

        Date.strptime(val, '%d.%m.%Y')
      rescue ArgumentError
        add_error(impossible_date_error(name, idx, val, line_number))
      end

      def check_uhrzeit(name, idx, val, line_number, _opts = nil)
        return add_error(uhrzeit_format_error(name, idx, val, line_number)) unless
          val.match?(/^\d{2}:\d{2}$/)

        hh, mm = val.split(':').map(&:to_i)
        return if (0..23).cover?(hh) && (0..59).cover?(mm)

        add_error(time_out_of_range_error(name, idx, val, line_number))
      end

      def check_zeit(name, idx, val, line_number, _opts = nil)
        return add_error(zeit_format_error(name, idx, val, line_number)) unless
          val.match?(/^\d{2}:\d{2}:\d{2},\d{2}$/)

        h, m, s, hh = parse_zeit_parts(val)
        return if (0..23).cover?(h) && (0..59).cover?(m) && (0..59).cover?(s) && (0..99).cover?(hh)

        add_error(time_out_of_range_error(name, idx, val, line_number))
      end

      def datum_format_error(name, idx, val, line_number)
        "Element #{name}, attribute #{idx}: invalid Datum '#{val}' " \
          "(expected TT.MM.JJJJ) (line #{line_number})"
      end

      def impossible_date_error(name, idx, val, line_number)
        "Element #{name}, attribute #{idx}: impossible date '#{val}' (line #{line_number})"
      end

      def uhrzeit_format_error(name, idx, val, line_number)
        "Element #{name}, attribute #{idx}: invalid Uhrzeit '#{val}' " \
          "(expected HH:MM) (line #{line_number})"
      end

      def zeit_format_error(name, idx, val, line_number)
        "Element #{name}, attribute #{idx}: invalid Zeit '#{val}' " \
          "(expected HH:MM:SS,hh) (line #{line_number})"
      end

      def time_out_of_range_error(name, idx, val, line_number)
        "Element #{name}, attribute #{idx}: time out of range '#{val}' (line #{line_number})"
      end

      def parse_zeit_parts(val)
        h, m, s_hh = val.split(':')
        s, hh = s_hh.split(',')
        [h.to_i, m.to_i, s.to_i, hh.to_i]
      end
    end
  end
end
