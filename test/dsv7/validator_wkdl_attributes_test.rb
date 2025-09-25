# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'dsv7/parser'

module WkdlTestHelpers
  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def wk_head
    <<~DSV
      FORMAT:Wettkampfdefinitionsliste;7;
      ERZEUGER:Soft;1.0;mail@example.com;
      VERANSTALTUNG:Name;Ort;25;HANDZEIT;
      VERANSTALTUNGSORT:Schwimmstadion Duisburg-Wedau;Margaretenstr. 11;47055;Duisburg;GER;09999/11111;Kein Fax;;
      AUSSCHREIBUNGIMNETZ:;
      VERANSTALTER:Club;
      AUSRICHTER:SC Duisburg;Biene, Petra;Wabenstr. 69;47055;Duisburg;GER;0888/22222;0888/22223;PetraBiene@GibtsNicht.de;
      MELDEADRESSE:Kontakt;;;;;;;kontakt@example.com;
    DSV
  end

  def wk_tail
    <<~DSV
      DATEIENDE
    DSV
  end

  def wk_body(relative: nil, meldegeld_line: 'MELDEGELD:EINZELMELDEGELD;2,00;;')
    abs = 'ABSCHNITT:1;01.01.2024;;;10:00;'
    abs += relative ? "#{relative};" : ';'
    <<~BODY
      MELDESCHLUSS:01.01.2024;12:00;
      #{abs}
      WETTKAMPF:1;V;1;;100;F;GL;M;SW;;;
      WERTUNG:1;V;1;JG;0;9999;;OFFENE WERTUNG;
      #{meldegeld_line}
    BODY
  end
end

class Dsv7ValidatorWkdlAttributesTest < Minitest::Test
  include WkdlTestHelpers

  def test_meldeschluss_date_and_time_types
    body = <<~BODY
      MELDESCHLUSS:01.01.2024;12:00;
      ABSCHNITT:1;01.01.2024;;;10:00;;
      WETTKAMPF:1;V;1;;100;F;GL;M;SW;;;
      WERTUNG:1;V;1;JG;0;9999;;OFFENE WERTUNG;
      MELDEGELD:EINZELMELDEGELD;2,00;;
    BODY
    content = wk_head + body + wk_tail
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end

  def invalid_date_time_content
    body = <<~BODY
      MELDESCHLUSS:2024-01-01;24:00;
      ABSCHNITT:1;32.13.2024;;;10:00;;
      WETTKAMPF:1;V;1;;100;F;GL;M;SW;;;
      WERTUNG:1;V;1;JG;0;9999;;OFFENE WERTUNG;
      MELDEGELD:EINZELMELDEGELD;2,00;;
    BODY
    wk_head + body + wk_tail
  end

  def test_invalid_date_format_is_rejected
    result = validate_string(invalid_date_time_content)
    assert_includes result.errors,
                    "Element MELDESCHLUSS, attribute 1: invalid Datum '2024-01-01' " \
                    '(expected TT.MM.JJJJ) (line 9)'
  end

  def test_invalid_time_out_of_range_is_rejected
    result = validate_string(invalid_date_time_content)
    assert_includes result.errors,
                    "Element MELDESCHLUSS, attribute 2: time out of range '24:00' (line 9)"
  end

  def test_impossible_abschnitt_date_is_rejected
    result = validate_string(invalid_date_time_content)
    assert_includes result.errors,
                    "Element ABSCHNITT, attribute 2: impossible date '32.13.2024' (line 10)"
  end

  # moved to Dsv7ValidatorWkdlAttributesMoreTest

  # moved to Dsv7ValidatorWkdlAttributesMoreTest

  # moved to Dsv7ValidatorWkdlAttributesMoreTest

  def test_abschnitt_relative_flag_accepts_j
    content = wk_head + wk_body(relative: 'J') + wk_tail
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end

  def test_abschnitt_relative_flag_invalid_value
    bad = wk_head + wk_body(relative: 'K') + wk_tail
    r = validate_string(bad)
    assert_includes r.errors,
                    "Element ABSCHNITT, attribute 6: invalid Relative Angabe 'K' " \
                    '(allowed: J, N) (line 10)'
  end
end

# Split tests to keep class size within RuboCop limits
class Dsv7ValidatorWkdlAttributesMoreTest < Minitest::Test
  include WkdlTestHelpers

  def invalid_bahn_technik_content
    <<~DSV
      FORMAT:Wettkampfdefinitionsliste;7;
      ERZEUGER:Soft;1.0;mail@example.com;
      VERANSTALTUNG:Name;Ort;17;HANDZEIT;
      VERANSTALTUNGSORT:Halle;;;Ort;GER;;;
      AUSSCHREIBUNGIMNETZ:;
      VERANSTALTER:Club;
      AUSRICHTER:Club;Kontakt;;;;;;kontakt@example.com;
      MELDEADRESSE:Kontakt;;;;;;;kontakt@example.com;
      MELDESCHLUSS:01.01.2024;12:00;
      ABSCHNITT:1;01.01.2024;;;10:00;
      WETTKAMPF:1;V;1;;30000;Q;GL;M;SW;;;
      MELDEGELD:EINZELMELDEGELD;2,00;;
      DATEIENDE
    DSV
  end

  def test_veranstaltung_bahnlaenge_and_zeitmessung
    content = wk_head + wk_body + wk_tail
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end

  def test_meldegeld_type_and_requirement
    content = wk_head + wk_body(meldegeld_line: 'MELDEGELD:WKMELDEGELD;2,00;;') + wk_tail
    result = validate_string(content)
    assert_includes result.errors,
                    "Element MELDEGELD: 'WKMELDEGELD' requires Wettkampfnr (attr 3) (line 13)"
  end

  def test_invalid_bahnlaenge
    r = validate_string(invalid_bahn_technik_content)
    assert_includes r.errors,
                    "Element VERANSTALTUNG, attribute 3: invalid Bahnlänge '17' " \
                    '(allowed: 16, 20, 25, 33, 50, FW, X) (line 3)'
  end

  def test_invalid_technik_and_einzelstrecke
    r = validate_string(invalid_bahn_technik_content)
    assert_includes r.errors,
                    "Element WETTKAMPF, attribute 5: Einzelstrecke out of range '30000' " \
                    '(allowed 1..25000 or 0) (line 11)'
    assert_includes r.errors,
                    "Element WETTKAMPF, attribute 6: invalid Technik 'Q' " \
                    '(allowed: F, R, B, S, L, X) (line 11)'
  end
end
