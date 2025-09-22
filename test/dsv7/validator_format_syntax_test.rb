# frozen_string_literal: true

require 'minitest/autorun'
require 'dsv7/parser'

class Dsv7ValidatorFormatSyntaxTest < Minitest::Test
  def validate_string(content)
    Dsv7::Validator.validate(content)
  end

  def format_line(type = 'Wettkampfdefinitionsliste', version = '7')
    "FORMAT:#{type};#{version};"
  end

  def test_all_allowed_list_types_accept
    types = %w[
      Wettkampfdefinitionsliste Vereinsmeldeliste
      Wettkampfergebnisliste Vereinsergebnisliste
    ]
    types.each do |type|
      content = "#{format_line(type)}\nDATA;ok\nDATEIENDE\n"
      result = validate_string(content)
      assert result.valid?, "Expected valid for #{type}: #{result.errors.inspect}"
    end
  end

  def test_format_missing_trailing_semicolon_errors
    content = "FORMAT:Wettkampfdefinitionsliste;7\nDATA;ok\nDATEIENDE\n"
    result = validate_string(content)
    msg = "First non-empty line must be 'FORMAT:<Listentyp>;7;' (line 1)"
    assert_includes result.errors, msg
  end

  def test_inline_comment_on_format_is_ok
    content = "#{format_line} (* inline *)\nDATA;ok\nDATEIENDE\n"
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end

  def test_leading_trailing_spaces_on_keywords_are_ok
    content = "  #{format_line}  \nDATA;ok\n  DATEIENDE   \n"
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end

  def test_lowercased_keywords_error
    content = "format:Wettkampfdefinitionsliste;7;\nDateIEnde\n"
    result = validate_string(content)
    msg = "First non-empty line must be 'FORMAT:<Listentyp>;7;' (line 1)"
    assert_includes result.errors, msg
    assert_includes result.errors, "Missing 'DATEIENDE' terminator line"
  end

  def test_dateiende_with_trailing_spaces_is_ok
    content = "#{format_line}\nDATA;ok\nDATEIENDE   \n"
    result = validate_string(content)
    assert result.valid?, result.errors.inspect
  end
end
