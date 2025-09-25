# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ParserGenericTest < Minitest::Test
  def sample_vml
    <<~DSV
      (* header comment *)
      FORMAT:Vereinsmeldeliste;7;
      ERZEUGER:Soft;1.0;mail@example.com;
      DATEIENDE
    DSV
  end

  def test_generic_parse_emits_format_and_end
    events = []
    Dsv7::Parser.parse(sample_vml) { |type, payload, line_number| events << [type, payload, line_number] }
    refute_empty events
    assert_equal :format, events.first[0]
    assert_equal :end, events.last[0]
  end

  def test_generic_parse_format_payload
    events = []
    Dsv7::Parser.parse(sample_vml) { |type, payload, line_number| events << [type, payload, line_number] }
    fmt = events.first[1]
    assert_equal 'Vereinsmeldeliste', fmt[:list_type]
    assert_equal '7', fmt[:version]
  end

  def test_generic_parse_enumerator
    enum = Dsv7::Parser.parse(sample_vml)
    assert_kind_of Enumerator, enum
    types = enum.map(&:first)
    assert_includes types, :format
    assert_includes types, :element
    assert_equal :end, types.last
  end

  def test_generic_parse_requires_format
    content = "DATA:invalid;\nDATEIENDE\n"
    err = assert_raises(Dsv7::Parser::Error) { Dsv7::Parser.parse(content).to_a }
    assert_match(/First non-empty line must be FORMAT/, err.message)
  end
end
