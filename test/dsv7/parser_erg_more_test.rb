# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ParserErgMoreTest < Minitest::Test
  def erg_sample
    <<~DSV
      FORMAT:Wettkampfergebnisliste;7;
      ERZEUGER:Soft;1.0;mail@example.com; (* inline *)
      VERANSTALTUNG:Name;Ort;25;HANDZEIT;
      DATEIENDE
    DSV
  end

  def test_stops_emitting_after_dateiende
    content = "FORMAT:Wettkampfergebnisliste;7;\n" \
              "ERZEUGER:Soft;1.0;mail@example.com;\n" \
              "DATEIENDE\n" \
              "ERZEUGER:Other;2.0;after@eol;\n"
    events = Dsv7::Parser.parse_wettkampfergebnisliste(content).to_a
    assert_equal :format, events.first[0]
    # Only the first ERZEUGER should be emitted
    assert_equal(1, events.count { |e| e[0] == :element && e[1][:name] == 'ERZEUGER' })
    assert_equal :end, events.last[0]
  end

  def test_accepts_bom_prefix
    bom = "\xEF\xBB\xBF"
    events = Dsv7::Parser.parse_wettkampfergebnisliste(bom + erg_sample).to_a
    assert_equal :format, events.first[0]
    assert_equal 'Wettkampfergebnisliste', events.first[1][:list_type]
  end

  def test_reads_from_path
    path = 'tmp/parser_erg_more_input.DSV7'
    begin
      File.write(path, erg_sample)
      enum = Dsv7::Parser.parse_wettkampfergebnisliste(path)
      types = enum.map(&:first)
      assert_includes types, :format
      assert_equal :end, types.last
    ensure
      FileUtils.rm_f(path)
    end
  end

  def test_raises_for_missing_format
    content = "ERZEUGER:Soft;1.0;mail@example.com;\nDATEIENDE\n"
    err = assert_raises(Dsv7::Parser::Error) do
      Dsv7::Parser.parse_wettkampfergebnisliste(content).to_a
    end
    assert_match(/First non-empty line must be FORMAT/, err.message)
  end

  def test_handles_crlf_and_inline_comment_stripping
    content = "FORMAT:Wettkampfergebnisliste;7;\r\n" \
              "ERZEUGER:Soft(* c *);1.0(* c*);mail@example.com(* c*);\r\n" \
              "DATEIENDE\r\n"
    events = Dsv7::Parser.parse_wettkampfergebnisliste(content).to_a
    el = events.find { |e| e[0] == :element }
    assert_equal 'ERZEUGER', el[1][:name]
    assert_equal ['Soft', '1.0', 'mail@example.com'], el[1][:attrs]
  end
end
