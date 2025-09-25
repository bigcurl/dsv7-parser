# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ValidatorVmlTest < Minitest::Test
  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def vml_minimal
    <<~DSV
      FORMAT:Vereinsmeldeliste;7;
      ERZEUGER:Soft;1.0;mail@example.com;
      VERANSTALTUNG:Name;Ort;25;HANDZEIT;
      ABSCHNITT:1;01.01.2024;10:00;N;
      WETTKAMPF:1;V;1;;100;F;GL;M;;;
      VEREIN:Mein Verein;1234;17;GER;
      ANSPRECHPARTNER:Beispiel, Alice;;;;;;;alice@example.com;
      DATEIENDE
    DSV
  end

  def test_minimal_vml_is_valid
    result = validate_string(vml_minimal)
    assert result.valid?, result.errors.inspect
  end

  def test_missing_required_elements_are_reported
    content = <<~DSV
      FORMAT:Vereinsmeldeliste;7;
      DATEIENDE
    DSV
    result = validate_string(content)
    assert_includes result.errors, "Vereinsmeldeliste: missing required element 'ERZEUGER'"
    assert_includes result.errors, "Vereinsmeldeliste: missing required element 'ABSCHNITT'"
    assert_includes result.errors, "Vereinsmeldeliste: missing required element 'WETTKAMPF'"
    assert_includes result.errors, "Vereinsmeldeliste: missing required element 'VEREIN'"
    assert_includes result.errors, "Vereinsmeldeliste: missing required element 'ANSPRECHPARTNER'"
  end

  def test_abschnitt_relative_flag_invalid_value
    bad = vml_minimal.sub('ABSCHNITT:1;01.01.2024;10:00;N;',
                          'ABSCHNITT:1;01.01.2024;10:00;K;')
    r = validate_string(bad)
    assert_includes r.errors,
                    "Element ABSCHNITT, attribute 4: invalid Relative Angabe 'K' " \
                    '(allowed: J, N) (line 4)'
  end

  def test_pnmeldung_geschlecht_restricted
    content = vml_minimal.sub('DATEIENDE',
                              "PNMELDUNG:Mustermann, Max;0;4711;X;1990;;;GER;;;\nDATEIENDE")
    r = validate_string(content)
    assert_includes r.errors,
                    "Element PNMELDUNG, attribute 4: invalid Geschlecht 'X' " \
                    '(allowed: M, W, D) (line 8)'
  end
end
