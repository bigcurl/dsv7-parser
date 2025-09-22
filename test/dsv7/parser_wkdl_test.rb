# frozen_string_literal: true

require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ParserWkdlTest < Minitest::Test
  def wkdl_sample
    <<~DSV
      (* header comment *)
      FORMAT:Wettkampfdefinitionsliste;7;
      ERZEUGER:Soft;1.0;mail@example.com;
      VERANSTALTUNG:Name;Ort;25;HANDZEIT; (* inline *)
      MELDESCHLUSS:01.01.2024;12:00;
      DATEIENDE
    DSV
  end

  def test_streams_events_for_wkdl
    events = []
    Dsv7::Parser.parse_wettkampfdefinitionsliste(wkdl_sample) do |type, payload, line_number|
      events << [type, payload, line_number]
    end

    refute_empty events

    fmt = events.shift
    assert_equal :format, fmt[0]
    assert_equal 'Wettkampfdefinitionsliste', fmt[1][:list_type]
    assert_equal '7', fmt[1][:version]

    first_el = events.find { |e| e[0] == :element }
    refute_nil first_el
    assert_equal 'ERZEUGER', first_el[1][:name]
    assert_equal ['Soft', '1.0', 'mail@example.com'], first_el[1][:attrs]

    assert_equal :end, events.last[0]
  end

  def test_returns_enumerator_without_block
    enum = Dsv7::Parser.parse_wettkampfdefinitionsliste(wkdl_sample)
    assert_kind_of Enumerator, enum
    types = enum.map(&:first)
    assert_includes types, :format
    assert_includes types, :element
    assert_equal :end, types.last
  end

  def test_raises_for_other_list_types
    content = "FORMAT:Vereinsmeldeliste;7;\nDATEIENDE\n"
    assert_raises(Dsv7::Parser::Error) do
      Dsv7::Parser.parse_wettkampfdefinitionsliste(content).to_a
    end
  end
end
