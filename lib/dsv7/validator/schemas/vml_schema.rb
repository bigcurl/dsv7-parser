# frozen_string_literal: true

require_relative '../types'
require_relative 'base'

module Dsv7
  class Validator
    # Validates Vereinsmeldeliste attribute counts and datatypes.
    #
    # @api private
    class VmlSchema < SchemaBase
      include WkTypeChecks

      SCHEMAS = {
        'ERZEUGER' => [[:zk, true], [:zk, true], [:zk, true]],
        'VERANSTALTUNG' => [[:zk, true], [:zk, true], [:bahnl, true], [:zeitmessung, true]],
        'ABSCHNITT' => [[:zahl, true], [:datum, true], [:uhrzeit, true], [:relativ, false]],
        'WETTKAMPF' => [
          [:zahl, true], [:wk_art, true], [:zahl, true], [:zahl, false],
          [:einzelstrecke, true], [:technik, true], [:ausuebung, true],
          [:geschlecht_wk, true], [:zahl, false], [:wk_art, false]
        ],
        'VEREIN' => [[:zk, true], [:zahl, true], [:zahl, true], [:land, true]],
        'ANSPRECHPARTNER' => [
          [:zk, true], [:zk, false], [:zk, false], [:zk, false],
          [:land, false], [:zk, false], [:zk, false], [:zk, true]
        ],
        'KARIMELDUNG' => [[:zahl, true], [:zk, true], [:zk, true]],
        'KARIABSCHNITT' => [[:zahl, true], [:zahl, true], [:zk, false]],
        'TRAINER' => [[:zahl, true], [:zk, true]],
        'PNMELDUNG' => [
          [:zk, true], [:zahl, true], [:zahl, true], [:geschlecht_pf, true],
          [:zahl, true], [:zahl, false], [:zahl, false],
          [:land, false], [:land, false], [:land, false]
        ],
        'HANDICAP' => [
          [:zahl, true], [:zk, false], [:zk, false],
          [:zk, true], [:zk, true], [:zk, true], [:zk, false]
        ],
        'STARTPN' => [[:zahl, true], [:zahl, true], [:zeit, false]],
        'STMELDUNG' => [
          [:zahl, true], [:zahl, true], [:wert_typ, true],
          [:jgak, true], [:jgak, false], [:zk, false]
        ],
        'STARTST' => [[:zahl, true], [:zahl, true], [:zeit, false]],
        'STAFFELPERSON' => [[:zahl, true], [:zahl, true], [:zahl, true], [:zahl, true]]
      }.freeze

      # no extra cross-rules for VML currently
    end
  end
end
