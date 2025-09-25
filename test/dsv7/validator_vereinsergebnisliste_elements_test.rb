# frozen_string_literal: true

require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ValidatorVrlElementsTest < Minitest::Test
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

  def test_person_and_personergebnis_valid
    content = "#{vrl_head}" \
              "PERSON:Doe, Jane;123456;4711;D;1990;;;GER;;\n" \
              "PERSONENERGEBNIS:4711;1;V;1;7;00:01:00,82;;;;\n" \
              "#{vrl_tail}"
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_personergebnis_invalid_time
    bad = "#{vrl_head}" \
          "PERSON:Doe, Jane;123456;4711;D;1990;;;GER;;\n" \
          "PERSONENERGEBNIS:4711;1;V;1;7;1:00,82;;;;\n" \
          "#{vrl_tail}"
    r = validate_string(bad)
    msg = "Element PERSONENERGEBNIS, attribute 6: invalid Zeit '1:00,82' " \
          '(expected HH:MM:SS,hh) on line 11'
    assert_includes r.errors, msg
  end

  def test_personergebnis_invalid_grund_nichtwertung
    bad = "#{vrl_head}" \
          "PERSON:Doe, Jane;123456;4711;D;1990;;;GER;;\n" \
          "PERSONENERGEBNIS:4711;1;V;1;7;00:01:00,82;K;;;\n" \
          "#{vrl_tail}"
    r = validate_string(bad)
    msg = "Element PERSONENERGEBNIS, attribute 7: invalid Grund der Nichtwertung 'K' " \
          '(allowed: DS, NA, AB, AU, ZU) on line 11'
    assert_includes r.errors, msg
  end

  def test_pnzeiten_and_pnreaktion_valid
    content = "#{vrl_head}" \
              "PERSON:Doe, Jane;123456;4711;D;1990;;;GER;;\n" \
              "PNZWISCHENZEIT:4711;1;N;50;00:00:29,06;\n" \
              "PNREAKTION:4711;1;V;+;00:00:00,50;\n" \
              "#{vrl_tail}"
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_pnreaktion_invalid_art
    content = "#{vrl_head}" \
              "PERSON:Doe, Jane;123456;4711;D;1990;;;GER;;\n" \
              "PNZWISCHENZEIT:4711;1;N;50;00:00:29,06;\n" \
              "PNREAKTION:4711;1;V;K;00:00:00,50;\n" \
              "#{vrl_tail}"
    r = validate_string(content)
    msg = "Element PNREAKTION, attribute 4: invalid Reaktionsart 'K' " \
          '(allowed: +, -) on line 12'
    assert_includes r.errors, msg
  end

  def test_staffel_and_related_elements
    content = "#{vrl_head}" \
              "STAFFEL:1;2525;JG;1989;1990;\n" \
              "STAFFELPERSON:2525;4;E;Doe, John;123437;1;M;1989;;GER;;;\n" \
              "STAFFELERGEBNIS:2525;4;E;1;2;00:04:30,84;;;;;\n" \
              "STZWISCHENZEIT:2525;4;E;1;100;00:01:04,11;\n" \
              "STABLOESE:2525;4;E;1;+;00:00:00,30;\n" \
              "#{vrl_tail}"
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end
end
