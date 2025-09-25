# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'dsv7/parser'

class Dsv7ValidatorVrlExtraTest < Minitest::Test
  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def vrl_head
    <<~DSV
      FORMAT:Vereinsergebnisliste;7;
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

  def vrl_tail
    <<~DSV
      DATEIENDE
    DSV
  end

  def test_kampfgericht_valid
    content = "#{vrl_head}KAMPFGERICHT:1;Obmann;Starter;Zeitnehmer;\n#{vrl_tail}"
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_stergebnis_alias_valid
    content = "#{vrl_head}STERGEBNIS:2525;4;E;1;2;00:04:30,84;;;;;\n#{vrl_tail}"
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_wertung_invalid_wk_art
    content = vrl_head.sub('WERTUNG:1;V;1;JG;0;;;OFFEN;', 'WERTUNG:1;A;1;JG;0;;;OFFEN;') + vrl_tail
    r = validate_string(content)
    msg = "Element WERTUNG, attribute 2: invalid Wettkampfart 'A' (allowed: V, Z, F, E) (line 8)"
    assert_includes r.errors, msg
  end

  def test_wertung_ak_is_valid
    content = vrl_head.sub(
      'WERTUNG:1;V;1;JG;0;;;OFFEN;',
      'WERTUNG:1;V;1;AK;80+;;;AK 80+;'
    ) + vrl_tail
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_personergebnis_attribute_count_error
    # 8 attributes instead of 9: drop one trailing empty
    body = "#{vrl_head}" \
           "PERSON:Doe, Jane;123456;4711;D;1990;;;GER;;\n" \
           "PERSONENERGEBNIS:4711;1;V;1;7;00:01:00,82;;;\n" \
           "#{vrl_tail}"
    r = validate_string(body)
    assert_includes r.errors, 'Element PERSONENERGEBNIS: expected 9 attributes, got 8 (line 11)'
  end
end
