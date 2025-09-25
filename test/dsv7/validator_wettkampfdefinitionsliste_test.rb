# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'dsv7/parser'

class Dsv7ValidatorWkdlTest < Minitest::Test
  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def wk_minimal
    <<~DSV
      FORMAT:Wettkampfdefinitionsliste;7;
      ERZEUGER:Soft;1.0;mail@example.com;
      VERANSTALTUNG:Name;Ort;25;HANDZEIT;
      VERANSTALTUNGSORT:Schwimmstadion Duisburg-Wedau;Margaretenstr. 11;47055;Duisburg;GER;09999/11111;Kein Fax;;
      AUSSCHREIBUNGIMNETZ:;
      VERANSTALTER:Club;
      AUSRICHTER:SC Duisburg;Biene, Petra;Wabenstr. 69;47055;Duisburg;GER;0888/22222;0888/22223;PetraBiene@GibtsNicht.de;
      MELDEADRESSE:Kontakt;;;;;;;kontakt@example.com;
      MELDESCHLUSS:01.01.2024;12:00;
      ABSCHNITT:1;01.01.2024;;;10:00;;
      WETTKAMPF:1;V;1;;100;F;GL;M;SW;;;
      WERTUNG:1;V;1;JG;0;9999;;OFFENE WERTUNG;
      MELDEGELD:EINZELMELDEGELD;2,00;;
      DATEIENDE
    DSV
  end

  def test_minimal_wkdl_is_valid
    result = validate_string(wk_minimal)
    assert result.valid?, result.errors.inspect
  end

  def test_missing_required_elements_are_reported
    content = <<~DSV
      FORMAT:Wettkampfdefinitionsliste;7;
      DATEIENDE
    DSV
    result = validate_string(content)
    assert_includes result.errors, "Wettkampfdefinitionsliste: missing required element 'ERZEUGER'"
    assert_includes result.errors, "Wettkampfdefinitionsliste: missing required element 'ABSCHNITT'"
    assert_includes result.errors, "Wettkampfdefinitionsliste: missing required element 'WETTKAMPF'"
    assert_includes result.errors, "Wettkampfdefinitionsliste: missing required element 'WERTUNG'"
    assert_includes result.errors, "Wettkampfdefinitionsliste: missing required element 'MELDEGELD'"
  end

  def test_exactly_one_elements_reject_duplicates
    dupe = wk_minimal.sub(
      "ERZEUGER:Soft;1.0;mail@example.com;\n",
      "ERZEUGER:Soft;1.0;mail@example.com;\n" \
      "ERZEUGER:Soft;1.1;mail2@example.com;\n"
    )
    result = validate_string(dupe)
    assert_includes result.errors,
                    "Wettkampfdefinitionsliste: element 'ERZEUGER' occurs 2 times (expected 1)"
  end

  def test_zero_or_one_elements_reject_more_than_one
    content = wk_minimal.sub(
      "MELDESCHLUSS:01.01.2024;12:00;\n",
      "MELDESCHLUSS:01.01.2024;12:00;\n" \
      "BANKVERBINDUNG:Bank;DE12;BIC;\n" \
      "BANKVERBINDUNG:Bank;DE34;BIC2;\n"
    )
    result = validate_string(content)
    assert_includes result.errors,
                    "Wettkampfdefinitionsliste: element 'BANKVERBINDUNG' occurs 2 times (max 1)"
  end
end
