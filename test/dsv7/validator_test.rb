# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'fileutils'
require 'dsv7/parser'

class Dsv7ValidatorTest < Minitest::Test
  def setup
    FileUtils.mkdir_p('tmp')
  end

  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def format_line(type = 'Wettkampfergebnisliste', version = '7')
    "FORMAT:#{type};#{version};"
  end

  def test_valid_minimal_file_is_valid
    content = <<~DSV
      (* header comment *)

      #{format_line}
      DATA;ok
      DATEIENDE
    DSV

    result = validate_string(content)
    assert result.valid?, "Expected valid, errors: #{result.errors.inspect}"
    assert_empty result.warnings
  end

  def test_format_line_must_be_first_effective_line
    content = <<~DSV
      XYZ;abc
      DATEIENDE
    DSV

    result = validate_string(content)
    assert_includes result.errors, "First non-empty line must be 'FORMAT:<Listentyp>;7;' (line 1)"
  end

  def test_unknown_list_type_is_error
    content = <<~DSV
      #{format_line('Unbekannt')}
      DATEIENDE
    DSV

    result = validate_string(content)
    assert_includes result.errors, "Unknown list type in FORMAT: 'Unbekannt' (line 1)"
  end

  def test_version_must_be_seven
    content = <<~DSV
      #{format_line('Wettkampfdefinitionsliste', '6')}
      DATEIENDE
    DSV

    result = validate_string(content)
    assert_includes result.errors, "Unsupported format version '6', expected '7' (line 1)"
  end

  def test_dateiende_must_be_present
    content = <<~DSV
      #{format_line}
    DSV

    result = validate_string(content)
    assert_includes result.errors, "Missing 'DATEIENDE' terminator line"
  end

  def test_no_effective_content_allowed_after_dateiende
    content = "#{format_line}\nDATEIENDE\nDATA;after\n"
    result = validate_string(content)
    assert_includes result.errors, "Content found after 'DATEIENDE' (line 3)"
  end
end
