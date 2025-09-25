# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'dsv7/parser'

class Dsv7ValidatorVmlElementsTest < Minitest::Test
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

  # KARIMELDUNG
  def test_karimeldung_valid
    content = vml_minimal.sub('DATEIENDE', "KARIMELDUNG:1;Alice;Beispiel;\nDATEIENDE")
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_karimeldung_invalid_zahl_and_count
    content = vml_minimal.sub('DATEIENDE', "KARIMELDUNG:ID;Alice;Beispiel;\nDATEIENDE")
    r = validate_string(content)
    assert_includes r.errors, "Element KARIMELDUNG, attribute 1: invalid Zahl 'ID' (line 8)"

    content2 = vml_minimal.sub('DATEIENDE', "KARIMELDUNG:1;Alice;\nDATEIENDE")
    r2 = validate_string(content2)
    assert_includes r2.errors, 'Element KARIMELDUNG: expected 3 attributes, got 2 (line 8)'
  end

  # KARIABSCHNITT
  def test_kariabschnitt_valid_with_optional_text
    content = vml_minimal.sub('DATEIENDE', "KARIABSCHNITT:1;2;Früh;\nDATEIENDE")
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_kariabschnitt_invalid_zahlen_and_count
    content = vml_minimal.sub('DATEIENDE', "KARIABSCHNITT:ID;2;\nDATEIENDE")
    r = validate_string(content)
    assert_includes r.errors, "Element KARIABSCHNITT, attribute 1: invalid Zahl 'ID' (line 8)"

    content2 = vml_minimal.sub('DATEIENDE', "KARIABSCHNITT:1;X;\nDATEIENDE")
    r2 = validate_string(content2)
    assert_includes r2.errors, "Element KARIABSCHNITT, attribute 2: invalid Zahl 'X' (line 8)"

    content3 = vml_minimal.sub('DATEIENDE', "KARIABSCHNITT:1;\nDATEIENDE")
    r3 = validate_string(content3)
    assert_includes r3.errors, 'Element KARIABSCHNITT: expected 3 attributes, got 1 (line 8)'
  end

  # TRAINER
  def test_trainer_valid
    ok = vml_minimal.sub('DATEIENDE', "TRAINER:1;Bob;\nDATEIENDE")
    r = validate_string(ok)
    assert r.valid?, r.errors.inspect
  end

  def test_trainer_invalid_zahl
    bad = vml_minimal.sub('DATEIENDE', "TRAINER:ID;Bob;\nDATEIENDE")
    r2 = validate_string(bad)
    assert_includes r2.errors, "Element TRAINER, attribute 1: invalid Zahl 'ID' (line 8)"
  end

  def test_trainer_attribute_count_mismatch
    too_many = vml_minimal.sub('DATEIENDE', "TRAINER:1;Bob;Extra;\nDATEIENDE")
    r3 = validate_string(too_many)
    assert_includes r3.errors, 'Element TRAINER: expected 2 attributes, got 3 (line 8)'
  end

  # HANDICAP, STARTPN/STARTST, STAFFELPERSON moved to separate class
end

# Split to keep class length within RuboCop limits
class Dsv7ValidatorVmlElementsMoreTest < Minitest::Test
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

  # HANDICAP
  def test_handicap_valid
    content = vml_minimal.sub('DATEIENDE', "HANDICAP:1;;;'Req4';Req5;Req6;;\nDATEIENDE")
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_handicap_missing_required_attribute
    # Attribute 4 is required but empty; keep overall count at 7
    content = vml_minimal.sub('DATEIENDE', "HANDICAP:1;X;Y;;B;C;;\nDATEIENDE")
    r = validate_string(content)
    assert_includes r.errors, 'Element HANDICAP: missing required attribute 4 on line 8'
  end

  def test_handicap_attribute_count_mismatch
    content = vml_minimal.sub('DATEIENDE', "HANDICAP:1;;;;;\nDATEIENDE")
    r = validate_string(content)
    assert_includes r.errors, 'Element HANDICAP: expected 7 attributes, got 5 (line 8)'
  end

  def test_startpn_valid_without_time_and_with_time
    no_time = vml_minimal.sub('DATEIENDE', "STARTPN:1;2;;\nDATEIENDE")
    r1 = validate_string(no_time)
    assert r1.valid?, r1.errors.inspect

    with_time = vml_minimal.sub('DATEIENDE', "STARTPN:1;2;00:10:00,50;\nDATEIENDE")
    r2 = validate_string(with_time)
    assert r2.valid?, r2.errors.inspect
  end

  def test_startst_valid_and_invalid_zahl
    ok = vml_minimal.sub('DATEIENDE', "STARTST:1;1;00:00:10,00;\nDATEIENDE")
    r = validate_string(ok)
    assert r.valid?, r.errors.inspect

    bad = vml_minimal.sub('DATEIENDE', "STARTST:ID;1;;\nDATEIENDE")
    r2 = validate_string(bad)
    assert_includes r2.errors, "Element STARTST, attribute 1: invalid Zahl 'ID' (line 8)"
  end

  def test_staffelperson_valid_and_invalid
    ok = vml_minimal.sub('DATEIENDE', "STAFFELPERSON:1;2;3;4;\nDATEIENDE")
    r = validate_string(ok)
    assert r.valid?, r.errors.inspect

    bad = vml_minimal.sub('DATEIENDE', "STAFFELPERSON:1;A;3;4;\nDATEIENDE")
    r2 = validate_string(bad)
    assert_includes r2.errors, "Element STAFFELPERSON, attribute 2: invalid Zahl 'A' (line 8)"
  end
end

# Additional HANDICAP optional-field combinations
class Dsv7ValidatorVmlHandicapEdgeTest < Minitest::Test
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

  def test_handicap_all_optionals_present_valid
    # attrs: 1 Zahl, 2 opt, 3 opt, 4 req, 5 req, 6 req, 7 opt
    content = vml_minimal.sub(
      'DATEIENDE',
      "HANDICAP:2;Opt2;Opt3;Req4;Req5;Req6;Note\nDATEIENDE"
    )
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_handicap_invalid_attr1_zahl
    content = vml_minimal.sub(
      'DATEIENDE',
      "HANDICAP:ID;Opt2;Opt3;Req4;Req5;Req6;Note\nDATEIENDE"
    )
    r = validate_string(content)
    assert_includes r.errors, "Element HANDICAP, attribute 1: invalid Zahl 'ID' (line 8)"
  end

  def test_handicap_missing_required_attribute_five
    content = vml_minimal.sub(
      'DATEIENDE',
      "HANDICAP:1;;;'Req4';;Req6;;\nDATEIENDE"
    )
    r = validate_string(content)
    assert_includes r.errors, 'Element HANDICAP: missing required attribute 5 on line 8'
  end

  def test_handicap_missing_required_attribute_six
    content = vml_minimal.sub(
      'DATEIENDE',
      "HANDICAP:1;;;'Req4';Req5;;\nDATEIENDE"
    )
    r = validate_string(content)
    assert_includes r.errors, 'Element HANDICAP: missing required attribute 6 on line 8'
  end
end

# Additional KARIABSCHNITT edge combinations
class Dsv7ValidatorVmlKariabschnittEdgeTest < Minitest::Test
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

  def test_kariabschnitt_valid_with_empty_optional_field
    # Use ;; to keep an empty 3rd attribute while maintaining count=3
    content = vml_minimal.sub('DATEIENDE', "KARIABSCHNITT:1;2;;\nDATEIENDE")
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_kariabschnitt_missing_optional_field_is_count_error
    content = vml_minimal.sub('DATEIENDE', "KARIABSCHNITT:1;2\nDATEIENDE")
    r = validate_string(content)
    assert_includes r.errors, 'Element KARIABSCHNITT: expected 3 attributes, got 2 (line 8)'
  end

  def test_kariabschnitt_zero_values_valid
    content = vml_minimal.sub('DATEIENDE', "KARIABSCHNITT:0;0;;\nDATEIENDE")
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end
end
