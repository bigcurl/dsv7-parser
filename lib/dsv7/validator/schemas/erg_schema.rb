# frozen_string_literal: true

require_relative '../types'
require_relative 'base'

module Dsv7
  class Validator
    # Validates Wettkampfergebnisliste attribute counts and datatypes.
    # Accepts synonymous element names found in the wild
    # (e.g., STAFFELERGEBNIS/STERGEBNIS).
    #
    # @api private
    class ErgSchema < SchemaBase
      include WkTypeChecks

      SCHEMAS = {
        'ERZEUGER' => [[:zk, true], [:zk, true], [:zk, true]],
        'VERANSTALTUNG' => [[:zk, true], [:zk, true], [:bahnl, true], [:zeitmessung, true]],
        'VERANSTALTER' => [[:zk, true]],
        'AUSRICHTER' => [
          [:zk, true], [:zk, true], [:zk, false], [:zk, false], [:zk, false],
          [:land, false], [:zk, false], [:zk, false], [:zk, true]
        ],
        'ABSCHNITT' => [[:zahl, true], [:datum, true], [:uhrzeit, true], [:relativ, false]],
        'KAMPFGERICHT' => [[:zahl, true], [:zk, true], [:zk, true], [:zk, true]],
        'WETTKAMPF' => [
          [:zahl, true], [:wk_art_erg, true], [:zahl, true], [:zahl, false],
          [:einzelstrecke, true], [:technik, true], [:ausuebung, true],
          [:geschlecht_wk, true], [:bestenliste, true], [:zahl, false], [:wk_art, false]
        ],
        'WERTUNG' => [
          [:zahl, true], [:wk_art, true], [:zahl, true], [:wert_typ, true],
          [:jgak, true], [:jgak, false], [:geschlecht_erw, false], [:zk, true]
        ],
        'VEREIN' => [[:zk, true], [:zahl, true], [:zahl, true], [:land, true]],
        'PNERGEBNIS' => [
          [:zahl, true], [:wk_art_erg, true], [:zahl, true], [:zahl, true],
          [:zk, false], [:zk, true], [:zahl, true], [:zahl, true],
          [:geschlecht_pf, true], [:zahl, true], [:zahl, false], [:zk, true],
          [:zahl, true], [:zeit, true], [:zk, false], [:nachtrag_flag, false],
          [:land, false], [:land, false], [:land, false]
        ],
        'PNZWISCHENZEIT' => [
          [:zahl, true], [:zahl, true], [:wk_art_erg, true], [:zahl, true], [:zeit, true]
        ],
        'PNREAKTION' => [
          [:zahl, true], [:zahl, true], [:wk_art_erg, true], [:reaktion_art, false], [:zeit, true]
        ],
        # Accept both names as they appear across sources
        'STAFFELERGEBNIS' => [
          [:zahl, true], [:wk_art_erg, true], [:zahl, true], [:zahl, true],
          [:zk, false], [:zahl, true], [:zahl, true], [:zk, true], [:zahl, true],
          [:zeit, true], [:zahl, false], [:zk, false], [:nachtrag_flag, false]
        ],
        'STERGEBNIS' => [
          [:zahl, true], [:wk_art_erg, true], [:zahl, true], [:zahl, true],
          [:zk, false], [:zahl, true], [:zahl, true], [:zk, true], [:zahl, true],
          [:zeit, true], [:zahl, false], [:zk, false], [:nachtrag_flag, false]
        ],
        'STAFFELPERSON' => [
          [:zahl, true], [:zahl, true], [:wk_art_erg, true], [:zk, true],
          [:zahl, true], [:zahl, true], [:geschlecht_pf, true], [:zahl, true],
          [:zahl, false], [:land, false], [:land, false], [:land, false]
        ],
        'STZWISCHENZEIT' => [
          [:zahl, true], [:zahl, true], [:wk_art_erg, true], [:zahl, true], [:zahl, true],
          [:zeit, true]
        ],
        'STABLOESE' => [
          [:zahl, true], [:zahl, true], [:wk_art_erg, true], [:zahl, true],
          [:reaktion_art, false], [:zeit, true]
        ]
      }.freeze
    end
  end
end
