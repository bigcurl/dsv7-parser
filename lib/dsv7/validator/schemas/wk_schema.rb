# frozen_string_literal: true

require_relative '../types'
require_relative 'base'

module Dsv7
  class Validator
    # Validates Wettkampfdefinitionsliste attribute counts and datatypes.
    #
    # The `SCHEMAS` constant defines the exact attribute counts and types per
    # element according to the current spec interpretation.
    class WkSchema < SchemaBase
      include WkTypeChecks

      SCHEMAS = {
        'ERZEUGER' => [[:zk, true], [:zk, true], [:zk, true]],
        'VERANSTALTUNG' => [
          [:zk, true], [:zk, true], [:bahnl, true], [:zeitmessung, true]
        ],
        'VERANSTALTUNGSORT' => [
          [:zk, true], [:zk, false], [:zk, false], [:zk, true],
          [:land, true], [:zk, false], [:zk, false], [:zk, false]
        ],
        'AUSSCHREIBUNGIMNETZ' => [[:zk, false]],
        'VERANSTALTER' => [[:zk, true]],
        'AUSRICHTER' => [
          [:zk, true], [:zk, true], [:zk, false], [:zk, false], [:zk, false],
          [:land, false], [:zk, false], [:zk, false], [:zk, true]
        ],
        'MELDEADRESSE' => [
          [:zk, true], [:zk, false], [:zk, false], [:zk, false],
          [:land, false], [:zk, false], [:zk, false], [:zk, true]
        ],
        'MELDESCHLUSS' => [[:datum, true], [:uhrzeit, true]],
        'BANKVERBINDUNG' => [[:zk, false], [:zk, true], [:zk, false]],
        'BESONDERES' => [[:zk, true]],
        'NACHWEIS' => [[:datum, true], [:datum, false], [:nachweis_bahn, true]],
        'ABSCHNITT' => [
          [:zahl, true], [:datum, true], [:uhrzeit, false],
          [:uhrzeit, false], [:uhrzeit, true], [:relativ, false]
        ],
        'WETTKAMPF' => [
          [:zahl, true], [:wk_art, true], [:zahl, true], [:zahl, false],
          [:einzelstrecke, true], [:technik, true], [:ausuebung, true],
          [:geschlecht_wk, true], [:bestenliste, true], [:zahl, false], [:wk_art, false]
        ],
        'WERTUNG' => [
          [:zahl, true], [:wk_art, true], [:zahl, true], [:wert_typ, true],
          [:jgak, true], [:jgak, false], [:geschlecht_erw, false], [:zk, true]
        ],
        # Intentionally omitting PFLICHTZEIT for now (spec examples appear inconsistent)
        'MELDEGELD' => [[:meldegeld_typ, true], [:betrag, true], [:zahl, false]]
      }.freeze

      def validate_cross_rules(name, attrs, line_number)
        return unless name == 'MELDEGELD'

        type_str = attrs[0].to_s.upcase
        needs_wk = type_str == 'WKMELDEGELD' && (attrs[2].nil? || attrs[2].empty?)
        return unless needs_wk

        add_error(
          "Element MELDEGELD: 'WKMELDEGELD' requires Wettkampfnr (attr 3) (line #{line_number})"
        )
      end
    end
  end
end
