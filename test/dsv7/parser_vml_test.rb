# frozen_string_literal: true

require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ParserVmlTest < Minitest::Test
  def collect_events
    events = []
    Dsv7::Parser.parse_vereinsmeldeliste(vml_sample) do |type, payload, line_number|
      events << [type, payload, line_number]
    end
    events
  end

  def vml_sample
    <<~DSV
      (* header comment *)
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

  def test_streams_format_event
    events = collect_events
    refute_empty events
    fmt = events.shift
    assert_equal :format, fmt[0]
    assert_equal 'Vereinsmeldeliste', fmt[1][:list_type]
    assert_equal '7', fmt[1][:version]
  end

  def test_streams_first_element_and_end
    events = collect_events
    first_el = events.find { |e| e[0] == :element }
    refute_nil first_el
    assert_equal 'ERZEUGER', first_el[1][:name]
    assert_equal ['Soft', '1.0', 'mail@example.com'], first_el[1][:attrs]
    assert_equal :end, events.last[0]
  end

  def test_returns_enumerator_without_block
    enum = Dsv7::Parser.parse_vereinsmeldeliste(vml_sample)
    assert_kind_of Enumerator, enum
    types = enum.map(&:first)
    assert_includes types, :format
    assert_includes types, :element
    assert_equal :end, types.last
  end

  def test_raises_for_other_list_types
    content = "FORMAT:Wettkampfdefinitionsliste;7;\nDATEIENDE\n"
    assert_raises(Dsv7::Parser::Error) do
      Dsv7::Parser.parse_vereinsmeldeliste(content).to_a
    end
  end
end
