# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'dsv7/parser'

class Dsv7ValidatorEncodingTest < Minitest::Test
  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def format_line(type = 'Wettkampfergebnisliste', version = '7')
    "FORMAT:#{type};#{version};"
  end

  def test_utf8_bom_detected_as_error
    bom = "\xEF\xBB\xBF".b
    content = bom + "#{format_line}\nDATEIENDE\n"
    result = validate_string(content)
    assert_includes result.errors, 'UTF-8 BOM detected (spec requires UTF-8 without BOM)'
  end

  def test_invalid_utf8_triggers_error
    invalid_byte = [0xC3].pack('C') # lone lead byte -> invalid UTF-8
    content = "#{format_line}\n(* #{invalid_byte} *)\nDATEIENDE\n"
    result = validate_string(content)
    assert_includes result.errors, 'File is not valid UTF-8 encoding'
  end

  def test_invalid_utf8_in_data_line_errors
    invalid = "\xC3".b
    content = "#{format_line}\nDATA;ok#{invalid}\nDATEIENDE\n"
    result = validate_string(content)
    assert_includes result.errors, 'File is not valid UTF-8 encoding'
  end

  def test_crlf_line_endings_warn
    content = "#{format_line}\r\nDATEIENDE\r\n"
    result = validate_string(content)
    assert_includes result.warnings, 'CRLF line endings detected'
    assert result.valid?, "Unexpected errors: #{result.errors.inspect}"
  end

  def test_mixed_lf_and_crlf_warns_once_and_valid
    content = "#{format_line}\r\nDATA;ok\nDATEIENDE\r\n"
    result = validate_string(content)
    assert_includes result.warnings, 'CRLF line endings detected'
    assert result.valid?, result.errors.inspect
  end
end
