# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'dsv7/parser'

class Dsv7ValidatorVmlMoreTest < Minitest::Test
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

  # Cardinalities
  def test_duplicate_singleton_element_is_error
    content = vml_minimal.sub(
      "VERANSTALTUNG:Name;Ort;25;HANDZEIT;\n",
      "VERANSTALTUNG:Name;Ort;25;HANDZEIT;\nVERANSTALTUNG:Name;Ort;25;HANDZEIT;\n"
    )
    r = validate_string(content)
    assert_includes r.errors,
                    "Vereinsmeldeliste: element 'VERANSTALTUNG' occurs 2 times (expected 1)"
  end

  def test_missing_abschnitt_only_is_reported
    content = vml_minimal.lines.reject { |l| l.start_with?('ABSCHNITT:') }.join
    r = validate_string(content)
    assert_includes r.errors, "Vereinsmeldeliste: missing required element 'ABSCHNITT'"
  end

  def test_missing_wettkampf_only_is_reported
    content = vml_minimal.lines.reject { |l| l.start_with?('WETTKAMPF:') }.join
    r = validate_string(content)
    assert_includes r.errors, "Vereinsmeldeliste: missing required element 'WETTKAMPF'"
  end

  # Attribute counts
  def test_verein_attribute_count_too_many
    content = vml_minimal.sub(
      "VEREIN:Mein Verein;1234;17;GER;\n",
      "VEREIN:Mein Verein;1234;17;GER;EXTRA;\n"
    )
    r = validate_string(content)
    assert_includes r.errors,
                    'Element VEREIN: expected 4 attributes, got 5 (line 6)'
  end

  def test_verein_missing_required_attribute_is_reported
    # leave attribute 4 (Land) empty but present, so type-checker reports missing required
    content = vml_minimal.sub(
      "VEREIN:Mein Verein;1234;17;GER;\n",
      "VEREIN:Mein Verein;1234;17;;\n"
    )
    r = validate_string(content)
    assert_includes r.errors,
                    'Element VEREIN: missing required attribute 4 on line 6'
  end

  # Datatypes/enums
  def test_abschnitt_relative_flag_accepts_j
    good = vml_minimal.sub('ABSCHNITT:1;01.01.2024;10:00;N;',
                           'ABSCHNITT:1;01.01.2024;10:00;J;')
    r = validate_string(good)
    assert r.valid?, r.errors.inspect
  end

  def test_verein_invalid_land_and_id_types
    bad = vml_minimal.sub(
      'VEREIN:Mein Verein;1234;17;GER;',
      'VEREIN:Mein Verein;abc;17;DE;'
    )
    r = validate_string(bad)
    assert_includes r.errors,
                    "Element VEREIN, attribute 2: invalid Zahl 'abc' (line 6)"
    assert_includes r.errors,
                    "Element VEREIN, attribute 4: invalid Land 'DE' " \
                    '(expected FINA code, e.g., GER) on line 6'
  end
end
# End of first batch; keep class size in check
# Split tests to keep class size within RuboCop limits

class Dsv7ValidatorVmlMoreBTest < Minitest::Test
  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def test_wettkampf_invalid_wettkampfart
    bad = vml_minimal.sub('WETTKAMPF:1;V;1;;100;F;GL;M;;;', 'WETTKAMPF:1;Q;1;;100;F;GL;M;;;')
    r = validate_string(bad)
    assert_includes r.errors,
                    "Element WETTKAMPF, attribute 2: invalid Wettkampfart 'Q' " \
                    '(allowed: V, Z, F, E) on line 5'
  end

  def test_wettkampf_invalid_technik
    bad = vml_minimal.sub('WETTKAMPF:1;V;1;;100;F;GL;M;;;', 'WETTKAMPF:1;V;1;;100;Q;GL;M;;;')
    r = validate_string(bad)
    assert_includes r.errors,
                    "Element WETTKAMPF, attribute 6: invalid Technik 'Q' " \
                    '(allowed: F, R, B, S, L, X) on line 5'
  end

  def test_wettkampf_invalid_ausuebung
    bad = vml_minimal.sub('WETTKAMPF:1;V;1;;100;F;GL;M;;;', 'WETTKAMPF:1;V;1;;100;F;ZZ;M;;;')
    r = validate_string(bad)
    assert_includes r.errors,
                    "Element WETTKAMPF, attribute 7: invalid Ausübung 'ZZ' " \
                    '(allowed: GL, BE, AR, ST, WE, GB, X) on line 5'
  end

  def test_wettkampf_invalid_geschlecht
    bad = vml_minimal.sub('WETTKAMPF:1;V;1;;100;F;GL;M;;;', 'WETTKAMPF:1;V;1;;100;F;GL;D;;;')
    r = validate_string(bad)
    assert_includes r.errors,
                    "Element WETTKAMPF, attribute 8: invalid Geschlecht 'D' " \
                    '(allowed: M, W, X) on line 5'
  end

  def test_pnmeldung_geschlecht_d_is_accepted
    content = vml_minimal.sub('DATEIENDE',
                              "PNMELDUNG:Mustermann, Max;0;4711;D;1990;;;GER;;;\nDATEIENDE")
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_pnmeldung_invalid_zahl_and_land_are_reported
    content = vml_minimal.sub('DATEIENDE',
                              "PNMELDUNG:Mustermann, Max;ID;4711;M;199O;;;DE;;;\nDATEIENDE")
    r = validate_string(content)
    assert_includes r.errors, "Element PNMELDUNG, attribute 2: invalid Zahl 'ID' (line 8)"
    assert_includes r.errors, "Element PNMELDUNG, attribute 5: invalid Zahl '199O' (line 8)"
    assert_includes r.errors,
                    "Element PNMELDUNG, attribute 8: invalid Land 'DE' " \
                    '(expected FINA code, e.g., GER) on line 8'
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

  def test_startpn_time_out_of_range
    content = vml_minimal.sub('DATEIENDE', "STARTPN:1;1;25:00:00,00\nDATEIENDE")
    r = validate_string(content)
    assert_includes r.errors,
                    "Element STARTPN, attribute 3: time out of range '25:00:00,00' on line 8"
  end

  def test_startst_invalid_zeit_format
    content = vml_minimal.sub('DATEIENDE', "STARTST:1;1;AA:BB:CC,hh\nDATEIENDE")
    r = validate_string(content)
    assert_includes r.errors,
                    "Element STARTST, attribute 3: invalid Zeit 'AA:BB:CC,hh' " \
                    '(expected HH:MM:SS,hh) on line 8'
  end

  def test_stmeldung_wertung_and_jgak_variants
    content = vml_minimal.sub('DATEIENDE',
                              "STMELDUNG:1;1;JG;2010;;;\nSTMELDUNG:1;1;AK;E;;;\nDATEIENDE")
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_stmeldung_invalid_wert_typ_and_jgak
    content = vml_minimal.sub('DATEIENDE', "STMELDUNG:1;1;XX;!!;;;\nDATEIENDE")
    r = validate_string(content)
    assert_includes r.errors,
                    "Element STMELDUNG, attribute 3: invalid Wertungstyp 'XX' " \
                    '(allowed: JG, AK) on line 8'
    assert_includes r.errors, "Element STMELDUNG, attribute 4: invalid JG/AK '!!' on line 8"
  end

  def test_comment_only_lines_after_dateiende_are_ignored
    content = "#{vml_minimal}(* trailing comment *)\n\n"
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end
end
