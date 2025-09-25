# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'fileutils'
require 'dsv7/parser'
require_relative 'e2e_helpers'

class Dsv7E2EErgVrlTest < Minitest::Test
  include Dsv7E2EHelpers

  def test_e2e_erg_validate_then_parse
    content = erg_minimal
    result = validate_string(content)
    assert result.valid?, "Expected valid, errors: #{result.errors.inspect}"
    enum = parse_for_list_type(result.list_type, content)
    assert_parses_minimally(enum, 'Wettkampfergebnisliste')
  end

  def test_e2e_vrl_validate_then_parse
    content = vrl_minimal
    result = validate_string(content)
    assert result.valid?, "Expected valid, errors: #{result.errors.inspect}"
    enum = parse_for_list_type(result.list_type, content)
    assert_parses_minimally(enum, 'Vereinsergebnisliste')
  end

  def test_e2e_crlf_is_warned_but_parsed
    content = vml_minimal.gsub("\n", "\r\n")
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
    assert_includes result.warnings, 'CRLF line endings detected'
    enum = Dsv7::Parser.parse_vereinsmeldeliste(content)
    assert_parses_minimally(enum, 'Vereinsmeldeliste')
  end

  def test_e2e_bad_filename_warns_but_parsed
    path = 'tmp/e2e_badname.txt'
    File.write(path, vml_minimal)
    result = Dsv7::Validator.validate(path)
    assert result.valid?, result.errors.inspect
    assert_includes result.warnings,
                    "Filename 'e2e_badname.txt' does not follow 'JJJJ-MM-TT-Ort-Zusatz.DSV7'"
    assert_parses_minimally(Dsv7::Parser.parse_vereinsmeldeliste(path), 'Vereinsmeldeliste')
  ensure
    FileUtils.rm_f(path)
  end

  def test_e2e_comments_after_dateiende_are_ok_and_not_emitted
    content = "#{vml_minimal}(* trailing comment *)\n\n"
    result = validate_string(content)
    assert result.valid?, 'Comment-only lines after DATEIENDE should be allowed'
    events = Dsv7::Parser.parse_vereinsmeldeliste(content).to_a
    assert_equal :end, events.last[0]
    # Ensure no element after DATEIENDE was emitted
    assert_nil(events[0..-2].find { |e| e[0] == :element && e[2] > events.last[2] })
  end

  def test_e2e_content_after_dateiende_is_rejected_but_not_parsed
    content = "FORMAT:Vereinsmeldeliste;7;\nDATEIENDE\nDATA;after\n"
    result = validate_string(content)
    assert_includes result.errors, "Content found after 'DATEIENDE' (line 3)"
    # Parser should stop at DATEIENDE and not emit the trailing DATA line
    events = Dsv7::Parser.parse_vereinsmeldeliste(content).to_a
    assert_equal :end, events.last[0]
    assert_nil(events.find { |e| e[0] == :element && e[1][:name] == 'DATA' })
  end
end
