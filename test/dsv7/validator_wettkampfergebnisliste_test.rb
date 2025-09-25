# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'dsv7/parser'

class Dsv7ValidatorErgTest < Minitest::Test
  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def erg_minimal
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
      DATEIENDE
    DSV
  end

  def test_minimal_erg_is_valid
    result = validate_string(erg_minimal)
    assert result.valid?, result.errors.inspect
  end

  def test_missing_required_elements_are_reported
    content = <<~DSV
      FORMAT:Wettkampfergebnisliste;7;
      WETTKAMPF:1;A;1;;100;F;GL;M;SW;;;
      DATEIENDE
    DSV
    result = validate_string(content)
    missing = %w[ERZEUGER VERANSTALTUNG VERANSTALTER AUSRICHTER ABSCHNITT WERTUNG VEREIN]
    missing.each do |el|
      assert_includes result.errors, "Wettkampfergebnisliste: missing required element '#{el}'"
    end
  end

  def test_wettkampf_wk_art_allows_a_and_n
    content = erg_minimal.sub('WETTKAMPF:1;A;', 'WETTKAMPF:1;N;')
    r = validate_string(content)
    assert r.valid?, r.errors.inspect

    bad = erg_minimal.sub('WETTKAMPF:1;A;', 'WETTKAMPF:1;Q;')
    r2 = validate_string(bad)
    msg = "Element WETTKAMPF, attribute 2: invalid Wettkampfart 'Q' " \
          '(allowed: V, Z, F, E, A, N) on line 7'
    assert_includes r2.errors, msg
  end
end
