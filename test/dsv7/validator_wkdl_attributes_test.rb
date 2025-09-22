# frozen_string_literal: true

require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ValidatorWkdlAttributesTest < Minitest::Test
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

  def test_meldeschluss_date_and_time_types
    body = <<~BODY
      MELDESCHLUSS:01.01.2024;12:00;
      ABSCHNITT:1;01.01.2024;;;10:00;;
      WETTKAMPF:1;V;1;;100;F;GL;M;SW;;;
      MELDEGELD:EINZELMELDEGELD;2,00;;
    BODY
    content = wk_head + body + wk_tail
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end

  def test_invalid_date_and_time_are_rejected
    body = <<~BODY
      MELDESCHLUSS:2024-01-01;24:00;
      ABSCHNITT:1;32.13.2024;;;10:00;;
      WETTKAMPF:1;V;1;;100;F;GL;M;SW;;;
      MELDEGELD:EINZELMELDEGELD;2,00;;
    BODY
    content = wk_head + body + wk_tail
    result = validate_string(content)
    assert_includes result.errors,
                    "Element MELDESCHLUSS, attribute 1: invalid Datum '2024-01-01' " \
                    '(expected TT.MM.JJJJ) on line 9'
    assert_includes result.errors,
                    "Element MELDESCHLUSS, attribute 2: time out of range '24:00' on line 9"
    assert_includes result.errors,
                    "Element ABSCHNITT, attribute 2: impossible date '32.13.2024' on line 10"
  end

  def test_veranstaltung_bahnlaenge_and_zeitmessung
    body = <<~BODY
      MELDESCHLUSS:01.01.2024;12:00;
      ABSCHNITT:1;01.01.2024;;;10:00;;
      WETTKAMPF:1;V;1;;100;F;GL;M;SW;;;
      MELDEGELD:EINZELMELDEGELD;2,00;;
    BODY
    content = wk_head + body + wk_tail
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end

  def test_invalid_bahnlaenge_and_technik
    content = <<~DSV
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
    result = validate_string(content)
    assert_includes result.errors,
                    "Element VERANSTALTUNG, attribute 3: invalid Bahnlänge '17' " \
                    '(allowed: 16, 20, 25, 33, 50, FW, X) on line 3'
    assert_includes result.errors,
                    "Element WETTKAMPF, attribute 5: Einzelstrecke out of range '30000' " \
                    '(allowed 1..25000 or 0) on line 11'
    assert_includes result.errors,
                    "Element WETTKAMPF, attribute 6: invalid Technik 'Q' (allowed: F, R, B, S, L, X) on line 11"
  end

  def test_meldegeld_type_and_requirement
    body = <<~BODY
      MELDESCHLUSS:01.01.2024;12:00;
      ABSCHNITT:1;01.01.2024;;;10:00;
      WETTKAMPF:1;V;1;;100;F;GL;M;SW;;;
      MELDEGELD:WKMELDEGELD;2,00;;
    BODY
    content = wk_head + body + wk_tail
    result = validate_string(content)
    assert_includes result.errors,
                    "Element MELDEGELD: 'WKMELDEGELD' requires Wettkampfnr (attr 3) on line 12"
  end

  def test_abschnitt_relative_flag_validation
    body = <<~BODY
      MELDESCHLUSS:01.01.2024;12:00;
      ABSCHNITT:1;01.01.2024;;;10:00;J;
      WETTKAMPF:1;V;1;;100;F;GL;M;SW;;;
      MELDEGELD:EINZELMELDEGELD;2,00;;
    BODY
    content = wk_head + body + wk_tail
    result = validate_string(content)
    assert result.valid?, result.errors.inspect

    bad_body = <<~BODY
      MELDESCHLUSS:01.01.2024;12:00;
      ABSCHNITT:1;01.01.2024;;;10:00;K;
      WETTKAMPF:1;V;1;;100;F;GL;M;SW;;;
      MELDEGELD:EINZELMELDEGELD;2,00;;
    BODY
    bad = wk_head + bad_body + wk_tail
    bad_result = validate_string(bad)
    assert_includes bad_result.errors,
                    "Element ABSCHNITT, attribute 6: invalid Relative Angabe 'K' (allowed: J, N) on line 10"
  end
end
