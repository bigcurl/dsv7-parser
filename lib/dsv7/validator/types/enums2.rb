# frozen_string_literal: true

module Dsv7
  class Validator
    module WkTypeChecksEnums2
      def check_technik(name, idx, val, line_number, _opts = nil)
        return if %w[F R B S L X].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Technik '#{val}' " \
          "(allowed: F, R, B, S, L, X) on line #{line_number}"
        )
      end

      def check_ausuebung(name, idx, val, line_no, _opts = nil)
        return if %w[GL BE AR ST WE GB X].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Ausübung '#{val}' " \
          "(allowed: GL, BE, AR, ST, WE, GB, X) on line #{line_no}"
        )
      end

      def check_geschlecht_wk(name, idx, val, line_no, _opts = nil)
        return if %w[M W X].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Geschlecht '#{val}' (allowed: M, W, X) " \
          "on line #{line_no}"
        )
      end

      def check_bestenliste(name, idx, val, line_no, _opts = nil)
        return if %w[SW EW PA MS KG XX].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Zuordnung '#{val}' " \
          "(allowed: SW, EW, PA, MS, KG, XX) on line #{line_no}"
        )
      end

      def check_wert_typ(name, idx, val, line_number, _opts = nil)
        return if %w[JG AK].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Wertungstyp '#{val}' (allowed: JG, AK) " \
          "on line #{line_number}"
        )
      end

      def check_jgak(name, idx, val, line_number, _opts = nil)
        return if val.match?(/^\d{1,4}$/) || val.match?(/^[ABCDEJ]$/) || val.match?(/^\d{2,3}\+$/)

        add_error(
          "Element #{name}, attribute #{idx}: invalid JG/AK '#{val}' on line #{line_number}"
        )
      end

      def check_geschlecht_erw(name, idx, val, line_number, _opts = nil)
        return if %w[M W X D].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Geschlecht '#{val}' (allowed: M, W, X, D) " \
          "on line #{line_number}"
        )
      end

      def check_geschlecht_pf(name, idx, val, line_number, _opts = nil)
        return if %w[M W D].include?(val)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Geschlecht '#{val}' (allowed: M, W, D) " \
          "on line #{line_number}"
        )
      end

      def check_meldegeld_typ(name, idx, val, line_number, _opts = nil)
        allowed = %w[
          MELDEGELDPAUSCHALE EINZELMELDEGELD STAFFELMELDEGELD WKMELDEGELD MANNSCHAFTMELDEGELD
        ]
        return if allowed.include?(val.upcase)

        add_error(
          "Element #{name}, attribute #{idx}: invalid Meldegeld Typ '#{val}' on line #{line_number}"
        )
      end
    end
  end
end
