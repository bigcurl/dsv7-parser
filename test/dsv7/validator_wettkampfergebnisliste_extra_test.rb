# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'dsv7/parser'

module ErgTestHelpers
  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def erg_head
    <<~DSV
      FORMAT:Wettkampfergebnisliste;7;
      ERZEUGER:Soft;1.0;mail@example.com;
      VERANSTALTUNG:Name;Ort;25;HANDZEIT;
      VERANSTALTER:Club;
      AUSRICHTER:SC Duisburg;Biene, Petra;Wabenstr. 69;47055;Duisburg;GER;0888/22222;0888/22223;PetraBiene@GibtsNicht.de;
      ABSCHNITT:1;01.01.2024;10:00;N;
      WETTKAMPF:1;A;1;;100;F;GL;M;SW;;;
      WERTUNG:1;V;1;JG;0;;;OFFEN;
      VEREIN:SV Hansa Adorf;1234;17;GER;
    DSV
  end

  def erg_tail
    <<~DSV
      DATEIENDE
    DSV
  end

  def erg_minimal_without_core_sets
    [
      'FORMAT:Wettkampfergebnisliste;7;',
      'ERZEUGER:Soft;1.0;mail@example.com;',
      'VERANSTALTUNG:Name;Ort;25;HANDZEIT;',
      'VERANSTALTER:Club;',
      'AUSRICHTER:SC Duisburg;Biene, Petra;Wabenstr. 69;47055;Duisburg;GER;0888/22222;' \
      '0888/22223;PetraBiene@GibtsNicht.de;',
      'DATEIENDE'
    ].join("\n")
  end
end

class Dsv7ValidatorErgExtraTest < Minitest::Test
  include ErgTestHelpers

  def test_staffelergebnis_alias_is_accepted
    content = "#{erg_head}" \
              "STAFFELERGEBNIS:4;E;6;1;;1;2012;Delphin Burgstadt;1235;00:04:29,74;;;;\n" \
              "#{erg_tail}"
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_duplicate_required_elements_are_reported
    content = erg_head.sub(
      "ERZEUGER:Soft;1.0;mail@example.com;\n",
      "ERZEUGER:Soft;1.0;mail@example.com;\nERZEUGER:Soft;1.0;mail@example.com;\n"
    ) + erg_tail
    r = validate_string(content)
    assert_includes r.errors,
                    "Wettkampfergebnisliste: element 'ERZEUGER' occurs 2 times (expected 1)"
  end

  def test_require_at_least_one_of_core_sets
    r = validate_string(erg_minimal_without_core_sets)
    %w[ABSCHNITT WETTKAMPF WERTUNG VEREIN].each do |el|
      assert_includes r.errors, "Wettkampfergebnisliste: missing required element '#{el}'"
    end
  end

  def test_veranstaltung_invalid_bahnl_and_zeitmessung
    bad = erg_head.gsub('VERANSTALTUNG:Name;Ort;25;HANDZEIT;',
                        'VERANSTALTUNG:Name;Ort;34;SCHNELLZEIT;') + erg_tail
    r = validate_string(bad)
    msg1 = "Element VERANSTALTUNG, attribute 3: invalid Bahnlänge '34' (allowed: " \
           '16, 20, 25, 33, 50, FW, X) (line 3)'
    msg2 = "Element VERANSTALTUNG, attribute 4: invalid Zeitmessung 'SCHNELLZEIT' (allowed: " \
           'HANDZEIT, AUTOMATISCH, HALBAUTOMATISCH) (line 3)'
    assert_includes r.errors, msg1
    assert_includes r.errors, msg2
  end

  def test_abschnitt_impossible_date_and_time_out_of_range
    bad = erg_head.gsub('ABSCHNITT:1;01.01.2024;10:00;N;',
                        'ABSCHNITT:1;31.02.2024;24:00;N;') + erg_tail
    r = validate_string(bad)
    assert_includes r.errors,
                    "Element ABSCHNITT, attribute 2: impossible date '31.02.2024' (line 6)"
    assert_includes r.errors,
                    "Element ABSCHNITT, attribute 3: time out of range '24:00' (line 6)"
  end
end

class Dsv7ValidatorErgExtra2Test < Minitest::Test
  include ErgTestHelpers

  def test_verein_invalid_land
    bad = erg_head.gsub('VEREIN:SV Hansa Adorf;1234;17;GER;',
                        'VEREIN:SV Hansa Adorf;1234;17;DE;') + erg_tail
    r = validate_string(bad)
    assert_includes r.errors,
                    "Element VEREIN, attribute 4: invalid Land 'DE' " \
                    '(expected FINA code, e.g., GER) (line 9)'
  end

  def test_wertung_invalid_wert_typ_and_jgak
    bad = erg_head.gsub('WERTUNG:1;V;1;JG;0;;;OFFEN;',
                        'WERTUNG:1;V;1;XX;foo;;;OFFEN;') + erg_tail
    r = validate_string(bad)
    assert_includes r.errors,
                    "Element WERTUNG, attribute 4: invalid Wertungstyp 'XX' " \
                    '(allowed: JG, AK) (line 8)'
    assert_includes r.errors,
                    "Element WERTUNG, attribute 5: invalid JG/AK 'foo' (line 8)"
  end

  def test_wettkampf_optional_wk_art_invalid
    bad = erg_head.gsub('WETTKAMPF:1;A;1;;100;F;GL;M;SW;;;',
                        'WETTKAMPF:1;A;1;;100;F;GL;M;SW;;Q;') + erg_tail
    r = validate_string(bad)
    assert_includes r.errors,
                    "Element WETTKAMPF, attribute 11: invalid Wettkampfart 'Q' " \
                    '(allowed: V, Z, F, E) (line 7)'
  end

  def test_comment_only_lines_after_dateiende_are_ok
    content = <<~DSV
      FORMAT:Wettkampfergebnisliste;7;
      DATEIENDE
      (* trailing note *)
      (* another one *)
    DSV
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end
end
