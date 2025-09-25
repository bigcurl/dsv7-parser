# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ParserVrlEdgeTest < Minitest::Test
  def sample_with_spacing
    <<~DSV

      (* header comment *)
      FORMAT:Vereinsergebnisliste;7;
      ERZEUGER:Soft;1.0;mail@example.com;
      VERANSTALTUNG:Name;Ort;25;HANDZEIT; (* inline *)
      DATEIENDE
      PERSON:Should;Not;Be;Seen;W;2000;;;GER;;
    DSV
  end

  def line_number_for(events, type, name = nil)
    case type
    when :format
      events.find { |e| e[0] == :format }[2]
    when :element
      events.find { |e| e[0] == :element && e[1][:name] == name }[2]
    when :end
      events.last[2]
    else
      raise ArgumentError, "unknown type: #{type}"
    end
  end

  def test_emits_correct_line_numbers
    events = Dsv7::Parser.parse_vereinsergebnisliste(sample_with_spacing).to_a
    assert_equal 3, line_number_for(events, :format),
                 'FORMAT line number should match physical line'

    assert_equal 4, line_number_for(events, :element, 'ERZEUGER')

    assert_equal :end, events.last[0]
    assert_equal 6, line_number_for(events, :end), 'DATEIENDE position should be recorded on :end'
  end

  def test_strips_inline_comment_from_attributes
    events = Dsv7::Parser.parse_vereinsergebnisliste(sample_with_spacing).to_a
    ver = events.find { |e| e[0] == :element && e[1][:name] == 'VERANSTALTUNG' }
    refute_nil ver
    assert_equal %w[Name Ort 25 HANDZEIT], ver[1][:attrs]
  end

  def test_raises_if_first_effective_line_is_not_format
    content = "ERZEUGER:Soft;1.0;mail@example.com;\nDATEIENDE\n"
    err = assert_raises(Dsv7::Parser::Error) do
      Dsv7::Parser.parse_vereinsergebnisliste(content).to_a
    end
    assert_match(/First non-empty line must be FORMAT \(line 1\)/, err.message)
  end
end
