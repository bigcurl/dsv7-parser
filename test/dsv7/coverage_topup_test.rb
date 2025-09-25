# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7CoverageTopupTest < Minitest::Test
  def setup
    @result = Dsv7::Validator::Result.new
  end

  def test_enums1_nachweis_bahn_invalid
    schema = Dsv7::Validator::WkSchema.new(@result)
    # NACHWEIS: [:datum, true], [:datum, false], [:nachweis_bahn, true]
    schema.validate_element('NACHWEIS', ['01.01.2024', '', '30'], 5)
    assert_includes @result.errors,
                    "Element NACHWEIS, attribute 3: invalid Bahnlänge '30' (allowed: 25, 50, FW, AL) (line 5)"
  end

  def test_enums2_ausuebung_invalid
    result = Dsv7::Validator::Result.new
    schema = Dsv7::Validator::WkSchema.new(result)
    # WETTKAMPF with invalid Ausübung at attribute 7
    attrs = ['1', 'V', '1', '', '100', 'F', 'QQ', 'M', 'SW', '', '']
    schema.validate_element('WETTKAMPF', attrs, 12)
    assert_includes result.errors,
                    "Element WETTKAMPF, attribute 7: invalid Ausübung 'QQ' (allowed: GL, BE, AR, ST, WE, GB, X) (line 12)"
  end

  def test_enums2_bestenliste_invalid
    result = Dsv7::Validator::Result.new
    schema = Dsv7::Validator::WkSchema.new(result)
    # WETTKAMPF with invalid Bestenliste at attribute 9
    attrs = ['1', 'V', '1', '', '100', 'F', 'GL', 'M', 'ZZ', '', '']
    schema.validate_element('WETTKAMPF', attrs, 13)
    assert_includes result.errors,
                    "Element WETTKAMPF, attribute 9: invalid Zuordnung 'ZZ' (allowed: SW, EW, PA, MS, KG, XX) (line 13)"
  end

  def test_enums2_geschlecht_erw_invalid
    result = Dsv7::Validator::Result.new
    schema = Dsv7::Validator::WkSchema.new(result)
    # WERTUNG: invalid Geschlecht Erw at attribute 7
    attrs = ['1', 'V', '1', 'JG', '0', '', 'Q', 'OFFEN']
    schema.validate_element('WERTUNG', attrs, 8)
    assert_includes result.errors,
                    "Element WERTUNG, attribute 7: invalid Geschlecht 'Q' (allowed: M, W, X, D) (line 8)"
  end

  def test_enums2_nichtwertung_grund_invalid
    result = Dsv7::Validator::Result.new
    schema = Dsv7::Validator::VrlSchema.new(result)
    # PERSONENERGEBNIS: invalid Grund der Nichtwertung at attribute 7
    attrs = ['1', '1', 'V', '1', '1', '00:59:59,99', 'XX', '', '']
    schema.validate_element('PERSONENERGEBNIS', attrs, 20)
    assert_includes result.errors,
                    "Element PERSONENERGEBNIS, attribute 7: invalid Grund der Nichtwertung 'XX' (allowed: DS, NA, AB, AU, ZU) (line 20)"
  end

  def test_common_betrag_invalid
    result = Dsv7::Validator::Result.new
    schema = Dsv7::Validator::WkSchema.new(result)
    # MELDEGELD: invalid Betrag format
    schema.validate_element('MELDEGELD', ['EINZELMELDEGELD', '2.00', ''], 30)
    assert_includes result.errors,
                    "Element MELDEGELD, attribute 2: invalid Betrag '2.00' (expected x,yy) (line 30)"
  end

  def test_enums2_meldegeld_typ_invalid
    result = Dsv7::Validator::Result.new
    schema = Dsv7::Validator::WkSchema.new(result)
    schema.validate_element('MELDEGELD', ['BADTYPE', '2,00', ''], 31)
    assert_includes result.errors,
                    "Element MELDEGELD, attribute 1: invalid Meldegeld Typ 'BADTYPE' (line 31)"
  end

  def test_datetime_uhrzeit_invalid_format
    result = Dsv7::Validator::Result.new
    schema = Dsv7::Validator::WkSchema.new(result)
    schema.validate_element('MELDESCHLUSS', ['01.01.2024', '1200'], 40)
    assert_includes result.errors,
                    "Element MELDESCHLUSS, attribute 2: invalid Uhrzeit '1200' (expected HH:MM) (line 40)"
  end

  def test_validator_unsupported_input_raises
    assert_raises(ArgumentError) { Dsv7::Validator.validate(123) }
  end

  def test_parser_unsupported_input_raises
    assert_raises(ArgumentError) { Dsv7::Parser.parse_wettkampfdefinitionsliste(123).to_a }
  end
end
