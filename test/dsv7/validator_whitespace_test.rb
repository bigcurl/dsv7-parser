# frozen_string_literal: true

require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ValidatorWhitespaceTest < Minitest::Test
  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def test_empty_file_reports_missing_format_and_dateiende
    result = validate_string('')
    assert_includes result.errors, 'Missing FORMAT line at top of file'
    assert_includes result.errors, "Missing 'DATEIENDE' terminator line"
  end

  def test_only_comments_and_whitespace_reports_missing_both
    content = "\n  (* x *)\n\n\t\n"
    result = validate_string(content)
    assert_includes result.errors, 'Missing FORMAT line at top of file'
    assert_includes result.errors, "Missing 'DATEIENDE' terminator line"
  end

  def test_whitespace_only_lines_after_dateiende_are_ok
    content = "FORMAT:Wettkampfergebnisliste;7;\nDATEIENDE\n   \n\t\n"
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end

  def test_comment_only_lines_after_dateiende_are_ok
    content = "FORMAT:Wettkampfergebnisliste;7;\nDATEIENDE\n(* trailing comment *)\n(* another *)\n"
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end
end
