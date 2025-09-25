# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'dsv7/parser'

class Dsv7ValidatorErgElementsTest < Minitest::Test
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

  def test_pnergebnis_valid
    ok = "#{erg_head}" \
         "PNERGEBNIS:1;V;1;1;;Schwimmer, Max;123456;4711;D;1990;;Club;1234;00:01:00,82;;;GER;;;\n" \
         "#{erg_tail}"
    r_ok = validate_string(ok)
    assert r_ok.valid?, r_ok.errors.inspect
  end

  def test_pnergebnis_invalid_time
    bad = "#{erg_head}" \
          "PNERGEBNIS:1;V;1;1;;Schwimmer, Max;123456;4711;D;1990;;Club;1234;1:00,82;;;GER;;;\n" \
          "#{erg_tail}"
    r_bad = validate_string(bad)
    msg = 'Element PNERGEBNIS, attribute 14: invalid Zeit ' \
          "'1:00,82' (expected HH:MM:SS,hh) (line 10)"
    assert_includes r_bad.errors, msg
  end

  def test_pnzwischenzeit_and_pnreaktion_valid
    content = "#{erg_head}" \
              "PNZWISCHENZEIT:4711;1;N;50;00:00:29,06;\n" \
              "PNREAKTION:4711;1;V;+;00:00:00,50;\n" \
              "#{erg_tail}"
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_pnreaktion_invalid_art
    bad = "#{erg_head}" \
          "PNREAKTION:4711;1;V;K;00:00:00,50;\n" \
          "#{erg_tail}"
    r2 = validate_string(bad)
    msg2 = "Element PNREAKTION, attribute 4: invalid Reaktionsart 'K' " \
           '(allowed: +, -) (line 10)'
    assert_includes r2.errors, msg2
  end

  def test_stergebnis_and_staffelperson_and_stzeiten
    content = "#{erg_head}" \
              "STERGEBNIS:4;E;6;1;;1;2012;Delphin Burgstadt;1235;00:04:29,74;;;;\n" \
              "STAFFELPERSON:2012;4;E;Doe, John;123437;1;M;1989;;GER;;;\n" \
              "STZWISCHENZEIT:2012;4;E;1;100;00:01:04,11;\n" \
              "STABLOESE:2012;4;E;1;+;00:00:00,30;\n" \
              "#{erg_tail}"
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end
end
