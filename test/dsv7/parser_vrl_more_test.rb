# frozen_string_literal: true

require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ParserVrlMoreTest < Minitest::Test
  def vrl_sample
    <<~DSV
      FORMAT:Vereinsergebnisliste;7;
      ERZEUGER:Soft;1.0;mail@example.com; (* inline *)
      VERANSTALTUNG:Name;Ort;25;HANDZEIT;
      DATEIENDE
    DSV
  end

  def test_stops_emitting_after_dateiende
    content = "FORMAT:Vereinsergebnisliste;7;\n" \
              "ERZEUGER:Soft;1.0;mail@example.com;\n" \
              "DATEIENDE\n" \
              "PERSON:Should;Not;Appear;Here;W;2000;;;GER;\n"
    events = Dsv7::Parser.parse_vereinsergebnisliste(content).to_a
    assert_equal :format, events.first[0]
    # Only the first ERZEUGER should be emitted
    assert_equal(1, events.count { |e| e[0] == :element && e[1][:name] == 'ERZEUGER' })
    assert_equal :end, events.last[0]
  end

  def test_accepts_bom_prefix
    bom = "\xEF\xBB\xBF"
    events = Dsv7::Parser.parse_vereinsergebnisliste(bom + vrl_sample).to_a
    assert_equal :format, events.first[0]
    assert_equal 'Vereinsergebnisliste', events.first[1][:list_type]
  end

  def test_reads_from_path
    path = 'tmp/parser_vrl_more_input.DSV7'
    begin
      File.write(path, vrl_sample)
      enum = Dsv7::Parser.parse_vereinsergebnisliste(path)
      types = enum.map(&:first)
      assert_includes types, :format
      assert_equal :end, types.last
    ensure
      FileUtils.rm_f(path)
    end
  end
end
