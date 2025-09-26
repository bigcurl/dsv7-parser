# frozen_string_literal: true

module Dsv7
  class Validator
    ##
    # Enum/group checks (part 1): Bahnlänge, Zeitmessung, Land, etc.
    #
    # These normalize expectations found in the spec and examples and produce
    # actionable error messages that include allowed values.
    #
    # @see specification/dsv7/dsv7_specification.md Enumerations overview
    # @api private
    module WkTypeChecksEnums1
      private

      def check_bahnl(name, idx, val, line_number, _opts = nil)
        allowed = %w[16 20 25 33 50 FW X]
        return if allowed.include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Bahnlänge '#{val}' (allowed: " \
          "#{allowed.join(', ')}) (line #{line_number})"
        )
      end

      def check_zeitmessung(name, idx, val, line_number, _opts = nil)
        allowed = %w[HANDZEIT AUTOMATISCH HALBAUTOMATISCH]
        return if allowed.include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Zeitmessung '#{val}' (allowed: " \
          "#{allowed.join(', ')}) (line #{line_number})"
        )
      end

      def check_land(name, idx, val, line_number, _opts = nil)
        return if val.match?(/^[A-Z]{3}$/)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Land '#{val}' " \
          "(expected FINA code, e.g., GER) (line #{line_number})"
        )
      end

      def check_nachweis_bahn(name, idx, val, line_number, _opts = nil)
        allowed = %w[25 50 FW AL]
        return if allowed.include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Bahnlänge '#{val}' (allowed: " \
          "#{allowed.join(', ')}) (line #{line_number})"
        )
      end

      def check_relativ(name, idx, val, line_number, _opts = nil)
        return if %w[J N].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Relative Angabe '#{val}' (allowed: J, N) " \
          "(line #{line_number})"
        )
      end

      def check_wk_art(name, idx, val, line_number, _opts = nil)
        return if %w[V Z F E].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Wettkampfart '#{val}' " \
          "(allowed: V, Z, F, E) (line #{line_number})"
        )
      end

      # Wettkampfergebnisliste allows additional values 'A' and 'N'
      def check_wk_art_erg(name, idx, val, line_number, _opts = nil)
        return if %w[V Z F E A N].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Wettkampfart '#{val}' " \
          "(allowed: V, Z, F, E, A, N) (line #{line_number})"
        )
      end
    end
  end
end
