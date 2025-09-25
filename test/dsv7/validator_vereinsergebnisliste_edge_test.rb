# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'fileutils'
require 'dsv7/parser'

class Dsv7ValidatorVrlEdgeTest < Minitest::Test
  def setup
    FileUtils.mkdir_p('tmp')
  end

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

  def test_comment_only_lines_after_dateiende_are_ignored
    content = "#{vrl_head}#{vrl_tail}(* trailing comment *)\n\n"
    r = validate_string(content)
    assert r.valid?, r.errors.inspect
  end

  def test_multiple_erzeuger_reports_cardinality_error
    dup = vrl_head.sub(
      "ERZEUGER:Soft;1.0;mail@example.com;\n",
      "ERZEUGER:Soft;1.0;mail@example.com;\nERZEUGER:Other;2.0;other@example.com;\n"
    ) +
          vrl_tail
    r = validate_string(dup)
    msg = "Vereinsergebnisliste: element 'ERZEUGER' occurs 2 times (expected 1)"
    assert_includes r.errors, msg
  end

  def test_stzwischenzeit_invalid_zahl_attribute
    bad = "#{vrl_head}STZWISCHENZEIT:2525;4;E;1;X;00:01:04,11;\n#{vrl_tail}"
    r = validate_string(bad)
    assert_includes r.errors, "Element STZWISCHENZEIT, attribute 5: invalid Zahl 'X' (line 10)"
  end

  def test_stabloese_invalid_time_format
    bad = "#{vrl_head}STABLOESE:2525;4;E;1;+;00:00:0,30;\n#{vrl_tail}"
    r = validate_string(bad)
    msg = "Element STABLOESE, attribute 6: invalid Zeit '00:00:0,30' " \
          '(expected HH:MM:SS,hh) (line 10)'
    assert_includes r.errors, msg
  end

  def test_pnreaktion_missing_art_is_allowed
    ok = "#{vrl_head}PNREAKTION:4711;1;V;;00:00:00,50;\n#{vrl_tail}"
    r = validate_string(ok)
    assert r.valid?, r.errors.inspect
  end

  def test_person_invalid_geschlecht
    bad = "#{vrl_head}PERSON:Doe, Jane;123456;4711;X;1990;;;GER;;\n#{vrl_tail}"
    r = validate_string(bad)
    msg = "Element PERSON, attribute 4: invalid Geschlecht 'X' (allowed: M, W, D) (line 10)"
    assert_includes r.errors, msg
  end

  def test_personergebnis_invalid_nachtrag_flag
    bad = vrl_head + "PERSON:Doe, Jane;123456;4711;D;1990;;;GER;;\n" \
                     "PERSONENERGEBNIS:4711;1;V;1;7;00:01:00,82;;;K\n" \
          + vrl_tail
    r = validate_string(bad)
    msg = "Element PERSONENERGEBNIS, attribute 9: invalid Nachtragskennzeichen 'K' " \
          '(allowed: E, F, N) (line 11)'
    assert_includes r.errors, msg
  end

  def test_filename_pattern_ok_for_vrl
    path = 'tmp/2025-09-22-Berlin-Pr.DSV7'
    File.write(path, vrl_head + vrl_tail)
    result = Dsv7::Validator.validate(path)
    assert_empty result.warnings
    assert result.valid?
  ensure
    FileUtils.rm_f(path)
  end

  def test_filename_bad_pattern_warns_for_vrl
    path = 'tmp/2025_09_22_BerlinPr.DSV7'
    File.write(path, vrl_head + vrl_tail)
    result = Dsv7::Validator.validate(path)
    msg = "Filename '2025_09_22_BerlinPr.DSV7' does not follow 'JJJJ-MM-TT-Ort-Zusatz.DSV7'"
    assert_includes result.warnings, msg
    assert result.valid?
  ensure
    FileUtils.rm_f(path)
  end
end
