# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ValidatorCommentsTest < Minitest::Test
  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def format_line(type = 'Wettkampfergebnisliste', version = '7')
    "FORMAT:#{type};#{version};"
  end

  def test_unmatched_comment_delimiters_error
    content = <<~DSV
      #{format_line}
      (* unmatched;
      DATEIENDE
    DSV

    result = validate_string(content)
    assert_includes result.errors, 'Unmatched comment delimiters (line 2)'
  end

  def test_multiple_inline_comments_in_one_line
    content = <<~DSV
      #{format_line}
      DATA;value (*a*)(*b*) tail
      DATEIENDE
    DSV
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end

  def test_semicolon_only_inside_comment_is_error
    content = <<~DSV
      #{format_line}
      DATA (* ; *)
      DATEIENDE
    DSV
    result = validate_string(content)
    assert_includes result.errors, "Missing attribute delimiter ';' (line 2)"
  end

  def test_multiline_unmatched_comment_reports_both_lines
    content = <<~DSV
      #{format_line}
      (* open
      *)
      DATEIENDE
    DSV
    result = validate_string(content)
    assert_includes result.errors, 'Unmatched comment delimiters (line 2)'
    assert_includes result.errors, 'Unmatched comment delimiters (line 3)'
  end

  def test_comment_only_lines_after_dateiende_are_ok
    content = <<~DSV
      #{format_line}
      DATEIENDE
      (* only comment *)
      (* another *)
    DSV
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end
end
